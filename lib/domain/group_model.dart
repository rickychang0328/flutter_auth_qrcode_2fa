/// Mirrors Android `GroupModel` (batch QR export group attachment).
class GroupModel {
  GroupModel({
    required this.id,
    required this.text,
    List<int>? codeLastIdList,
    this.pinned = false,
  }) : codeLastIdList = List<int>.from(codeLastIdList ?? const []);

  final int id;
  final String text;
  final List<int> codeLastIdList;
  final bool pinned;
}
