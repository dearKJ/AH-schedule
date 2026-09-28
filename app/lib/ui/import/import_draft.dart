import 'package:ah_schedule_core/ah_schedule_core.dart';

/// 预览页手上那份**还没入库的课表**：解析解出来的安排，加上使用者在预览里改的那些。
///
/// 它是**界面状态**，不是领域模型。领域层里一条上课安排是**值**——没有标识，靠内容
/// 区分（见 `ClassSession`）；而预览页得点名改「那一条」，所以这里给每条安排编一个
/// **只在这次预览里有效**的号。入库时号就被丢掉了：存下去的仍然是一张
/// [`Timetable`]，里面一条一条都是值。
///
/// 它按**安排自己的星期与节次跨度**摆格子（[at] / [hasOpenErrorAt]），不问「某一教学周
/// 有哪几条」——那是 `core` 的 `expandWeek` 干的事，而预览要看的是一整份文件里的全部
/// 安排（周次错开的两条在任何一个真实的教学周里都不会同时出现，可这里两条都得看得见）。
///
/// 改完就按改后的内容入库——[sessions] 就是入库时唯一的那份来源，没有「原件」与
/// 「改过的」两份并存。
class ImportDraft {
  ImportDraft({
    required this.term,
    required List<ClassSession> sessions,
    required List<ImportDiagnostic> diagnostics,
  }) : _parsedCount = sessions.length,
       diagnostics = List.unmodifiable(diagnostics) {
    for (final session in sessions) {
      _entries.add(DraftEntry(_nextId++, session));
    }
  }

  /// 这份课表要挂到哪个学年学期。文件页头里读到的只是默认值，这里是**使用者确认过的**
  /// 那个——预览页可以改它。
  ///
  /// 改的只是归属：解析出来的安排一条都不动（学期不是解析的输入）。
  AcademicTerm term;

  /// 解析产出的全部诊断，按产生顺序，一条不丢。
  ///
  /// 用过之后也只是标成「已处理」——**不从这张表上消失**：它记的是「这一格当时没解
  /// 出来」，那是一份凭据，不该因为使用者补上了就没了。
  final List<ImportDiagnostic> diagnostics;

  /// 解析**解出来**多少条。它不随使用者的编辑变——汇总里「解出 N 条」与「现在这份
  /// 有 M 条」是两件事，混成一个数就说不清这次导入的质量了。
  final int _parsedCount;

  final List<DraftEntry> _entries = [];
  final Set<int> _handled = {};
  final Set<int> _addedIds = {};
  final Set<int> _replacedIds = {};
  var _nextId = 0;

  int get parsedCount => _parsedCount;

  /// 全部安排，按它们在课表里的先后（解析顺序，补的接在后面）。
  List<ClassSession> get sessions => [
    for (final entry in _entries) entry.session,
  ];

  /// 带标识的安排，供界面点名编辑。
  List<DraftEntry> get entries => List.unmodifiable(_entries);

  int get length => _entries.length;

  /// 使用者**补了几条**。
  int get addedCount => _addedIds.length;

  /// 使用者**改了几条**。
  int get replacedCount => _replacedIds.length;

  /// 补的加改的。导入汇总里要说出这个数——把使用者补的也算成「解出来的」，等于把这次
  /// 导入的质量说高了。
  int get touchedCount => addedCount + replacedCount;

  /// 还没处理的诊断条数。**这是「有多少处需要留意」那个数。**
  int get pendingCount => diagnostics.length - _handled.length;

  /// 第 [index] 条诊断处理过了没有（补上了，或者使用者说了不管）。
  bool isHandled(int index) => _handled.contains(index);

  void setHandled(int index, {required bool handled}) {
    if (handled) {
      _handled.add(index);
    } else {
      _handled.remove(index);
    }
  }

  /// 落在某一格上的安排：星期是 [weekday]，[period] 落在它的节次跨度里。
  ///
  /// 连堂那几条会同时出现在它占的每一格上——与画出来的样子一致。
  List<DraftEntry> at(int weekday, int period) => [
    for (final entry in _entries)
      if (entry.session.weekday == weekday &&
          entry.session.periods.contains(period))
        entry,
  ];

  /// 补一条。号是新编的，并且算「补的」。
  void add(ClassSession session) {
    final entry = DraftEntry(_nextId++, session);
    _entries.add(entry);
    _addedIds.add(entry.id);
  }

  /// 改第 [id] 条。
  void replace(int id, ClassSession session) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries[index] = DraftEntry(id, session);
    _replacedIds.add(id);
  }

  /// 删掉第 [id] 条。删掉的不再算「动过」——它已经不在这份课表里了。
  void remove(int id) {
    _entries.removeWhere((entry) => entry.id == id);
    _addedIds.remove(id);
    _replacedIds.remove(id);
  }

  /// 这一格上有没有**还没处理**的出错诊断（画网格时把这一格标出来）。
  bool hasOpenErrorAt(int weekday, int period) {
    for (var index = 0; index < diagnostics.length; index++) {
      final diagnostic = diagnostics[index];
      if (_handled.contains(index)) continue;
      if (!diagnostic.isError) continue;
      if (diagnostic.weekday == weekday && diagnostic.period == period) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() =>
      'ImportDraft(${term.label}, ${_entries.length} 条安排, '
      '$pendingCount/${diagnostics.length} 条诊断未处理)';
}

/// 草稿里的一条：编号 + 安排。
///
/// 编号只在这次预览里有效（见 [ImportDraft] 的说明）。
class DraftEntry {
  const DraftEntry(this.id, this.session);

  final int id;
  final ClassSession session;
}
