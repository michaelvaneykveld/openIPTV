class ChannelOverride {
  final String portalId;
  final String channelId;
  final bool isHidden;
  final String? customName;
  final String? customGroup;
  final int? position;

  const ChannelOverride({
    required this.portalId,
    required this.channelId,
    this.isHidden = false,
    this.customName,
    this.customGroup,
    this.position,
  });

  ChannelOverride copyWith({
    bool? isHidden,
    String? customName,
    String? customGroup,
    int? position,
  }) {
    return ChannelOverride(
      portalId: portalId,
      channelId: channelId,
      isHidden: isHidden ?? this.isHidden,
      customName: customName ?? this.customName,
      customGroup: customGroup ?? this.customGroup,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'portal_id': portalId,
      'channel_id': channelId,
      'is_hidden': isHidden ? 1 : 0,
      'custom_name': customName,
      'custom_group': customGroup,
      'position': position,
    };
  }

  factory ChannelOverride.fromMap(Map<String, dynamic> map) {
    return ChannelOverride(
      portalId: map['portal_id'] as String,
      channelId: map['channel_id'] as String,
      isHidden: (map['is_hidden'] as int? ?? 0) == 1,
      customName: map['custom_name'] as String?,
      customGroup: map['custom_group'] as String?,
      position: map['position'] as int?,
    );
  }
}
