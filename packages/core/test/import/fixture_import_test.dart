import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// **规格里那条最重要的测试**：用真实导出文件的脱敏夹具跑完，逐格内容与教务系统
/// 一致，**每个格子都解得出来**、**一条安排都不少**。
///
/// ## 期望值是怎么来的
///
/// 对着夹具那张表**逐格抄**下来的（见 [`docs/reference/ahpu-jwxt-export-format.md`]
/// 第四节）。抄出来的数字是：
///
/// - 84 个逻辑格子，其中 **8 格有内容**；
/// - 这 8 格里一共 **16 条正文条目**；
/// - 其中 **2 条是「停课」标记**（都在 `TD38_0` 那一格），按格式文档第五条合并进
///   正常那条安排；
/// - 所以最终是 **14 条上课安排**、**0 个无法配对的格子**。
///
/// 写成一张平铺的清单而不是几条抽象断言——它是这份解析器的验收凭据，改坏了要
/// 看得见是**哪一格**变了。
///
/// **提醒**：`test/fixtures/README.md` 的「结构指纹」表里原先写着「解出上课安排
/// 15 条」，那个数字与夹具本身对不上（照上面那样数出来是 14）。这里以夹具为准。
void main() {
  late TimetableImportResult result;

  setUpAll(() {
    result = importFixture();
  });

  test('夹具读得进来，且全部字节都解出来了', () {
    expect(fixtureFile.existsSync(), isTrue);
    expect(fixtureBytes().length, 38639, reason: '夹具的结构指纹：字节数');
    expect(
      result.withCode(ImportIssue.unmappedByte),
      isEmpty,
      reason: '真实导出文件不该有解不出来的字节',
    );
  });

  test('解出 14 条上课安排，0 个无法配对的单元格', () {
    expect(result.timetable.sessions, hasLength(14));
    expect(
      result.withCode(ImportIssue.unparsableCell),
      isEmpty,
      reason: '样本里 8 个有内容的格子全部解得出来，0 个无法配对',
    );
    expect(result.hasUnparsableContent, isFalse);
  });

  test('逐格内容与教务系统一致', () {
    expect(result.timetable.sessions.map(describe).toList(), const [
      // 星期一第一节，连堂两节。
      '编译原理 (胡冰) 星期一 第1-2节 1-12周 @4J410(主校区)',
      // 星期二第一节，同格两条：一门课上半个学期、另一门接下半个学期。
      '数字图像处理 (汪军) 星期二 第1-2节 1-8周 @4J209(主校区)',
      '嵌入式开发 (刘蓓) 星期二 第1-2节 9-18周 @4J203(主校区)',
      // 星期三第一节，同样是同格两条。课程名带全角括号。
      'Software Testing（软件测试技术） (齐斌) 星期三 第1-2节 1-10周 @4J313(主校区)',
      '形势与政策3 (孙德茹) 星期三 第1-2节 11-14周 @4J210(主校区)',
      '计算机组成与结构 (卢桂馥) 星期五 第1-2节 2-16周 @4J209(主校区)',
      // 星期一第三～五节，连堂三节；同一门课中途换教师，是**两条**安排。
      '人机交互的软件工程方法 (李超波) 星期一 第3-5节 1-8周 @4J410(主校区)',
      '人机交互的软件工程方法 (戴家树) 星期一 第3-5节 9-16周 @4J410(主校区)',
      '习近平新时代中国特色社会主义思想概论 (鲍小会) 星期三 第3-5节 1-14周 @4J312(主校区)',
      // 星期四第三～四节：这一格是**停课那条与正常那条并排**，合并成一条，
      // 周次集合里第 2 周是断档（见格式文档第五条）。
      '编译原理 (胡冰) 星期四 第3-4节 1 3-12周 @4J410(主校区)',
      '数字图像处理 (汪军) 星期五 第3-4节 1-8周 @4J209(主校区)',
      '嵌入式开发 (刘蓓) 星期五 第3-4节 9-18周 @4J203(主校区)',
      // 第六～七节。
      'Software Testing（软件测试技术） (齐斌) 星期一 第6-7节 1-10周 @4J313(主校区)',
      '计算机组成与结构 (卢桂馥) 星期二 第6-7节 2-16周 @4J209(主校区)',
    ]);
  });

  test('同一门课的多条安排彼此独立，没有被合并', () {
    final digital = result.timetable.sessionsOf('数字图像处理');
    expect(digital, hasLength(2), reason: '数字图像处理一周上两次');
    expect(digital.map((session) => session.weekday).toSet(), {2, 5});
    expect(digital.map((session) => session.weeks.toText()).toSet(), {'1-8'});

    final hci = result.timetable.sessionsOf('人机交互的软件工程方法');
    expect(hci, hasLength(2), reason: '同一门课中途换教师，是两条独立的安排');
    expect(
      hci.map((session) => session.teacher).toSet(),
      {'李超波', '戴家树'},
      reason: '换教师那两条的教师不同——这正是「用课程当单位会把模型做错」的地方',
    );
    expect(
      hci.map((session) => session.weeks.toText()).toSet(),
      {'1-8', '9-16'},
      reason: '两条各占一半学期，没有并成 1-16',
    );
  });

  test('连堂按 rowspan 解成节次跨度', () {
    final bySpan = <String, List<ClassSession>>{};
    for (final session in result.timetable.sessions) {
      bySpan.putIfAbsent(session.periods.toString(), () => []).add(session);
    }
    expect(bySpan.keys.toSet(), {'第1-2节', '第3-5节', '第3-4节', '第6-7节'});
    expect(bySpan['第3-5节'], hasLength(3));
    expect(
      bySpan['第3-5节']!.first.periods,
      PeriodSpan(3, 3),
      reason: 'rowspan=3 解成从第 3 节起连 3 节',
    );
  });

  test('课程名里的课程号被去掉，教师与课程名分开', () {
    final byCourse = {
      for (final session in result.timetable.sessions)
        session.courseName: session.teacher,
    };
    expect(byCourse['数字图像处理'], '汪军');
    expect(byCourse['形势与政策3'], '孙德茹');
    expect(
      byCourse.keys.any((name) => name.contains('073170140')),
      isFalse,
      reason: '课程号不该留在课程名里',
    );
    expect(
      result.timetable.sessions.every((session) => session.teacher != null),
      isTrue,
      reason: '样本里每条安排都带教师',
    );
  });

  test('每一条安排都落在合理的位置上', () {
    for (final session in result.timetable.sessions) {
      expect(session.weekday, inInclusiveRange(1, 7));
      expect(session.periods.start, greaterThanOrEqualTo(1));
      expect(
        session.periods.end,
        lessThanOrEqualTo(12),
        reason: '节次不能超出这张表的节次总数',
      );
      expect(session.weeks.isNotEmpty, isTrue, reason: '不能有一条永远不出现的安排');
      expect(session.venue.room, isNotEmpty);
    }
  });

  test('导出文件里没有的东西，不假装知道', () {
    // 学期设置（第 1 周的第一天、总周数）导出文件里没有，所以留空等使用者填。
    expect(result.timetable.settings.firstDayOfWeek1, isNull);
    expect(result.timetable.settings.totalWeeks, isNull);
    // 学年学期来自调用方，不是从文件里猜的。
    expect(result.timetable.term.id, '2026-2027-1');
  });
}

/// 把一条安排写成一行便于比对。
String describe(ClassSession session) =>
    '${session.courseName}${session.teacher == null ? '' : ' (${session.teacher})'} '
    '${_weekdayLabels[session.weekday - 1]} ${session.periods} '
    '${session.weeks.toText()}周 @${session.venue.toText()}';

const List<String> _weekdayLabels = [
  '星期一',
  '星期二',
  '星期三',
  '星期四',
  '星期五',
  '星期六',
  '星期日',
];
