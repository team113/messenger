import 'package:uuid/uuid.dart';

enum TransactionStatus {
  completed,
  failed,
  sent,
  pending,
  declined,
}

abstract class Transaction {
  Transaction({
    String? id,
    required this.amount,
    required this.at,
    this.status = TransactionStatus.completed,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final TransactionStatus status;
  final double amount;
  final DateTime at;
}

class OutgoingTransaction extends Transaction {
  OutgoingTransaction({
    super.id,
    required super.amount,
    required super.at,
    super.status = TransactionStatus.completed,
  });
}

class IncomingTransaction extends Transaction {
  IncomingTransaction({
    super.id,
    required super.amount,
    required super.at,
    super.status = TransactionStatus.completed,
  });
}
