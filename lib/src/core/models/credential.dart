class Credential {
  final String portalUrl;
  final String macAddress;

  Credential({required this.portalUrl, required this.macAddress});

  // Convert a Credential object into a Map.
  Map<String, dynamic> toJson() => {
        'portalUrl': portalUrl,
        'macAddress': macAddress,
      };

  // Construct a Credential object from a Map.
  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      portalUrl: json['portalUrl'] as String,
      macAddress: json['macAddress'] as String,
    );
  }
}