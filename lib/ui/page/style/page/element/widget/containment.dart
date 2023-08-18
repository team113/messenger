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

import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/util/message_popup.dart';
import '/ui/page/home/page/chat/widget/attachment_selector.dart';
import '/ui/page/home/page/my_profile/link_details/view.dart';
import '/ui/widget/outlined_rounded_button.dart';

class ContainmentWidget extends StatelessWidget {
  const ContainmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          _PopUpCard(
            title: 'ModalPopup',
            message: 'Intended to be displayed with the [show] method.',
            onPressed: () => LinkDetailsView.show(context),
          ),
          const SizedBox(height: 16),
          _PopUpCard(
            title: 'MessagePopup.success',
            message: 'Shows a [FloatingSnackBar] with the [title] message.',
            onPressed: () => MessagePopup.success('label_copied'.l10n),
          ),
          const SizedBox(height: 16),
          _PopUpCard(
            title: 'MessagePopup.error',
            message: 'Shows an error popup with the provided argument.',
            onPressed: () => MessagePopup.error('err_uneditable_message'.l10n),
          ),
          const SizedBox(height: 16),
          _PopUpCard(
            title: 'MessagePopup.alert',
            message:
                'Shows a confirmation popup with the specified [title], [description], and [additional] widgets to put under the [description].',
            onPressed: () => MessagePopup.alert(
              'label_hide_chat'.l10n,
              description: [
                TextSpan(text: 'alert_phone_will_be_deleted1'.l10n),
                TextSpan(text: '+79604875329', style: style.fonts.labelLarge),
                TextSpan(text: 'alert_phone_will_be_deleted2'.l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PopUpCard(
            title: 'AttachmentSourceSelector',
            message: 'Choosing a source to pick an [Attachment] from.',
            onPressed: () => AttachmentSourceSelector.show(
              context,
              onPickFile: () {},
              onPickMedia: () {},
              onTakePhoto: () {},
              onTakeVideo: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _PopUpCard extends StatelessWidget {
  const _PopUpCard({
    required this.title,
    required this.message,
    this.onPressed,
  });

  final String title;

  final String message;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: 120,
      width: 320,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: style.colors.onPrimary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: style.fonts.titleMedium),
              const SizedBox(width: 5),
              Tooltip(
                message: message,
                child: const Icon(Icons.info_outline_rounded, size: 14),
              )
            ],
          ),
          SizedBox(
            width: 240,
            child: OutlinedRoundedButton(
              color: style.colors.primary,
              title: Text(
                'show $title',
                style: style.fonts.titleMediumOnPrimary,
              ),
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
