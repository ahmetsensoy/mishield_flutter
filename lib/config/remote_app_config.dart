/// JSON shape for [remoteConfigUrl] (all keys optional).
///
/// Example:
/// ```json
/// {
///   "min_supported_version": "1.0.0",
///   "primary_dns": "94.140.14.14",
///   "secondary_dns": "94.140.15.15",
///   "show_ads": false
/// }
/// ```
class RemoteAppConfig {
  const RemoteAppConfig({
    this.minSupportedVersion,
    this.primaryDns,
    this.secondaryDns,
    this.showAds,
  });

  final String? minSupportedVersion;
  final String? primaryDns;
  final String? secondaryDns;
  final bool? showAds;

  factory RemoteAppConfig.fromJson(Map<String, dynamic> json) {
    return RemoteAppConfig(
      minSupportedVersion: json['min_supported_version'] as String?,
      primaryDns: json['primary_dns'] as String?,
      secondaryDns: json['secondary_dns'] as String?,
      showAds: json['show_ads'] as bool?,
    );
  }
}

/// Effective runtime values after merging remote + defaults.
class ResolvedAppConfig {
  const ResolvedAppConfig({
    required this.primaryDns,
    required this.secondaryDns,
    required this.showAds,
    this.remote,
  });

  final String primaryDns;
  final String secondaryDns;
  final bool showAds;
  final RemoteAppConfig? remote;
}
