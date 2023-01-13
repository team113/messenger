import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';

import '/ui/widget/text_field.dart';

class ChatItemReadsController extends GetxController {
  ChatItemReadsController({this.reads = const [], this.getUser});

  /// [LastChatRead]s themselves.
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  final TextFieldState search = TextFieldState();

  final RxnString query = RxnString(null);
  final RxList<RxUser> users = RxList();

  @override
  void onInit() {
    init();
    super.onInit();
  }

  Future<void> init() async {
    // for (var v in reads) {
    //   RxUser? user = await getUser?.call(v.memberId);
    //   print('user $user');
    //   if (user != null) {
    //     users.add(user);
    //   }
    // }

    List<Future> futures = reads
        .map((e) => getUser?.call(e.memberId)?..then((v) => users.add(v!)))
        .whereNotNull()
        .toList();

    await Future.wait(futures);
  }
}
