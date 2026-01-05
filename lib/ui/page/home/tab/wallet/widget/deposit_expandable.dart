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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/country.dart';
import '/domain/model/deposit.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/tab/wallet/select_country/view.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'amount_tile.dart';

/// Fields required for [DepositExpandable] for inputs.
class DepositFields {
  /// Fields for [DepositKind.payPal].
  final PayPalDepositFields paypal = PayPalDepositFields();

  /// Returns an [IsoCode] of the provided [provider].
  Rx<IsoCode?> getCountry(DepositKind provider) {
    return switch (provider) {
      DepositKind.payPal => paypal.country,
    };
  }

  /// Sets the provided [iso] for these fields.
  void applyCountry(IsoCode? iso) {
    paypal.country.value = iso ?? paypal.country.value;
  }
}

/// Fields required for [DepositKind.payPal] deposit.
class PayPalDepositFields {
  PayPalDepositFields();

  /// [IsoCode] of the country to deposit from.
  final Rx<IsoCode?> country = Rx(null);
}

/// Widget for rendering deposit information.
class DepositExpandable extends StatelessWidget {
  const DepositExpandable({
    super.key,
    required this.provider,
    this.expanded = false,
    this.onPressed,
    required this.fields,
  });

  final DepositKind provider;
  final bool expanded;
  final void Function()? onPressed;
  final DepositFields fields;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final title = switch (provider) {
      DepositKind.payPal => 'label_paypal'.l10n,
    };

    final asset = switch (provider) {
      DepositKind.payPal => SvgIcons.payPal,
    };

    final List<Text> texts = [
      ...switch (provider) {
        DepositKind.payPal => [Text('label_instant_top_up'.l10n)],
      },
    ];

    final List<InlineSpan> spans = texts.mapIndexed((i, e) {
      return WidgetSpan(
        child: DefaultTextStyle(
          style: style.fonts.small.regular.secondary,
          overflow: TextOverflow.ellipsis,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [e, if (i < texts.length - 1) Text(', ')],
          ),
        ),
      );
    }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.fromLTRB(10, 1.5, 10, expanded ? 10 : 1.5),
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        borderRadius: style.cardRadius,
        border: expanded ? provider.border : style.cardBorder,
        boxShadow: expanded
            ? [BoxShadow(color: provider.shadow, blurRadius: 4)]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WidgetButton(
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  SvgIcon(asset, width: 50, height: 50),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: style.fonts.medium.regular.onBackground,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease,
                              turns: expanded ? 0.5 : 0,
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: style.colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(children: spans),
                                style: style.fonts.small.regular.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          Flexible(
            child: AnimatedSizeAndFade.showHide(
              fadeDuration: const Duration(milliseconds: 250),
              sizeDuration: const Duration(milliseconds: 250),
              show: expanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: provider.build(context, withLogo: false, fields: fields),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension BuildProviderExtension on DepositKind {
  Widget build(
    BuildContext context, {
    bool withLogo = true,
    DepositFields? fields,
  }) {
    final style = Theme.of(context).style;

    final PayPalDepositFields? paypal = fields?.paypal;

    final country = fields?.getCountry(this);

    Widget countryButton({bool error = false}) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Obx(() {
          return _countryButton(
            context,
            country: country?.value,
            onCode: (code) => country?.value = code,
            available: IsoCodeExtension.available(this),
            error: error,
          );
        }),
      );
    }

    switch (this) {
      case DepositKind.payPal:
        if (paypal == null) {
          return const SizedBox();
        }

        final nominals = [5, 10, 25, 50, 75, 100];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (withLogo) ...[
              const SizedBox(height: 8),
              Container(
                width: 96,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: const SvgImage.asset(
                  'assets/images/paypal.svg',
                  width: 64,
                  height: 32,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Obx(() {
              final available = IsoCodeExtension.available(
                this,
              ).contains(paypal.country.value);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  countryButton(error: !available),
                  if (!available) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                        child: Text(
                          'label_paypal_is_not_available_in_this_country'.l10n,
                          style: style.fonts.small.regular.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 20),
            Flexible(
              child: Obx(() {
                final available = IsoCodeExtension.available(
                  this,
                ).contains(paypal.country.value);

                return Opacity(
                  opacity: available ? 1 : 0.5,
                  child: IgnorePointer(
                    ignoring: !available,
                    child: _responsive(
                      nominals,
                      onPressed: (e) async {
                        if (paypal.country.value == null) {
                          final result = await SelectCountryView.show(
                            context,
                            available: IsoCodeExtension.available(this),
                          );
                          if (result != null) {
                            paypal.country.value = result;
                          }
                        }

                        if (paypal.country.value != null) {
                          if (context.mounted) {
                            // TODO: Display interface for PayPal.
                          }
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        );
    }
  }
}

Widget _responsive(List<int> nominals, {void Function(int)? onPressed}) {
  Widget tile(int i) {
    return WidgetButton(
      onPressed: () => onPressed?.call(nominals[i]),
      child: AmountTile(nominal: nominals[i]),
    );
  }

  return Column(
    children: [
      Row(
        children: [
          Flexible(flex: 100, child: tile(0)),
          const SizedBox(width: 4),
          Flexible(flex: 112, child: tile(1)),
          const SizedBox(width: 4),
          Flexible(flex: 140, child: tile(2)),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Flexible(flex: 160, child: tile(3)),
          const SizedBox(width: 4),
          Flexible(flex: 196, child: tile(4)),
        ],
      ),
      const SizedBox(height: 4),
      tile(5),
    ],
  );
}

Widget _countryButton(
  BuildContext context, {
  IsoCode? country,
  void Function(IsoCode)? onCode,
  Set<IsoCode> available = const {},
  Set<IsoCode> restricted = const {},
  bool error = false,
}) {
  return FieldButton(
    headline: Text('label_country'.l10n),
    onPressed: () async {
      final result = await SelectCountryView.show(
        context,
        available: available,
        restricted: restricted,
      );

      if (result != null) {
        onCode?.call(result);
      }
    },
    error: error,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (country != null) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: ClipOval(
              child: SvgImage.asset(
                'assets/images/country/${country.name.toLowerCase()}.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          country == null
              ? 'label_choose_country'.l10n
              : 'country_${country.name.toLowerCase()}'.l10n,
        ),
      ],
    ),
  );
}

extension on DepositKind {
  Border get border {
    return switch (this) {
      DepositKind.payPal => Border.all(color: Color(0xFF2997D8), width: 0.5),
    };
  }

  Color get shadow {
    return switch (this) {
      DepositKind.payPal => Color(0xFF2997D8).withAlpha((255 * 0.25).round()),
    };
  }
}
