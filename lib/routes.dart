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

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'domain/model/chat.dart';
import 'domain/model/chat_item.dart';
import 'domain/model/user.dart';
import 'domain/repository/call.dart';
import 'domain/repository/chat.dart';
import 'domain/repository/contact.dart';
import 'domain/repository/my_user.dart';
import 'domain/repository/settings.dart';
import 'domain/repository/user.dart';
import 'domain/service/auth.dart';
import 'domain/service/call.dart';
import 'domain/service/chat.dart';
import 'domain/service/contact.dart';
import 'domain/service/my_user.dart';
import 'domain/service/user.dart';
import 'l10n/l10n.dart';
import 'provider/gql/graphql.dart';
import 'provider/hive/application_settings.dart';
import 'provider/hive/background.dart';
import 'provider/hive/chat.dart';
import 'provider/hive/chat_call_credentials.dart';
import 'provider/hive/contact.dart';
import 'provider/hive/gallery_item.dart';
import 'provider/hive/media_settings.dart';
import 'provider/hive/my_user.dart';
import 'provider/hive/user.dart';
import 'store/call.dart';
import 'store/chat.dart';
import 'store/contact.dart';
import 'store/my_user.dart';
import 'store/settings.dart';
import 'store/user.dart';
import 'ui/page/auth/view.dart';
import 'ui/page/chat_direct_link/view.dart';
import 'ui/page/home/view.dart';
import 'ui/page/popup_call/view.dart';
import 'ui/page/style/view.dart';
import 'ui/widget/lifecycle_observer.dart';
import 'ui/worker/call.dart';
import 'ui/worker/chat.dart';
import 'ui/worker/my_user.dart';
import 'ui/worker/settings.dart';
import 'util/scoped_dependencies.dart';
import 'util/web/web_utils.dart';

/// Application's global router state.
late RouterState router;

/// Application routes names.
class Routes {
  static const auth = '/';
  static const call = '/call';
  static const chat = '/chat';
  static const chatDirectLink = '/d';
  static const chatInfo = '/info';
  static const contact = '/contact';
  static const home = '/';
  static const me = '/me';
  static const menu = '/menu';
  static const personalization = '/personalization';
  static const settings = '/settings';
  static const settingsMedia = '/settings/media';
  static const user = '/user';

  // E2E tests related page, should not be used in non-test environment.
  static const restart = '/restart';

  // TODO: Styles page related, should be removed at some point.
  static const style = '/style';
}

/// List of [Routes.home] page tabs.
enum HomeTab { contacts, chats, menu }

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
  BuildContext? context;

  /// Reactive [AppLifecycleState].
  final Rx<AppLifecycleState> lifecycle =
      Rx<AppLifecycleState>(AppLifecycleState.resumed);

  /// Reactive title prefix of the current browser tab.
  final RxnString prefix = RxnString(null);

  /// Routes history stack.
  final RxList<String> routes = RxList([]);

  /// Dynamic arguments of the [route].
  Map<String, dynamic>? arguments;

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
            routes.last == Routes.contact ||
            routes.last == Routes.chat ||
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

  /// Returns guarded route based on [_auth] status.
  ///
  /// - [Routes.home] is allowed always.
  /// - Any other page is allowed to visit only on success auth status.
  String _guarded(String to) {
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
  RouteConfiguration(this.route, [this.tab, this.loggedIn = true]);

  /// Current route as a [String] value.
  ///
  /// e.g. `/auth`, `/chat/0`, etc.
  final String route;

  /// Current [Routes.home] [HomeTab] value. Non null if current [route] is
  /// [Routes.home].
  final HomeTab? tab;

  /// Whether current user is logged in or not.
  bool loggedIn;
}

/// Parses the [RouteConfiguration] from/to [RouteInformation].
class AppRouteInformationParser
    extends RouteInformationParser<RouteConfiguration> {
  @override
  SynchronousFuture<RouteConfiguration> parseRouteInformation(
      RouteInformation routeInformation) {
    RouteConfiguration configuration;
    switch (routeInformation.location) {
      case Routes.contact:
        configuration = RouteConfiguration(Routes.home, HomeTab.contacts);
        break;
      case Routes.chat:
        configuration = RouteConfiguration(Routes.home, HomeTab.chats);
        break;
      case Routes.menu:
        configuration = RouteConfiguration(Routes.home, HomeTab.menu);
        break;
      default:
        configuration = RouteConfiguration(routeInformation.location!, null);
        break;
    }

    return SynchronousFuture(configuration);
  }

  @override
  RouteInformation restoreRouteInformation(RouteConfiguration configuration) {
    String route = configuration.route;

    // If logged in and on [Routes.home] page, then modify the URL's route.
    if (configuration.loggedIn && configuration.route == Routes.home) {
      switch (configuration.tab!) {
        case HomeTab.contacts:
          route = Routes.contact;
          break;
        case HomeTab.chats:
          route = Routes.chat;
          break;
        case HomeTab.menu:
          route = Routes.menu;
          break;
      }
    }

    return RouteInformation(location: route, state: configuration.tab?.index);
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
  Future<void> setInitialRoutePath(RouteConfiguration configuration) {
    Future.delayed(
        Duration.zero, () => _state.context = navigatorKey.currentContext);
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(RouteConfiguration configuration) async {
    _state.routes.value = [configuration.route];
    if (configuration.tab != null) {
      _state.tab = configuration.tab!;
    }
    _state.notifyListeners();
  }

  @override
  RouteConfiguration get currentConfiguration => RouteConfiguration(
      _state.route, _state.tab, _state._auth.status.value.isSuccess);

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
                deps.put(MyUserHiveProvider()).init(userId: me),
                deps.put(ChatHiveProvider()).init(userId: me),
                deps.put(GalleryItemHiveProvider()).init(userId: me),
                deps.put(UserHiveProvider()).init(userId: me),
                deps.put(ContactHiveProvider()).init(userId: me),
                deps.put(MediaSettingsHiveProvider()).init(userId: me),
                deps.put(ApplicationSettingsHiveProvider()).init(userId: me),
                deps.put(BackgroundHiveProvider()).init(userId: me),
                deps.put(ChatCallCredentialsHiveProvider()).init(userId: me),
              ]);

              AbstractSettingsRepository settingsRepository =
                  deps.put<AbstractSettingsRepository>(
                SettingsRepository(Get.find(), Get.find(), Get.find()),
              );

              // Should be initialized before any [L10n]-dependant entities as
              // it sets the stored [Language] from the [SettingsRepository].
              await deps.put(SettingsWorker(settingsRepository)).init();

              GraphQlProvider graphQlProvider = Get.find();
              UserRepository userRepository = UserRepository(
                graphQlProvider,
                Get.find(),
                Get.find(),
              );
              deps.put<AbstractUserRepository>(userRepository);
              AbstractCallRepository callRepository =
                  deps.put<AbstractCallRepository>(
                CallRepository(
                  graphQlProvider,
                  userRepository,
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
                  callRepository,
                  userRepository,
                  me: me,
                ),
              );
              AbstractContactRepository contactRepository =
                  deps.put<AbstractContactRepository>(
                ContactRepository(
                  graphQlProvider,
                  Get.find(),
                  userRepository,
                  Get.find(),
                ),
              );
              AbstractMyUserRepository myUserRepository =
                  deps.put<AbstractMyUserRepository>(
                MyUserRepository(
                  graphQlProvider,
                  Get.find(),
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
                settingsRepository,
                callRepository,
              ));

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
            ScopedDependencies deps = ScopedDependencies();
            UserId me = _state._auth.userId!;

            await Future.wait([
              deps.put(MyUserHiveProvider()).init(userId: me),
              deps.put(ChatHiveProvider()).init(userId: me),
              deps.put(GalleryItemHiveProvider()).init(userId: me),
              deps.put(UserHiveProvider()).init(userId: me),
              deps.put(ContactHiveProvider()).init(userId: me),
              deps.put(MediaSettingsHiveProvider()).init(userId: me),
              deps.put(ApplicationSettingsHiveProvider()).init(userId: me),
              deps.put(BackgroundHiveProvider()).init(userId: me),
              deps.put(ChatCallCredentialsHiveProvider()).init(userId: me),
            ]);

            AbstractSettingsRepository settingsRepository =
                deps.put<AbstractSettingsRepository>(
              SettingsRepository(Get.find(), Get.find(), Get.find()),
            );

            // Should be initialized before any [L10n]-dependant entities as
            // it sets the stored [Language] from the [SettingsRepository].
            await deps.put(SettingsWorker(settingsRepository)).init();

            GraphQlProvider graphQlProvider = Get.find();
            UserRepository userRepository = UserRepository(
              graphQlProvider,
              Get.find(),
              Get.find(),
            );
            deps.put<AbstractUserRepository>(userRepository);
            AbstractCallRepository callRepository =
                deps.put<AbstractCallRepository>(
              CallRepository(
                graphQlProvider,
                userRepository,
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
                callRepository,
                userRepository,
                me: me,
              ),
            );
            AbstractContactRepository contactRepository =
                deps.put<AbstractContactRepository>(
              ContactRepository(
                graphQlProvider,
                Get.find(),
                userRepository,
                Get.find(),
              ),
            );
            AbstractMyUserRepository myUserRepository =
                deps.put<AbstractMyUserRepository>(
              MyUserRepository(
                graphQlProvider,
                Get.find(),
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
              settingsRepository,
              callRepository,
            ));

            deps.put(CallWorker(
              Get.find(),
              callService,
              chatService,
              Get.find(),
            ));

            deps.put(ChatWorker(
              chatService,
              Get.find(),
            ));

            deps.put(MyUserWorker(myUserService));

            return deps;
          },
        ),
      ));
    } else {
      pages.add(const MaterialPage(
        key: ValueKey('AuthPage'),
        name: Routes.auth,
        child: AuthView(),
      ));
    }

    if (_state.route.startsWith(Routes.chat) ||
        _state.route.startsWith(Routes.contact) ||
        _state.route.startsWith(Routes.user) ||
        _state.route == Routes.me ||
        _state.route == Routes.settings ||
        _state.route == Routes.settingsMedia ||
        _state.route == Routes.personalization ||
        _state.route == Routes.home) {
      _updateTabTitle();
    } else {
      pages.add(_notFoundPage);
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) => LifecycleObserver(
        didChangeAppLifecycleState: (v) => _state.lifecycle.value = v,
        child: Scaffold(
          body: Navigator(
            key: navigatorKey,
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
      );

  /// Sets the browser's tab title accordingly to the [_state.tab] value.
  void _updateTabTitle() {
    String? prefix = _state.prefix.value;
    if (prefix != null) {
      prefix = '$prefix ';
    }
    prefix ??= '';

    if (_state._auth.status.value.isSuccess) {
      switch (_state.tab) {
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
  void auth() => go(Routes.auth);

  /// Changes router location to the [Routes.home] page.
  void home() => go(Routes.home);

  /// Changes router location to the [Routes.settings] page.
  void settings() => go(Routes.settings);

  /// Changes router location to the [Routes.settingsMedia] page.
  void settingsMedia() => go(Routes.settingsMedia);

  /// Changes router location to the [Routes.personalization] page.
  void personalization() => go(Routes.personalization);

  /// Changes router location to the [Routes.me] page.
  void me() => go(Routes.me);

  /// Changes router location to the [Routes.contact] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void contact(UserId id, {bool push = false}) =>
      push ? this.push('${Routes.contact}/$id') : go('${Routes.contact}/$id');

  /// Changes router location to the [Routes.user] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void user(UserId id, {bool push = false}) =>
      push ? this.push('${Routes.user}/$id') : go('${Routes.user}/$id');

  /// Changes router location to the [Routes.chat] page.
  ///
  /// If [push] is `true`, then location is pushed to the router location stack.
  void chat(
    ChatId id, {
    bool push = false,
    ChatItemId? itemId,
  }) {
    if (push) {
      this.push('${Routes.chat}/$id');
    } else {
      go('${Routes.chat}/$id');
    }

    arguments = {'itemId': itemId};
  }

  /// Changes router location to the [Routes.chatInfo] page.
  void chatInfo(ChatId id) => go('${Routes.chat}/$id${Routes.chatInfo}');
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
        return false;
    }
  }
}
