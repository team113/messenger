// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

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
