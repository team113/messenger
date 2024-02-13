import 'package:get/get.dart';
import 'package:messenger/ui/widget/text_field.dart';

class SetPriceController extends GetxController {
  SetPriceController({
    String? initialValue,
  }) {
    value = TextFieldState(text: initialValue ?? '0');
  }

  late final TextFieldState value;
}
