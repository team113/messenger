Contribution Guide
==================

1. [Requirements](#requirements)
2. [Prerequisites](#prerequisites)
3. [Operations](#operations)
4. [Structure overview](#structure-overview)
5. [Code style](#code-style)




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

Application uses [Fluent] localization that is placed under `l10n/` directory. Any newly added language should be named as a `languagecode-COUNTRYCODE` locale (i.e. `en-US`, `ru-RU`, etc).

Adding a new language means:
1. Adding language's dictionary as a new `.ftl` file in `assets/l10n` folder.
2. Adding language to the `languages` mapping.
  
Using l10n is as easy as adding `.td` or `.tdp(...)` to the string literal:
```dart
Text('Hello, world'.td);
Text('Hello, world'.tdp(arguments));
```




## Code style

All [Dart] source code must follow [Effective Dart] official recommendations, and the project sources must be formatted with [dartfmt].

Any rules described here are in priority if they have conflicts with [Effective Dart] recommendations.


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


### Explicit reactive variable creation

Do __NOT__ use shorthand `.obs` syntax when creating rx (reactive) variables.

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




[Dart]: https://dart.dev
[dartfmt]: https://dart.dev/tools/dart-format
[Docker]: https://www.docker.com
[Effective Dart]: https://dart.dev/guides/language/effective-dart
[Fluent]: https://projectfluent.org/
[Flutter]: https://flutter.dev

[`GetMaterialApp`]:https://pub.dev/documentation/get_navigation/latest/get_navigation/GetMaterialApp-class.html
[`GetX`]: https://pub.dev/packages/get
[`GetxController`]: https://pub.dev/documentation/get_state_manager/latest/get_state_manager/GetxController-class.html
[`Makefile`]: Makefile
[`Router`]: https://api.flutter.dev/flutter/widgets/Router-class.html
[`StatelessWidget`]: https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html

[1]: https://flutter.dev/docs/get-started/install
