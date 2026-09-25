import '../class_session.dart';
import '../period_span.dart';
import '../session_exception.dart';
import '../venue.dart';
import '../week_set.dart';
import 'cell_arrangements.dart';
import 'html_course_table.dart';
import 'import_diagnostics.dart';

/// 把逻辑网格里的每个格子解成领域层的 `ClassSession`，顺带产出诊断。
///
/// 这一层负责三件事，也是整个导入里最容易做错的三件事：
///
/// 1. **星期与节次**由格子在网格里的位置给（星期来自 `id` 那套坐标 / DOM 列，
///    节次来自节次行，连堂来自 `rowspan`）。
/// 2. **停课那一行不单算一次课**。教务系统把「某周停课」额外单列一条，而正常那
///    条的周次集合**已经排除了那一周**，两条要合并理解为「一次带例外的排课」。
/// 3. **解不出来的格子一律产出诊断**，带着位置与原文。
abstract final class ClassSessionBuilder {
  /// 铺完一张网格。
  ///
  /// 只返回**能解出来的**那部分课表——解不出来的部分不静默丢掉，而是落在
  /// [issues] 里。两者必须一起用，没有「只拿课表」的用法。
  static List<ClassSession> build({
    required GridTable table,
    required ImportIssues issues,
  }) {
    final sessions = <ClassSession>[];

    for (final cell in table.cells) {
      // 节次列（第 0 列）在表头里，逻辑网格里不该有；表格若是残的会落进这里。
      if (cell.weekday == null) continue;

      final content = CellArrangements.parse(cell.rawText);
      final rawText = CellArrangements.stripTags(cell.rawText);

      if (content.isBlank) {
        // 空格子。这里**不报诊断**——空课表是正常结果，报出来只会淹没真问题。
        continue;
      }
      if (content.arrangements.isEmpty) {
        _reportCellIssues(content.problems, cell, rawText, issues);
        continue;
      }

      final end = cell.period + cell.rowSpan - 1;
      if (end > table.periodCount) {
        issues.add(
          ImportDiagnostic(
            code: ImportIssue.malformedTable,
            severity: ImportSeverity.error,
            message:
                '这一格从第 ${cell.period} 节起连 ${cell.rowSpan} 节，'
                '越过了最后一节（第 ${table.periodCount} 节），这一格没有导入',
            weekday: cell.weekday,
            period: cell.period,
            rawText: rawText,
          ),
        );
        continue;
      }

      final span = PeriodSpan(cell.period, cell.rowSpan);
      sessions.addAll(
        _sessionsOf(
          arrangements: content.arrangements,
          weekday: cell.weekday!,
          span: span,
          rawText: rawText,
          issues: issues,
        ),
      );
    }

    return sessions;
  }

  /// 一格里的全部叶子安排 → 若干条 `ClassSession`。
  ///
  /// ## 一路排课正文里的条目，分成「排课」与「例外」两类
  ///
  /// - **停课**（`(2,停课(主校区))`）是**例外**：它不产出安排，只改既有那条。
  /// - **线上教学**（`(第14周,线上教学(校区))`）是**排课**，不是例外——它占着原本
  ///   放教室名的位置，整行就是「这周的课在这里上」。它的地点是 [Venue.online]，
  ///   同时挂一条 [OnlineTeaching] 例外把「改线上」这件事也记下来（`CONTEXT.md`
  ///   的「线上教学」说它是一个例外种类）。要是把它只当例外、不产出安排，那
  ///   「一门课上到一半改线上」时那一周就会**什么都不显示**——那是静默失败。
  ///
  /// 这一层不合并「教室那条与线上那条」：周次已经说清哪周在哪上，而合并要判断
  /// 「哪条盖住哪周」，那是展开（issue #9）那边的事。见 [ClassSession.coversWeek]。
  static List<ClassSession> _sessionsOf({
    required List<Arrangement> arrangements,
    required int weekday,
    required PeriodSpan span,
    required String rawText,
    required ImportIssues issues,
  }) {
    final cancellations = <Arrangement>[];
    final reservations = <Arrangement>[];
    for (final arrangement in arrangements) {
      (arrangement.isCancellation ? cancellations : reservations)
          .add(arrangement);
    }

    final sessions = <ClassSession>[
      for (final arrangement in reservations)
        ClassSession(
          courseName: arrangement.courseName,
          teacher: arrangement.teacher,
          weekday: weekday,
          periods: span,
          weeks: arrangement.weeks,
          venue: _venueOf(arrangement),
          exceptions: _exceptionsFor(
            arrangement: arrangement,
            cancellations: cancellations,
          ),
        ),
    ];

    if (reservations.isEmpty && cancellations.isNotEmpty) {
      // 一格里的正文**只有**停课那一行。样本里没出现过，但真出现的话不能当成
      // 「这格没问题」——例外是挂在安排上的信息，挂不上去就是信息丢了。
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.unparsableCell,
          severity: ImportSeverity.error,
          message: '这一格里只有停课那一行，没有对应的排课行，停课挂不上去',
          weekday: weekday,
          period: span.start,
          rawText: rawText,
        ),
      );
    }

    return sessions;
  }

  /// 一条排课该挂哪些例外。
  static List<SessionException> _exceptionsFor({
    required Arrangement arrangement,
    required List<Arrangement> cancellations,
  }) {
    final exceptions = <SessionException>[];

    for (final cancellation in cancellations) {
      // 停课那一条的周次**通常已经被正常那条排除了**（样本里就是），这时它不带新
      // 信息，不再挂一遍例外——领域层里例外的意思是「这条安排原本包含这一周，但
      // 这一周不上」，挂到一条本来就不含这一周的安排上是自相矛盾的。
      final week = _firstOverlappingWeek(cancellation.weeks, arrangement.weeks);
      if (week != null && !exceptions.contains(Cancellation(week))) {
        exceptions.add(Cancellation(week));
      }
    }

    // 线上教学那一行自己就是一条排课（见 [_sessionsOf]），再把「改线上」记成例外，
    // `CONTEXT.md` 里说的那个例外种类就齐了。
    final venue = arrangement.venue;
    if (venue is OnlineVenue) {
      final exception = OnlineTeaching(
        arrangement.weeks.min,
        campus: venue.campus,
      );
      if (!exceptions.contains(exception)) exceptions.add(exception);
    }

    return exceptions;
  }


  /// 把一个格子里读不出来的地方落成诊断，**每条都带星期 / 节次与原文**。
  static void _reportCellIssues(
    List<String> problems,
    GridCell cell,
    String rawText,
    ImportIssues issues,
  ) {
    for (final problem in problems) {
      issues.add(
        ImportDiagnostic(
          code: ImportIssue.unparsableCell,
          severity: ImportSeverity.error,
          message: problem,
          weekday: cell.weekday,
          period: cell.period,
          rawText: rawText,
        ),
      );
    }
  }

  static Venue _venueOf(Arrangement arrangement) => switch (arrangement.venue) {
    RoomVenue(room: final room, campus: final campus) => Venue(
      room: room,
      campus: campus,
    ),
    OnlineVenue(campus: final campus) => Venue.online(campus: campus),
    // 停课那一行到不了这里：它被分进了 cancellations，不产出安排。
    CancellationVenue() => Venue.online(),
  };

  static int? _firstOverlappingWeek(WeekSet a, WeekSet b) {
    for (final week in a.weeks) {
      if (b.contains(week)) return week;
    }
    return null;
  }
}
