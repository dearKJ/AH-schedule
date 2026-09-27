import 'dart:convert';
import 'dart:typed_data';

import '../academic_term.dart';
import '../bell_schedule.dart';
import '../class_session.dart';
import '../clock_time.dart';
import '../day_block.dart';
import '../period_span.dart';
import '../period_time.dart';
import '../session_exception.dart';
import '../term_settings.dart';
import '../timetable.dart';
import '../venue.dart';
import '../week_set.dart';
import 'json_diagnostics.dart';

/// 课表与一份**带版本号**的 JSON 之间的双向转换：`课表 ⇄ 带版本号的 JSON`。
///
/// 这是规格里 `core` 的第三个纯函数入口，也是**往来于设备与同学之间的唯一契约**
/// （ADR-0002：没有服务器，换手机靠它，分享给同学也靠它）。文件格式的权威出处是
/// `docs/reference/timetable-json-format.md`。
///
/// 三条硬要求，都是刻意的：
///
/// - **导出时剥离学号 / 姓名 / 班级。** 这不是可选项：这个 App 要发给同学，一次
///   分享等于公开自己的学号。这里的做法是最硬的那种——**这些字段压根没有位置可
///   写**：`Timetable` 里没有装它们的字段，编码器也只认得它自己写的那几个键。见
///   `test/json/export_privacy_test.dart`。
/// - **带版本号**，便于以后升级而不破坏旧文件。
/// - **反序列化不抛异常**：版本号缺失 / 不认识、缺字段、坏字段、字节不是 UTF-8，
///   一律返回 [TimetableDecodeResult] 里的一条 [JsonError]，由调用方决定怎么给
///   用户看。
///
/// 不做 `.ics`——iCalendar 表达不了单双周、断档周、停课例外，硬塞会丢信息。
abstract final class TimetableJson {
  /// 这份 JSON 的版本号。**只增不改**：改了语义就换一个新号。
  ///
  /// 解码器今天只认这一个版本，其余一律 [JsonIssue.unknownVersion]——现在就只有
  /// v1，所以「认不出别的版本」就是全部该做的事。将来发 v2 时**必须同时留着读
  /// v1 的路径**，「老文件照样读得进」这句承诺是在那一天兑现的。
  static const int formatVersion = 1;

  /// `课表 → JSON`。缩进两格——这份文件是要给同学、也可能给人看的。
  static String encode(Timetable timetable) =>
      const JsonEncoder.withIndent('  ').convert(_encodeTimetable(timetable));

  /// `JSON → 课表`。**不抛异常**：任何坏输入都落成 [TimetableDecodeResult.error]。
  static TimetableDecodeResult decode(String text) {
    try {
      return TimetableDecodeResult._(timetable: _decodeTimetable(text));
    } on _JsonFailure catch (failure) {
      return TimetableDecodeResult._(error: failure.error);
    }
  }

  /// `文件的字节 → 课表`。给分享进来的文件用——**文件层面的坏法也在这里兜住**：
  /// 字节不是 UTF-8（选错了文件、传坏了、过了一手 GBK 的编辑器）一样是一条明确
  /// 错误，不是异常。
  static TimetableDecodeResult decodeBytes(Uint8List bytes) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException catch (error) {
      return TimetableDecodeResult._(
        error: JsonError(
          code: JsonIssue.notUtf8,
          message: '这个文件不是 UTF-8 文本，读不出课表：${error.message}',
        ),
      );
    }
    return decode(text);
  }
}

/// 反序列化的结果：**课表，或者一条说清哪一处坏了的错误**。
///
/// 两者必居其一，没有「课表 + 错误」那种半成品——结构一坏就没什么可解的了。
class TimetableDecodeResult {
  const TimetableDecodeResult._({this.timetable, this.error});

  /// 解出来的课表。失败时是 null。
  final Timetable? timetable;

  /// 拦路的那条错误。成功时是 null。
  final JsonError? error;

  /// 解出来了吗。
  bool get isSuccess => error == null;

  @override
  String toString() => isSuccess
      ? 'TimetableDecodeResult($timetable)'
      : 'TimetableDecodeResult($error)';
}

// ─────────────────────────────── 编码 ───────────────────────────────

Map<String, Object?> _encodeTimetable(Timetable timetable) => {
  'version': TimetableJson.formatVersion,
  'term': {'id': timetable.term.id, 'label': timetable.term.label},
  'settings': _encodeSettings(timetable.settings),
  'sessions': [
    for (final session in timetable.sessions) _encodeSession(session),
  ],
};

Map<String, Object?> _encodeSettings(TermSettings settings) => {
  if (settings.firstDayOfWeek1 != null)
    'firstDayOfWeek1': _formatDate(settings.firstDayOfWeek1!),
  if (settings.totalWeeks != null) 'totalWeeks': settings.totalWeeks,
  'bellSchedule': _encodeBellSchedule(settings.bellSchedule),
};

Map<String, Object?> _encodeBellSchedule(BellSchedule schedule) => {
  'name': schedule.name,
  'periods': [
    for (final period in schedule.periods)
      {
        'period': period.period,
        'start': period.start.toText(),
        'end': period.end.toText(),
        'block': _blockNames[period.block],
      },
  ],
};

Map<String, Object?> _encodeSession(ClassSession session) => {
  'courseName': session.courseName,
  if (session.teacher != null) 'teacher': session.teacher,
  'weekday': session.weekday,
  'periods': {'start': session.periods.start, 'length': session.periods.length},
  'weeks': session.weeks.weeks,
  'venue': _encodeVenue(session.venue),
  if (session.exceptions.isNotEmpty)
    'exceptions': [
      for (final exception in session.exceptions)
        _encodeException(exception),
    ],
};

/// 例外：**哪一教学周 + 哪种变化**。`type` 是这套写法里唯一一个认字符串的地方，
/// 认不出来就报错——静默丢掉一条「这周停课」等于悄悄多上一节课。
Map<String, Object?> _encodeException(SessionException exception) =>
    switch (exception) {
      Cancellation() => {'type': _cancellationType, 'week': exception.week},
      OnlineTeaching() => {
        'type': _onlineTeachingType,
        'week': exception.week,
        if (exception.campus != null) 'campus': exception.campus,
      },
    };

Map<String, Object?> _encodeVenue(Venue venue) => {
  'room': venue.room,
  if (venue.campus != null) 'campus': venue.campus,
};

String _formatDate(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)}';

String _two(int value) => value.toString().padLeft(2, '0');

// ─────────────────────── 认字符串的那三处 ───────────────────────
//
// 文件格式是契约，**不许绑在 Dart 标识符上**：重命名一个枚举成员不该让所有 v1 文件
// 读不进来。所以这三处（时段、停课、线上教学）各有一张显式的对照表，编码解码都走它。

/// 时段在文件里的写法。
const Map<DayBlock, String> _blockNames = {
  DayBlock.morning: 'morning',
  DayBlock.afternoon: 'afternoon',
  DayBlock.evening: 'evening',
};

final Map<String, DayBlock> _blocksByName = {
  for (final entry in _blockNames.entries) entry.value: entry.key,
};

String get _blockNamesText => _blockNames.values.join(' / ');

/// 例外类型在文件里的写法。
const String _cancellationType = 'cancellation';
const String _onlineTeachingType = 'onlineTeaching';

// ─────────────────────────────── 解码 ───────────────────────────────

Timetable _decodeTimetable(String text) {
  final root = _decodeJson(text);
  if (root is! Map<String, Object?>) {
    // 顶层的坏法单独一码：读到的是数组 / 字符串 / 数字，说明拿到的根本不是一份
    // 课表文件，而不是里面某个字段写坏了。
    _fail(
      JsonIssue.notObject,
      '课表文件的顶层应该是一个对象，读到的是${_describe(root)}',
      null,
    );
  }
  final file = _Node(root, '');
  _checkVersion(file);

  return Timetable(
    term: _decodeTerm(file.object('term')),
    settings: _decodeSettings(file.object('settings')),
    sessions: _decodeSessions(
      file.objectList('sessions', what: '一条上课安排'),
    ),
  );
}

/// 版本号必须在、必须认得。**这一条挡在最前面**——版本不认识就说明后面的字段未必
/// 是这套形状，硬解下去只会报出一堆莫名其妙的「缺字段」。
void _checkVersion(_Node file) {
  final path = file.childPath('version');
  final version = file.json['version'];
  if (version == null) {
    // 显式的 null 与「这个键不在」是同一件事：都没有版本号。
    _fail(
      JsonIssue.missingVersion,
      '文件里没有版本号（version）——这不像是一份课表文件',
      path,
    );
  }
  if (version is! int) {
    _fail(
      JsonIssue.badField,
      '版本号要写成整数，读到的是${_describe(version)}',
      path,
    );
  }
  if (version != TimetableJson.formatVersion) {
    _fail(
      JsonIssue.unknownVersion,
      '版本号 $version 认不出来——本机认得的版本是 '
      '${TimetableJson.formatVersion}。这份文件可能来自更新版本的 App，'
      '升级之后再打开它',
      path,
    );
  }
}

AcademicTerm _decodeTerm(_Node file) {
  final id = file.string('id');
  final label = file.string('label');
  return _domain(file.path, () => AcademicTerm(id: id, label: label));
}

TermSettings _decodeSettings(_Node file) {
  final firstDay = file.optionalDate('firstDayOfWeek1');
  final totalWeeks = file.optionalInteger('totalWeeks');
  final bellSchedule = _decodeBellSchedule(file.object('bellSchedule'));
  return _domain(
    file.path,
    () => TermSettings(
      firstDayOfWeek1: firstDay,
      totalWeeks: totalWeeks,
      bellSchedule: bellSchedule,
    ),
  );
}

BellSchedule _decodeBellSchedule(_Node file) {
  final name = file.string('name');
  final periods = [
    for (final period in file.objectList('periods', what: '一个节次'))
      _decodePeriodTime(period),
  ];
  return _domain(file.path, () => BellSchedule(name: name, periods: periods));
}

PeriodTime _decodePeriodTime(_Node node) => _domain(
  node.path,
  () => PeriodTime(
    period: node.integer('period'),
    start: node.clock('start'),
    end: node.clock('end'),
    block: node.block('block'),
  ),
);

List<ClassSession> _decodeSessions(List<_Node> sessions) => [
  for (final session in sessions) _decodeSession(session),
];

ClassSession _decodeSession(_Node node) => _domain(
  node.path,
  () => ClassSession(
    courseName: node.string('courseName'),
    teacher: node.optionalString('teacher'),
    weekday: node.integer('weekday'),
    periods: _decodePeriodSpan(node.object('periods')),
    weeks: _decodeWeeks(node),
    venue: _decodeVenue(node.object('venue')),
    exceptions: [
      for (final exception in node.optionalObjectList(
        'exceptions',
        what: '一条例外',
      ))
        _decodeException(exception),
    ],
  ),
);

PeriodSpan _decodePeriodSpan(_Node node) => _domain(
  node.path,
  () => PeriodSpan(node.integer('start'), node.integer('length')),
);

Venue _decodeVenue(_Node node) => _domain(
  node.path,
  () => Venue(room: node.string('room'), campus: node.optionalString('campus')),
);

/// 周次：数组的**元素**，所以路径停在数组这一层，不跟着 `error.name` 往下长。
WeekSet _decodeWeeks(_Node session) {
  final weeks = session.intList('weeks', what: '周次');
  return _domain(session.childPath('weeks'), () => WeekSet(weeks));
}

SessionException _decodeException(_Node node) {
  final type = node.string('type');
  final week = node.integer('week');
  final campus = node.optionalString('campus');
  if (type == _cancellationType) {
    return _domain(node.path, () => Cancellation(week));
  }
  if (type == _onlineTeachingType) {
    return _domain(node.path, () => OnlineTeaching(week, campus: campus));
  }
  _fail(
    JsonIssue.unknownValue,
    '例外只认「$_cancellationType」与「$_onlineTeachingType」，读到的是「$type」'
    '——这一条不敢丢，丢了就可能悄悄多上一节课',
    node.childPath('type'),
  );
}

// ─────────────────────── 取值：一个带路径的节点 ───────────────────────

/// 一个 JSON 对象 + **它在文件里的位置**。
///
/// 取值一律走它，子路径自己从父节点长出来（`settings` → `settings.totalWeeks`），
/// 于是「报错说清是哪一处」不靠调用方记得把路径拼对——拼错路径这件事，本来就是
/// 这个类存在的理由。位置是这块东西的 `rawText`：没有它，「文件里有个字段坏了」
/// 这句话使用者无从下手。
class _Node {
  _Node(this.json, this.path);

  final Map<String, Object?> json;

  /// 空串表示顶层——拼子路径时不至于拼出一个前导的点。
  final String path;

  /// 子字段在文件里的位置。
  String childPath(String key) => path.isEmpty ? key : '$path.$key';

  /// 必填的子对象。
  _Node object(String key) {
    final child = childPath(key);
    final value = _required(key, child);
    if (value is! Map<String, Object?>) {
      _fail(
        JsonIssue.badField,
        '「$key」应该是一个对象，读到的是${_describe(value)}',
        child,
      );
    }
    return _Node(value, child);
  }

  /// 必填的子对象数组。[what] 让错误消息说人话（「一条上课安排」）。
  List<_Node> objectList(String key, {required String what}) =>
      _elements(_required(key, childPath(key)), childPath(key), what);

  /// 可选的子对象数组：不在、或者是 null，都当作「一条都没有」。
  List<_Node> optionalObjectList(String key, {required String what}) {
    final child = childPath(key);
    final value = json[key];
    if (value == null) return const [];
    return _elements(value, child, what);
  }

  /// 必填的整数数组。[what] 让错误消息说人话（「周次」）。
  List<int> intList(String key, {required String what}) {
    final child = childPath(key);
    final value = _required(key, child);
    if (value is! List<Object?>) {
      _fail(
        JsonIssue.badField,
        '「$key」应该是一个数组，读到的是${_describe(value)}',
        child,
      );
    }
    final integers = <int>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! int) {
        _fail(
          JsonIssue.badField,
          '$what要写成一串整数，第 ${index + 1} 个读到的是${_describe(item)}',
          '$child[$index]',
        );
      }
      integers.add(item);
    }
    return integers;
  }

  /// 必填的字符串。空串**不算坏字段**——`ClassSession` / `AcademicTerm` 自己会把
  /// 空白挡掉，报在同一条记录的路径上。
  String string(String key) => _asString(_required(key, childPath(key)), key);

  /// 可选的字符串：不在、或者是 null，都当作「没有」。
  String? optionalString(String key) {
    final value = json[key];
    return value == null ? null : _asString(value, key);
  }

  /// 必填的整数。
  int integer(String key) => _asInteger(_required(key, childPath(key)), key);

  /// 可选的整数：不在、或者是 null，都当作「没有」。
  int? optionalInteger(String key) {
    final value = json[key];
    return value == null ? null : _asInteger(value, key);
  }

  /// 必填的时刻，写法 `HH:mm`。
  ClockTime clock(String key) {
    final child = childPath(key);
    final raw = _asString(_required(key, child), key);
    try {
      return ClockTime.parse(raw);
    } on FormatException catch (error) {
      _fail(JsonIssue.badField, error.message, child);
    }
  }

  /// 必填的时段（上午 / 下午 / 晚上）。
  DayBlock block(String key) {
    final child = childPath(key);
    final raw = _asString(_required(key, child), key);
    final block = _blocksByName[raw];
    if (block == null) {
      _fail(
        JsonIssue.unknownValue,
        '「$key」只认 $_blockNamesText，读到的是「$raw」',
        child,
      );
    }
    return block;
  }

  /// 可选的日期，写法 `YYYY-MM-DD`。
  DateTime? optionalDate(String key) {
    final child = childPath(key);
    final value = json[key];
    if (value == null) return null;
    final raw = _asString(value, key);
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) {
      _fail(
        JsonIssue.badField,
        '「$key」要写成「YYYY-MM-DD」，读到的是「$raw」',
        child,
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // `DateTime(2026, 2, 30)` 会悄悄归一成 3 月 2 日。日期认不出来就报错，不静默改。
    if (date.year != year || date.month != month || date.day != day) {
      _fail(JsonIssue.badField, '这个日期不存在：「$raw」', child);
    }
    return date;
  }

  String _asString(Object? value, String key) {
    if (value is String) return value;
    _fail(
      JsonIssue.badField,
      '「$key」应该是一个字符串，读到的是${_describe(value)}',
      childPath(key),
    );
  }

  int _asInteger(Object? value, String key) {
    if (value is int) return value;
    _fail(
      JsonIssue.badField,
      '「$key」应该是一个整数，读到的是${_describe(value)}',
      childPath(key),
    );
  }

  /// 必填字段：不在就报「缺字段」。**可选字段不走这里**——它们在不在都正常。
  Object? _required(String key, String child) {
    if (!json.containsKey(key)) {
      _fail(JsonIssue.missingField, '缺字段「$key」', child);
    }
    return json[key];
  }

  static List<_Node> _elements(Object? value, String path, String what) {
    if (value is! List<Object?>) {
      _fail(
        JsonIssue.badField,
        '这里应该是一个数组，读到的是${_describe(value)}',
        path,
      );
    }
    return [
      for (var index = 0; index < value.length; index++)
        _element(value[index], '$path[$index]', what),
    ];
  }

  static _Node _element(Object? value, String path, String what) {
    if (value is Map<String, Object?>) return _Node(value, path);
    _fail(
      JsonIssue.badField,
      '$what应该是一个对象，读到的是${_describe(value)}',
      path,
    );
  }
}

// ─────────────────────────── 报错的几条道 ───────────────────────────

/// 构造一个领域对象，把它的构造校验（`ArgumentError`）翻成一条「字段取值不对」。
///
/// **取值的规则不在这里抄一份**（星期 1..7、周次 1..53、第 1 周第一天必须是周一……），
/// 交给领域模型自己的构造校验去挡，抄了会漂。
///
/// 领域模型的 `ArgumentError.value(x, '字段名', …)` 都带着**字段名**，用它把路径补
/// 到具体那一项上（`settings` → `settings.firstDayOfWeek1`）。路径已经点着那一项时
/// 不重复补——周次是数组的元素，那里的 `weeks` 说的不是下一层字段。
T _domain<T>(String path, T Function() build) {
  try {
    return build();
  } on ArgumentError catch (error) {
    final name = error.name;
    final named = name is String && name.isNotEmpty;
    _fail(
      JsonIssue.badField,
      '${error.message ?? error}',
      named && !path.endsWith('.$name') ? '$path.$name' : path,
    );
  }
}

/// 解析 JSON 文本。**先剥掉 BOM**——记事本之类的编辑器会在 UTF-8 开头加一个，
/// JSON 解析器不认它，而同学发来的文件很可能过了一手 Windows。
Object? _decodeJson(String text) {
  // 用转义写，别让一个看不见的字符躺在源码里。
  final source = text.startsWith('﻿') ? text.substring(1) : text;
  try {
    return jsonDecode(source);
  } on FormatException catch (error) {
    _fail(JsonIssue.notJson, '这段文本不是 JSON：${error.message}', null);
  }
}

/// 把读到的东西说成人话，用在错误消息里。
String _describe(Object? node) => switch (node) {
  null => 'null',
  String() => '字符串「$node」',
  int() => '整数 $node',
  double() => '小数 $node',
  bool() => '布尔值 $node',
  List<Object?>() => '一个数组',
  Map<Object?, Object?>() => '一个对象',
  _ => '$node',
};

/// 报错。返回 [Never] 是为了让取值小工具在报错之后还能当收窄类型用。
Never _fail(String code, String message, String? path) =>
    throw _JsonFailure(JsonError(code: code, message: message, path: path));

/// 解码过程中的「退出」。它**只在这里面飞**：`decode` 接住它、翻成返回值——
/// 反序列化的错误是返回值的一部分，不是异常。
class _JsonFailure implements Exception {
  _JsonFailure(this.error);

  final JsonError error;
}
