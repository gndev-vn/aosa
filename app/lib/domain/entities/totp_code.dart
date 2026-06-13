class TotpCode {
  final String code;
  final int timeLeft;
  final int totalPeriod;
  final String algorithm;
  final int digits;

  const TotpCode({
    required this.code,
    required this.timeLeft,
    required this.totalPeriod,
    required this.algorithm,
    required this.digits,
  });

  double get progress => timeLeft / totalPeriod;
  bool get isExpired => timeLeft <= 0;

  TotpCode copyWith({
    String? code,
    int? timeLeft,
    int? totalPeriod,
    String? algorithm,
    int? digits,
  }) {
    return TotpCode(
      code: code ?? this.code,
      timeLeft: timeLeft ?? this.timeLeft,
      totalPeriod: totalPeriod ?? this.totalPeriod,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
    );
  }
}
