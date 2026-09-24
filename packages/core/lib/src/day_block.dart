/// 一节次在一天里属于哪一段。分界与教务系统导出文件里节次行的底色一致
/// （第一至五节上午、第六至九节下午、第十至十二节晚上）。
enum DayBlock {
  morning('上午'),
  afternoon('下午'),
  evening('晚上');

  const DayBlock(this.label);

  /// 界面上的写法。
  final String label;
}
