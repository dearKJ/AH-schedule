import 'dart:convert';

import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import '../import/fixture.dart';

/// **导出里不许有学号 / 姓名 / 班级。** 这是 ADR-0002 的前置条件，不是可选项：
/// 这个 App 要发给同学，一次分享等于公开自己的学号。
///
/// 这条测试刻意对着**真实夹具**跑，而不是对着编造的数据——夹具的原始字节里真的
/// 带着那三样东西（见 `test/fixtures/README.md` 的脱敏表），所以「导出里没有」才是
/// 一句有内容的话。前提本身也先断言一遍，免得哪天夹具被换掉之后这条测试空转着变绿。
void main() {
  /// 夹具原始字节里**确实存在**的个人信息。夹具是把真值换成这三个假值之后入库的，
  /// 值本身不敏感，形式与真值一致。
  const piiValuesInFixture = ['3200000001', '张三', '示例241'];

  /// 这几样东西的字段名。它们出现在导出文件里同样等于泄露——值是假的时候也一样，
  /// 因为那说明这份文件里**留了位置**给它们。
  const piiFieldNames = [
    '学号',
    '姓名',
    '学生姓名',
    '班级',
    '所属班级',
    '行政班级',
    'studentId',
    'studentName',
    'className',
  ];

  group('前提：夹具里确实有个人信息', () {
    test('夹具的原始文本里带着学号 / 姓名 / 班级', () {
      final source = fixtureText();

      for (final value in piiValuesInFixture) {
        expect(
          source,
          contains(value),
          reason: '夹具里没有「$value」的话，下面那条「导出里没有」就是空转的',
        );
      }
      for (final field in ['学号', '学生姓名', '所属班级']) {
        expect(source, contains(field), reason: '夹具里没有「$field」这个字段名');
      }
    });
  });

  group('导出：剥掉学号 / 姓名 / 班级', () {
    test('真实课表导出的 JSON 里，这三样一个都不在', () {
      final json = TimetableJson.encode(importFixture().timetable);

      for (final value in piiValuesInFixture) {
        expect(json, isNot(contains(value)), reason: '导出的文件里出现了「$value」');
      }
      for (final field in piiFieldNames) {
        expect(json, isNot(contains(field)), reason: '导出的文件里出现了「$field」');
      }
    });

    test('导出的键就是这几个——多一个键都要先想清楚它会不会带出个人信息', () {
      final json = jsonDecode(TimetableJson.encode(_everything()));

      expect(
        _keyPaths(json),
        _allowedKeys,
        reason:
            '这一条是**结构性**的那道闸：只要编码器能写出来的键就这几个，'
            '个人信息就没有位置可放。加字段时这条会红——那时请对着 '
            'ADR-0002 想一遍再把它加进白名单。',
      );
    });

    test('个人信息的原文不会顺着别的字段溜进来', () {
      // 导出的是**课表本身**，不是导入诊断。诊断带着出问题那一格的原文，而原文
      // 可能落在学生信息行上——所以课表 JSON 里不该有任何诊断的位置。
      final json = TimetableJson.encode(importFixture().timetable);

      expect(json, isNot(contains('rawText')));
      expect(json, isNot(contains('diagnostics')));
    });
  });
}

/// 一份把所有可选字段都用上的课表——键白名单要照**最长的**那份数。
Timetable _everything() {
  final term = AcademicTerm.parseLabel('2026-2027学年第一学期');
  return Timetable(
    term: term,
    settings: TermSettings(
      firstDayOfWeek1: DateTime(2026, 9, 7),
      totalWeeks: 18,
      bellSchedule: BellSchedule.ahpuDefault,
    ),
    sessions: [
      ClassSession(
        courseName: '高等数学(一)',
        teacher: '胡冰',
        weekday: DateTime.monday,
        periods: PeriodSpan(1, 2),
        weeks: WeekSet([1, 2, 3]),
        venue: Venue(room: '4J410', campus: '主校区'),
        exceptions: [
          Cancellation(2),
          OnlineTeaching(14, campus: '主校区'),
        ],
      ),
      // 教师与校区都没有的那条：可选字段不该被写成空串或占位符。
      ClassSession(
        courseName: '大学英语(二)',
        weekday: DateTime.friday,
        periods: PeriodSpan(6, 1),
        weeks: WeekSet([5]),
        venue: Venue(room: '线上教学'),
        exceptions: [OnlineTeaching(5)],
      ),
    ],
  );
}

/// 导出产物能写出来的全部键，用路径写成一张白名单。
///
/// `sessions[]` 表示数组元素的路径——写成路径而不是平铺的键名，是为了让新字段
/// 加在哪一层一眼看得出来。
const Set<String> _allowedKeys = {
  'version',
  'term',
  'term.id',
  'term.label',
  'settings',
  'settings.firstDayOfWeek1',
  'settings.totalWeeks',
  'settings.bellSchedule',
  'settings.bellSchedule.name',
  'settings.bellSchedule.periods',
  'settings.bellSchedule.periods[].period',
  'settings.bellSchedule.periods[].start',
  'settings.bellSchedule.periods[].end',
  'settings.bellSchedule.periods[].block',
  'sessions',
  'sessions[].courseName',
  'sessions[].teacher',
  'sessions[].weekday',
  'sessions[].periods',
  'sessions[].periods.start',
  'sessions[].periods.length',
  'sessions[].weeks',
  'sessions[].venue',
  'sessions[].venue.room',
  'sessions[].venue.campus',
  'sessions[].exceptions',
  'sessions[].exceptions[].type',
  'sessions[].exceptions[].week',
  'sessions[].exceptions[].campus',
};

/// 把一个 JSON 节点里的键收集成路径。
Set<String> _keyPaths(Object? node, [String prefix = '']) {
  final paths = <String>{};
  if (node is Map<String, Object?>) {
    node.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      paths.add(path);
      paths.addAll(_keyPaths(value, path));
    });
  } else if (node is List<Object?>) {
    for (final item in node) {
      paths.addAll(_keyPaths(item, '$prefix[]'));
    }
  }
  return paths;
}
