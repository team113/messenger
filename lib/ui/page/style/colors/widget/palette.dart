// Colors tab view of the [Routes.style] page.
import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

import 'color.dart';
import 'custom_switcher.dart';

class PaletteWidget extends StatefulWidget {
  const PaletteWidget({super.key});

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
}

/// State of a [PaletteWidget] used to keep the [isDarkMode] indicator.
class _PaletteWidgetState extends State<PaletteWidget> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      width: MediaQuery.sizeOf(context).width,
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.light_mode, color: style.colors.warningColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomSwitcher(
                    onChanged: (b) => setState(() => isDarkMode = b),
                  ),
                ),
                const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomColor(
                isDarkMode,
                style.colors.onBackground,
                title: 'onBackground',
                subtitle: 'Цвет основного текста приложения.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackground,
                title: 'secondaryBackground',
                subtitle: 'Фон текста и обводки.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackgroundLight,
                title: 'secondaryBackgroundLight',
                subtitle: 'Цвет заднего фона звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackgroundLightest,
                title: 'secondaryBackground\nLightest',
                subtitle: 'Цвет заднего фона аватара, кнопок звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondary,
                title: 'secondary',
                subtitle: 'Цвет текста и обводок.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlightDarkest,
                title: 'secondaryHighlightDarkest',
                subtitle: 'Цвет надписей и иконок над задним фоном звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlightDark,
                title: 'secondaryHighlightDark',
                subtitle: 'Цвет кнопок навигационной панели.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlight,
                title: 'secondaryHighlight',
                subtitle: 'Цвет колеса загрузки.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.background,
                title: 'background',
                subtitle: 'Общий фон.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryOpacity87,
                title: 'secondaryOpacity87',
                subtitle:
                    'Цвет поднятой руки и выключенного микрофона в звонке.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity50,
                title: 'onBackgroundOpacity50',
                subtitle: 'Цвет фона прикрепленного файла.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity40,
                title: 'onBackgroundOpacity40',
                subtitle: 'Цвет нижнего бара в чате.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity27,
                title: 'onBackgroundOpacity27',
                subtitle: 'Цвет тени плавающей панели.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity20,
                title: 'onBackgroundOpacity20',
                subtitle: 'Цвет панели с кнопками в звонке.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity13,
                title: 'onBackgroundOpacity13',
                subtitle: 'Цвет кнопки проигрывания видео.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity7,
                title: 'onBackgroundOpacity7',
                subtitle: 'Цвет разделителей в приложении.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity2,
                title: 'onBackgroundOpacity2',
                subtitle:
                    'Цвет текста "Подключение", "Звоним" и т.д. в звонке.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimary,
                title: 'onPrimary',
                subtitle:
                    'Цвет, использующийся в левой части страницы профиля.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity95,
                title: 'onPrimaryOpacity95',
                subtitle: 'Цвет сообщения, которое было получено.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity50,
                title: 'onPrimaryOpacity50',
                subtitle:
                    'Цвет обводки кнопок принятия звонка с аудио и видео.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity25,
                title: 'onPrimaryOpacity25',
                subtitle: 'Цвет тени пересланных сообщений.',
              ),
              CustomColor(
                isDarkMode,

                style.colors.onPrimaryOpacity7,
                title: 'onPrimaryOpacity7',
                subtitle: 'Дополнительный цвет бэкграунда звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliary,
                title: 'backgroundAuxiliary',
                subtitle: 'Цвет активного звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLight,
                title: 'backgroundAuxiliaryLight',
                subtitle: 'Цвет фона профиля.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity88,
                title: 'onSecondaryOpacity88',
                subtitle: 'Цвет верхней перетаскиваемой строки заголовка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondary,
                title: 'onSecondary',
                subtitle: 'Цвет кнопок в звонке.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity60,
                title: 'onSecondaryOpacity60',
                subtitle:
                    'Дополнительный цвет верхней перетаскиваемой строки заголовка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity50,
                title: 'onSecondaryOpacity50',
                subtitle: 'Цвет кнопок в галерее.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity20,
                title: 'onSecondaryOpacity20',
                subtitle: 'Цвет мобильного селектора.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlight,
                title: 'primaryHighlight',
                subtitle: 'Цвет выпадающего меню.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primary,
                title: 'primary',
                subtitle: 'Цвет кнопок и ссылок.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlightShiniest,
                title: 'primaryHighlightShiniest',
                subtitle: 'Цвет прочитанного сообщения.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlightLightest,
                title: 'primaryHighlightLightest',
                subtitle: 'Цвет обводки прочитанного сообщения.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLighter,
                title: 'backgroundAuxiliaryLighter',
                subtitle: 'Цвет отмены загрузки.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLightest,
                title: 'backgroundAuxiliaryLightest',
                subtitle:
                    'Цвет фона участников группы и непрочитанного сообщения.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.acceptAuxiliaryColor,
                title: 'acceptAuxiliaryColor',
                subtitle: 'Цвет панели пользователя.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.acceptColor,
                title: 'acceptColor',
                subtitle: 'Цвет кнопки принятия звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.dangerColor,
                title: 'dangerColor',
                subtitle: 'Цвет, предупредающий о чем-либо.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.declineColor,
                title: 'declineColor',
                subtitle: 'Цвет кнопки завершения звонка.',
              ),
              CustomColor(
                isDarkMode,
                style.colors.warningColor,
                title: 'warningColor',
                subtitle: 'Цвет статуса "Не беспокоить".',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
