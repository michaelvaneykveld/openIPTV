/// Represents the type of IPTV provider.
enum ProviderType { m3u, xtream, stalker }

/// Base class for credentials, specific implementations will extend this.
abstract class Credentials {
  final ProviderType type;
  Credentials(this.type);
}

class M3uCredentials extends Credentials {
  final String m3uUrl;
  final String? epgUrl;
  M3uCredentials({required this.m3uUrl, this.epgUrl}) : super(ProviderType.m3u);
}

class XtreamCredentials extends Credentials {
  final String serverUrl;
  final String username;
  final String password;
  XtreamCredentials({required this.serverUrl, required this.username, required this.password}) : super(ProviderType.xtream);
}

class StalkerCredentials extends Credentials {
  final String portalUrl;
  final String macAddress;
  StalkerCredentials({required this.portalUrl, required this.macAddress}) : super(ProviderType.stalker);
}

// Define other models based on your plan.
// These are simplified for brevity.

class Channel {
  final String id;
  final String name;
  final String? logoUrl;
  final String group;
  final String epgId;

  Channel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.group,
    required this.epgId,
  });
}

class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});
}

class VodItem {
  final String id;
  final String name;
  final String? posterUrl;
  VodItem({required this.id, required this.name, this.posterUrl});
}

class Series {
  final String id;
  final String name;
  final String? posterUrl;
  Series({required this.id, required this.name, this.posterUrl});
}

class EpgEvent {
  // ... properties like start, end, title, desc
}