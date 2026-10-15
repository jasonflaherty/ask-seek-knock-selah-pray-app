/// Who can see a prayer. Just me never leaves the device.
enum ShareScope {
  justMe,
  group,
  church,
}

extension ShareScopeX on ShareScope {
  String get storageValue => switch (this) {
        ShareScope.justMe => 'justMe',
        ShareScope.group => 'group',
        ShareScope.church => 'church',
      };

  String get label => switch (this) {
        ShareScope.justMe => 'Just me',
        ShareScope.group => 'Group',
        ShareScope.church => 'Church',
      };

  bool get isShared => this != ShareScope.justMe;

  static ShareScope fromStorage(String? raw) {
    switch (raw) {
      case 'group':
        return ShareScope.group;
      case 'church':
        return ShareScope.church;
      default:
        return ShareScope.justMe;
    }
  }

  /// Maps legacy `shared` boolean rows before shareScope existed.
  static ShareScope fromLegacyShared(bool shared) =>
      shared ? ShareScope.church : ShareScope.justMe;
}
