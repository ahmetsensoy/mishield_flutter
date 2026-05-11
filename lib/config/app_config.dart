/// Central place for values you ship with the app and tune per release.
///
/// **Remote config** is a plain JSON file at [remoteConfigUrl] (GitHub raw, Cloudflare R2,
/// any HTTPS static file). It is not a custom API server — only a URL you control.
abstract final class AppConfig {
  /// HTTPS URL returning JSON (see [RemoteAppConfig]).
  /// Replace with your real host before shipping.
  static const String remoteConfigUrl =
      'https://gist.githubusercontent.com/example/raw/mishield_remote_config.json';

  /// Play Store package id (must match `applicationId` in Android).
  static const String playStorePackageId = 'com.marcatsoftware.mishieldapp';

  /// Built-in DNS if remote fetch fails or omits values. Change to your ad-blocking resolvers.
  static const String defaultPrimaryDns = '94.140.14.14';
  static const String defaultSecondaryDns = '94.140.15.15';

  /// Google test banner (safe while developing). Use your real unit id in release builds.
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  /// Replace before Play release when enabling ads.
  static const String releaseBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
}
