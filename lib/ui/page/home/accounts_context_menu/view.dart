import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../themes.dart';
import '../../../widget/modal_popup.dart';
import '../../../widget/primary_button.dart';
import '../../../widget/svg/svg.dart';

import '../../login/controller.dart';
import '../../login/view.dart';

class AccountsContextMenuView extends StatefulWidget {
  const AccountsContextMenuView({super.key, required this.child});

  /// widget that viewed in layout
  final Widget child;

  @override
  State<AccountsContextMenuView> createState() =>
      _AccountsContextMenuViewState();
}

class _AccountsContextMenuViewState extends State<AccountsContextMenuView> {
  late final OverlayPortalController _controller;

  @override
  initState() {
    _controller = OverlayPortalController();
    super.initState();
  }

  void _show() {
    _controller.show();
  }

  final GlobalKey _overlayKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      key: _overlayKey,
      controller: _controller,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        onLongPress: _show,
        onSecondaryTap: _show,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final render = _overlayKey.currentContext?.findRenderObject() as RenderBox;

    final holeCenter = render.localToGlobal(Offset.zero);
    final holeSize = render.size;
    var style = Theme.of(context).style;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _controller.hide();
      },
      child: Stack(
        children: [
          ClipPath(
            clipper: _HoleClipper(
              center: holeCenter + Offset(17, 17),
              radius: 20,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.1,
                ), // Semi-transparent overlay
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height - holeCenter.dy + 20,
            right:
                MediaQuery.sizeOf(context).width -
                holeCenter.dx -
                holeSize.width -
                2,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.min(MediaQuery.of(context).size.width, 320),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: style.colors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: PrimaryButton(
                          onPressed: () async {
                            await LoginView.show(
                              context,
                              initial: LoginViewStage.signUpOrSignIn,
                            );
                          },
                          leading: SvgIcon(SvgIcons.logoutWhite),
                          title: 'btn_add_account'.l10n,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: holeCenter.dx,
            top: holeCenter.dy,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  /// hole size
  final double radius;

  final Offset center;

  _HoleClipper({required this.radius, required this.center});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    // Define the outer rectangle (the blurred area)
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    path.addOval(
      Rect.fromCircle(
        center: Offset(320, 600),
        radius: 50,
        // Radius.circular(100),
      ),
    );

    // Combine the paths, subtracting the hole from the outer rectangle
    return Path.combine(
      PathOperation.difference,
      path,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
