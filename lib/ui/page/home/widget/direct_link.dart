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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/config.dart';
import '/domain/model/link.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show UpdateDirectLinkException, UpdateGroupDirectLinkException;
import '/themes.dart';
import '/ui/page/home/page/my_profile/add_link/view.dart';
import '/ui/page/home/page/my_profile/qr_code/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'field_button.dart';

/// [ReactiveTextField] displaying the provided [links].
///
/// If [links] are empty, generates and displays a random [DirectLinkSlug] as
/// the first one.
class DirectLinkField extends StatefulWidget {
  const DirectLinkField(
    this.links, {
    super.key,
    this.onAdded,
    this.onRemoved,
    this.onMore,
    this.canAddMore = true,
  });

  /// [DirectLink]s to display.
  final Iterable<DirectLink> links;

  /// Callback, called when a new [DirectLinkSlug] is submitted.
  final FutureOr<void> Function(DirectLinkSlug)? onAdded;

  /// Callback, called when a certain [DirectLinkSlug] is removed.
  final FutureOr<void> Function(DirectLinkSlug)? onRemoved;

  /// Callback, called when more [links] can be fetched.
  final FutureOr<void> Function()? onMore;

  /// Indicator whether a new link can be added.
  final bool canAddMore;

  @override
  State<DirectLinkField> createState() => _DirectLinkFieldState();
}

/// State of an [DirectLinkField] maintaining the [_state].
class _DirectLinkFieldState extends State<DirectLinkField> {
  /// Generated [DirectLinkSlug], used in the [_state].
  final String _generated = DirectLinkSlug.generate(10).val;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state;

  /// [ScrollController] controlling the [ListView] for pagination.
  final ScrollController _scrollController = ScrollController();

  /// Indicator whether [CircularProgressIndicator] should be displayed.
  bool _fetching = false;

  @override
  void initState() {
    _state = TextFieldState(
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
      onSubmitted: (_) async => await _submitLink(),
    );

    _scrollController.addListener(_scrollListener);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Widget bottom;

    final Iterable<DirectLink> links = widget.links.where((e) => e.isEnabled);

    if (links.isEmpty) {
      bottom = Column(
        key: const Key('AddLink'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (links.isNotEmpty) const SizedBox(height: 20),

          const SizedBox(height: 8),
          ReactiveTextField(
            state: _state,
            hint: _generated,
            floatingAccent: true,
            label: 'label_add_link'.l10n,
            prefixText: Config.link,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            spellCheck: false,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            key: const Key('CreateLinkButton'),
            title: 'btn_save_and_copy'.l10n,
            onPressed: () async {
              if (_state.text.isEmpty) {
                _state.text = _generated;
              }

              PlatformUtils.copy(text: '${Config.link}${_state.text}');
              MessagePopup.success('label_copied'.l10n);

              await _submitLink();
            },
            leading: SvgIcon(SvgIcons.copy19White),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      bottom = Column(
        key: const Key('None'),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.canAddMore) ...[
            const SizedBox(height: 20),
            FieldButton(
              onPressed: () async {
                await AddLinkView.show(context, onAdded: widget.onAdded);
              },
              trailing: SvgIcon(SvgIcons.addLink),
              child: Text('btn_add_link'.l10n),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (links.isNotEmpty) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: ListView(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                ...links
                    .map((e) {
                      final String url = '${Config.link}${e.slug}';

                      return [
                        ReactiveTextField(
                          state: TextFieldState(
                            text: e.slug.val,
                            editable: false,
                          ),
                          hint: _generated,
                          label: e.createdAt.val.yMd,
                          prefixText: Config.link,
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          spellCheck: false,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Row(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SvgIcon(SvgIcons.linkViews),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${e.visitors}',
                                    style: style.fonts.small.regular.primary,
                                  ),
                                ],
                              ),
                              Spacer(),
                              WidgetButton(
                                onPressed: () {},
                                onPressedWithDetails: (u) {
                                  PlatformUtils.copy(text: url);
                                  MessagePopup.success(
                                    'label_copied'.l10n,
                                    at: u.globalPosition,
                                  );
                                },
                                child: Text(
                                  'btn_copy'.l10n,
                                  style: style.fonts.small.regular.primary,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                width: 1,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: style.colors.secondaryHighlight,
                                ),
                              ),
                              if (PlatformUtils.isMobile) ...[
                                WidgetButton(
                                  onPressed: () async {
                                    await SharePlus.instance.share(
                                      ShareParams(text: url),
                                    );
                                  },
                                  child: Text(
                                    'btn_share'.l10n,
                                    style: style.fonts.small.regular.primary,
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                  width: 1,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: style.colors.secondaryHighlight,
                                  ),
                                ),
                              ],
                              ContextMenuRegion(
                                enablePrimaryTap: true,
                                actions: [
                                  ContextMenuButton(
                                    onPressed: () async {
                                      await QrCodeView.show(context, data: url);
                                    },
                                    label: 'btn_show_qr_code'.l10n,
                                    trailing: SvgIcon(SvgIcons.contextQr),
                                    inverted: SvgIcon(SvgIcons.contextQrWhite),
                                  ),
                                  ContextMenuButton(
                                    onPressed: () async {
                                      final proceed = await MessagePopup.alert(
                                        'label_unlink_link'.l10n,
                                        additional: [
                                          Text(
                                            url,
                                            style: style
                                                .fonts
                                                .normal
                                                .regular
                                                .onBackground,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'label_unlink_link_confirm_description1'
                                                .l10n,
                                            style: style
                                                .fonts
                                                .small
                                                .regular
                                                .secondary,
                                          ),
                                        ],
                                        button: (context) =>
                                            MessagePopup.deleteButton(
                                              context,
                                              label: 'btn_unlink'.l10n,
                                              icon: SvgIcons.buttonUnlink,
                                            ),
                                      );

                                      if (proceed == true) {
                                        await widget.onRemoved?.call(e.slug);
                                      }
                                    },
                                    label: 'btn_unlink'.l10n,
                                    trailing: SvgIcon(SvgIcons.contextUnlink),
                                    inverted: SvgIcon(
                                      SvgIcons.contextUnlinkWhite,
                                    ),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    6,
                                    0,
                                    6,
                                  ),
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: SvgIcon(SvgIcons.more),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ];
                    })
                    .expand((e) => e),
                if (_fetching) ...[
                  CircularProgressIndicator(),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: const LineDivider(''),
          ),
          const SizedBox(height: 4),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AnimatedSizeAndFade(
            sizeDuration: const Duration(milliseconds: 300),
            fadeDuration: const Duration(milliseconds: 300),
            child: bottom,
          ),
        ),
      ],
    );
  }

  /// Submits this [DirectLinkField].
  Future<void> _submitLink() async {
    _state.focus.unfocus();

    DirectLinkSlug? slug;

    if (_state.text.isNotEmpty) {
      try {
        slug = DirectLinkSlug(_state.text);
      } on FormatException {
        _state.error.value = 'err_invalid_symbols_in_link'.l10n;
      }
    }

    if (mounted) {
      setState(() {});
    }

    if (slug == null) {
      return;
    }

    if (_state.error.value == null || _state.resubmitOnError.isTrue) {
      _state.editable.value = false;
      _state.status.value = RxStatus.loading();

      try {
        await widget.onAdded?.call(slug);
        setState(() {});
      } on UpdateDirectLinkException catch (e) {
        _state.error.value = e.toMessage();
      } on UpdateGroupDirectLinkException catch (e) {
        _state.error.value = e.toMessage();
      } catch (e) {
        _state.resubmitOnError.value = true;
        _state.error.value = 'err_data_transfer'.l10n;
        _state.unsubmit();
        rethrow;
      } finally {
        _state.status.value = RxStatus.empty();
        _state.editable.value = true;
      }
    }
  }

  /// Invokes [DirectLinkField.onMore] when [_scrollController] hits the bottom
  /// scrolling window, thus paginating the links.
  Future<void> _scrollListener() async {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.pixels;
      final max = _scrollController.position.maxScrollExtent;

      if (position >= max - 50) {
        if (mounted) {
          setState(() => _fetching = true);
        }

        try {
          await widget.onMore?.call();
        } finally {
          if (mounted) {
            setState(() => _fetching = false);
          }
        }
      }
    }
  }
}
