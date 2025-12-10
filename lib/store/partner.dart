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
import '/domain/repository/partner.dart';
import 'model/operation.dart';
import 'model/page_info.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';
import 'wallet.dart';

/// [MyUser] wallet repository interface.
class PartnerRepository extends DisposableInterface
    implements AbstractPartnerRepository {
  PartnerRepository();

  @override
  final RxDouble balance = RxDouble(0);

  @override
  late final OperationsPaginated operations = OperationsPaginated(
    initial: [],
    pagination: Pagination(
      onKey: (e) => e.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) async => Page([], PageInfo()),
      ),
    ),
    transform: ({required DtoOperation data, Operation? previous}) {
      return data.value;
    },
  );

  @override
  void onInit() {
    operations.around();
    super.onInit();
  }
}
