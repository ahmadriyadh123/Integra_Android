class ScormSessionState {
  final String startUrl;
  final bool isZipPackage;

  ScormSessionState({
    required this.startUrl,
    required this.isZipPackage,
  });
}

class ScormBridgeMessage {
  final String type;
  final Map<String, dynamic>? payload;

  ScormBridgeMessage({required this.type, this.payload});

  factory ScormBridgeMessage.fromJson(Map<String, dynamic> json) {
    return ScormBridgeMessage(
      type: json['type'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}