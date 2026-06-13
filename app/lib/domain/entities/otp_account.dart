class OtpAccount {
  final String id;
  final String issuer;
  final String accountLabel;
  final String secretBase32;
  final String algorithm;
  final int digits;
  final int period;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? shortcutKey;
  final int sortOrder;

  const OtpAccount({
    required this.id,
    required this.issuer,
    required this.accountLabel,
    this.secretBase32 = '',
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.version = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.shortcutKey,
    this.sortOrder = -1,
  });

  OtpAccount copyWith({
    String? id,
    String? issuer,
    String? accountLabel,
    String? secretBase32,
    String? algorithm,
    int? digits,
    int? period,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? shortcutKey,
    int? sortOrder,
  }) {
    return OtpAccount(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      accountLabel: accountLabel ?? this.accountLabel,
      secretBase32: secretBase32 ?? this.secretBase32,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      shortcutKey: shortcutKey ?? this.shortcutKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'account_label': accountLabel,
        'secret_base32': secretBase32,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
        'version': version,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'shortcut_key': shortcutKey,
        'sort_order': sortOrder,
      };

  factory OtpAccount.fromJson(Map<String, dynamic> json) => OtpAccount(
        id: json['id'] as String,
        issuer: json['issuer'] as String,
        accountLabel: json['account_label'] as String? ?? '',
        secretBase32: json['secret_base32'] as String? ?? '',
        algorithm: json['algorithm'] as String? ?? 'SHA1',
        digits: json['digits'] as int? ?? 6,
        period: json['period'] as int? ?? 30,
        version: json['version'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        shortcutKey: json['shortcut_key'] as String?,
        sortOrder: json['sort_order'] as int? ?? -1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtpAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
