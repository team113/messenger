// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/wallet.dart';
import '/api/backend/schema.dart' show OperationStatus;
import '/domain/model/country.dart';
import '/domain/model/operation.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/price.dart';
import '/domain/model/user.dart';
import '/domain/repository/wallet.dart';
import '/domain/service/disposable_service.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import 'model/operation.dart';
import 'model/page_info.dart';
import 'paginated.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';

typedef OperationsPaginated =
    RxPaginatedImpl<OperationId, Operation, DtoOperation, OperationsCursor>;

/// [MyUser] wallet repository interface.
class WalletRepository extends IdentityDependency
    implements AbstractWalletRepository {
  WalletRepository(this._graphQlProvider, {required super.me});

  @override
  final RxDouble balance = RxDouble(0);

  @override
  late final OperationsPaginated operations = OperationsPaginated(
    initial: [
      {
        OperationId('aaaaaaaaaa'): OperationDeposit(
          id: OperationId('aaaaaaaaaa'),
          num: OperationNum('1'),
          status: OperationStatus.inProgress,
          amount: Price(sum: Sum(10), currency: Currency('G')),
          createdAt: PreciseDateTime.now().subtract(
            Duration(days: 5, hours: 3, minutes: 2, seconds: 10),
          ),
          billingCountry: CountryCode('US'),
        ),
        OperationId('bbbbbbbbbb'): OperationDeposit(
          id: OperationId('bbbbbbbbbb'),
          num: OperationNum('2'),
          status: OperationStatus.failed,
          amount: Price(sum: Sum(50), currency: Currency('G')),
          createdAt: PreciseDateTime.now().subtract(
            Duration(days: 2, hours: 7, minutes: 49, seconds: 49),
          ),
          billingCountry: CountryCode('US'),
        ),
        OperationId('cccccccccc'): OperationDeposit(
          id: OperationId('cccccccccc'),
          num: OperationNum('3'),
          status: OperationStatus.completed,
          invoice: InvoiceFile('example.com'),
          amount: Price(sum: Sum(1000), currency: Currency('G')),
          createdAt: PreciseDateTime.now(),
          billingCountry: CountryCode('US'),
        ),
        OperationId('dddddddddd'): OperationDepositBonus(
          id: OperationId('dddddddddd'),
          num: OperationNum('3'),
          status: OperationStatus.completed,
          amount: Price(sum: Sum(5), currency: Currency('G')),
          createdAt: PreciseDateTime.now(),
          depositId: OperationId('cccccccccc'),
        ),
      },
    ],
    pagination: Pagination(
      onKey: (e) => e.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) async {
          final Page<DtoOperation, OperationsCursor> page = await _operations(
            after: after,
            before: before,
            first: first,
            last: last,
          );

          return page;
        },
      ),
    ),
    transform: ({required DtoOperation data, Operation? previous}) {
      return data.value;
    },
  );

  /// [GraphQlProvider] for fetching the [Operation]s list.
  final GraphQlProvider _graphQlProvider;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');
    super.onInit();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me)', '$runtimeType');

    operations.clear();

    if (!me.isLocal) {
      operations.around();
    }
  }

  /// Fetches purse operations with pagination.
  Future<Page<DtoOperation, OperationsCursor>> _operations({
    int? first,
    OperationsCursor? after,
    int? last,
    OperationsCursor? before,
  }) async {
    Log.debug('_operations($first, $after, $last, $before)', '$runtimeType');

    if (me.isLocal) {
      return Page([], PageInfo());
    }

    final query = await _graphQlProvider.operations(
      first: first,
      after: after,
      last: last,
      before: before,
    );

    return Page(
      query.edges.map((e) => e.node.toDto(cursor: e.cursor)).toList(),
      query.pageInfo.toModel((c) => OperationsCursor(c)),
    );
  }
}
