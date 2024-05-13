import 'package:drift/drift.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';

class PreciseDateTimeConverter extends TypeConverter<PreciseDateTime, int> {
  const PreciseDateTimeConverter();

  @override
  PreciseDateTime fromSql(int fromDb) {
    return PreciseDateTime.fromMicrosecondsSinceEpoch(fromDb);
  }

  @override
  int toSql(PreciseDateTime value) {
    return value.microsecondsSinceEpoch;
  }
}
