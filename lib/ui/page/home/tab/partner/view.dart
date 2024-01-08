// // Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
// //                       <https://github.com/team113>
// //
// // This program is free software: you can redistribute it and/or modify it under
// // the terms of the GNU Affero General Public License v3.0 as published by the
// // Free Software Foundation, either version 3 of the License, or (at your
// // option) any later version.
// //
// // This program is distributed in the hope that it will be useful, but WITHOUT
// // ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// // FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// // more details.
// //
// // You should have received a copy of the GNU Affero General Public License v3.0
// // along with this program. If not, see
// // <https://www.gnu.org/licenses/agpl-3.0.html>.

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:messenger/domain/model/vacancy.dart';
// import 'package:messenger/l10n/l10n.dart';
// import 'package:messenger/routes.dart';
// import 'package:messenger/themes.dart';
// import 'package:messenger/ui/page/home/widget/app_bar.dart';
// import 'package:messenger/ui/page/home/widget/balance_provider.dart';
// import 'package:messenger/ui/page/home/widget/navigation_bar.dart';
// import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
// import 'package:messenger/ui/page/home/widget/transaction.dart';
// import 'package:messenger/ui/page/home/widget/vacancy.dart';
// import 'package:messenger/ui/widget/animated_button.dart';
// import 'package:messenger/ui/widget/svg/svg.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'controller.dart';

// class PartnerTabView extends StatelessWidget {
//   const PartnerTabView({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final style = Theme.of(context).style;

//     return GetBuilder(
//       init: PartnerTabController(Get.find()),
//       builder: (PartnerTabController c) {
//         return Scaffold(
//           extendBodyBehindAppBar: true,
//           extendBody: true,
//           appBar: CustomAppBar(
//             title: Text('label_work_with_us'.l10n),
//             // title: Text('Balance: \$${c.balance.value / 100}'),
//             leading: [
//               // SizedBox(width: 40),
//               AnimatedButton(
//                 decorator: (child) => Container(
//                   padding: const EdgeInsets.only(left: 18),
//                   height: double.infinity,
//                   child: Center(child: child),
//                 ),
//                 onPressed: () {},
//                 child: Icon(
//                   Icons.handshake_outlined,
//                   color: style.colors.primary,
//                 ),
//               ),
//             ],
//             actions: [
//               AnimatedButton(
//                 decorator: (child) => Container(
//                   padding: const EdgeInsets.only(right: 18),
//                   height: double.infinity,
//                   child: Center(child: child),
//                 ),
//                 onPressed: () {},
//                 child: Icon(
//                   Icons.more_vert,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             ],
//           ),
//           body: Obx(() {
//             if (c.withdrawing.value) {
//               Widget button({required String title, required IconData icon}) {
//                 return BalanceProviderWidget(
//                   title: title,
//                   leading: [Icon(icon)],
//                   onTap: () {},
//                 );
//               }

//               return PaddedScrollView(
//                 child: SafeScrollbar(
//                   child: ListView(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     children: [
//                       const SizedBox(height: CustomAppBar.height),
//                       button(
//                         title: 'SWIFT',
//                         icon: Icons.account_balance,
//                       ),
//                       button(
//                         title: 'SEPA',
//                         icon: Icons.account_balance,
//                       ),
//                       button(title: 'PayPal', icon: Icons.paypal),
//                       const SizedBox(height: CustomNavigationBar.height),
//                     ],
//                   ),
//                 ),
//               );
//             }

//             return PaddedScrollView(
//               child: SafeScrollbar(
//                 child: ListView(
//                   children: [
//                     VacancyWidget(
//                       'Баланс: \$9999.99',
//                       trailing: [
//                         Column(
//                           children: [
//                             SvgImage.asset(
//                               'assets/icons/external_link_blue.svg',
//                               height: 16,
//                               width: 16,
//                             ),
//                             const SizedBox(height: 21),
//                           ],
//                         ),
//                       ],
//                       subtitle: [
//                         // const SizedBox(height: 4),
//                         Text(
//                           // '\$${c.balance.value / 100}',
//                           'Вывести деньги',
//                           style: style.fonts.small.regular.secondary,
//                         )
//                       ],
//                       onPressed: () async {
//                         await launchUrl(
//                           Uri.https('google.com', 'search', {'q': 'withdraw'}),
//                         );
//                       },
//                     ),
//                     VacancyWidget(
//                       'Транзакции',
//                       subtitle: [
//                         Text.rich(
//                           TextSpan(
//                             children: [
//                               TextSpan(
//                                 text: 'Новых транзакций: ',
//                                 style: style.fonts.small.regular.onBackground
//                                     .copyWith(color: style.colors.secondary),
//                               ),
//                               TextSpan(
//                                 text: '4',
//                                 style: style.fonts.small.regular.onBackground
//                                     .copyWith(color: style.colors.danger),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                       trailing: [
//                         Column(
//                           children: [
//                             SvgImage.asset(
//                               'assets/icons/external_link_blue.svg',
//                               height: 16,
//                               width: 16,
//                             ),
//                             const SizedBox(height: 21),
//                           ],
//                         ),
//                       ],
//                       onPressed: () async {
//                         await launchUrl(
//                           Uri.https(
//                             'google.com',
//                             'search',
//                             {'q': 'transactions'},
//                           ),
//                         );
//                       },
//                     ),
//                     const Padding(
//                       padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
//                       child: Center(child: Text('Работайте с нами')),
//                     ),
//                     ...Vacancies.all.map((e) {
//                       return Obx(() {
//                         final bool selected = router.routes.firstWhereOrNull(
//                                 (m) => m == '${Routes.vacancy}/${e.id}') !=
//                             null;

//                         return VacancyWidget(
//                           e.title,
//                           subtitle: [
//                             if (e.subtitle != null) ...[
//                               Text(e.subtitle!),
//                             ],
//                           ],
//                           selected: selected,
//                           onPressed: () => router.vacancy(e.id),
//                         );
//                       });
//                     }),
//                   ],
//                 ),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

// class PaddedScrollView extends StatelessWidget {
//   const PaddedScrollView({
//     super.key,
//     required this.child,
//   });

//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return child;

//     return CustomScrollView(
//       slivers: [
//         SliverPadding(
//           padding: const EdgeInsets.only(
//             top: CustomAppBar.height,
//             bottom: CustomNavigationBar.height + 5,
//             left: 10,
//             right: 10,
//           ),
//           sliver: SliverToBoxAdapter(child: child),
//         )
//       ],
//     );
//   }
// }
