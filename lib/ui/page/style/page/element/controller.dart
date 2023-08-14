import 'package:get/get.dart';

import '../../../../widget/text_field.dart';

class ElementsController extends GetxController {
  /// [MyUser.name]'s field state.
  late final TextFieldState name;

  /// [MyUser.name]'s field state.
  late final TextFieldState typing;

  /// [MyUser.name]'s field state.
  late final TextFieldState loading;

  /// [MyUser.name]'s field state.
  late final TextFieldState success;

  /// [MyUser.name]'s field state.
  late final TextFieldState error;

  @override
  void onInit() {
    loading = TextFieldState(
      text: 'Benedict Cumberbatch',
      editable: false,
      status: RxStatus.loading(),
    );

    typing = TextFieldState(text: 'Benedict Cumberba');

    success = TextFieldState(
      text: 'Benedict Cumberbatch',
      status: RxStatus.success(),
    );

    error = TextFieldState(
      text: 'Benedict C@c@mber',
      status: RxStatus.error(),
      onChanged: (s) => s.error.value = 'Incorrect input',
      onSubmitted: (s) => s.error.value = 'Incorrect input',
    );

    name = TextFieldState(
      text: 'Benedict Cumberbatch',
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;
      },
      onSubmitted: (s) async {
        s.error.value = null;

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );
    super.onInit();
  }
}
