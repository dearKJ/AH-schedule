import 'package:ah_schedule_core/ah_schedule_core.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// 学年学期在「领域对象」与「数据库行」之间的映射。
///
/// 这一层**刻意薄**：只做存与取，不引入新的业务规则。业务规则属于领域层——放错地方
/// 就没法被最快的纯 Dart 测试砸了（issue #8 的规矩，这里先照着来）。
class AcademicTermRepository {
  AcademicTermRepository(this._database);

  final AppDatabase _database;

  /// 库里现有的学年学期，按 id 升序——最新的排在最后。
  Future<List<AcademicTerm>> loadAll() async {
    final query = _database.select(_database.academicTerms)
      ..orderBy([(table) => OrderingTerm.asc(table.id)]);
    final rows = await query.get();
    return [for (final row in rows) AcademicTerm(id: row.id, label: row.label)];
  }

  /// 存下一个学年学期。同 id 再存一次是改写，不是新增第二条。
  Future<void> save(AcademicTerm term) async {
    await _database
        .into(_database.academicTerms)
        .insertOnConflictUpdate(
          AcademicTermsCompanion.insert(id: term.id, label: term.label),
        );
  }
}
