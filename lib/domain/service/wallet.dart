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

import 'package:get/get.dart';

import '/domain/model/operation.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/wallet.dart';
import 'disposable_service.dart';

/// Service responsible for [MyUser] wallet functionality.
class WalletService extends DisposableService {
  WalletService(this._walletRepository);

  /// [AbstractWalletRepository] managing the wallet data.
  final AbstractWalletRepository _walletRepository;

  /// Returns the balance [MyUser] has in their wallet.
  RxDouble get balance => _walletRepository.balance;

  /// Returns the [Operation]s happening in [MyUser]'s wallet.
  Paginated<OperationId, Operation> get operations =>
      _walletRepository.operations;
}
