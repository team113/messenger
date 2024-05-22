// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'domain/model/chat.dart';
import 'domain/model/chat_item.dart';
import 'domain/model/user.dart';
import 'domain/repository/blocklist.dart';
import 'domain/repository/call.dart';
import 'domain/repository/chat.dart';
import 'domain/repository/contact.dart';
import 'domain/repository/my_user.dart';
import 'domain/repository/settings.dart';
import 'domain/repository/user.dart';
import 'domain/service/auth.dart';
import 'domain/service/blocklist.dart';
import 'domain/service/call.dart';
import 'domain/service/chat.dart';
import 'domain/service/contact.dart';
import 'domain/service/my_user.dart';
import 'domain/service/notification.dart';
import 'domain/service/user.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'main.dart' show handlePushNotification;
import 'provider/drift/chat_item.dart';
import 'provider/drift/user.dart';
import 'provider/gql/graphql.dart';
import 'provider/hive/application_settings.dart';
import 'provider/hive/background.dart';
import 'provider/hive/blocklist.dart';
import 'provider/hive/blocklist_sorting.dart';
import 'provider/hive/call_credentials.dart';
import 'provider/hive/call_rect.dart';
import 'provider/hive/chat.dart';
import 'provider/hive/chat_credentials.dart';
import 'provider/hive/contact.dart';
import 'provider/hive/contact_sorting.dart';
import 'provider/hive/draft.dart';
import 'provider/hive/favorite_chat.dart';
import 'provider/hive/favorite_contact.dart';
import 'provider/hive/media_settings.dart';
import 'provider/hive/monolog.dart';
import 'provider/hive/recent_chat.dart';
import 'provider/hive/session_data.dart';
import 'store/blocklist.dart';
import 'store/call.dart';
import 'store/chat.dart';
import 'store/contact.dart';
import 'store/my_user.dart';
import 'store/settings.dart';
import 'store/user.dart';
import 'themes.dart';
import 'ui/page/auth/view.dart';
import 'ui/page/chat_direct_link/view.dart';
import 'ui/page/erase/view.dart';
import 'ui/page/home/view.dart';
import 'ui/page/popup_call/view.dart';
import 'ui/page/style/view.dart';
import 'ui/page/support/view.dart';
import 'ui/page/work/view.dart';
import 'ui/widget/lifecycle_observer.dart';
import 'ui/widget/progress_indicator.dart';
import 'ui/worker/call.dart';
import 'ui/worker/chat.dart';
import 'ui/worker/my_user.dart';
import 'ui/worker/settings.dart';
import 'util/platform_utils.dart';
import 'util/scoped_dependencies.dart';
import 'util/web/web_utils.dart';

/// Application's global router state.
late RouterState router;

/// Application routes names.
class Routes {
  static const auth = '/';
  static const call = '/call';
  static const chatDirectLink = '/d';
  static const chatInfo = '/info';
  static const chats = '/chats';
  static const contacts = '/contacts';
  static const erase = '/erase';
  static const home = '/';
  static const me = '/me';
  static const menu = '/menu';
  static const support = '/support';
  static const user = '/user';
  static const work = '/work';

  // TODO: Dirty hack used to reinitialize the dependencies when changing
  //       accounts, should remove it.
  static const nowhere = '/nowhere';

  // E2E tests related page, should not be used in non-test environment.
  static const restart = '/restart';

  // TODO: Styles page related, should be removed at some point.
  static const style = '/dev/style';
}

/// List of [Routes.home] page tabs.
enum HomeTab { work, contacts, chats, menu }

/// List of [Routes.work] page sections.
enum WorkTab { frontend, backend, freelance }

/// List of [Routes.me] page sections.
enum ProfileTab {
  public,
  signing,
  link,
  background,
  chats,
  calls,
  media,
  notifications,
  storage,
  language,
  blocklist,
  devices,
  sections,
  download,
  danger,
  legal,
  support,
  logout,
}

/// Application's router state.
///
/// Any change requires [notifyListeners] to be invoked in order for the router
/// to update its state.
class RouterState extends ChangeNotifier {
  RouterState(this._auth) {
    delegate = AppRouterDelegate(this);
    parser = AppRouteInformationParser();
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
  final Rx<AppLifecycleState> lifecycle =
      Rx<AppLifecycleState>(AppLifecycleState.resumed);

  /// Reactive title prefix of the current browser tab.
  final RxnString prefix = RxnString(null);

  /// Routes history stack.
  final RxList<String> routes = RxList([]);

  /// Indicator whether [HomeView] page navigation should be visible.
  final RxBool navigation = RxBool(true);

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
    arguments = null;
    routes.value = [_guarded(to)];
    notifyListeners();
  }

  /// Pushes [to] to the [routes] stack.
  void push(String to) {
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
  void pop() {
    if (routes.isNotEmpty) {
      if (routes.length == 1) {
        String last = routes.last.split('/').last;
        routes.last = routes.last.replaceFirst('/$last', '');
        if (routes.last == '' ||
            (_auth.status.value.isSuccess && routes.last == Routes.work) ||
            routes.last == Routes.contacts ||
            routes.last == Routes.chats ||
            routes.last == Routes.menu ||
            routes.last == Routes.user) {
          routes.last = Routes.home;
        }
      } else {
        routes.removeLast();
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
    routes.value = routes.map((e) => e.replaceAll(from, to)).toList();
  }

  /// Returns guarded route based on [_auth] status.
  ///
  /// - [Routes.home] is allowed always.
  /// - Any other page is allowed to visit only on success auth status.
  String _guarded(String to) {
    if (to.startsWith(Routes.work) ||
        to.startsWith(Routes.erase) ||
        to.startsWith(Routes.support)) {
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
    String route = routeInformation.uri.path;
    HomeTab? tab;

    if (route.startsWith(Routes.work)) {
      tab = HomeTab.work;
    } else if (route.startsWith(Routes.contacts)) {
      tab = HomeTab.contacts;
    } else if (route.startsWith(Routes.chats)) {
      tab = HomeTab.chats;
    } else if (route.startsWith(Routes.menu) || route == Routes.me) {
      tab = HomeTab.menu;
    }

    if (route == Routes.work ||
        route == Routes.contacts ||
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
        case HomeTab.work:
          route = Routes.work;
          break;

        case HomeTab.contacts:
          route = Routes.contacts;
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
  Page<dynamic> get _notFoundPage => MaterialPage(
        key: const ValueKey('404'),
        child: Scaffold(body: Center(child: Text('label_unknown_page'.l10n))),
      );

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
      return [
        MaterialPage(
          key: const ValueKey('NowherePage'),
          name: Routes.nowhere,
          child: Scaffold(
            backgroundColor: Theme.of(router.context!).style.colors.background,
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
    } else if (_state.route.startsWith('${Routes.chatDirectLink}/')) {
      String slug = _state.route.replaceFirst('${Routes.chatDirectLink}/', '');
      return [
        MaterialPage(
          key: ValueKey('ChatDirectLinkPage$slug'),
          name: Routes.chatDirectLink,
          child: ChatDirectLinkView(slug),
        )
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
              ScopedDependencies deps = ScopedDependencies();
              UserId me = _state._auth.userId!;

              await Future.wait([
                deps.put(ChatHiveProvider()).init(userId: me),
                deps.put(RecentChatHiveProvider()).init(userId: me),
                deps.put(FavoriteChatHiveProvider()).init(userId: me),
                deps.put(SessionDataHiveProvider()).init(userId: me),
                deps.put(BlocklistHiveProvider()).init(userId: me),
                deps.put(BlocklistSortingHiveProvider()).init(userId: me),
                deps.put(ContactHiveProvider()).init(userId: me),
                deps.put(FavoriteContactHiveProvider()).init(userId: me),
                deps.put(ContactSortingHiveProvider()).init(userId: me),
                deps.put(MediaSettingsHiveProvider()).init(userId: me),
                deps.put(ApplicationSettingsHiveProvider()).init(userId: me),
                deps.put(BackgroundHiveProvider()).init(userId: me),
                deps.put(CallCredentialsHiveProvider()).init(userId: me),
                deps.put(ChatCredentialsHiveProvider()).init(userId: me),
                deps.put(DraftHiveProvider()).init(userId: me),
                deps.put(CallRectHiveProvider()).init(userId: me),
                deps.put(MonologHiveProvider()).init(userId: me),
              ]);

              deps.put(UserDriftProvider(Get.find()));
              deps.put(ChatItemDriftProvider(Get.find()));

              AbstractSettingsRepository settingsRepository =
                  deps.put<AbstractSettingsRepository>(
                SettingsRepository(
                  Get.find(),
                  Get.find(),
                  Get.find(),
                  Get.find(),
                ),
              );

              // Should be initialized before any [L10n]-dependant entities as
              // it sets the stored [Language] from the [SettingsRepository].
              await deps.put(SettingsWorker(settingsRepository)).init();

              GraphQlProvider graphQlProvider = Get.find();
              UserRepository userRepository =
                  UserRepository(graphQlProvider, Get.find());
              deps.put<AbstractUserRepository>(userRepository);
              AbstractCallRepository callRepository =
                  deps.put<AbstractCallRepository>(
                CallRepository(
                  graphQlProvider,
                  userRepository,
                  Get.find(),
                  Get.find(),
                  settingsRepository,
                  me: me,
                ),
              );
              AbstractChatRepository chatRepository =
                  deps.put<AbstractChatRepository>(
                ChatRepository(
                  graphQlProvider,
                  Get.find(),
                  Get.find(),
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

              AbstractContactRepository contactRepository =
                  deps.put<AbstractContactRepository>(
                ContactRepository(
                  graphQlProvider,
                  Get.find(),
                  Get.find(),
                  Get.find(),
                  userRepository,
                  Get.find(),
                ),
              );
              userRepository.getContact = contactRepository.get;

              BlocklistRepository blocklistRepository = BlocklistRepository(
                graphQlProvider,
                Get.find(),
                Get.find(),
                userRepository,
                Get.find(),
              );
              deps.put<AbstractBlocklistRepository>(blocklistRepository);
              AbstractMyUserRepository myUserRepository =
                  deps.put<AbstractMyUserRepository>(
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
              ChatService chatService =
                  deps.put(ChatService(chatRepository, Get.find()));
              deps.put(CallService(
                Get.find(),
                chatService,
                callRepository,
              ));
              deps.put(BlocklistService(blocklistRepository));

              return deps;
            },
          ),
        )
      ];
    }

    /// [Routes.home] or [Routes.auth] page is always included.
    List<Page<dynamic>> pages = [];

    if (_state._auth.status.value.isSuccess) {
      pages.add(MaterialPage(
        key: const ValueKey('HomePage'),
        name: Routes.home,
        child: HomeView(
          () async {
            final UserId? me = _state._auth.userId;
            if (me == null) {
              return null;
            }

            final ScopedDependencies deps = ScopedDependencies();

            await Future.wait([
              deps.put(ChatHiveProvider()).init(userId: me),
              deps.put(RecentChatHiveProvider()).init(userId: me),
              deps.put(FavoriteChatHiveProvider()).init(userId: me),
              deps.put(SessionDataHiveProvider()).init(userId: me),
              deps.put(BlocklistHiveProvider()).init(userId: me),
              deps.put(BlocklistSortingHiveProvider()).init(userId: me),
              deps.put(ContactHiveProvider()).init(userId: me),
              deps.put(FavoriteContactHiveProvider()).init(userId: me),
              deps.put(ContactSortingHiveProvider()).init(userId: me),
              deps.put(MediaSettingsHiveProvider()).init(userId: me),
              deps.put(ApplicationSettingsHiveProvider()).init(userId: me),
              deps.put(BackgroundHiveProvider()).init(userId: me),
              deps.put(CallCredentialsHiveProvider()).init(userId: me),
              deps.put(ChatCredentialsHiveProvider()).init(userId: me),
              deps.put(DraftHiveProvider()).init(userId: me),
              deps.put(CallRectHiveProvider()).init(userId: me),
              deps.put(MonologHiveProvider()).init(userId: me),
            ]);

            deps.put(UserDriftProvider(Get.find()));
            deps.put(ChatItemDriftProvider(Get.find()));

            GraphQlProvider graphQlProvider = Get.find();

            NotificationService notificationService =
                deps.put(NotificationService(graphQlProvider));

            AbstractSettingsRepository settingsRepository =
                deps.put<AbstractSettingsRepository>(
              SettingsRepository(
                Get.find(),
                Get.find(),
                Get.find(),
                Get.find(),
              ),
            );

            // Should be initialized before any [L10n]-dependant entities as
            // it sets the stored [Language] from the [SettingsRepository].
            await deps
                .put(
                  SettingsWorker(
                    settingsRepository,
                    onChanged: notificationService.setLanguage,
                  ),
                )
                .init();

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

            UserRepository userRepository =
                UserRepository(graphQlProvider, Get.find());
            deps.put<AbstractUserRepository>(userRepository);
            CallRepository callRepository = CallRepository(
              graphQlProvider,
              userRepository,
              Get.find(),
              Get.find(),
              settingsRepository,
              me: me,
            );
            deps.put<AbstractCallRepository>(callRepository);
            ChatRepository chatRepository = ChatRepository(
              graphQlProvider,
              Get.find(),
              Get.find(),
              Get.find(),
              Get.find(),
              Get.find(),
              callRepository,
              Get.find(),
              userRepository,
              Get.find(),
              Get.find(),
              me: me,
            );
            deps.put<AbstractChatRepository>(chatRepository);

            userRepository.getChat = chatRepository.get;
            callRepository.ensureRemoteDialog =
                chatRepository.ensureRemoteDialog;

            AbstractContactRepository contactRepository =
                deps.put<AbstractContactRepository>(
              ContactRepository(
                graphQlProvider,
                Get.find(),
                Get.find(),
                Get.find(),
                userRepository,
                Get.find(),
              ),
            );
            userRepository.getContact = contactRepository.get;

            BlocklistRepository blocklistRepository = BlocklistRepository(
              graphQlProvider,
              Get.find(),
              Get.find(),
              userRepository,
              Get.find(),
            );
            deps.put<AbstractBlocklistRepository>(blocklistRepository);
            AbstractMyUserRepository myUserRepository =
                deps.put<AbstractMyUserRepository>(
              MyUserRepository(
                graphQlProvider,
                Get.find(),
                blocklistRepository,
                userRepository,
                Get.find(),
              ),
            );

            MyUserService myUserService =
                deps.put(MyUserService(Get.find(), myUserRepository));
            deps.put(UserService(userRepository));
            deps.put(ContactService(contactRepository));
            ChatService chatService =
                deps.put(ChatService(chatRepository, Get.find()));
            CallService callService = deps.put(CallService(
              Get.find(),
              chatService,
              callRepository,
            ));
            deps.put(BlocklistService(blocklistRepository));

            deps.put(CallWorker(
              callService,
              chatService,
              myUserService,
              Get.find(),
            ));

            deps.put(ChatWorker(chatService, myUserService, Get.find()));

            deps.put(MyUserWorker(myUserService));

            return deps;
          },
          signedUp: router.arguments?['signedUp'] as bool? ?? false,
          link: router.arguments?['link'] as ChatDirectLinkSlug?,
        ),
      ));
    } else if (_state.route.startsWith(Routes.work)) {
      return const [
        MaterialPage(
          key: ValueKey('WorkPage'),
          name: Routes.work,
          child: WorkView(),
        )
      ];
    } else if (_state.route.startsWith(Routes.erase)) {
      return const [
        MaterialPage(
          key: ValueKey('ErasePage'),
          name: Routes.erase,
          child: EraseView(),
        )
      ];
    } else if (_state.route.startsWith(Routes.support)) {
      return const [
        MaterialPage(
          key: ValueKey('SupportPage'),
          name: Routes.support,
          child: SupportView(),
        )
      ];
    } else {
      pages.add(const MaterialPage(
        key: ValueKey('AuthPage'),
        name: Routes.auth,
        child: AuthView(),
      ));
    }

    if (_state.route.startsWith(Routes.chats) ||
        _state.route.startsWith(Routes.contacts) ||
        _state.route.startsWith(Routes.user) ||
        _state.route.startsWith(Routes.work) ||
        _state.route.startsWith(Routes.erase) ||
        _state.route.startsWith(Routes.support) ||
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
    return LifecycleObserver(
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
            onPopPage: (Route<dynamic> route, dynamic result) {
              final bool success = route.didPop(result);
              if (success) {
                _state.pop();
              }
              return success;
            },
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
        case HomeTab.work:
          WebUtils.title('$prefix${'label_work_with_us'.l10n}');
          break;

        case HomeTab.contacts:
          WebUtils.title('$prefix${'label_tab_contacts'.l10n}');
          break;

        case HomeTab.chats:
          WebUtils.title('$prefix${'label_tab_chats'.l10n}');
          break;

        case HomeTab.menu:
          WebUtils.title('$prefix${'label_tab_menu'.l10n}');
          break;
      }
    } else {
      WebUtils.title('Gapopa');
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
    bool push = false,
    ChatItemId? itemId,
    ChatDirectLinkSlug? link,

    // TODO: Remove when backend supports welcome messages.
    ChatMessageText? welcome,
  }) {
    (push ? this.push : go)('${Routes.chats}/$id');

    arguments = {
      'itemId': itemId,
      'welcome': welcome,
      'link': link,
    };
  }

  /// Changes router location to the [Routes.chatInfo] page.
  void chatInfo(ChatId id, {bool push = false}) =>
      (push ? this.push : go)('${Routes.chats}/$id${Routes.chatInfo}');

  /// Changes router location to the [Routes.work] page.
  void work(WorkTab? tab, {bool push = false}) => (push
      ? this.push
      : go)('${Routes.work}${tab == null ? '' : '/${tab.name}'}');

  /// Changes router location to the [Routes.support] page.
  void support({bool push = false}) => (push ? this.push : go)(Routes.support);

  /// Changes router location to the [Routes.style] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void style({bool push = false}) => (push ? this.push : go)(Routes.style);

  /// Changes router location to the [Routes.nowhere] page.
  void nowhere() => go(Routes.nowhere);
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
