import 'package:equatable/equatable.dart';

class WalletTransactionModel extends Equatable {
  final String id;
  final String title;
  final double amount;
  final bool isCredit;
  final String formattedDate;

  /// Fields the server has always returned and the app discarded.
  final String reference;
  final String orderId;
  final String ledgerType;

  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.formattedDate,
    this.reference = '',
    this.orderId = '',
    this.ledgerType = '',
  });

  /// Ledger rows come back as
  /// `{_id, type: 'credit'|'debit', title, amount, date, reference, orderId,
  ///   source, ledgerType}`.
  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase() ?? '';
    return WalletTransactionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['description']?.toString() ??
          'Transaction',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isCredit: json['isCredit'] == true || type == 'credit',
      formattedDate: json['date']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      ledgerType: json['ledgerType']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, title, amount, isCredit, formattedDate, reference, orderId, ledgerType];
}
