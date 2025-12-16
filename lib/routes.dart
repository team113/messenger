// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config.dart';
import 'domain/model/chat.dart';
import 'domain/model/chat_item.dart';
import 'domain/model/user.dart';
import 'domain/repository/blocklist.dart';
import 'domain/repository/call.dart';
import 'domain/repository/chat.dart';
import 'domain/repository/contact.dart';
import 'domain/repository/my_user.dart';
import 'domain/repository/partner.dart';
import 'domain/repository/session.dart';
import 'domain/repository/settings.dart';
import 'domain/repository/user.dart';
import 'domain/repository/wallet.dart';
import 'domain/service/auth.dart';
import 'domain/service/blocklist.dart';
import 'domain/service/call.dart';
import 'domain/service/chat.dart';
import 'domain/service/contact.dart';
import 'domain/service/my_user.dart';
import 'domain/service/notification.dart';
import 'domain/service/partner.dart';
import 'domain/service/session.dart';
import 'domain/service/user.dart';
import 'domain/service/wallet.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'main.dart' show handlePushNotification;
import 'provider/drift/background.dart';
import 'provider/drift/blocklist.dart';
import 'provider/drift/call_credentials.dart';
import 'provider/drift/call_rect.dart';
import 'provider/drift/chat.dart';
import 'provider/drift/chat_credentials.dart';
import 'provider/drift/chat_item.dart';
import 'provider/drift/chat_member.dart';
import 'provider/drift/credentials.dart';
import 'provider/drift/draft.dart';
import 'provider/drift/drift.dart';
import 'provider/drift/monolog.dart';
import 'provider/drift/my_user.dart';
import 'provider/drift/session.dart';
import 'provider/drift/settings.dart';
import 'provider/drift/user.dart';
import 'provider/drift/version.dart';
import 'provider/gql/graphql.dart';
import 'store/blocklist.dart';
import 'store/call.dart';
import 'store/chat.dart';
import 'store/contact.dart';
import 'store/my_user.dart';
import 'store/partner.dart';
import 'store/session.dart';
import 'store/settings.dart';
import 'store/user.dart';
import 'store/wallet.dart';
import 'themes.dart';
import 'ui/page/auth/view.dart';
import 'ui/page/chat_direct_link/view.dart';
import 'ui/page/erase/view.dart';
import 'ui/page/home/view.dart';
import 'ui/page/popup_call/view.dart';
import 'ui/page/popup_gallery/view.dart';
import 'ui/page/style/view.dart';
import 'ui/page/unknown/view.dart';
import 'ui/widget/lifecycle_observer.dart';
import 'ui/widget/progress_indicator.dart';
import 'ui/worker/call.dart';
import 'ui/worker/chat.dart';
import 'ui/worker/my_user.dart';
import 'ui/worker/settings.dart';
import 'util/get.dart';
import 'util/log.dart';
import 'util/platform_utils.dart';
import 'util/scoped_dependencies.dart';
import 'util/web/web_utils.dart';

/// Application's global router state.
late RouterState router;

/// Application routes names.
class Routes {
  static const affiliate = '/partner/affiliate';
  static const auth = '/';
  static const call = '/call';
  static const chatDirectLink = '/~';
  static const chatInfo = '/info';
  static const chats = '/chats';
  static const contacts = '/contacts';
  static const deposit = '/wallet/deposit';
  static const erase = '/erase';
  static const gallery = '/gallery';
  static const home = '/';
  static const me = '/me';
  static const menu = '/menu';
  static const partner = '/partner';
  static const partnerTransactions = '/partner/transactions';
  static const prices = '/partner/prices';
  static const promotion = '/partner/promotion';
  static const statistics = '/partner/statistics';
  static const user = '/user';
  static const wallet = '/wallet';
  static const walletTransactions = '/wallet/transactions';
  static const withdraw = '/partner/withdraw';

  // TODO: Dirty hack used to reinitialize the dependencies when changing
  //       accounts, should remove it.
  static const nowhere = '/nowhere';

  // E2E tests related page, should not be used in non-test environment.
  static const restart = '/restart';

  // TODO: Styles page related, should be removed at some point.
  static const style = '/dev/style';
}

/// List of [Routes.home] page tabs.
enum HomeTab { wallet, partner, chats, menu }

/// List of [Routes.me] page sections.
enum ProfileTab {
  public,
  signing,
  link,
  media,
  welcome,
  notifications,
  storage,
  confidential,
  interface,
  devices,
  download,
  legal,
  danger,
  logout,
}

/// Navigation mode.
enum RouteAs {
  /// Pushes to the [router]'s routes stack.
  push,

  /// Clears all routes and pushes to the [router]'s routes stack.
  replace,

  /// Pops last route and pushes to the [router]'s routes stack.
  insteadOfLast,
}

/// Application's router state.
///
/// Any change requires [notifyListeners] to be invoked in order for the router
/// to update its state.
class RouterState extends ChangeNotifier {
  RouterState(this._auth, {RouteInformation? initial}) {
    delegate = AppRouterDelegate(this);
    parser = AppRouteInformationParser();

    if (initial != null) {
      provider = PlatformRouteInformationProvider(
        initialRouteInformation: initial,
      );
    }
  }

  /// Application's [RouterDelegate].
  late final RouterDelegate<Object> delegate;

  /// Application's [RouteInformationParser].
  late final RouteInformationParser<Object> parser;

  /// Application's optional [RouteInformationProvider].
  ///
  /// [PlatformRouteInformationProvider] is used on null.
  RouteInformationProvider? provider;

  /// This router's global [BuildContext] to use in contextless scenarios.
  ///
  /// Note that this [BuildContext] doesn't contain a [Overlay] widget. If you
  /// need one, use the [overlay].
  BuildContext? context;

  /// This router's global [OverlayState] to use in contextless scenarios.
  OverlayState? overlay;

  /// Reactive [AppLifecycleState].
  final Rx<AppLifecycleState> lifecycle = Rx<AppLifecycleState>(
    AppLifecycleState.detached,
  );

  /// Reactive title prefix of the current browser tab.
  final RxnString prefix = RxnString(null);

  /// Routes history stack.
  final RxList<String> routes = RxList([]);

  /// Indicator whether [HomeView] page navigation should be visible.
  final RxBool navigation = RxBool(true);

  /// Builder building the [NavigationBar] on the [HomeView], if any.
  final Rx<Widget Function(BuildContext)?> navigator = Rx(null);

  /// [ModalRoute]s obscuring any [Navigator] being built.
  final RxList<ModalRoute> obscuring = RxList();

  /// Dynamic arguments of the [route].
  Map<String, dynamic>? arguments;

  /// Current [Routes.me] page section.
  final Rx<ProfileTab?> profileSection = Rx(null);

  /// Auth service used to determine the auth status.
  final AuthService _auth;

  /// Current [Routes.home] tab.
  HomeTab _tab = HomeTab.chats;

  /// Current route (last in the [routes] history).
  String get route => routes.lastOrNull == null ? Routes.home : routes.last;

  /// Current [Routes.home] tab.
  HomeTab get tab => _tab;

  /// Changes selected [tab] to the provided one.
  set tab(HomeTab to) {
    if (_tab != to) {
      _tab = to;
      notifyListeners();
    }
  }

  /// Sets the current [route] to [to] if guard allows it.
  ///
  /// Clears the whole [routes] stack.
  void go(String to) {
    Log.debug('go($to)', '$runtimeType');

    arguments = null;

    routes.value = [_guarded(to)];
    notifyListeners();
  }

  /// Pushes [to] to the [routes] stack.
  void push(String to) {
    Log.debug('push($to)', '$runtimeType');

    arguments = null;
    int pageIndex = routes.indexWhere((e) => e == to);
    if (pageIndex != -1) {
      while (routes.length - 1 > pageIndex) {
        pop();
      }
    } else {
      routes.add(_guarded(to));
    }

    notifyListeners();
  }

  /// Removes the last route in the [routes] history.
  ///
  /// If [routes] contain only one record, then removes segments of that record
  /// by `/` if any, otherwise replaces it with [Routes.home].
  void pop([String? page]) {
    Log.debug('pop($page)', '$runtimeType');

    if (routes.isNotEmpty) {
      if (page != null && !routes.contains(page)) {
        return;
      }

      if (routes.length == 1) {
        final String split = routes.last.split('/').last;
        String last = routes.last.replaceFirst('/$split', '');
        if (last == '' ||
            last == Routes.contacts ||
            last == Routes.chats ||
            last == Routes.menu ||
            last == Routes.user ||
            last == Routes.wallet ||
            last == Routes.partner) {
          last = Routes.home;
        }

        routes.last = last;
      } else {
        if (page != null) {
          routes.remove(page);
        } else {
          routes.removeLast();
        }

        if (routes.isEmpty) {
          routes.add(Routes.home);
        }
      }

      notifyListeners();
    }
  }

  /// Removes the [routes] satisfying the provided [predicate].
  void removeWhere(bool Function(String element) predicate) {
    for (String e in routes.toList(growable: false)) {
      if (predicate(e)) {
        routes.remove(route);
      }
    }

    notifyListeners();
  }

  /// Replaces the provided [from] with the specified [to] in the [routes].
  void replace(String from, String to) {
    Log.debug('replace($from, $to)', '$runtimeType');

    routes.value = routes.map((e) => e.replaceAll(from, to)).toList();
  }

  /// Returns guarded route based on [_auth] status.
  ///
  /// - [Routes.home] is allowed always.
  /// - Any other page is allowed to visit only on success auth status.
  String _guarded(String to) {
    if (to.startsWith(Routes.wallet) ||
        to.startsWith(Routes.erase) ||
        to.startsWith(Routes.partner) ||
        to.startsWith(Routes.chatDirectLink)) {
      return to;
    }

    switch (to) {
      case Routes.home:
      case Routes.style:
        return to;
      default:
        if (_auth.status.value.isSuccess) {
          return to;
        } else {
          return route;
        }
    }
  }
}

/// Application's route configuration used to determine the current router state
/// to parse from/to [RouteInformation].
class RouteConfiguration {
  RouteConfiguration(
    this.route, {
    this.tab,
    this.authorized = true,
    this.arguments = const {},
  });

  /// Current route as a [String] value.
  ///
  /// e.g. `/auth`, `/chat/0`, etc.
  final String route;

  /// Current [Routes.home] [HomeTab] value. Non null if current [route] is
  /// [Routes.home].
  final HomeTab? tab;

  /// Whether current user is logged in or not.
  bool authorized;

  /// Query parameters of the [route].
  Map<String, dynamic> arguments;
}

/// Parses the [RouteConfiguration] from/to [RouteInformation].
class AppRouteInformationParser
    extends RouteInformationParser<RouteConfiguration> {
  @override
  SynchronousFuture<RouteConfiguration> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    String route = routeInformation.uri.toString();
    HomeTab? tab;

    if (Config.scheme.isNotEmpty) {
      route = route.replaceFirst('${Config.scheme}:/', '');
    }

    // Omit the scheme from the route, which may be present when a deep link is
    // being parsed.
    if (route.startsWith('http://') || route.startsWith('https://')) {
      route = route.replaceFirst('https://', '').replaceFirst('http://', '');
      route = route.substring(max(route.indexOf('/'), 0));
    }

    if (route.startsWith(Routes.chats)) {
      tab = HomeTab.chats;
    } else if (route.startsWith(Routes.menu) || route == Routes.me) {
      tab = HomeTab.menu;
    }

    if (route == Routes.contacts ||
        route == Routes.chats ||
        route == Routes.menu) {
      route = Routes.home;
    }

    return SynchronousFuture(
      RouteConfiguration(
        route,
        tab: tab,
        arguments: routeInformation.uri.queryParameters,
      ),
    );
  }

  @override
  RouteInformation restoreRouteInformation(RouteConfiguration configuration) {
    String route = configuration.route;

    // If logged in and on [Routes.home] page, then modify the URL's route.
    if (configuration.authorized && configuration.route == Routes.home) {
      switch (configuration.tab!) {
        case HomeTab.wallet:
          route = Routes.wallet;
          break;

        case HomeTab.partner:
          route = Routes.partner;
          break;

        case HomeTab.chats:
          route = Routes.chats;
          break;

        case HomeTab.menu:
          route = Routes.menu;
          break;
      }
    }

    return RouteInformation(
      uri: Uri(path: route),
      state: configuration.tab?.index,
    );
  }
}

/// Application's router delegate that builds the root [Navigator] based on
/// the [_state].
class AppRouterDelegate extends RouterDelegate<RouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteConfiguration> {
  AppRouterDelegate(this._state) {
    _state.addListener(notifyListeners);
    _prefixWorker = ever(_state.prefix, (_) => _updateTabTitle());
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Router's state used to determine current [Navigator]'s pages.
  final RouterState _state;

  /// Worker to react on the [RouterState.prefix] changes.
  late final Worker _prefixWorker;

  @override
  Future<void> setInitialRoutePath(RouteConfiguration configuration) async {
    Future.delayed(Duration.zero, () {
      _state.context = navigatorKey.currentContext;
      _state.overlay = navigatorKey.currentState?.overlay;
    });

    if (_state.routes.isEmpty) {
      await setNewRoutePath(configuration);
    }
  }

  @override
  Future<void> setNewRoutePath(RouteConfiguration configuration) async {
    _state.routes.value = [configuration.route];
    if (configuration.tab != null) {
      _state.tab = configuration.tab!;
    }
    _state.arguments = configuration.arguments;
    _state.notifyListeners();
  }

  @override
  RouteConfiguration get currentConfiguration => RouteConfiguration(
    _state.route,
    tab: _state.tab,
    authorized: _state._auth.status.value.isSuccess,
    arguments: _state.arguments ?? const {},
  );

  @override
  void dispose() {
    _prefixWorker.dispose();
    super.dispose();
  }

  /// Unknown page view.
  Page<dynamic> get _notFoundPage {
    return const MaterialPage(key: ValueKey('404'), child: UnknownView());
  }

  /// [Navigator]'s pages generation based on the [_state].
  List<Page<dynamic>> get _pages {
    if (_state.route == Routes.restart) {
      return [
        const MaterialPage(
          key: ValueKey('RestartPage'),
          name: Routes.restart,
          child: Center(child: Text('Restarting...')),
        ),
      ];
    } else if (_state.route == Routes.nowhere) {
      final style = router.context == null
          ? null
          : Theme.of(router.context!).style;

      return [
        MaterialPage(
          key: const ValueKey('NowherePage'),
          name: Routes.nowhere,
          child: Scaffold(
            backgroundColor: style?.colors.background,
            body: const Center(child: CustomProgressIndicator.big()),
          ),
        ),
      ];
    } else if (_state.route == Routes.style) {
      return [
        const MaterialPage(
          key: ValueKey('StylePage'),
          name: Routes.style,
          child: StyleView(),
        ),
      ];
    } else if (_state.route.startsWith('${Routes.call}/')) {
      Uri uri = Uri.parse(_state.route);
      ChatId id = ChatId(uri.path.replaceFirst('${Routes.call}/', ''));

      return [
        MaterialPage(
          key: ValueKey('PopupCallView${id.val}'),
          name: '${Routes.call}/${id.val}',
          child: PopupCallView(
            chatId: id,
            depsFactory: () async {
              final ScopedDependencies deps = ScopedDependencies();
              final UserId me = _state._auth.userId!;

              final ScopedDriftProvider scoped = deps.put(
                ScopedDriftProvider.from(deps.put(ScopedDatabase(me))),
              );

              deps.put(UserDriftProvider(Get.find(), scoped));
              deps.put(ChatItemDriftProvider(Get.find(), scoped));
              deps.put(ChatMemberDriftProvider(Get.find(), scoped));
              deps.put(ChatDriftProvider(Get.find(), scoped));
              deps.put(BlocklistDriftProvider(Get.find(), scoped));
              deps.put(CallCredentialsDriftProvider(Get.find(), scoped));
              deps.put(ChatCredentialsDriftProvider(Get.find(), scoped));
              deps.put(CallRectDriftProvider(Get.find(), scoped));
              deps.put(MonologDriftProvider(Get.find(), scoped));
              deps.put(DraftDriftProvider(Get.find(), scoped));
              deps.put(SessionDriftProvider(Get.find(), scoped));
              await deps.put(VersionDriftProvider(Get.find())).init();

              final AbstractSettingsRepository settingsRepository = deps
                  .put<AbstractSettingsRepository>(
                    SettingsRepository(me, Get.find(), Get.find(), Get.find()),
                  );

              // Should be awaited to ensure [PopupCallView] using the stored
              // settings and not the default ones.
              await settingsRepository.init();

              // Should be initialized before any [L10n]-dependant entities as
              // it sets the stored [Language] from the [SettingsRepository].
              await deps.put(SettingsWorker(settingsRepository)).init();

              final GraphQlProvider graphQlProvider = Get.find();
              final UserRepository userRepository = UserRepository(
                graphQlProvider,
                Get.find(),
              );
              deps.put<AbstractUserRepository>(userRepository);
              final AbstractCallRepository callRepository = deps
                  .put<AbstractCallRepository>(
                    CallRepository(
                      graphQlProvider,
                      userRepository,
                      Get.find(),
                      Get.find(),
                      settingsRepository,
                      me: me,
                    ),
                  );
              final AbstractChatRepository chatRepository = deps
                  .put<AbstractChatRepository>(
                    ChatRepository(
                      graphQlProvider,
                      Get.find(),
                      Get.find(),
                      Get.find(),
                      callRepository,
                      Get.find(),
                      userRepository,
                      Get.find(),
                      Get.find(),
                      me: me,
                    ),
                  );

              userRepository.getChat = chatRepository.get;

              final AbstractContactRepository contactRepository = deps
                  .put<AbstractContactRepository>(
                    ContactRepository(
                      graphQlProvider,
                      userRepository,
                      Get.find(),
                      me: me,
                    ),
                  );
              userRepository.getContact = contactRepository.get;

              final BlocklistRepository blocklistRepository =
                  BlocklistRepository(
                    graphQlProvider,
                    Get.find(),
                    userRepository,
                    Get.find(),
                    me: me,
                  );
              deps.put<AbstractBlocklistRepository>(blocklistRepository);
              final AbstractMyUserRepository myUserRepository = deps
                  .put<AbstractMyUserRepository>(
                    MyUserRepository(
                      graphQlProvider,
                      Get.find(),
                      blocklistRepository,
                      userRepository,
                      Get.find(),
                    ),
                  );

              deps.put(MyUserService(Get.find(), myUserRepository));
              deps.put(UserService(userRepository));
              deps.put(ContactService(contactRepository));

              final ChatService chatService = deps.put(
                ChatService(chatRepository, Get.find()),
              );

              final CallService callService = deps.put(
                CallService(Get.find(), chatService, callRepository),
              );
              callService.onChatRemoved = chatRepository.remove;

              deps.put(BlocklistService(blocklistRepository));

              return deps;
            },
          ),
        ),
      ];
    } else if (_state.route.startsWith('${Routes.gallery}/')) {
      final Uri uri = Uri.parse(_state.route);
      final ChatId chatId = ChatId(
        uri.path.replaceFirst('${Routes.gallery}/', ''),
      );

      final id = router.arguments?['id'];
      final index = router.arguments?['index'];

      return [
        MaterialPage(
          key: ValueKey('GalleryView${chatId.val}'),
          name: '${Routes.gallery}/${chatId.val}',
          child: PopupGalleryView(
            chatId: chatId,
            initialKey: id is String ? id : null,
            initialIndex: index is int ? index : 0,
            depsFactory: () async {
              final ScopedDependencies deps = ScopedDependencies();
              final UserId me = _state._auth.userId!;

              final ScopedDriftProvider scoped = deps.put(
                ScopedDriftProvider.from(deps.put(ScopedDatabase(me))),
              );

              deps.put(UserDriftProvider(Get.find(), scoped));
              deps.put(ChatItemDriftProvider(Get.find(), scoped));
              deps.put(ChatMemberDriftProvider(Get.find(), scoped));
              deps.put(ChatDriftProvider(Get.find(), scoped));
              deps.put(BlocklistDriftProvider(Get.find(), scoped));
              deps.put(CallCredentialsDriftProvider(Get.find(), scoped));
              deps.put(ChatCredentialsDriftProvider(Get.find(), scoped));
              deps.put(CallRectDriftProvider(Get.find(), scoped));
              deps.put(MonologDriftProvider(Get.find(), scoped));
              deps.put(DraftDriftProvider(Get.find(), scoped));
              deps.put(SessionDriftProvider(Get.find(), scoped));
              await deps.put(VersionDriftProvider(Get.find())).init();

              final AbstractSettingsRepository settingsRepository = deps
                  .put<AbstractSettingsRepository>(
                    SettingsRepository(me, Get.find(), Get.find(), Get.find()),
                  );

              // Should be awaited to ensure [PopupGalleryView] using the stored
              // settings and not the default ones.
              await settingsRepository.init();

              // Should be initialized before any [L10n]-dependant entities as
              // it sets the stored [Language] from the [SettingsRepository].
              await deps.put(SettingsWorker(settingsRepository)).init();

              final GraphQlProvider graphQlProvider = Get.find();
              final UserRepository userRepository = UserRepository(
                graphQlProvider,
                Get.find(),
              );
              deps.put<AbstractUserRepository>(userRepository);
              final AbstractCallRepository callRepository = deps
                  .put<AbstractCallRepository>(
                    CallRepository(
                      graphQlProvider,
                      userRepository,
                      Get.find(),
                      Get.find(),
                      settingsRepository,
                      me: me,
                    ),
                  );
              final AbstractChatRepository chatRepository = deps
                  .put<AbstractChatRepository>(
                    ChatRepository(
                      graphQlProvider,
                      Get.find(),
                      Get.find(),
                      Get.find(),
                      callRepository,
                      Get.find(),
                      userRepository,
                      Get.find(),
                      Get.find(),
                      me: me,
                    ),
                  );

              userRepository.getChat = chatRepository.get;

              final AbstractContactRepository contactRepository = deps
                  .put<AbstractContactRepository>(
                    ContactRepository(
                      graphQlProvider,
                      userRepository,
                      Get.find(),
                      me: me,
                    ),
                  );
              userRepository.getContact = contactRepository.get;

              final BlocklistRepository blocklistRepository =
                  BlocklistRepository(
                    graphQlProvider,
                    Get.find(),
                    userRepository,
                    Get.find(),
                    me: me,
                  );
              deps.put<AbstractBlocklistRepository>(blocklistRepository);
              final AbstractMyUserRepository myUserRepository = deps
                  .put<AbstractMyUserRepository>(
                    MyUserRepository(
                      graphQlProvider,
                      Get.find(),
                      blocklistRepository,
                      userRepository,
                      Get.find(),
                    ),
                  );

              deps.put(MyUserService(Get.find(), myUserRepository));
              deps.put(UserService(userRepository));
              // deps.put(ContactService(contactRepository));

              deps.put(ChatService(chatRepository, Get.find()));

              return deps;
            },
          ),
        ),
      ];
    }

    /// [Routes.home] or [Routes.auth] page is always included.
    List<Page<dynamic>> pages = [];

    if (_state._auth.status.value.isSuccess) {
      pages.add(
        MaterialPage(
          key: const ValueKey('HomePage'),
          name: Routes.home,
          child: HomeView(
            () async {
              final UserId? me = _state._auth.userId;
              if (me == null) {
                return null;
              }

              final ScopedDependencies deps = ScopedDependencies();

              final ScopedDriftProvider scoped = deps.put(
                ScopedDriftProvider.from(deps.put(ScopedDatabase(me))),
              );

              final CommonDriftProvider common = Get.find();

              final userProvider = deps.put(UserDriftProvider(common, scoped));
              final chatProvider = deps.put(ChatDriftProvider(common, scoped));
              final chatItemProvider = deps.put(
                ChatItemDriftProvider(common, scoped),
              );
              final chatMemberProvider = deps.put(
                ChatMemberDriftProvider(common, scoped),
              );
              final blocklistProvider = deps.put(
                BlocklistDriftProvider(common, scoped),
              );
              final callCredsProvider = deps.put(
                CallCredentialsDriftProvider(common, scoped),
              );
              final chatCredsProvider = deps.put(
                ChatCredentialsDriftProvider(common, scoped),
              );
              final callRectProvider = deps.put(
                CallRectDriftProvider(common, scoped),
              );
              final monologProvider = deps.put(
                MonologDriftProvider(common, scoped),
              );
              final draftProvider = deps.put(
                DraftDriftProvider(common, scoped),
              );
              final sessionProvider = deps.put(
                SessionDriftProvider(Get.find(), scoped),
              );
              final versionProvider = deps.put(VersionDriftProvider(common));
              await versionProvider.init();

              final GraphQlProvider graphQlProvider = Get.find();

              final NotificationService notificationService = deps.put(
                NotificationService(graphQlProvider),
              );

              _state._auth.onLogout = ({bool keepData = true}) async {
                Log.debug(
                  '_state._auth.onLogout -> keepData: $keepData',
                  '$runtimeType',
                );

                try {
                  await notificationService.unregisterPushDevice();
                } catch (_) {
                  // No-op.
                }

                if (!keepData) {
                  try {
                    // Scope can already close the database due to `onClose`
                    // races - in such cases the database should be constructed
                    // so that it is being opened and then reset.
                    if (scoped.isClosed) {
                      final ScopedDatabase db = ScopedDatabase(me);
                      await db.reset(false);
                      await db.close();
                    } else {
                      await scoped.reset(false);
                    }

                    final backgroundProvider =
                        Get.findOrNull<BackgroundDriftProvider>();
                    final credentialsProvider =
                        Get.findOrNull<CredentialsDriftProvider>();
                    final myUserProvider =
                        Get.findOrNull<MyUserDriftProvider>();
                    final settingsProvider =
                        Get.findOrNull<SettingsDriftProvider>();
                    final versionProvider =
                        Get.findOrNull<VersionDriftProvider>();

                    await backgroundProvider?.delete(me);
                    await credentialsProvider?.delete(me);
                    await myUserProvider?.delete(me);
                    await settingsProvider?.delete(me);
                    await versionProvider?.delete(me);
                  } catch (_) {
                    // No-op.
                  }
                }
              };

              final AbstractSettingsRepository settingsRepository = deps
                  .put<AbstractSettingsRepository>(
                    SettingsRepository(
                      me,
                      Get.find(),
                      Get.find(),
                      callRectProvider,
                    ),
                  );

              // Should be awaited to ensure [Home] using the stored settings and
              // not the default ones.
              await settingsRepository.init();

              SessionService? sessionService;

              // Should be initialized before any [L10n]-dependant entities as
              // it sets the stored [Language] from the [SettingsRepository].
              await deps
                  .put(
                    SettingsWorker(
                      settingsRepository,
                      onChanged: (language) {
                        notificationService.setLanguage(language);
                        sessionService?.setLanguage(language);
                      },
                    ),
                  )
                  .init();

              final AbstractSessionRepository sessionRepository = deps
                  .put<AbstractSessionRepository>(
                    SessionRepository(
                      graphQlProvider,
                      Get.find(),
                      versionProvider,
                      sessionProvider,
                      Get.find(),
                      Get.find(),
                    ),
                  );
              sessionService = deps.put<SessionService>(
                SessionService(sessionRepository),
              );
              sessionService.setLanguage(L10n.chosen.value?.locale.toString());

              notificationService.init(
                language: L10n.chosen.value?.locale.toString(),
                firebaseOptions: PlatformUtils.pushNotifications
                    ? DefaultFirebaseOptions.currentPlatform
                    : null,
                onResponse: (payload) {
                  if (payload.startsWith(Routes.chats)) {
                    router.push(payload);
                  }
                },
                onBackground: handlePushNotification,
              );

              final UserRepository userRepository = UserRepository(
                graphQlProvider,
                userProvider,
              );
              deps.put<AbstractUserRepository>(userRepository);
              final CallRepository callRepository = CallRepository(
                graphQlProvider,
                userRepository,
                callCredsProvider,
                chatCredsProvider,
                settingsRepository,
                me: me,
              );
              deps.put<AbstractCallRepository>(callRepository);
              final ChatRepository chatRepository = ChatRepository(
                graphQlProvider,
                chatProvider,
                chatItemProvider,
                chatMemberProvider,
                callRepository,
                draftProvider,
                userRepository,
                versionProvider,
                monologProvider,
                me: me,
              );
              deps.put<AbstractChatRepository>(chatRepository);

              userRepository.getChat = chatRepository.get;
              callRepository.ensureRemoteDialog =
                  chatRepository.ensureRemoteDialog;
              _state._auth.hasCalls = () => callRepository.calls.values
                  .where((e) => e.value.connected)
                  .isNotEmpty;

              final AbstractContactRepository contactRepository = deps
                  .put<AbstractContactRepository>(
                    ContactRepository(
                      graphQlProvider,
                      userRepository,
                      versionProvider,
                      me: me,
                    ),
                  );
              userRepository.getContact = contactRepository.get;

              final BlocklistRepository blocklistRepository =
                  BlocklistRepository(
                    graphQlProvider,
                    blocklistProvider,
                    userRepository,
                    versionProvider,
                    me: me,
                  );
              deps.put<AbstractBlocklistRepository>(blocklistRepository);
              final AbstractMyUserRepository myUserRepository = deps
                  .put<AbstractMyUserRepository>(
                    MyUserRepository(
                      graphQlProvider,
                      Get.find(),
                      blocklistRepository,
                      userRepository,
                      Get.find(),
                    ),
                  );

              final MyUserService myUserService = deps.put(
                MyUserService(Get.find(), myUserRepository),
              );
              deps.put(UserService(userRepository));
              deps.put(ContactService(contactRepository));

              final ChatService chatService = deps.put(
                ChatService(chatRepository, Get.find()),
              );

              final CallService callService = deps.put(
                CallService(Get.find(), chatService, callRepository),
              );
              callService.onChatRemoved = chatRepository.remove;

              deps.put(BlocklistService(blocklistRepository));

              final AbstractWalletRepository walletRepository = deps
                  .put<AbstractWalletRepository>(WalletRepository(Get.find()));
              deps.put(WalletService(walletRepository));

              final AbstractPartnerRepository partnerRepository = deps
                  .put<AbstractPartnerRepository>(PartnerRepository());
              deps.put(PartnerService(partnerRepository));

              deps.put(
                CallWorker(
                  callService,
                  chatService,
                  myUserService,
                  Get.find(),
                  Get.find(),
                  settingsRepository,
                  graphQlProvider,
                  Get.find(),
                ),
              );

              deps.put(ChatWorker(chatService, myUserService, Get.find()));

              deps.put(MyUserWorker(myUserService));

              return deps;
            },
            signedUp: router.arguments?['signedUp'] as bool? ?? false,
            link: router.arguments?['link'] as ChatDirectLinkSlug?,
          ),
        ),
      );
    } else if (_state.route.startsWith(Routes.erase)) {
      return const [
        MaterialPage(
          key: ValueKey('ErasePage'),
          name: Routes.erase,
          child: EraseView(),
        ),
      ];
    } else if (_state.route.startsWith(Routes.chatDirectLink)) {
      final String slug = _state.route.replaceFirst(Routes.chatDirectLink, '');
      return [
        MaterialPage(
          key: ValueKey('ChatDirectLinkPage$slug'),
          name: '${Routes.chatDirectLink}$slug',
          child: ChatDirectLinkView(slug),
        ),
      ];
    } else {
      pages.add(
        const MaterialPage(
          key: ValueKey('AuthPage'),
          name: Routes.auth,
          child: AuthView(),
        ),
      );
    }

    if (_state.route.startsWith(Routes.chats) ||
        _state.route.startsWith(Routes.contacts) ||
        _state.route.startsWith(Routes.user) ||
        _state.route.startsWith(Routes.wallet) ||
        _state.route.startsWith(Routes.erase) ||
        _state.route.startsWith(Routes.partner) ||
        _state.route.startsWith(Routes.chatDirectLink) ||
        _state.route == Routes.me ||
        _state.route == Routes.home) {
      _updateTabTitle();
    } else {
      pages.add(_notFoundPage);
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return SentryDisplayWidget(
      child: LifecycleObserver(
        onStateChange: (v) => _state.lifecycle.value = v,
        child: Listener(
          onPointerDown: (_) => PlatformUtils.keepActive(),
          onPointerHover: (_) => PlatformUtils.keepActive(),
          onPointerSignal: (_) => PlatformUtils.keepActive(),
          child: Scaffold(
            body: Navigator(
              key: navigatorKey,
              observers: [SentryNavigatorObserver(), ModalNavigatorObserver()],
              pages: _pages,
              onDidRemovePage: (Page<Object?> page) {
                final bool success = page.canPop;
                if (success) {
                  _state.pop(page.name);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Sets the browser's tab title accordingly to the [_state.tab] value.
  void _updateTabTitle() {
    String? prefix = _state.prefix.value;
    if (prefix != null) {
      prefix = '$prefix ';
    }
    prefix ??= '';

    if (_state._auth.status.value.isSuccess) {
      switch (_state.tab) {
        case HomeTab.wallet:
          WebUtils.title('$prefix${'label_tab_wallet'.l10n}');
          break;

        case HomeTab.partner:
          WebUtils.title('$prefix${'label_tab_partner'.l10n}');
          break;

        case HomeTab.chats:
          WebUtils.title('$prefix${'label_tab_chats'.l10n}');
          break;

        case HomeTab.menu:
          WebUtils.title('$prefix${'label_tab_menu'.l10n}');
          break;
      }
    } else {
      WebUtils.title('Tapopa');
    }
  }
}

/// [RouterState]'s extension shortcuts on [Routes] constants.
extension RouteLinks on RouterState {
  /// Changes router location to the [Routes.auth] page.
  ///
  /// Invokes [WebUtils.closeWindow], if called from a [WebUtils.isPopup].
  void auth() {
    if (WebUtils.isPopup) {
      WebUtils.closeWindow();
    } else {
      go(Routes.auth);
    }
  }

  /// Changes router location to the [Routes.home] page.
  void home({bool? signedUp}) {
    go(Routes.home);
    arguments = {'signedUp': signedUp};
  }

  /// Changes router location to the [Routes.me] page.
  void me() => go(Routes.me);

  /// Changes router location to the [Routes.contacts] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void contact(UserId id, {bool push = false}) =>
      (push ? this.push : go)('${Routes.contacts}/$id');

  /// Changes router location to the [Routes.user] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void user(UserId id, {bool push = false}) =>
      (push ? this.push : go)('${Routes.user}/$id');

  /// Changes router location to the [Routes.chats] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void chat(
    ChatId id, {
    RouteAs mode = RouteAs.replace,
    ChatItemId? itemId,
    ChatDirectLinkSlug? link,
  }) {
    switch (mode) {
      case RouteAs.insteadOfLast:
        routes.removeLast();
        push('${Routes.chats}/$id');
        break;

      case RouteAs.replace:
        go('${Routes.chats}/$id');
        break;

      case RouteAs.push:
        push('${Routes.chats}/$id');
        break;
    }

    arguments = {'itemId': itemId, 'link': link};
  }

  /// Changes router location to the [Routes.chats] page respecting the possible
  /// [chat] being a dialog.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void dialog(
    Chat chat,
    UserId? me, {
    RouteAs mode = RouteAs.replace,
    ChatItemId? itemId,
    ChatDirectLinkSlug? link,
  }) {
    ChatId chatId = chat.id;

    if (chat.isDialog || chat.isMonolog) {
      ChatMember? member = chat.members.firstWhereOrNull(
        (e) => e.user.id != me,
      );
      member ??= chat.members.firstOrNull;

      if (member != null) {
        chatId = ChatId.local(member.user.id);
      }
    }

    router.chat(chatId, itemId: itemId, link: link, mode: mode);
  }

  /// Changes router location to the [Routes.chatInfo] page.
  void chatInfo(ChatId id, {bool push = false}) =>
      (push ? this.push : go)('${Routes.chats}/$id${Routes.chatInfo}');

  /// Changes router location to the [Routes.style] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void style({bool push = false}) => (push ? this.push : go)(Routes.style);

  /// Changes router location to the [Routes.nowhere] page.
  void nowhere() => go(Routes.nowhere);

  /// Changes router location to the [Routes.chatDirectLink] page.
  void link(ChatDirectLinkSlug slug) => go('${Routes.chatDirectLink}$slug');

  /// Changes router location to the [Routes.erase] page.
  void erase({bool push = false}) => (push ? this.push : go)(Routes.erase);

  /// Changes router location to the [Routes.affiliate] page.
  void affiliate({bool push = false}) =>
      (push ? this.push : go)(Routes.affiliate);

  /// Changes router location to the [Routes.promotion] page.
  void promotion({bool push = false}) =>
      (push ? this.push : go)(Routes.promotion);

  /// Changes router location to the [Routes.prices] page.
  void prices({bool push = false}) => (push ? this.push : go)(Routes.prices);

  /// Changes router location to the [Routes.statistics] page.
  void statistics({bool push = false}) =>
      (push ? this.push : go)(Routes.statistics);

  /// Changes router location to the [Routes.withdraw] page.
  void withdraw({bool push = false}) =>
      (push ? this.push : go)(Routes.withdraw);

  /// Changes router location to the [Routes.partnerTransactions] page.
  void partnerTransactions({bool push = false}) =>
      (push ? this.push : go)(Routes.partnerTransactions);

  /// Changes router location to the [Routes.walletTransactions] page.
  void walletTransactions({bool push = false}) =>
      (push ? this.push : go)(Routes.walletTransactions);

  /// Changes router location to the [Routes.deposit] page.
  void deposit({bool push = false}) => (push ? this.push : go)(Routes.deposit);
}

/// Extension adding helper methods to an [AppLifecycleState].
extension AppLifecycleStateExtension on AppLifecycleState {
  /// Indicates whether this [AppLifecycleState] is considered as a foreground.
  bool get inForeground {
    switch (this) {
      case AppLifecycleState.resumed:
        return true;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return false;
    }
  }
}

/// [NavigatorObserver] tracking [ModalRoute]s opened and closed via
/// [RouterState.obscuring].
class ModalNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is ModalRoute && _isObscuring(route)) {
      router.obscuring.add(route);
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route is ModalRoute && _isObscuring(route)) {
      router.obscuring.remove(route);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (route is ModalRoute && _isObscuring(route)) {
      router.obscuring.remove(route);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null &&
        _isObscuring(newRoute) &&
        (oldRoute == null || !_isObscuring(oldRoute))) {
      router.obscuring.remove(newRoute);
    }
  }

  /// Indicates whether the [route] should be considered as one obscuring the
  /// content.
  bool _isObscuring(Route route) {
    return (route is RawDialogRoute && route is! DialogRoute) ||
        route is ModalBottomSheetRoute;
  }
}
