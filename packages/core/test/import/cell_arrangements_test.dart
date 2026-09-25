import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:test/test.dart';

/// 单元格正文的解析。
///
/// 这一组测试盯的是**教务系统模板自身的三个 bug**（见
/// `docs/reference/ahpu-jwxt-export-format.md` 第五节）。这三个坑不是编出来的边角
/// 情况——它们就在使用者导出的那份文件里，编造的样本锁不住它们。
void main() {
  group('模板 bug 一：多条安排同格时，除最后一条外每条周次行末尾缺一个 `)`', () {
    test('缺括号的那条照样解得出来', () {
      final content = CellArrangements.parse(
        '数字图像处理(073170280.01) (汪军)<br/>'
        '(1-8,4J209(主校区)<br/>'
        '嵌入式开发(07311116.01) (刘蓓)<br/>'
        '(9-18,4J203(主校区)',
      );

      expect(content.problems, isEmpty);
      expect(content.arrangements, hasLength(2));

      final first = content.arrangements[0];
      expect(first.courseName, '数字图像处理');
      expect(first.venue, isA<RoomVenue>());
      expect((first.venue as RoomVenue).room, '4J209');
      expect((first.venue as RoomVenue).campus, '主校区');
      expect(first.weeks.toText(), '1-8');

      // 第二条是**正常闭合**的，两条都要对。
      final second = content.arrangements[1];
      expect(second.courseName, '嵌入式开发');
      expect(second.venue.toText(), '4J203(主校区)');
    });

    test('末尾多一个 `)` 也不会把校区名带进来', () {
      // 同一条写法闭合时是 `(1-8,4J209(主校区))`，去一层即可，不能连里面的括号
      // 一起去。
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>(1-12,4J410(主校区))');
      expect(content.problems, isEmpty);
      expect(
        content.arrangements.single.venue,
        const RoomVenue(room: '4J410', campus: '主校区'),
      );
    });
  });

  group('模板 bug 二：断档周用空格分隔区段，不是逗号', () {
    test('先按第一个逗号切开，左侧整体是周次集合', () {
      // `(1 3-12,4J410(主校区))` = 第 1 周 + 第 3–12 周，**不是**「第 1 周到第 3 周
      // 再到第 12 周」之类。逗号右边才是地点。
      final content = CellArrangements.parse(
        '编译原理(073170140.01) (胡冰)<br/>(1 3-12,4J410(主校区))',
      );

      expect(content.problems, isEmpty);
      final arrangement = content.arrangements.single;
      expect(arrangement.weeks.weeks, [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(arrangement.weeks.contains(2), isFalse, reason: '第 2 周是断档');
      expect(arrangement.venue.toText(), '4J410(主校区)');
    });

    test('逗号左边的空格**不当作分隔符**切到地点里去', () {
      // 反面例子：要是先按空格切，`1` 与 `3-12` 会被分开、`4J410(主校区)` 会被
      // 当成第三段周次，整条就解错了。
      final content = CellArrangements.parse('某课(1.01) (师)<br/>(1 3-12,4J410(主校区))');
      expect(content.arrangements.single.venue.toText(), '4J410(主校区)');
    });
  });

  group('模板 bug 三：停课会额外单列一条', () {
    test('停课那条单独解出来时标着 isCancellation', () {
      final content = CellArrangements.parse(
        '编译原理(073170140.01) (胡冰)<br/>'
        '(2,停课(主校区)<br/>'
        '编译原理(073170140.01) (胡冰)<br/>'
        '(1 3-12,4J410(主校区)',
      );

      expect(content.problems, isEmpty);
      expect(content.arrangements, hasLength(2));

      final cancellation = content.arrangements[0];
      expect(cancellation.isCancellation, isTrue);
      expect(cancellation.weeks.weeks, [2]);
      expect(
        cancellation.venue,
        const CancellationVenue(statusText: '停课', campus: '主校区'),
      );

      final normal = content.arrangements[1];
      expect(normal.isCancellation, isFalse);
      expect(normal.weeks.contains(2), isFalse, reason: '正常那条已经排除了第 2 周');
    });
  });

  group('正文的三种渲染都认', () {
    // 同一份内容在导出文件里有三种落法：`<br>` 分隔的正文（权威）、`;;;` 分隔的
    // title 属性、以及分号分隔。它们必须解出同一个东西。
    const body =
        '编译原理(073170140.01) (胡冰)<br/>(1-12,4J410(主校区))';
    const escaped = '编译原理(073170140.01) (胡冰);;;(1-12,4J410(主校区))';

    test('<br> 正文与 ;;; title 属性解出同一条安排', () {
      final fromBody = CellArrangements.parse(body);
      final fromTitle = CellArrangements.parse(escaped);

      expect(fromBody.arrangements, hasLength(1));
      expect(fromTitle.arrangements, hasLength(1));
      final a = fromBody.arrangements.single;
      final b = fromTitle.arrangements.single;
      expect(a.courseName, b.courseName);
      expect(a.teacher, b.teacher);
      expect(a.weeks, b.weeks);
      expect(a.venue.toText(), b.venue.toText());
    });
  });

  group('课程行：课程名与教师分开', () {
    test('课程号被去掉，教师取行尾带空格的括号', () {
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>(1-12,4J410(主校区))');
      final arrangement = content.arrangements.single;
      expect(arrangement.courseName, '编译原理');
      expect(arrangement.teacher, '胡冰');
    });

    test('课程名自带全角括号时不会被当课程号削掉', () {
      final content = CellArrangements.parse(
        'Software Testing（软件测试技术）(073180040.01) (齐斌)<br/>(1-10,4J313(主校区))',
      );
      final arrangement = content.arrangements.single;
      expect(arrangement.courseName, 'Software Testing（软件测试技术）');
      expect(arrangement.teacher, '齐斌');
    });

    test('没有教师时不会把课程号当成教师', () {
      // 课程号与课程名之间**没有空格**，所以它不是 `(教师)` 那个位置。
      final content = CellArrangements.parse('形势与政策3(16312025.H0)<br/>(11-14,4J210(主校区))');
      final arrangement = content.arrangements.single;
      expect(arrangement.courseName, '形势与政策3');
      expect(arrangement.teacher, isNull);
    });
  });

  group('空格子不报诊断', () {
    test('空正文没有任何问题', () {
      expect(CellArrangements.parse('').isBlank, isTrue);
      expect(
        CellArrangements.parse('   \n  ').isBlank,
        isTrue,
        reason: '只有空白的格子是空格子，不是「解不出来」',
      );
    });
  });

  group('解不出来时**产出诊断**，且带着原文', () {
    test('课程行后面没有周次行', () {
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>');
      expect(content.arrangements, isEmpty);
      expect(content.problems, hasLength(1));
      expect(content.problems.single, contains('编译原理'));
      expect(content.problems.single, contains('没有周次行'));
    });

    test('周次行前面没有课程行', () {
      final content = CellArrangements.parse('<br/>(1-12,4J410(主校区))');
      expect(content.arrangements, isEmpty);
      expect(content.problems.single, contains('前面没有课程行'));
    });

    test('正文里全是认不出来的东西', () {
      final content = CellArrangements.parse('这一格的正文不是排课格式');
      expect(content.arrangements, isEmpty);
      expect(content.problems, hasLength(1));
      expect(content.problems.single, contains('「这一格的正文不是排课格式」'));
    });

    test('周次那一段解不出来时说清是哪一行', () {
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>(第十八周,4J410(主校区))');
      expect(content.arrangements, isEmpty);
      expect(content.problems.single, contains('第十八周'));
    });

    test('缺地点', () {
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>(1-12,)');
      expect(content.arrangements, isEmpty);
      expect(content.problems.single, contains('没有地点'));
    });

    test('周次行里没有逗号', () {
      final content = CellArrangements.parse('编译原理(073170140.01) (胡冰)<br/>(1-12)');
      expect(content.arrangements, isEmpty);
      expect(content.problems.single, contains('没有逗号'));
    });
  });
}
