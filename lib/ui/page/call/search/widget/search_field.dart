import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/view.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/animated_switcher.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';

class SearchField extends StatelessWidget {
  const SearchField(
    this.state, {
    super.key,
    this.onChanged,
    this.hint,
  });

  final TextFieldState state;
  final void Function()? onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox(
      height: CustomAppBar.height,
      child: Obx(() {
        return CustomAppBar(
          margin: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          top: false,
          border: state.isFocused.value || !state.isEmpty.value
              ? Border.all(color: style.colors.primary, width: 2)
              : null,
          title: Theme(
            data: MessageFieldView.theme(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: ReactiveTextField(
                  key: const Key('SearchField'),
                  state: state,
                  hint: hint ?? 'label_search'.l10n,
                  maxLines: 1,
                  filled: false,
                  dense: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  style: style.fonts.medium.regular.onBackground,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          leading: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 6),
              width: 46,
              height: double.infinity,
              child: const Center(child: SvgIcon(SvgIcons.search)),
            ),
          ],
          actions: [
            Obx(() {
              final Widget child;

              if (state.isEmpty.value) {
                child = const SizedBox();
              } else {
                child = AnimatedButton(
                  key: const Key('ClearButton'),
                  onPressed: state.clear,
                  child: Container(
                    padding: const EdgeInsets.only(right: 20, left: 6),
                    width: 46,
                    height: double.infinity,
                    child: const Center(child: SvgIcon(SvgIcons.clearSearch)),
                  ),
                );
              }

              return SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: child,
              );
            }),
          ],
        );
      }),
    );
  }
}
