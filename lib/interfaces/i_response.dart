class IResponse {
  final bool success;
  final String message;
  final dynamic data;

  IResponse({required this.success, required this.message, this.data});
}