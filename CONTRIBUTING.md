Contribution Guide
==================

1. [Requirements](#requirements)
2. [Prerequisites](#prerequisites)
3. [Operations](#operations)
4. [Structure overview](#structure-overview)
5. [Code style](#code-style)
6. [Backend connectivity](#backend-connectivity)




## Requirements

- If you don't use [Docker]-wrapped commands, make sure that tools you're using have the same version as in [Docker]-wrapped commands.




## Prerequisites

See ["Get started" Flutter guide][1] to set up [Flutter] development toolchain.

Use `doctor` utility to run [Flutter] self-diagnosis and show information about the installed tooling:
```bash
flutter doctor     # simple output
flutter doctor -v  # verbose output
```




## Operations

Take a look at [`Makefile`] for command usage details.


### Local development

To run the application use the following [`Makefile`] command:
```bash
make run                # in debug mode on a default device
make run debug=no       # in release mode on a default device
make run device=chrome  # in debug mode on Chrome (web) target
```


### Building

To build/rebuild project use the following [`Makefile`] command:
```bash
make build platform=apk
make build platform=apk dockerized=yes  # Docker-wrapped
```


### Linting

To perform a static analysis of [Dart] sources use the following [`Makefile`] command:
```bash
make lint
make lint dockerized=yes  # Docker-wrapped
```


### Formatting

To auto-format [Dart] sources use the following [`Makefile`] command:
```bash
make fmt
make fmt check=yes       # report error instead of making changes in-place
make fmt dockerized=yes  # Docker-wrapped
```


### Testing

To run unit tests use the following [`Makefile`] command:
```bash
make test.unit
make test.unit dockerized=yes  # Docker-wrapped
```


### Documentation

To generate project documentation use the following [`Makefile`] command:
```bash
make docs
make docs open=yes        # open using `dhttpd`
make docs dockerized=yes  # Docker-wrapped
```
  
In order for `open=yes` to work you need to activate `dhttpd` before running the command:
```bash
flutter pub activate global dhttpd
```

__Note:__ Changing the deployment environment from `dockerized=yes` to local machine and vice versa requires re-running `make deps` since `dartdoc` doesn't do it on its own.


### Cleaning

To reset project and clean up it from temporary and generated files use the following [`Makefile`] command:
```bash
make clean
make clean dockerized=yes  # Docker-wrapped
```




## Structure overview

Project uses [`GetX`] package for navigation, state management, l10n and much more. So, it's required to become familiar with [`GetX`] first.


### Domain layer

```
- domain
    - model
        - ...
        - user.dart
    - repository
        - ...
        - user.dart
    - service
        - ...
        - auth.dart
- provider
    - ...
    - graphql.dart
- store
    - ...
    - user.dart
```
  
_Providers_ are stateful classes that work directly with the external resources and fetch/push some raw data.

_Repositories_ are classes that mediate the communication between our controllers/services and our data. `domain/repository/` directory contains interfaces for our repositories and their implementations are located in the `store/` directory.
  
_Services_ are stateful classes that implement functionality that is not bound to concrete UI component or domain entity and can be used by UI controllers or other services.  


### UI (user interface) layer

```
- ui
    - page
        - ...
            - controller.dart
            - view.dart
    - widget
        - ...
```
  
UI is separated to pages. Each page has its own UI component consisting of a `View` and its `Controller`. It may also contain a set of other UI components that are specific to this page __only__.
  
`Controller` is a [`GetxController`] sub-class containing a state of the specific `View`. It may have access to the domain layer via repositories or services.
  
`View` is a [`StatelessWidget`] rendering the `Controller`'s state and with access to its methods.


### Routing

Application uses custom [`Router`] routing.  
  
Application has nested `Router`s (e.g. one in the [`GetMaterialApp`] and one nested on the `Home` page). So, a newly added page should be placed correspondingly in the proper `Router`.


### l10n (localization)

Application uses [Fluent] localization that is placed under `assets/l10n/` directory. Any newly added `.ftl` file should be named with a [valid Unicode BCP47 Locale Identifier][2] (i.e. `en-US`, `ru-RU`, etc).

Adding a new language means:
1. Adding language's dictionary as a new `.ftl` file to `assets/l10n/` directory.
2. Adding language to the `languages` mapping.
  
Using localization is as easy as adding `.l10n` or `.l10nfmt(...)` to the string literal:
```dart
Text('Hello, world'.l10n);
Text('Hello, world'.l10nfmt(arguments));
```




## Code style

All [Dart] source code must follow [Effective Dart] official recommendations, and the project sources must be formatted with [dartfmt].

Any rules described here are in priority if they have conflicts with [Effective Dart] recommendations.


### Documentation

__DO__ document your code. Documentation must follow [Effective Dart] official recommendations with the following exception:
- prefer omitting leading `A`, `An` or `The` article.


### Imports inside `/lib` directory

__DO__ use absolute or relative imports within `/lib` directory.

#### 🚫 Wrong
```dart
import '../../../../ui/widget/animated_button.dart'; // Too deep.
import 'package:messenger/ui/widget/modal_popup.dart'; // `package:` import.
```

#### 👍 Correct
```dart
import '../animated_button.dart';
import '/ui/widget/modal_popup.dart';
import 'home/page/widget/animated_button.dart';
import 'widget/animated_button.dart';
```


### Imports grouping and sorting

__Do__ group Dart imports in the stated groups:
1. Dart imports (`dart:io`, `dart:async`, etc).
2. `package:` imports (`package:get`, `package:flutter`, `package:messenger`, etc).
3. Relative imports (`/lib/util/platform_utils.dart`, `../controller.dart`).

__Do__ sort imports within single group alphabetically.

#### 🚫 Wrong
```dart
import '/lib/util/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller.dart';

import 'dart:io';
import 'dart:async';
```

#### 👍 Correct
```dart
import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../controller.dart';
import '/lib/util/platform_utils.dart';
```


### Classes, constructors, fields and methods ordering

__DO__ place constructors first in class, as stated in [Flutter style guidelines][3]:

> This helps readers determine whether the class has a default implied constructor or not at a glance. If it was possible for a constructor to be anywhere in the class, then the reader would have to examine every line of the class to determine whether or not there was an implicit constructor or not.

The methods, fields, getters, etc should sustain a consistent ordering to help read and understand code fluently. First rule is public first: when reading code someone else wrote, you usually interested in API you're working with: public classes, fields, methods, etc. Private counterparts are consider implementation-specific and should be moved lower in a file. Second rule is a recommendation towards ordering of constructors, methods, fields, etc, inside a class. The following order is suggested (notice the public/private rule being applied as well):
1. Default constructor
2. Named/other constructors
3. Public fields
4. Private fields
5. Public getters/setters
6. Private getters/setters
7. Public methods
8. Private methods

#### 🚫 Wrong
```dart
class _ChatWatcher {
    // ...
}

class Chat {
    final ChatId id;
    final ChatKind kind;

    final Map<UserId, _ChatWatcher> _reads = {};

    Chat.monolog(this.id) : kind = ChatKind.monolog;
    Chat.dialog(this.id) : kind = ChatKind.dialog;
    Chat.group(this.id) : kind = ChatKind.group;
    Chat(this.id, this.kind);

    void _ensureWatcher(UserId userId) {
        // ...
    }
    
    void dispose() {
        // ...
    }

    bool isReadBy(UserId userId) {
        // ...
    }

    bool get isMonolog => kind == ChatKind.monolog;
    bool get isDialog => kind == ChatKind.dialog;
    bool get isGroup => kind == ChatKind.group;
}

class ChatId {
    // ...
}

enum ChatKind {
    monolog,
    dialog,
    group,
}
```

#### 👍 Correct
```dart
enum ChatKind {
    monolog,
    dialog,
    group,
}

class Chat {
    Chat(this.id, this.kind);

    Chat.monolog(this.id) : kind = ChatKind.monolog;
    Chat.dialog(this.id) : kind = ChatKind.dialog;
    Chat.group(this.id) : kind = ChatKind.group;

    final ChatId id;
    final ChatKind kind;

    final Map<UserId, _ChatWatcher> _reads = {};

    bool get isMonolog => kind == ChatKind.monolog;
    bool get isDialog => kind == ChatKind.dialog;
    bool get isGroup => kind == ChatKind.group;

    void dispose() {
        // ...
    }

    bool isReadBy(UserId userId) {
        // ...
    }

    void _ensureWatcher(UserId userId) {
        // ...
    }
}

class ChatId {
    // ...
}

class _ChatWatcher {
    // ...
}
```


### Explicit dependencies injection

__DO__ pass all the dependencies of your class/service/etc needs via its constructor.

#### 🚫 Wrong
```dart
class AuthService {
    AuthService();

    GraphQlProvider? graphQlProvider;
    StorageProvider? storageProvider;
    //...
    
    void onInit() {
        super.onInit();
        // or in any other place that is not CTOR
        graphQlProvider = Get.find();
        storageProvider = Get.find();
    }
}
```
  
#### 👍 Correct
```dart
class AuthService {
    AuthService(this.graphQlProvider, this.storageProvider//, ...);

    GraphQlProvider graphQlProvider;
    StorageProvider storageProvider;
    // ...
}
```


### Explicit types

__Do__ specify types explicitly to increase code readability and strictness.

#### 🚫 Wrong
```dart
var authService = Get.find();
var counter = 0.obs;
var user = User().obs;
queryUsers() { 
    // ...
    return Map<...>;
}
```

#### 👍 Correct
```dart
AuthService authService = Get.find();
RxInt counter = RxInt(0);
Rx<User> user = Rx<User>(User());
Map<...> queryUsers() { 
    // ...
    return Map<...>;
}
```


### Type safety via new types

__PREFER__ using [New Type Idiom](https://doc.rust-lang.org/rust-by-example/generics/new_types.html) to increase type safety and to have more granular decomposition.

#### 🚫 Bad
```dart
class User {
    String id;
    String? username;
    String? email;
    String? bio;
}
```

#### 👍 Good
```dart
class User {
    UserId id;
    UserName? username;
    UserEmail? email;
    UserBio? bio;
}

class UserId {
    UserId(this.value);
    final String value;
}

class UserName {
    UserName(this.value);
    final String value;
}

class UserEmail {
    UserEmail(this.value);
    final String value;
}

class UserBio {
    UserBio(this.value);
    final String value;
}
```


### Fluent keys alphabetical sorting

__Do__ sort Fluent keys in `.ftl` files alphabetically.

#### 🚫 Wrong
```ftl
label_work_with_us_desc =
    Work
    with us
err_account_not_found = Indicated account is not found
label_hidden = Last seen recently
btn_call_audio_on = Unmute
```

#### 👍 Correct
```ftl
btn_call_audio_on = Unmute
err_account_not_found = Indicated account is not found
label_hidden = Last seen recently
label_work_with_us_desc =
    Work
    with us
```




## Backend connectivity

### Local development

Development [GraphQL] API playground is available [here][4].

In order to connect to the development backend [GraphQL] endpoint, you should either use the following `--dart-define`s:

```bash
--dart-define=SOCAPP_HTTP_URL=https://messenger.soc.stg.t11913.org
--dart-define=SOCAPP_WS_URL=wss://messenger.soc.stg.t11913.org
--dart-define=SOCAPP_HTTP_PORT=443
--dart-define=SOCAPP_WS_PORT=443
--dart-define=SOCAPP_CONF_REMOTE=false
```

__Or__ pass the following configuration to `assets/conf.toml`:

```toml
[conf]
remote = false

[server.http]
url = "https://messenger.soc.stg.t11913.org"
port = 443

[server.ws]
url = "wss://messenger.soc.stg.t11913.org"
port = 443
```

__Note__, that you may pass `--dart-define`s to `make e2e`, `make build` or `make run` commands by specifying the `dart-env` parameter (see [`Makefile`] for usage details).




[Dart]: https://dart.dev
[dartfmt]: https://dart.dev/tools/dart-format
[Docker]: https://www.docker.com
[Effective Dart]: https://dart.dev/guides/language/effective-dart
[Fluent]: https://projectfluent.org
[Flutter]: https://flutter.dev
[GraphQL]: https://graphql.org

[`GetMaterialApp`]:https://pub.dev/documentation/get_navigation/latest/get_navigation/GetMaterialApp-class.html
[`GetX`]: https://pub.dev/packages/get
[`GetxController`]: https://pub.dev/documentation/get_state_manager/latest/get_state_manager/GetxController-class.html
[`Makefile`]: Makefile
[`Router`]: https://api.flutter.dev/flutter/widgets/Router-class.html
[`StatelessWidget`]: https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html

[1]: https://flutter.dev/docs/get-started/install
[2]: https://api.flutter.dev/flutter/dart-ui/Locale/toLanguageTag.html
[3]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#constructors-come-first-in-a-class
[4]: https://messenger.soc.stg.t11913.org/api/graphql/v1/graphiql
