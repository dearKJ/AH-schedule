import 'bell_schedule.dart';
import 'class_session.dart';
import 'period_time.dart';
import 'session_exception.dart';
import 'timetable.dart';
import 'venue.dart';
import 'week_set.dart';

/// 把课表与教学周号展开成**某一周的格子**：`课表 + 教学周号 → 该周的格子`。
///
/// 这是 ADR-0001 点名过的那段逻辑，也正是规格里 `core` 的第二个纯函数入口——
/// **不依赖框架、不碰存储**。消费它的是周网格、日后的「今日课程」与桌面小组件。
///
/// 展开要处理四件事：
///
/// 1. 一条安排落在本周时占住它的**节次跨度**（连堂占多个格子）。
/// 2. 周次集合不含本周的安排**完全不出现**。
/// 3. **停课例外生效的那一周，这条安排不出现**——但它仍然存在，其他周照常。
/// 4. **线上教学**的例外改的是**地点那一项**，不影响它出不出现。
///
/// **冲突**也在这里判定，UI 只负责画：[WeekCell.hasConflict] 为真的格子意味着
/// 「同一格 + 同一周 + 两条安排」。周次错开的多门课不是冲突。
WeekGrid expandWeek(Timetable timetable, int week) =>
    WeekGrid(timetable: timetable, week: week);

/// 某一教学周的全部格子：7 天 × 每一天的节次数。
///
/// 它是**读取时算出来的**，不落存储（ADR-0001）——教学周一换就重新展开一次。
class WeekGrid {
  /// 展开某一教学周。
  ///
  /// [week] 是教学周号，必须落在 `1..53`；越界抛 [ArgumentError]——周次认错
  /// 比报错糟得多。
  ///
  /// [bellSchedule] 给出一天有几节、每节的时刻；不给就用课表学期设置里的那张。
  /// 只能放得进这张表的节次，放不进的（如第 13 节）**不进网格**。
  factory WeekGrid({
    required Timetable timetable,
    required int week,
    BellSchedule? bellSchedule,
  }) {
    if (week < 1 || week > WeekSet.maxWeek) {
      throw ArgumentError.value(
        week,
        'week',
        '教学周号必须在 1..${WeekSet.maxWeek} 之间',
      );
    }

    final schedule = bellSchedule ?? timetable.settings.bellSchedule;
    // 节次号未必是连续的下标（作息时间表只要求唯一且升序，见 [BellSchedule]），
    // 所以格子按**节次号**建、按**节次号**取，不拿它当下标用。
    final cells = [
      for (var day = 0; day < 7; day++)
        [
          for (final periodTime in schedule.periods)
            WeekCell._(day + 1, periodTime.period),
        ],
    ];

    for (final session in timetable.sessions) {
      final venue = _venueOf(session, week);
      if (venue == null) continue; // 本周不出现：周次不含本周，或这周停课。
      final day = cells[session.weekday - 1];
      for (final period in session.periods.periods) {
        // 表里没有这个节次（如 12 节表里的第 13 节）：这条铺不进网格，不折叠、不溢出。
        final index = _indexOfPeriod(day, period);
        if (index < 0) continue;
        day[index].add(GridEntry(session, venue));
      }
    }

    for (final day in cells) {
      for (final cell in day) {
        cell.mergeOnlineDuplicates();
      }
    }

    return WeekGrid._(
      week: week,
      periods: List.unmodifiable(schedule.periods),
      days: List.unmodifiable([
        for (var day = 0; day < cells.length; day++)
          DayGrid._(
            index: day,
            periods: List.unmodifiable(schedule.periods),
            cells: List.unmodifiable(cells[day]),
          ),
      ]),
    );
  }

  const WeekGrid._({
    required this.week,
    required this.periods,
    required this.days,
  });

  /// 这张网格展的是第几教学周。
  final int week;

  /// 节次栏：从作息时间表来的「第几节 → 起止时刻与时段」。7 天共用这一份。
  final List<PeriodTime> periods;

  /// 7 天，[days] `[0]` 是星期一、`[6]` 是星期日。
  final List<DayGrid> days;

  /// 一周里有多少节。来自作息时间表，不写死 12。
  int get periodCount => periods.length;

  /// 某一天某一节的格子。
  ///
  /// [weekday] 用 1 = 星期一 … 7 = 星期日；[period] 是**节次号**，必须是作息时间
  /// 表里有的那一节——它不当下标用，所以表里节次号不连续也没关系。
  /// 越界一律抛 [ArgumentError]——**不返回空格子**，画错了不报错就会一路画到底。
  WeekCell at(int weekday, int period) {
    if (weekday < 1 || weekday > days.length) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        '星期必须在 1..${days.length} 之间（1 = 星期一）',
      );
    }
    final day = days[weekday - 1];
    final index = _indexOfPeriod(day.cells, period);
    if (index < 0) {
      throw ArgumentError.value(
        period,
        'period',
        '第 $period 节不在作息时间表里（这张表的节次是 '
        '${day.periods.map((periodTime) => periodTime.period).join('、')}）',
      );
    }
    return day.cells[index];
  }

  @override
  String toString() =>
      'WeekGrid(第$week周, ${days.length} 天 × $periodCount 节)';
}

/// 一周里的一天。
class DayGrid {
  DayGrid._({
    required this.index,
    required this.periods,
    required this.cells,
  });

  /// 0 = 星期一 … 6 = 星期日。
  final int index;

  /// 节次栏，与 [WeekGrid.periods] 是同一份。
  final List<PeriodTime> periods;

  /// 这一天各节的格子，升序。空着的格子是 [WeekCell.isEmpty] 为真的格子——
  /// **留白，不摆占位文字**。
  final List<WeekCell> cells;

  /// 这一天是星期几：1 = 星期一 … 7 = 星期日（与 `DateTime.weekday` 一致）。
  int get weekday => index + 1;

  @override
  String toString() => 'DayGrid(星期$weekday, ${cells.length} 节)';
}

/// 一格：某一天某一节上，这一教学周要画的那几条。
///
/// 平时一条，空着时零条。两条以上意味着**同一格同一周的冲突**——周次错开的安排在
/// 展开了的某一周里本来就不会同时出现，而「教室那条 + 线上那条」也已经被并成一条
/// （见 [mergeOnlineDuplicates]）。
class WeekCell {
  WeekCell._(this.weekday, this.period) : _entries = [];

  /// 星期几：1 = 星期一 … 7 = 星期日。
  final int weekday;

  /// 节次号：1 = 第一节。它就是作息时间表里那个节次。
  final int period;

  final List<GridEntry> _entries;

  void add(GridEntry entry) => _entries.add(entry);

  /// 把「同一门课、同一节次、一条在教室一条在线上」的两条并成**线上那一条**。
  ///
  /// 导入解析把线上教学那一行单独解成一条安排（见 `ClassSessionBuilder`），与教室
  /// 那条**周次互斥**时它们落在不同周、本来就不会同时出现；周次一旦有重叠，这一格
  /// 就会同时收到两条，看起来像冲突。可它不是冲突——`CONTEXT.md` 的「线上教学」说得
  /// 清楚：它改的是**地点那一项**，不是多出来一门课。
  ///
  /// 两条都留着会画出「同一门课并排两条、还标红」，那是假冲突；静默丢掉教室那条又会
  /// 让使用者以为课没了。所以并成线上那条：**出现**照着教室那条的周次集合，**地点**
  /// 照线上那条。
  ///
  /// 只并「课程名 + 教师 + 星期 + 节次跨度」都相同的一对，其余一概不动——判不准的
  /// 时候宁可不并，两条都留着让人眼看（规格：「不自动取舍」）。
  void mergeOnlineDuplicates() {
    if (_entries.length < 2) return;

    // 两条以上在线上就判不准是哪条盖哪条，一条都不并——宁可不取舍。
    final online = _entries
        .where((entry) => entry.venue.isOnline)
        .toList(growable: false);
    if (online.length != 1) return;
    final target = online.single;

    _entries.removeWhere(
      (entry) =>
          !identical(entry, target) &&
          entry.session.courseName == target.session.courseName &&
          entry.session.teacher == target.session.teacher &&
          entry.session.periods == target.session.periods,
    );
  }

  /// 这一周这一格要画的全部安排，按它们在课表里的先后。
  ///
  /// 冲突时**两条都在**，没有自动取舍。
  List<GridEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  /// 这一格是不是冲突：同一格 + 同一周 + 两条安排。
  ///
  /// 停课被展开挡在前面，所以不会出现「其中一条其实这周不上」的假冲突。
  bool get hasConflict => _entries.length > 1;

  @override
  String toString() =>
      'WeekCell(星期$weekday 第$period节, ${_entries.length} 条)';
}

/// 展开落在某一格上的一条：**哪条安排** + **这一周它在哪里上**。
///
/// 地点单列，是因为它**逐周可能不同**——线上教学的例外改的正是它（[venue] 变成
/// [`Venue.online`]），而 [session] 本身原样不动（ADR-0001：例外是信息，不是删除）。
class GridEntry {
  GridEntry(this.session, this.venue);

  /// 这条从哪来。连堂占的每一格带的都是同一条安排。
  final ClassSession session;

  /// 这一周的上课地点。没有线上教学例外时就是 `session.venue`。
  final Venue venue;

  /// 课程名。UI 按它分配颜色——同一门课跨格子、跨会话同色。
  String get courseName => session.courseName;

  @override
  String toString() => '$courseName @${venue.toText()}';

  @override
  bool operator ==(Object other) =>
      other is GridEntry && other.session == session && other.venue == venue;

  @override
  int get hashCode => Object.hash(session, venue);
}

/// 第 [period] 节在这一天的第几格；表里没有这个节次时返回 -1。
///
/// 节次号只保证唯一且升序，**不是下标**——第 3 节完全可能是这一天的第 3 格，
/// 也可能不是。
int _indexOfPeriod(List<WeekCell> cells, int period) {
  for (var index = 0; index < cells.length; index++) {
    if (cells[index].period == period) return index;
  }
  return -1;
}

/// 这一条安排在第 [week] 周该画在哪个地点；**这一周根本不出现时返回 null**。
///
/// 判定顺序就是规则本身的顺序：先看周次集合含不含本周，再看有没有停课例外，
/// 最后才是线上教学。停课与线上教学同时挂着时，停课说了算——不上就是不上，
/// 在哪儿上都无从谈起。
Venue? _venueOf(ClassSession session, int week) {
  if (!session.coversWeek(week)) return null;

  final exceptions = session.exceptions.where(
    (exception) => exception.week == week,
  );
  for (final exception in exceptions) {
    if (exception is Cancellation) return null;
  }
  for (final exception in exceptions) {
    if (exception is OnlineTeaching) {
      return Venue.online(campus: exception.campus ?? session.venue.campus);
    }
  }
  return session.venue;
}
