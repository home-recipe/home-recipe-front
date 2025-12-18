class ResponseDetail<T> {
  final String code;
  final T? data;

  ResponseDetail({
    required this.code,
    this.data,
  });
}