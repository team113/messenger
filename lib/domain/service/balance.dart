import 'package:get/get.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:uuid/uuid.dart';

import '../../util/log.dart';
import '/domain/repository/user.dart';
import '/domain/model/user.dart';

class BalanceService extends DisposableInterface {
  final RxDouble balance = RxDouble(0);
  final RxDouble hold = RxDouble(0);

  final RxList<Transaction> transactions = RxList(
    [
      Transaction(
        amount: -100,
        status: TransactionStatus.canceled,
        // reason: 'Suspicious activity',
        description: 'Withdraw to: PayPal\n'
            'Cancel reason: suspicious activity',
        at: DateTime.now()
            .subtract(const Duration(hours: 1))
            .copyWith(minute: 01),
      ),
      Transaction(
        amount: 1424,
        status: TransactionStatus.hold,
        by: UserNum('1234123412341234').toString(),
        description: 'Донат 4214',
        at: DateTime.now()
            .subtract(const Duration(hours: 2))
            .copyWith(minute: 48),
      ),
      Transaction(
        amount: 100,
        by: UserNum('1234123412341234').toString(),
        description: 'Платное сообщение 555',
        at: DateTime.now()
            .subtract(const Duration(hours: 5))
            .copyWith(minute: 14),
      ),
      Transaction(
        amount: -97,
        description: 'PayPal',
        at: DateTime.now()
            .subtract(const Duration(hours: 5))
            .copyWith(hour: 12, minute: 48),
      ),
      Transaction(
        amount: 2,
        by: 'Друг 15',
        at: DateTime.now()
            .subtract(const Duration(days: 1))
            .copyWith(hour: 23, minute: 26),
      ),
      Transaction(
        amount: -5,
        by: 'Вася Пупкин',
        at: DateTime.now()
            .subtract(const Duration(days: 7))
            .copyWith(hour: 3, minute: 9),
      ),
      Transaction(
        amount: -5,
        description: 'Withdraw to: PayPal',
        at: DateTime.now()
            .subtract(const Duration(days: 7))
            .copyWith(hour: 3, minute: 9),
      ),
      Transaction(
        amount: 100,
        by: UserNum('1234 1234 1234 1234').toString(),
        description: 'Трансляция 12341234',
        at: DateTime(2023),
      ),
    ],
  );

  final Rx<PricePreferences> all = Rx(PricePreferences());
  final Rx<PricePreferences> contacts = Rx(PricePreferences());
  final RxMap<UserId, Rx<PricePreferences>> individual = RxMap();

  final Map<UserId, Rx<PricePreferences>> monetizations = {};

  final RxBool verified = RxBool(false);
  final Rx<VerifiedPerson?> person = Rx(null);

  final RxnString services = RxnString();

  @override
  void onInit() {
    _recalculate();
    super.onInit();
  }

  void add(double amount) {
    transactions.add(Transaction(amount: amount, description: 'Given'));
    _recalculate();
  }

  void take(double amount) {
    transactions.add(Transaction(amount: -amount, description: 'Taken'));
    _recalculate();
  }

  void setAll({int? calls, int? messages}) {
    Log.info('setAll(calls: $calls, messages: $messages)', '$runtimeType');

    if (calls == null && messages == null) {
      all.value = PricePreferences();
    } else {
      all.value.calls = calls ?? all.value.calls;
      all.value.messages = messages ?? all.value.messages;
    }
  }

  void setContacts({int? calls, int? messages}) {
    Log.info('setContacts(calls: $calls, messages: $messages)', '$runtimeType');

    if (calls == null && messages == null) {
      contacts.value = PricePreferences();
    } else {
      contacts.value.calls = calls ?? contacts.value.calls;
      contacts.value.messages = messages ?? contacts.value.messages;
    }
  }

  void setIndividual(UserId id, {int? calls, int? messages}) {
    Log.info(
      'setIndividual($id, calls: $calls, messages: $messages)',
      '$runtimeType',
    );

    if ((calls == null && messages == null) ||
        (all.value.areZero && calls == 0 && messages == 0)) {
      individual.remove(id);
      return;
    }

    final existing = individual[id];
    if (existing != null) {
      existing.value.calls = calls ?? existing.value.calls;
      existing.value.messages = messages ?? existing.value.messages;
      existing.refresh();
    } else {
      individual[id] = Rx(
        PricePreferences(calls: calls ?? 0, messages: messages ?? 0),
      );
    }
  }

  void emulateMonetization(UserId id, PricePreferences? prefs) {
    Log.debug('emulateMonetization($id, $prefs)', '$runtimeType');

    if (prefs == null) {
      monetizations[id]?.value = PricePreferences();
    } else {
      final existing = monetizations[id];
      if (existing != null) {
        existing.value.calls = prefs.calls;
        existing.value.messages = prefs.messages;
        existing.refresh();
      } else {
        monetizations[id] = Rx(prefs);
      }
    }
  }

  Rx<PricePreferences> getMonetization(UserId id) {
    Rx<PricePreferences>? existing = monetizations[id];
    if (existing == null) {
      existing = Rx(PricePreferences());
      monetizations[id] = existing;
    }

    return existing;
  }

  Rx<PricePreferences>? resolvePriceFor(RxUser user) {
    final custom = individual[user.id];
    if (custom != null) {
      return custom;
    }

    if (user.contact.value != null) {
      return contacts;
    }

    return all;
    // return all.value.areZero ? null : all;
  }

  void _recalculate() {
    balance.value = transactions.fold(0, (a, b) {
      if (b.status != TransactionStatus.done) {
        return a;
      }

      return a + b.amount;
    });

    hold.value = transactions.fold(0, (a, b) {
      if (b.status != TransactionStatus.hold) {
        return a;
      }

      return a + b.amount;
    });
  }
}

class Transaction {
  Transaction({
    String? id,
    this.description,
    this.by,
    this.reason,
    this.amount = 0,
    DateTime? at,
    this.status = TransactionStatus.done,
  })  : id = id ?? const Uuid().v4(),
        at = at ?? DateTime.now();

  final String id;
  final String? description;
  final String? by;
  final String? reason;
  final double amount;
  final DateTime at;
  final TransactionStatus status;
}

enum TransactionStatus {
  hold,
  canceled,
  done,
}

class PricePreferences {
  PricePreferences({this.messages = 0, this.calls = 0});

  int messages;
  int calls;

  bool get areZero => messages == 0 && calls == 0;

  @override
  String toString() => 'PricePreferences(messages: $messages, calls: $calls)';
}

class VerifiedPerson {
  VerifiedPerson({
    required this.name,
    required this.address,
    required this.index,
    required this.phone,
    this.country,
    this.birthday,
    this.passport,
  });

  final String name;
  final String address;
  final String index;
  final String phone;
  final Country? country;
  final DateTime? birthday;
  final NativeFile? passport;

  VerifiedPerson copyWith() {
    return VerifiedPerson(
      name: name,
      address: address,
      index: index,
      phone: phone,
      country: country,
      birthday: birthday,
      passport: passport,
    );
  }
}
