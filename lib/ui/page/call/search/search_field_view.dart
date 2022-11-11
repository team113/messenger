// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the [User]s search.
class SearchFieldView extends StatelessWidget {
  const SearchFieldView({
    Key? key,
    required this.categories,
    this.searchStatus,
    this.autoFocus,
    this.onResultsUpdated,
  }) : super(key: key);

  /// [SearchCategory]ies to search through.
  final List<SearchCategory> categories;

  /// Indicator whether search field is autofocus or not.
  final bool? autoFocus;

  /// Status of a search completion.
  ///
  /// May be:
  /// - `searchStatus.empty`, meaning no search.
  /// - `searchStatus.loading`, meaning search is in progress.
  /// - `searchStatus.loadingMore`, meaning search is in progress after some
  ///   search results were already acquired.
  /// - `searchStatus.success`, meaning search is done and search results are
  ///   acquired.
  final Rx<RxStatus>? searchStatus;

  /// Callback, called when the selected items was changed.
  final void Function(SearchViewResults result, String query)? onResultsUpdated;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SearchController(
        Get.find(),
        Get.find(),
        Get.find(),
        categories: categories,
        onResultsUpdated: onResultsUpdated,
        status: searchStatus,
        autoFocus: autoFocus,
      ),
      builder: (SearchController c) {
        return ReactiveTextField(
          state: c.search,
          hint: 'label_search'.l10n,
          maxLines: 1,
          filled: false,
          dense: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          style: Theme.of(context)
              .extension<Style>()!
              .boldBody
              .copyWith(fontSize: 17),
          onChanged: () => c.query.value = c.search.text,
        );
      },
    );
  }
}
