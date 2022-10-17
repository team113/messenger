import 'package:hive/hive.dart';

import 'precise_date_time.dart';

/// Adapter for hive of [PreciseDateTime].
class PreciseDateTimeAdapter extends TypeAdapter<PreciseDateTime> {
  @override
  final typeId = 73;

  @override
  PreciseDateTime read(BinaryReader reader) => PreciseDateTime(
        DateTime.fromMicrosecondsSinceEpoch(
          reader.readInt(),
        ),
      );

  @override
  void write(BinaryWriter writer, PreciseDateTime obj) =>
      writer.writeInt(obj.microsecondsSinceEpoch);
}
