import 'package:get/get.dart';
import 'package:messenger/ui/widget/text_field.dart';

class SetPriceController extends GetxController {
  SetPriceController({
    String? initialCalls,
    String? initialMessages,
  }) {
    calls = TextFieldState(text: initialCalls ?? '0');
    messages = TextFieldState(text: initialMessages ?? '0');
  }

  late final TextFieldState calls;
  late final TextFieldState messages;
}
