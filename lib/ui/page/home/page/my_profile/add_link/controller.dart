// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/link.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';

/// Controller of a [AddLinkView] modal.
class AddLinkController extends GetxController {
  AddLinkController({this.onAdded, this.pop});

  /// Callback, called when a new [DirectLinkSlug] is submitted.
  final FutureOr<void> Function(DirectLinkSlug)? onAdded;

  /// Generated [DirectLinkSlug], used in the [state].
  final String generated = DirectLinkSlug.generate(10).val;

  /// Callback, called when a [AddLinkView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// State of the [ReactiveTextField].
  late final TextFieldState state = TextFieldState(
    onFocus: (s) {
      if (s.text.trim().isNotEmpty) {
        try {
          DirectLinkSlug(s.text);
        } on FormatException {
          if (s.text.length > 100) {
            s.error.value = 'err_incorrect_link_too_long'.l10n;
          } else {
            s.error.value = 'err_invalid_symbols_in_link'.l10n;
          }
        }
      }
    },
    onSubmitted: (_) async => await submit(),
  );

  /// Submits the [DirectLink].
  Future<void> submit() async {
    state.focus.unfocus();

    DirectLinkSlug? slug;

    if (state.text.isNotEmpty) {
      try {
        slug = DirectLinkSlug(state.text);
      } on FormatException {
        state.error.value = 'err_invalid_symbols_in_link'.l10n;
      }
    }

    if (slug == null) {
      return;
    }

    if (state.error.value == null || state.resubmitOnError.isTrue) {
      state.editable.value = false;
      state.status.value = RxStatus.loading();

      try {
        await onAdded?.call(slug);
        pop?.call();
      } on UpdateDirectLinkException catch (e) {
        state.error.value = e.toMessage();
      } on UpdateGroupDirectLinkException catch (e) {
        state.error.value = e.toMessage();
      } catch (e) {
        state.resubmitOnError.value = true;
        state.error.value = 'err_data_transfer'.l10n;
        state.unsubmit();
        rethrow;
      } finally {
        state.status.value = RxStatus.empty();
        state.editable.value = true;
      }
    }
  }
}
