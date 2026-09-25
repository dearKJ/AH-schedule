import '../venue.dart';
import '../week_set.dart';

/// 单元格正文里解出来的**一条叶子安排**——正文里的一对「课程行 + 周次行」。
///
/// 「叶子」是为了跟领域层的 `ClassSession` 区分：这里的周次还带着写法上的原样
/// （比如 `停课` 那一行），也还没有星期与节次。合并停课例外、贴星期节次、变成
/// `ClassSession` 是下一步的事（`class_session_builder.dart`）。
class Arrangement {
  const Arrangement({
    required this.courseName,
    required this.teacher,
    required this.weeks,
    required this.venue,
  });

  /// 课程名称（教学内容本身），已经从做法里去掉课程号那一段。
  final String courseName;

  /// 教师。没有时是 null。
  final String? teacher;

  /// 这一行的周次集合。`停课` / `线上教学` 那两条的周次也在这里。
  final WeekSet weeks;

  final ArrangementVenue venue;

  /// 这一行说的是「这周不上」而不是「这周在哪上」。
  bool get isCancellation => venue is CancellationVenue;

  @override
  String toString() =>
      '$courseName${teacher == null ? '' : ' ($teacher)'} '
      '${weeks.toText()}周 @${venue.toText()}';

  @override
  bool operator ==(Object other) =>
      other is Arrangement &&
      other.courseName == courseName &&
      other.teacher == teacher &&
      other.weeks == weeks &&
      other.venue == venue;

  @override
  int get hashCode => Object.hash(courseName, teacher, weeks, venue);
}

/// 正文里周次那一格解出来的地点。
///
/// 三个子类都是**值对象**：`==` 按内容比。这一层没有领域层那些校验（比如
/// [Venue] 不许教室名为空白）——它只负责把写法的原样记下来，合不合法由
/// `class_session_builder.dart` 转给 [Venue] 时再说。
sealed class ArrangementVenue {
  const ArrangementVenue();

  /// 原样写法，用于诊断。
  String toText();
}

/// 有教室也有校区（或只有教室）。
final class RoomVenue extends ArrangementVenue {
  const RoomVenue({required this.room, required this.campus});

  final String room;
  final String? campus;

  @override
  String toText() => campus == null ? room : '$room($campus)';

  @override
  String toString() => toText();

  @override
  bool operator ==(Object other) =>
      other is RoomVenue && other.room == room && other.campus == campus;

  @override
  int get hashCode => Object.hash(room, campus);
}

/// 线上教学——它占着原本放教室名的位置。
final class OnlineVenue extends ArrangementVenue {
  const OnlineVenue({required this.campus});

  final String? campus;

  @override
  String toText() => campus == null
      ? Venue.onlineRoomLabel
      : '${Venue.onlineRoomLabel}($campus)';

  @override
  String toString() => toText();

  @override
  bool operator ==(Object other) =>
      other is OnlineVenue && other.campus == campus;

  @override
  int get hashCode => campus.hashCode;
}

/// 停课——这一周的这次课不上。它是一条**例外**，不是删除。
final class CancellationVenue extends ArrangementVenue {
  const CancellationVenue({required this.statusText, required this.campus});

  /// 教务系统在这一格写的状态词，样本里是「停课」。
  final String statusText;

  final String? campus;

  @override
  String toText() => campus == null ? statusText : '$statusText($campus)';

  @override
  String toString() => toText();

  @override
  bool operator ==(Object other) =>
      other is CancellationVenue &&
      other.statusText == statusText &&
      other.campus == campus;

  @override
  int get hashCode => Object.hash(statusText, campus);
}

/// 单元格正文里读出的东西：安排 + 读不出来的地方。
class CellContent {
  CellContent({required List<Arrangement> arrangements, required List<String> problems})
    : arrangements = List.unmodifiable(arrangements),
      problems = List.unmodifiable(problems);

  /// 解出来的叶子安排，按正文顺序。
  final List<Arrangement> arrangements;

  /// 读不出来的地方，每条都**带着原文**。
  final List<String> problems;

  /// 正文里有没有内容（去掉标签与空白之后）。空格子是「没有内容」，不是「有问题」。
  bool get isBlank => arrangements.isEmpty && problems.isEmpty;

  @override
  String toString() =>
      'CellContent(${arrangements.length} 条安排'
      '${problems.isEmpty ? '' : ', ${problems.length} 处读不出来'})';
}

/// 把单元格正文解成叶子安排。
///
/// 正文的形状是「**每两行一组**」：第一行课程名（. 课程号）(教师)，第二行
/// `(周次,教室(校区))`；多条安排依次追加。
///
/// 分组**不按行数、也不先切行**，而是盯着一个**可见的断点**：正文里每个周次行
/// 前面都跟着一个换行（导出文件里是 `<br>`，`title` 属性里是 `;;;`），**课程行
/// 前面没有**。所以「换行 + 缩进 + `(`」才是新安排的开始，而紧贴在课程名后面的
/// `(`（比如 `形势与政策3(16312025.H0) (孙德茹)` 里的课程号）不是。
///
/// 先切成行再配对是行不通的：那样所有 `(` 开头的行都长得一样，分不出「这是下一
/// 条」还是「这是上一条课程名里的一部分」。同理，按 `;` 切会把
/// `Software Testing（软件测试技术）` 从中间劈开（样板里真踩过这一脚）。
///
/// 空行全部丢弃——单条安排的单元格里会夹着两个空行。模板偶发少写一个 `)` 也被
/// 吸收：周次行不需要闭合就能收掉。
abstract final class CellArrangements {
  /// 解析一格。
  static CellContent parse(String rawHtml) {
    final stripped = stripTags(rawHtml).trim();
    if (stripped.isEmpty) return CellContent(arrangements: [], problems: []);

    final problems = <String>[];
    final arrangements = <Arrangement>[];
    _parseTokens(_rawTokens(rawHtml), arrangements, problems);

    if (arrangements.isEmpty && problems.isEmpty) {
      problems.add('这一格的正文里没有能认出来的安排：「$stripped」');
    }
    return CellContent(arrangements: arrangements, problems: problems);
  }

  /// 正文 → 记号：一条课程行，或一条周次行。
  ///
  /// 一条周次行的写法是「从行首起、第一个 `(` 一直到行尾」，因为它内部的 `)`
  /// 个数不可信（模板会少写），只有行尾是可靠的。课程行则是「上一行周次行之后到
  /// 下一个周次行之前」，中间的空行与换行都留着当**断点**用。
  static List<String> _rawTokens(String rawHtml) {
    final text = rawHtml
        .replaceAll(RegExp(r'<br\b[^>]*/?>', caseSensitive: false), '\n')
        // `title` 属性那种写法拿 `;;;` 当换行用。
        .replaceAll(';;;', '\n');
    final leading = RegExp(
      r'^[ \t]*\([^\n]*',
      multiLine: true,
    ).allMatches(text).toList();

    final tokens = <String>[];
    var cursor = 0;
    for (final match in leading) {
      final name = text.substring(cursor, match.start).trim();
      if (name.isNotEmpty) tokens.add(name);
      tokens.add(match.group(0)!.trim());
      cursor = match.end;
    }
    final tail = text.substring(cursor).trim();
    if (tail.isNotEmpty) tokens.add(tail);
    return tokens;
  }

  /// 走一遍记号：周次行收掉前面那条课程行。
  static void _parseTokens(
    List<String> tokens,
    List<Arrangement> arrangements,
    List<String> problems,
  ) {
    String? pendingName;
    for (final token in tokens) {
      if (!token.startsWith('(')) {
        if (pendingName != null) {
          problems.add(
            '「$pendingName」后面直接跟了又一个课程行「$token」，'
            '少了对应的周次行——这条安排没解出来',
          );
        }
        pendingName = token;
        continue;
      }
      if (pendingName == null) {
        problems.add('周次行「$token」前面没有课程行，这条安排没解出来');
        continue;
      }
      final arrangement = _parseArrangement(pendingName, token, problems);
      if (arrangement != null) arrangements.add(arrangement);
      pendingName = null;
    }
    if (pendingName != null) {
      problems.add('课程行「$pendingName」后面没有周次行，这条安排没解出来');
    }
  }

  /// 「课程行 + 周次行」→ 叶子安排。解不出来时记问题并返回 null。
  static Arrangement? _parseArrangement(
    String nameLine,
    String weeksLine,
    List<String> problems,
  ) {
    final body = _stripOuterParentheses(weeksLine);
    final comma = body.indexOf(',');
    if (comma < 0) {
      problems.add('周次行「$weeksLine」里没有逗号，分不出周次与地点');
      return null;
    }

    final weeksText = body.substring(0, comma).trim();
    final venueText = _stripTrailingParenthesis(body.substring(comma + 1).trim());

    final weeks = _parseWeeks(weeksText, weeksLine, problems);
    if (weeks == null) return null;

    final venue = _parseVenue(venueText, weeksLine, problems);
    if (venue == null) return null;

    final name = parseCourseName(nameLine);
    return Arrangement(
      courseName: name.courseName,
      teacher: name.teacher,
      weeks: weeks,
      venue: venue,
    );
  }

  static WeekSet? _parseWeeks(
    String weeksText,
    String rawLine,
    List<String> problems,
  ) {
    try {
      return WeekSet.parse(weeksText);
    } on FormatException catch (error) {
      problems.add('周次行「$rawLine」里的周次解不出来：${error.message}');
      return null;
    }
  }

  static ArrangementVenue? _parseVenue(
    String venueText,
    String rawLine,
    List<String> problems,
  ) {
    if (venueText.isEmpty) {
      problems.add('周次行「$rawLine」里没有地点');
      return null;
    }

    if (venueText.startsWith('停课')) {
      return CancellationVenue(
        statusText: '停课',
        campus: _campusOf(venueText.substring('停课'.length)),
      );
    }
    if (venueText.startsWith(Venue.onlineRoomLabel)) {
      return OnlineVenue(
        campus: _campusOf(venueText.substring(Venue.onlineRoomLabel.length)),
      );
    }

    final open = venueText.indexOf('(');
    if (open < 0) return RoomVenue(room: venueText, campus: null);
    // 括号里没闭合（模板少写一个 `)`）时也要认——样本里 `(9-18,4J203(主校区)`
    // 就是这么来的。
    final room = venueText.substring(0, open).trim();
    final campus = _stripTrailingParenthesis(venueText.substring(open + 1).trim());
    if (room.isEmpty) {
      problems.add('周次行「$rawLine」里的地点解不出来');
      return null;
    }
    return RoomVenue(room: room, campus: campus.isEmpty ? null : campus);
  }

  /// 从 `(主校区)` / `主校区)` / `主校区` 里取出校区名；取不出来时是 null。
  static String? _campusOf(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final stripped = trimmed.startsWith('(')
        ? _stripOuterParentheses(trimmed)
        : _stripTrailingParenthesis(trimmed);
    return stripped.isEmpty ? null : stripped;
  }

  /// 去掉最外面的一对括号。模板偶发少写一个 `)`，所以**只对开头那个 `(` 提要求**。
  static String _stripOuterParentheses(String text) {
    var body = text.trim();
    if (body.startsWith('(')) body = body.substring(1);
    if (body.endsWith(')')) body = body.substring(0, body.length - 1);
    return body.trim();
  }

  /// 去掉末尾的一个 `)`（只去一个，去完还带 `)` 就是内容本身）。
  static String _stripTrailingParenthesis(String text) {
    var body = text.trim();
    if (body.endsWith(')')) body = body.substring(0, body.length - 1);
    return body.trim();
  }

  /// 课程行的解析产物（课程名 + 教师）。
  static CourseName parseCourseName(String line) => _parseCourseName(line);

  static CourseName _parseCourseName(String line) {
    var body = line.trim();

    // 教师写作行尾的 `(教师)`。样本里**教师与课程名之间必定有空格**，而课程名
    // 自带的括号不会（`Software Testing（软件测试技术） (齐斌)`）。用空格这个
    // 判据，而不是「取最后一个括号」——后者会把 `形势与政策3(16312025.H0)`
    // 这种没有教师的课程行的课程号当成教师。
    final teacherMatch = RegExp(r'\s\(([^()]*)\)\s*$').firstMatch(body);
    String? teacher;
    if (teacherMatch != null) {
      teacher = teacherMatch.group(1)!.trim();
      body = body.substring(0, teacherMatch.start).trim();
    }

    // 课程号写作 `(073170140.01)`，紧贴在课程名后面。留着它没用——课表的单位是
    // 「课程名称 × 教师 × 周次 × 节次 × 地点」，课程号只是导出文件里的一份附注；
    // 留着就会在界面上跟课程名一起显示。
    //
    // 认出课程号判据是**里面带点**（`073170140.01` / `16312025.H0`）。课程名自带
    // 的括号里通常没有点，所以不会误伤。
    body = body.replaceFirst(RegExp(r'\s*\([^()]*[.．][^()]*\)\s*$'), '').trim();

    return CourseName(
      courseName: body.isEmpty ? '（未标注课程名）' : body,
      teacher: teacher == null || teacher.isEmpty ? null : teacher,
    );
  }

  /// 把 HTML 标签去掉，只留可见文本（`<br>` 变成换行）。
  ///
  /// 刻意**不做实体解码**：样本里正文从来是裸文本，而 `&nbsp;` 之类出现在课表里
  /// 只会出现在别的地方。少做一件事，就少一处猜错。
  static String stripTags(String rawHtml) => rawHtml
      .replaceAll(RegExp(r'<br\b[^>]*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

/// 课程行解出来的东西。
class CourseName {
  const CourseName({required this.courseName, required this.teacher});

  final String courseName;
  final String? teacher;

  @override
  String toString() => teacher == null ? courseName : '$courseName ($teacher)';
}
