class InvalidApiResponseException implements Exception {
  final String message;

  InvalidApiResponseException(this.message);

  @override
  String toString() => 'InvalidApiResponseException: $message';
}
