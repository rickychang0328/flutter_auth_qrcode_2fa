/// Mirrors Android `Entry.ThirdPartyAction`.
enum ThirdPartyAction { create, copy, createFromClipboard }

extension ThirdPartyActionExtension on ThirdPartyAction {
  static ThirdPartyAction fromQueryAction(String? action) {
    if (action == null) return ThirdPartyAction.create;
    switch (action) {
      case 'set':
        return ThirdPartyAction.create;
      case 'get':
        return ThirdPartyAction.copy;
      default:
        return ThirdPartyAction.create;
    }
  }
}
