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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/ui/widget/selector/controller.dart';
import '/util/platform_utils.dart';

/// Class which is responsible for showing popup of items select.
abstract class Selector {
  static Future<T?> show<T>(
    BuildContext context,
    GlobalKey? key,
    List<String> items, {
    String? initialValue,
    List<String>? trails,
    Function(int)? onSelect,
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

              Widget _button(int i) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    child: InkWell(
                      hoverColor: const Color(0x3363B4FF),
                      highlightColor: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelect?.call(i),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(
                                items[i],
                                style: thin?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              if (trails != null) const Spacer(),
                              if (trails != null)
                                Text(
                                  trails[i],
                                  style: thin?.copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFF000000),
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
                                    children: List.generate(items.length,
                                        (index) => _button(index)),
                                  ),
                                ),
                                if (items.length >= 8)
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
                                              Color(0xFFFFFFFF),
                                              Color(0x00FFFFFF),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (items.length >= 8)
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
                                              Color(0x00FFFFFF),
                                              Color(0xFFFFFFFF),
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
          return GetBuilder(
            init: SelectorController(
              items.indexOf(initialValue ?? items.first),
              onSelect,
            ),
            builder: (SelectorController c) {
              return Container(
                height: min(items.length * (65), 330),
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
                                  scrollController: FixedExtentScrollController(
                                      initialItem: c.selected.value),
                                  magnification: 1,
                                  squeeze: 1,
                                  looping: true,
                                  diameterRatio: 100,
                                  useMagnifier: false,
                                  itemExtent: 38,
                                  selectionOverlay: Container(
                                    margin: const EdgeInsetsDirectional.only(
                                        start: 8, end: 8),
                                    decoration: const BoxDecoration(
                                        color: Color(0x3363B4FF)),
                                  ),
                                  onSelectedItemChanged: (int i) {
                                    HapticFeedback.selectionClick();
                                    c.selected.value = i;
                                  },
                                  children: List.generate(
                                      items.length,
                                      (index) => Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      46, 0, 29, 0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    items[index],
                                                    style: thin?.copyWith(
                                                      fontSize: 15,
                                                      color: const Color(
                                                          0xFF000000),
                                                    ),
                                                  ),
                                                  if (trails != null)
                                                    const Spacer(),
                                                  if (trails != null)
                                                    Text(
                                                      trails[index],
                                                      style: thin?.copyWith(
                                                        fontSize: 15,
                                                        color: const Color(
                                                            0xFF000000),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ))),
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
                                        Color(0xFFFFFFFF),
                                        Color(0x00FFFFFF),
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
                                        Color(0x00FFFFFF),
                                        Color(0xFFFFFFFF),
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
        },
      );
    }
  }
}
