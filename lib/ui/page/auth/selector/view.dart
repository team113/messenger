import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/_l10n.dart';
import 'package:messenger/util/platform_utils.dart';

abstract class Selector {
  static Future<T?> show<T>(
    BuildContext context,
    GlobalKey? key,
    Map<String, String> entries, {
    String? initialValue,
    VoidCallback? onSelect,
  }) {
    if (!context.isMobile) {
      final TextStyle? thin =
          context.textTheme.caption?.copyWith(color: Colors.black);

      Offset offset = Offset.zero;
      final keyContext = key?.currentContext;
      if (keyContext != null) {
        final box = keyContext.findRenderObject() as RenderBox?;
        offset = box?.localToGlobal(Offset.zero) ?? offset;
        offset = Offset(
          offset.dx + (box?.size.width ?? 0) / 2,
          offset.dy,
        );
      }

      return showDialog(
          context: context,
          barrierColor: kCupertinoModalBarrierColor,
          builder: (context) {
            return LayoutBuilder(builder: (context, constraints) {
              final keyContext = key?.currentContext;
              if (keyContext != null) {
                final box = keyContext.findRenderObject() as RenderBox?;
                offset = box?.localToGlobal(Offset.zero) ?? offset;
                offset = Offset(
                  offset.dx + (box?.size.width ?? 0) / 2,
                  offset.dy,
                );
              }

              Widget _button(MapEntry<String, String> e) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: InkWell(
                      hoverColor: const Color(0x3363B4FF),
                      highlightColor: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        L10n.chosen = e.key;
                        Get.updateLocale(L10n.locales[L10n.chosen]!);
                      },
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(
                                e.value,
                                style: thin?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                L10n.locales[e.key]!.languageCode.toUpperCase(),
                                style: thin?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  Positioned(
                    left: offset.dx - 260 / 2,
                    bottom: MediaQuery.of(context).size.height - offset.dy,
                    child: Listener(
                      onPointerUp: (d) {
                        Navigator.of(context).pop();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 260,
                            constraints: const BoxConstraints(maxHeight: 280),
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              10,
                              0,
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  child: Column(
                                    children: L10n.languages.entries
                                        .map(_button)
                                        .toList(),
                                  ),
                                ),
                                if (L10n.languages.length >= 8)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        height: 15,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black,
                                              Colors.white,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (L10n.languages.length >= 8)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 15,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black,
                                              Colors.white,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            });
          });
    } else {
      final TextStyle? thin = context.textTheme.caption
          ?.copyWith(color: Theme.of(context).colorScheme.primary);

      return showModalBottomSheet(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        builder: (context) {
          return Container(
            height: min(L10n.languages.length * (65), 330),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Stack(
                        children: [
                          CupertinoPicker(
                            magnification: 1,
                            squeeze: 1,
                            looping: true,
                            diameterRatio: 100,
                            useMagnifier: false,
                            itemExtent: 38,
                            selectionOverlay: Container(
                              margin: const EdgeInsetsDirectional.only(
                                  start: 8, end: 8),
                              decoration:
                                  const BoxDecoration(color: Color(0x3363B4FF)),
                            ),
                            onSelectedItemChanged: (int i) {
                              // if (!PlatformUtils.isIOS) {
                              //   HapticFeedback.selectionClick();
                              // }
                              // c.selectedLanguage.value = i;
                            },
                            children: L10n.languages.entries.map((e) {
                              return Center(
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(46, 0, 29, 0),
                                  child: Row(
                                    children: [
                                      Text(
                                        e.value,
                                        style: thin?.copyWith(
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        L10n.locales[e.key]!.languageCode
                                            .toUpperCase(),
                                        style: thin?.copyWith(
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: 15,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black,
                                    Colors.white,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 15,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black,
                                    Colors.white,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
