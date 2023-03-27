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

import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

import '/domain/model/image_gallery_item.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';
import 'gallery_popup.dart';

/// Carousel gallery view of [items].
class CarouselGallery extends StatefulWidget {
  const CarouselGallery({
    Key? key,
    this.items,
    this.index = 0,
    this.onChanged,
    this.overlay = const [],
    this.onCarouselController,
  }) : super(key: key);

  /// Gallery items to display in the carousel.
  ///
  /// Displays logo on `null`.
  final List<ImageGalleryItem>? items;

  /// Callback, called when carousel's index has changed.
  final Function(int)? onChanged;

  /// Initial index of [items] to display in the carousel.
  final int index;

  /// List of widgets to display above this [CarouselGallery].
  final List<Widget> overlay;

  /// Callback, called when a [CarouselController] is initialized.
  final void Function(CarouselController)? onCarouselController;

  @override
  State<CarouselGallery> createState() => _CarouselGalleryState();
}

/// State of [CarouselGallery] used to change the carousel with [_controller].
class _CarouselGalleryState extends State<CarouselGallery> {
  /// Controller used to change carousel's page.
  final CarouselController _controller = CarouselController();

  /// [GlobalKey] of the [CarouselGallery] to animate [GalleryPopup] from.
  final GlobalKey _galleryKey = GlobalKey();

  @override
  void didUpdateWidget(covariant CarouselGallery oldWidget) {
    if (mounted) {
      setState(() {});
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    widget.onCarouselController?.call(_controller);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.items?.isNotEmpty == true
          ? () {
              GalleryPopup.show(
                context: context,
                gallery: GalleryPopup(
                  initial: widget.index,
                  initialKey: _galleryKey,
                  children: (widget.items ?? [])
                      .map(
                        (e) => GalleryItem.image(
                          e.original.url,
                          checksum: e.original.checksum,
                          'IMG_${e.addedAt.microsecondsSinceEpoch}.${e.id}',
                          size: e.original.size,
                        ),
                      )
                      .toList(),
                  onPageChanged: (i) => _controller.jumpToPage(i),
                ),
              );
            }
          : null,
      child: Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.center,
        children: [
          widget.items?.isNotEmpty == true
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    key: ValueKey(widget.index),
                    child: RetryImage(
                      widget.items![widget.index].original.url,
                      checksum: widget.items![widget.index].original.checksum,
                      fit: BoxFit.cover,
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                )
              : Container(
                  color: Theme.of(context).extension<Style>()!.onPrimary),
          ScrollConfiguration(
            behavior: _MyCustomScrollBehavior(),
            child: CarouselSlider(
              key: _galleryKey,
              carouselController: _controller,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1,
                enableInfiniteScroll: false,
                onPageChanged: (i, __) => widget.onChanged?.call(i),
              ),
              items: widget.items?.isNotEmpty != true
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child:
                            SvgLoader.asset('assets/images/logo/logo0000.svg'),
                      ),
                    ]
                  : widget.items!
                      .map(
                        (e) => RetryImage(
                          e.original.url,
                          checksum: e.original.checksum,
                          height: double.infinity,
                          fit: BoxFit.fitHeight,
                        ),
                      )
                      .toList(),
            ),
          ),
          if (widget.items?.isNotEmpty == true) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.items!
                      .mapIndexed(
                        (i, e) => InkWell(
                          onTap: () => _controller.jumpToPage(i),
                          child: Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 1.0,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(blurRadius: 1)],
                              color: widget.index == i
                                  ? Theme.of(context)
                                      .extension<Style>()!
                                      .onPrimary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.items == null || widget.index == 0
                      ? null
                      : () => _controller.jumpToPage(widget.index - 1),
                  child: SizedBox(
                    width:
                        (MediaQuery.of(context).size.width / 8).clamp(50, 100),
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.items == null ||
                          widget.index + 1 == widget.items?.length
                      ? null
                      : () => _controller.jumpToPage(widget.index + 1),
                  child: SizedBox(
                    width:
                        (MediaQuery.of(context).size.width / 8).clamp(50, 100),
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ],
          ...widget.overlay,
        ],
      ),
    );
  }
}

/// [ScrollBehavior] to enable scroll of [CarouselGallery] with the mouse.
class _MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}
