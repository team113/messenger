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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/page/user/widget/blocklist_record.dart';
import '/ui/page/home/page/user/widget/status.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

/// [Routes.style] fields section.
class FieldsSection {
  /// Returns the [Widget]s of this [FieldsSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      Headlines(
        children: [
          (
            headline: 'ReactiveTextField',
            widget: ReactiveTextField(
              state: TextFieldState(approvable: true),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            headline: 'ReactiveTextField(error)',
            widget: ReactiveTextField(
              state: TextFieldState(
                text: 'Text',
                error: 'Error text',
                editable: false,
              ),
              hint: 'Hint',
              label: 'Label',
            ),
          ),
          (
            headline: 'ReactiveTextField(subtitle)',
            widget: ReactiveTextField(
              key: const Key('LoginField'),
              state: TextFieldState(text: 'Text'),
              onSuffixPressed: () {},
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: const SvgIcon(SvgIcons.copy),
              ),
              label: 'Label',
              hint: 'Hint',
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Subtitle with: ',
                      style: style.fonts.small.regular.secondary,
                    ),
                    TextSpan(
                      text: 'clickable.',
                      style: style.fonts.small.regular.primary,
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          (
            headline: 'ReactiveTextField(obscure)',
            widget: ObxValue((b) {
              return ReactiveTextField(
                state: TextFieldState(text: 'Text'),
                label: 'Obscured text',
                obscure: b.value,
                onSuffixPressed: b.toggle,
                treatErrorAsStatus: false,
                trailing: SvgImage.asset(
                  'assets/icons/${b.value ? 'visible_off' : 'visible_on'}.svg',
                  width: 17.07,
                  height: b.value ? 15.14 : 11.97,
                ),
              );
            }, RxBool(true)),
          ),
        ],
      ),
      Headline(
        child: CopyableTextField(
          state: TextFieldState(text: 'Text to copy', editable: false),
          label: 'Label',
        ),
      ),
      Headline(
        child: SharableTextField(text: 'Text to share', label: 'Label'),
      ),
      Headline(
        child: MessageFieldView(
          controller: MessageFieldController(
            null,
            null,
            null,
            null,
            null,
            null,
            null,
          ),
        ),
      ),
      Headline(
        headline: 'CustomAppBar(search)',
        child: SizedBox(
          height: 60,
          width: 400,
          child: CustomAppBar(
            top: false,
            border: Border.all(color: style.colors.primary, width: 2),
            title: Theme(
              data: MessageFieldView.theme(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Transform.translate(
                  offset: const Offset(0, 1),
                  child: ReactiveTextField(
                    state: TextFieldState(),
                    hint: 'Search',
                    maxLines: 1,
                    filled: false,
                    dense: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    style: style.fonts.medium.regular.onBackground,
                    onChanged: () {},
                  ),
                ),
              ),
            ),
            leading: [
              AnimatedButton(
                decorator: (child) => Container(
                  padding: const EdgeInsets.only(left: 20, right: 6),
                  height: double.infinity,
                  child: child,
                ),
                onPressed: () {},
                child: const SvgIcon(SvgIcons.back),
              ),
            ],
          ),
        ),
      ),
      Headline(
        headline: 'ReactiveTextField(search)',
        child: ReactiveTextField(
          key: const Key('SearchTextField'),
          state: TextFieldState(),
          label: 'Search',
          style: style.fonts.normal.regular.onBackground,
          onChanged: () {},
        ),
      ),
      const Headline(
        child: UserStatusCopyable(UserTextStatus.unchecked('Status')),
      ),
      const Headline(child: DirectLinkField(null)),
      Headline(
        child: BlocklistRecordWidget(
          BlocklistRecord(
            userId: const UserId('me'),
            at: PreciseDateTime.now(),
          ),
        ),
      ),
    ];
  }
}
