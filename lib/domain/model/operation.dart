// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

// ignore_for_file: avoid_types_as_parameter_names

import '/api/backend/schema.dart' show OperationStatus, OperationDepositKind;
import '/util/new_type.dart';
import 'country.dart';
import 'precise_date_time/precise_date_time.dart';
import 'price.dart';

/// Billing operation.
abstract class Operation {
  Operation({
    required this.id,
    required this.num,
    this.status = OperationStatus.completed,
    required this.amount,
    required this.createdAt,
  });

  /// ID of this [Operation].
  final OperationId id;

  /// Sequential number of this [Operation].
  final OperationNum num;

  /// [Status] of this [Operation].
  final OperationStatus status;

  /// Money [Sum] and [Currency] of this [Operation].
  final Price amount;

  /// [PreciseDateTime] when this [Operation] was created.
  final PreciseDateTime createdAt;
}

/// Operation of depositing money to [MyUser]'s purse.
class OperationDeposit extends Operation {
  OperationDeposit({
    required super.id,
    required super.num,
    super.status = OperationStatus.completed,
    required super.amount,
    required super.createdAt,
    this.kind = OperationDepositKind.paypal,
    required this.billingCountry,
    this.invoice,
  });

  /// Kind of this [OperationDeposit].
  final OperationDepositKind kind;

  /// Country of the billing address of this [OperationDeposit].
  final CountryCode billingCountry;

  /// [Invoice] of this [OperationDeposit].
  ///
  /// `null` if this [status] is not `COMPLETED`.
  final Invoice? invoice;
}

/// Operation of depositing money to [MyUser]'s purse.
class OperationDepositBonus extends Operation {
  OperationDepositBonus({
    required super.id,
    required super.num,
    super.status = OperationStatus.completed,
    required this.depositId,
    required super.amount,
    required super.createdAt,
  });

  /// [OperationDeposit] this [OperationDepositBonus] is related to.
  final OperationId depositId;
}

/// ID of an [Operation].
class OperationId extends NewType<String> {
  const OperationId(super.val);
}

/// Sequential number of an [Operation].
class OperationNum extends NewType<String> {
  const OperationNum(super.val);
}

/// Sequential number of an [Operation].
class Invoice extends NewType<String> {
  const Invoice(super.val);
}
