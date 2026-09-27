import 'dart:convert';
import 'dart:typed_data';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import '../import/fixture.dart';

void main() {
  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');

  group('往返', () {
    test('课表 → JSON → 课表 等价', () {
      final timetable = Timetable(term: term, sessions: [_session()]);

      final result = TimetableJson.decode(TimetableJson.encode(timetable));

      expect(result.error, isNull);
      expect(result.timetable, timetable);
    });

    test('例外原样往返：停课与线上教学都在', () {
      final session = _session(
        exceptions: [Cancellation(2), OnlineTeaching(14, campus: '主校区')],
      );

      final result = TimetableJson.decode(
        TimetableJson.encode(Timetable(term: term, sessions: [session])),
      );

      expect(result.error, isNull);
      expect(
        result.timetable!.sessions.single.exceptions,
        [Cancellation(2), OnlineTeaching(14, campus: '主校区')],
        reason: '例外是信息不是删除：往返之后星期、周次、类型一个都不许少',
      );
    });

    test('没有教师、没有校区的安排照样往返', () {
      final session = _session(
        teacher: null,
        venue: Venue(room: '4J410'),
      );

      final result = TimetableJson.decode(
        TimetableJson.encode(Timetable(term: term, sessions: [session])),
      );

      expect(result.error, isNull, reason: '可选字段不在是正常的，不是「缺字段」');
      expect(result.timetable!.sessions.single.teacher, isNull);
      expect(result.timetable!.sessions.single.venue.campus, isNull);
      expect(result.timetable, Timetable(term: term, sessions: [session]));
    });

    test('学期设置原样往返：第 1 周的第一天、总周数、自定义作息时间表', () {
      // 节次号刻意不连续、时段刻意与作息常规不符——照抄默认表也能「看起来对」。
      final bellSchedule = BellSchedule(
        name: '寒假短表',
        periods: [
          _periodTime(1, 9, 0, 9, 45, DayBlock.afternoon),
          _periodTime(3, 10, 0, 10, 45, DayBlock.evening),
        ],
      );
      final settings = TermSettings(
        firstDayOfWeek1: DateTime(2026, 9, 7),
        totalWeeks: 20,
        bellSchedule: bellSchedule,
      );
      final timetable = Timetable(
        term: term,
        settings: settings,
        sessions: [_session()],
      );

      final result = TimetableJson.decode(TimetableJson.encode(timetable));

      expect(result.error, isNull);
      expect(result.timetable!.settings, settings);
      expect(result.timetable!.settings.firstDayOfWeek1, DateTime(2026, 9, 7));
      expect(result.timetable!.settings.totalWeeks, 20);
      expect(result.timetable!.settings.bellSchedule.periods, hasLength(2));
    });

    test('学期设置留空时往返仍等价', () {
      final timetable = Timetable(term: term);

      final result = TimetableJson.decode(TimetableJson.encode(timetable));

      expect(result.error, isNull);
      expect(result.timetable!.settings.firstDayOfWeek1, isNull);
      expect(result.timetable!.settings.totalWeeks, isNull);
      expect(result.timetable!.settings, TermSettings(), reason: '留空就是留空，不补默认值');
    });

    test('多条安排保持顺序，同一门课的多条不会被合并', () {
      final sessions = [
        _session(courseName: '高等数学(一)', weekday: DateTime.monday),
        _session(courseName: '高等数学(一)', weekday: DateTime.thursday),
        _session(courseName: '大学英语(二)', teacher: '王五'),
      ];

      final result = TimetableJson.decode(
        TimetableJson.encode(Timetable(term: term, sessions: sessions)),
      );

      expect(result.error, isNull);
      expect(
        result.timetable!.sessions,
        hasLength(3),
        reason: '同一门课一周上两次就是两条独立的安排，合并了就丢信息',
      );
      expect(
        result.timetable!.sessions.map((s) => '${s.courseName}/${s.weekday}'),
        ['高等数学(一)/1', '高等数学(一)/4', '大学英语(二)/1'],
      );
    });

    test('编码是稳定的：解出来再编回去，字节一个不差', () {
      final timetable = Timetable(
        term: term,
        settings: TermSettings(
          firstDayOfWeek1: DateTime(2026, 9, 7),
          totalWeeks: 18,
        ),
        sessions: [
          _session(exceptions: [Cancellation(2)]),
          _session(courseName: '大学英语(二)', teacher: null),
        ],
      );

      final once = TimetableJson.encode(timetable);
      final twice = TimetableJson.encode(
        TimetableJson.decode(once).timetable!,
      );

      expect(twice, once);
    });

    test('真实夹具：导入的整张课表往返之后逐条一致', () {
      final imported = importFixture().timetable;

      final result = TimetableJson.decode(TimetableJson.encode(imported));

      expect(result.error, isNull);
      expect(result.timetable, imported);
      expect(result.timetable!.sessions, hasLength(14));
    });

    test('学期标识整个往返：id 与 label 都在', () {
      final result = TimetableJson.decode(TimetableJson.encode(_timetable()));

      expect(result.timetable!.term.id, '2026-2027-1');
      expect(
        result.timetable!.term.label,
        '2026-2027学年1学期',
        reason:
            '`AcademicTerm` 的 `==` 只比 id，光断言「课表相等」看不出 label 被丢了——'
            '而学期标识是这条验收标准点名要保住的东西',
      );
    });
  });

  group('写出来的写法', () {
    test('时段写成 morning / afternoon / evening，不跟着 Dart 枚举名走', () {
      final periods = _periodsOf(_jsonOf(_timetable()));

      expect(
        periods.map((period) => period['block']).toSet(),
        {'morning', 'afternoon', 'evening'},
        reason:
            '文件格式是契约，不该绑在 Dart 标识符上：重命名一个枚举成员不该让所有 '
            'v1 文件读不进来。所以名字写死在 _blockNames 里，这条测试盯着它。',
      );
    });

    test('带 BOM 的文件也读得进来', () {
      // 记事本存 UTF-8 会在开头加一个 BOM，而同学发来的文件很可能过了一手 Windows。
      final text = TimetableJson.encode(_timetable());

      // 用转义写 BOM，别让一个看不见的字符躺在源码里。
      final fromBytes = TimetableJson.decodeBytes(
        Uint8List.fromList(utf8.encode('﻿$text')),
      );
      final fromText = TimetableJson.decode('﻿$text');

      expect(fromBytes.error, isNull);
      expect(fromBytes.timetable, _timetable());
      expect(fromText.error, isNull);
      expect(fromText.timetable, _timetable());
    });
  });

  group('版本号', () {
    test('导出的 JSON 里带着版本号', () {
      final json = _jsonOf(_timetable());

      expect(json['version'], TimetableJson.formatVersion);
      expect(
        TimetableJson.formatVersion,
        1,
        reason: 'v1 是第一个版本；将来改了语义要换一个新号，老文件才读得进',
      );
    });

    test('版本号缺失 → 明确错误，不抛异常', () {
      final json = _jsonOf(_timetable())..remove('version');

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.missingVersion);
      expect(result.error!.path, 'version', reason: '得说清坏在哪一处');
      expect(result.timetable, isNull);
    });

    test('版本号不认识 → 明确错误，且提示升级', () {
      final json = _jsonOf(_timetable())..['version'] = 2;

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.unknownVersion);
      expect(result.error!.message, contains('2'));
      expect(result.timetable, isNull);
    });

    test('版本号不是整数 → 明确错误', () {
      for (final version in <Object?>['1', 1.0, true, null]) {
        final json = _jsonOf(_timetable());
        if (version == null) {
          json['version'] = null;
        } else {
          json['version'] = version;
        }

        final result = TimetableJson.decode(_textOf(json));

        // 显式的 null 与「不在」是同一件事：都没有版本号。
        expect(
          result.error!.code,
          version == null ? JsonIssue.missingVersion : JsonIssue.badField,
          reason: '版本号写成 $version 不算数',
        );
        expect(result.timetable, isNull);
      }
    });
  });

  group('坏输入', () {
    test('不是 JSON / 顶层不是对象 → 明确错误', () {
      expect(
        TimetableJson.decode('这不是 JSON').error!.code,
        JsonIssue.notJson,
      );
      expect(TimetableJson.decode('').error!.code, JsonIssue.notJson);
      expect(TimetableJson.decode('[]').error!.code, JsonIssue.notObject);
      expect(TimetableJson.decode('"课表"').error!.code, JsonIssue.notObject);
    });

    test('缺字段 → 明确错误，并指出是哪一个', () {
      final json = _jsonOf(_timetable());
      _sessionAt(json, 0).remove('courseName');

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.missingField);
      expect(result.error!.path, 'sessions[0].courseName');
      expect(result.error!.message, contains('courseName'));
      expect(result.timetable, isNull);
    });

    test('顶层缺 term / settings / sessions → 明确错误', () {
      for (final key in ['term', 'settings', 'sessions']) {
        final json = _jsonOf(_timetable())..remove(key);

        final result = TimetableJson.decode(_textOf(json));

        expect(result.error!.code, JsonIssue.missingField, reason: '缺 $key');
        expect(result.error!.path, key);
      }
    });

    test('字段类型不对 → 明确错误，并指出是哪一个', () {
      final cases = <String, Object?>{
        'weekday': '星期一',
        'courseName': 42,
        'weeks': '1-12',
        'periods': 3,
        'venue': '4J410',
      };

      cases.forEach((key, badValue) {
        final json = _jsonOf(_timetable());
        _sessionAt(json, 0)[key] = badValue;

        final result = TimetableJson.decode(_textOf(json));

        expect(
          result.error!.code,
          JsonIssue.badField,
          reason: '$key 写成 $badValue 应当报错',
        );
        expect(result.error!.path, 'sessions[0].$key');
        expect(result.timetable, isNull);
      });
    });

    test('周次数组里混进非整数 → 指出是第几个', () {
      final json = _jsonOf(_timetable());
      (_sessionAt(json, 0)['weeks']! as List<Object?>)[1] = '2';

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.badField);
      expect(result.error!.path, 'sessions[0].weeks[1]');
    });

    test('取值越界 → 明确错误（交给领域模型自己的校验）', () {
      final cases = <String, Object?>{'weekday': 8};
      cases.forEach((key, badValue) {
        final json = _jsonOf(_timetable());
        _sessionAt(json, 0)[key] = badValue;

        final result = TimetableJson.decode(_textOf(json));

        expect(result.error!.code, JsonIssue.badField);
        expect(
          result.error!.path,
          'sessions[0].$key',
          reason: '领域模型抛的 ArgumentError 带着字段名，路径要补到具体那一项上',
        );
        expect(
          result.error!.message,
          contains('星期'),
          reason: '消息里要点出是哪个字段，光说「不合法」没法查',
        );
      });

      final json = _jsonOf(_timetable());
      _sessionAt(json, 0)['weeks'] = <Object?>[];

      expect(
        TimetableJson.decode(_textOf(json)).error!.code,
        JsonIssue.badField,
        reason: '一条永不出现的安排是静默失败，得挡在门外',
      );
    });

    test('例外类型不认识 → 明确错误，不静默丢掉', () {
      final json = _jsonOf(_timetable(exceptions: [Cancellation(2)]));
      (_sessionAt(json, 0)['exceptions']! as List<Object?>).first =
          <String, Object?>{'type': '调课', 'week': 3};

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.unknownValue);
      expect(result.error!.path, 'sessions[0].exceptions[0].type');
      expect(
        result.timetable,
        isNull,
        reason: '宁可整份退回去，也不丢掉一条「这周停课」',
      );
    });

    test('坏输入一律返回错误，没有一种会抛异常', () {
      for (final text in <String>[
        '',
        '  ',
        '这不是 JSON',
        '[]',
        '{}',
        'null',
        '{"version":2}',
        '{"version":"1"}',
        '{"version":1}',
        '{"version":1,"term":null,"settings":null,"sessions":null}',
        '{"version":1,"term":{},"settings":{},"sessions":[]}',
        '{"version":1,"term":{"id":"x","label":"y"},"settings":{},"sessions":[]}',
        '{"version":1,"term":{"id":"x","label":"y"},'
            '"settings":{"bellSchedule":{"name":"n","periods":[{"period":0}]}},'
            '"sessions":[]}',
        '{"version":1,"term":{"id":"x","label":"y"},'
            '"settings":{"bellSchedule":{"name":"n","periods":['
            '{"period":1,"start":"25:00","end":"08:45","block":"morning"}]}},'
            '"sessions":[]}',
        '{"version":1,"term":{"id":"x","label":"y"},'
            '"settings":{"bellSchedule":{"name":"n","periods":['
            '{"period":1,"start":"08:00","end":"08:45","block":"上午"}]}},'
            '"sessions":[]}',
        '{"version":1,"term":{"id":"x","label":"y"},'
            '"settings":{"bellSchedule":{"name":"n","periods":['
            '{"period":1,"start":"08:00","end":"08:45","block":"morning"}]}},'
            '"sessions":[{"courseName":"高等数学","weekday":1,'
            '"periods":{"start":1,"length":2},"weeks":[0],'
            '"venue":{"room":"4J410"}}]}',
      ]) {
        final result = TimetableJson.decode(text);
        expect(
          result.error,
          isNotNull,
          reason: '这一段应当报错，而不是解出一张课表：$text',
        );
        expect(result.timetable, isNull);
      }
    });

    test('干净的输入对照：上面那一份去掉坏处就解得出来', () {
      final result = TimetableJson.decode(
        '{"version":1,"term":{"id":"x","label":"y"},'
        '"settings":{"bellSchedule":{"name":"n","periods":['
        '{"period":1,"start":"08:00","end":"08:45","block":"morning"}]}},'
        '"sessions":[{"courseName":"高等数学","weekday":1,'
        '"periods":{"start":1,"length":2},"weeks":[1],'
        '"venue":{"room":"4J410"}}]}',
      );

      expect(result.error, isNull);
      expect(result.timetable!.sessions.single.courseName, '高等数学');
      expect(
        result.timetable!.sessions.single.teacher,
        isNull,
        reason: '可选的字段不在，是正常的',
      );
    });

    test('第 1 周的第一天不是周一 → 明确错误', () {
      final json = _jsonOf(_timetable());
      (json['settings']! as Map<String, Object?>)['firstDayOfWeek1'] =
          '2026-09-08'; // 周二

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.badField);
      expect(
        result.error!.path,
        'settings.firstDayOfWeek1',
        reason: '领域模型抛的 ArgumentError 带着字段名，路径要补到具体那一项上',
      );
      expect(result.error!.message, contains('周一'));
    });

    test('日期写成不存在的那一天 → 明确错误，不悄悄挪到第二天', () {
      final json = _jsonOf(_timetable());
      (json['settings']! as Map<String, Object?>)['firstDayOfWeek1'] =
          '2026-02-30';

      final result = TimetableJson.decode(_textOf(json));

      expect(result.error!.code, JsonIssue.badField);
      expect(result.error!.path, 'settings.firstDayOfWeek1');
    });
  });
  group('吃字节的入口', () {
    test('文件的字节直接解得出来，与 decode 等价', () {
      final timetable = _timetable();
      final bytes = Uint8List.fromList(
        utf8.encode(TimetableJson.encode(timetable)),
      );

      final result = TimetableJson.decodeBytes(bytes);

      expect(result.error, isNull);
      expect(result.timetable, timetable);
    });

    test('不是 UTF-8 的字节 → 明确错误，不抛异常', () {
      // 0xFF 在 UTF-8 里永远不合法。
      final result = TimetableJson.decodeBytes(
        Uint8List.fromList([0xFF, 0xFE, 0x00, 0x41]),
      );

      expect(result.error!.code, JsonIssue.notUtf8);
      expect(result.timetable, isNull);
    });

    test('选错文件：拿教务系统导出的 .xls 当课表 JSON 读 → 明确错误', () {
      final result = TimetableJson.decodeBytes(fixtureBytes());

      expect(
        result.error!.code,
        JsonIssue.notUtf8,
        reason: '那份 .xls 是 GBK 的 HTML，不是 UTF-8 的 JSON',
      );
      expect(result.timetable, isNull);
    });

    test('空文件 → 明确错误', () {
      final result = TimetableJson.decodeBytes(Uint8List(0));

      expect(result.error!.code, JsonIssue.notJson);
      expect(result.timetable, isNull);
    });
  });
}

/// 导出的课表 JSON 解成 map——测试要改坏某几处时从它出发。
Map<String, Object?> _jsonOf(Timetable timetable) =>
    jsonDecode(TimetableJson.encode(timetable)) as Map<String, Object?>;

String _textOf(Map<String, Object?> json) => jsonEncode(json);

/// 第 [index] 条安排那个 JSON 对象。
Map<String, Object?> _sessionAt(Map<String, Object?> json, int index) =>
    (json['sessions']! as List<Object?>)[index] as Map<String, Object?>;

/// 作息时间表那一串节次。
List<Map<String, Object?>> _periodsOf(Map<String, Object?> json) {
  final settings = json['settings']! as Map<String, Object?>;
  final bellSchedule = settings['bellSchedule']! as Map<String, Object?>;
  return [
    for (final period in bellSchedule['periods']! as List<Object?>)
      period as Map<String, Object?>,
  ];
}

Timetable _timetable({List<SessionException> exceptions = const []}) =>
    Timetable(term: AcademicTerm.parseLabel('2026-2027学年第一学期'),
        sessions: [_session(exceptions: exceptions)]);

PeriodTime _periodTime(
  int period,
  int startHour,
  int startMinute,
  int endHour,
  int endMinute,
  DayBlock block,
) => PeriodTime(
  period: period,
  start: ClockTime(startHour, startMinute),
  end: ClockTime(endHour, endMinute),
  block: block,
);

ClassSession _session({
  String courseName = '高等数学(一)',
  String? teacher = '胡冰',
  int weekday = DateTime.monday,
  PeriodSpan? periods,
  WeekSet? weeks,
  Venue? venue,
  List<SessionException> exceptions = const [],
}) => ClassSession(
  courseName: courseName,
  teacher: teacher,
  weekday: weekday,
  periods: periods ?? PeriodSpan(1, 2),
  weeks: weeks ?? WeekSet([1, 2, 3]),
  venue: venue ?? Venue(room: '4J410', campus: '主校区'),
  exceptions: exceptions,
);
