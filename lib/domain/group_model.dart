/// Mirrors Android `GroupModel` (batch QR export group attachment).
class GroupModel {
  GroupModel({
    required this.id,
    required this.text,
    List<int>? codeLastIdList,
    this.pinned = false,
  }) : codeLastIdList = List<int>.from(codeLastIdList ?? const []);

  int id;
  String text;
  List<int> codeLastIdList;
  bool pinned;

  GroupModel copyWith({
    int? id,
    String? text,
    List<int>? codeLastIdList,
    bool? pinned,
  }) =>
      GroupModel(
        id: id ?? this.id,
        text: text ?? this.text,
        codeLastIdList: codeLastIdList ?? List<int>.from(this.codeLastIdList),
        pinned: pinned ?? this.pinned,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'codeLastIdList': codeLastIdList,
        'pinned': pinned,
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        codeLastIdList: (json['codeLastIdList'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            [],
        pinned: json['pinned'] as bool? ?? false,
      );
}
