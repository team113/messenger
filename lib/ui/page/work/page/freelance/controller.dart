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

import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UseChatDirectLinkException;
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Controller of the [WorkTab.freelance] section of [Routes.work] page.
class FreelanceWorkController extends GetxController {
  FreelanceWorkController(this._authService);

  /// [RxStatus] of the [useLink] being invoked.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning [useLink] isn't in progress.
  /// - `status.isLoading`, meaning [useLink] is fetching its data.
  final Rx<RxStatus> linkStatus = Rx(RxStatus.empty());

  /// [Issue]s to display.
  final RxList<Issue> issues = RxList();

  /// Status of the [issues] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning [issues] are not fetched.
  /// - `status.isLoading`, meaning [issues] are being fetched.
  /// - `status.isSuccess`, meaning [issues] are fetched.
  final Rx<RxStatus> issuesStatus = Rx(RxStatus.empty());

  /// Index of an [Issue] expanded from the [issues] list.
  final RxnInt expanded = RxnInt();

  /// [AuthService] for using the [_link].
  final AuthService _authService;

  /// [ChatDirectLinkSlug] to use in the [useLink].
  static const ChatDirectLinkSlug _link =
      ChatDirectLinkSlug.unchecked('freelance');

  // TODO: Remove when backend supports it out of the box.
  /// Welcome message of the [Chat] in the [_link].
  static final ChatMessageText _welcome =
      ChatMessageText('label_welcome_message_freelance'.l10n);

  /// URL to fetch the [Issue]s from.
  ///
  /// Supposed to be a GitHub issues endpoint, however may be any meeting the
  /// following requirements:
  /// - response must be in JSON format;
  /// - response must be a list of objects;
  /// - each object in the list must define `title`, `body`, `html_url` strings
  /// and `number` integer.
  static const String _url =
      'https://api.github.com/repos/team113/messenger/issues?direction=asc&labels=help wanted&assignee=none';

  /// Returns the authorization [RxStatus].
  Rx<RxStatus> get status => _authService.status;

  @override
  void onInit() {
    _initIssues();
    super.onInit();
  }

  /// Uses the [ChatDirectLinkSlug].
  Future<void> useLink({bool? signedUp}) async {
    linkStatus.value = RxStatus.loading();

    try {
      if (status.value.isEmpty) {
        router.home(signedUp: signedUp);
      }

      router.chat(
        await _authService.useChatDirectLink(_link),
        welcome: _welcome,
      );

      linkStatus.value = RxStatus.empty();
    } on UseChatDirectLinkException catch (e) {
      linkStatus.value = RxStatus.empty();
      MessagePopup.error(e.toMessage());
    } catch (e) {
      linkStatus.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Fetches the [issues] from the [_url].
  Future<void> _initIssues() async {
    issuesStatus.value = RxStatus.loading();

    final response = await (await PlatformUtils.dio).get(_url);

    if (response.statusCode == 200) {
      issues.value = (response.data as List<dynamic>).map((e) {
        return Issue(
          title: e['title'],
          description: e['body'],
          url: e['html_url'],
          number: e['number'],
        );
      }).toList();

      issuesStatus.value = RxStatus.success();
    } else {
      issuesStatus.value = RxStatus.error(response.statusMessage);
    }
  }
}

/// Single task to display in [FreelanceWorkView].
class Issue {
  const Issue({
    required this.title,
    this.description,
    this.url = '',
    this.number = 0,
  });

  /// Title of this [Issue].
  final String title;

  /// Description of this [Issue].
  final String? description;

  /// URL to the remote resource representing this [Issue].
  final String url;

  /// Number of this [Issue].
  final int number;
}
