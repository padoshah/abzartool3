final class JobReport {
  const JobReport(
      {required this.errorCode,
      required this.inputBytes,
      required this.outputBytes,
      required this.durationMs,
      required this.pageCount,
      required this.warningCount,
      this.error = ''});
  factory JobReport.fromJson(Map<String, Object?> json) => JobReport(
        errorCode: json['errorCode']! as int,
        inputBytes: json['inputBytes']! as int,
        outputBytes: json['outputBytes']! as int,
        durationMs: json['durationMs']! as int,
        pageCount: json['pageCount']! as int,
        warningCount: json['warningCount']! as int,
        error: (json['error'] as String?) ?? '',
      );
  final int errorCode;
  final int inputBytes;
  final int outputBytes;
  final int durationMs;
  final int pageCount;
  final int warningCount;
  final String error;
  bool get succeeded => errorCode == 0;
}
