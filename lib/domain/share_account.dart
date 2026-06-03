/// Share import/export history — mirrors Android `ShareAccount`.
class ShareAccount {
  ShareAccount({
    required this.type,
    required this.actionContent,
    required this.actionDate,
    this.shareAccountDetail = const [],
  });

  String type;
  String actionContent;
  String actionDate;
  List<ShareAccountDetail> shareAccountDetail;

  Map<String, dynamic> toJson() => {
        'type': type,
        'actionContent': actionContent,
        'actionDate': actionDate,
        'shareAccountDetail':
            shareAccountDetail.map((d) => d.toJson()).toList(),
      };

  factory ShareAccount.fromJson(Map<String, dynamic> json) => ShareAccount(
        type: json['type'] as String? ?? 'import',
        actionContent: json['actionContent'] as String? ?? '',
        actionDate: json['actionDate'] as String? ?? '',
        shareAccountDetail: (json['shareAccountDetail'] as List<dynamic>?)
                ?.map(
                  (e) => ShareAccountDetail.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList() ??
            [],
      );
}

class ShareAccountDetail {
  ShareAccountDetail({
    required this.issuer,
    required this.account,
    this.group = '',
  });

  String issuer;
  String account;
  String group;

  Map<String, dynamic> toJson() => {
        'issuer': issuer,
        'account': account,
        'group': group,
      };

  factory ShareAccountDetail.fromJson(Map<String, dynamic> json) =>
      ShareAccountDetail(
        issuer: json['issuer'] as String? ?? '',
        account: json['account'] as String? ?? '',
        group: json['group'] as String? ?? '',
      );
}
