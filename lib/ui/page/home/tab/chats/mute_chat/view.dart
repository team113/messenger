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

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import 'controller.dart';

/// View of the chat muting dialog.
class MuteChatView extends StatelessWidget {
  const MuteChatView(this.id, {Key? key}) : super(key: key);

  /// [ChatId] of this [Chat] overlay.
  final ChatId id;

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);
    TextStyle font13 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(
            color: Colors.black, fontSize: 13);

    Widget divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: const Color(0x99000000),
      height: 1,
      width: double.infinity,
    );

    return MediaQuery.removeViewInsets(
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      context: context,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 500,
          ),
          child: Material(
            color: const Color(0xFFFFFFFF),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            type: MaterialType.card,
            child: GetBuilder(
              init: MuteChatController(
                id,
                Navigator.of(context).pop,
                Get.find(),
              ),
              builder: (MuteChatController c) => Obx(
                () => c.status.value.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                const SizedBox(height: 5),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 5, 0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'label_mute_chat_for'.l10n,
                                        style: font17,
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                        onPressed: Navigator.of(context).pop,
                                        icon: const Icon(Icons.close, size: 20),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                divider
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemBuilder: (BuildContext context, int index) {
                                return Obx(
                                  () => ListTile(
                                    key: c.muteDateTimes[index].key,
                                    onTap: () => c.selectedMute.value = index,
                                    leading: Radio(
                                      value: index,
                                      onChanged: <int>(val) =>
                                          c.selectedMute.value = val,
                                      groupValue: c.selectedMute.value,
                                    ),
                                    title: Text(c.muteDateTimes[index].label),
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const Divider(),
                              itemCount: c.muteDateTimes.length,
                            ),
                          ),
                          Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                divider,
                                const SizedBox(height: 5),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 0, 5, 0),
                                  child: Row(
                                    children: [
                                      c.status.value.isError
                                          ? Expanded(
                                              child: Center(
                                                child: Text(
                                                  c.status.value.errorMessage ??
                                                      'err_unknown'.l10n,
                                                  style: font13.copyWith(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const Spacer(),
                                      TextButton(
                                        key: const Key('MuteButton'),
                                        onPressed: c.selectedMute.value == null
                                            ? null
                                            : c.mute,
                                        child: Text(
                                          'btn_mute'.l10n,
                                          style: c.selectedMute.value == null
                                              ? font17.copyWith(
                                                  color: Colors.grey,
                                                )
                                              : font17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5)
                              ],
                            ),
                          )
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
