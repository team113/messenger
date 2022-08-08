import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/domain/model/ongoing_call.dart';

abstract class Track {
  /// [RtcRenderer] of this [Track], if any.
  Rx<RtcRenderer?> renderer = Rx(null);

  /// [TrackMediaDirection] this [Track] has.
  Rx<TrackMediaDirection> direction = Rx(TrackMediaDirection.SendRecv);

  /// Indicator whether this [Track] is muted.
  RxBool isMuted = RxBool(false);

  void addTrack();
  void createRenderer(); // creates the renderer
  void removeRenderer(); // deletes the renderer
  void dispose() {} // disposes the track
}

class RemoteTrack extends Track {
  RemoteMediaTrack track;

  void createRenderer() {}
  void removeRenderer() {}
  void dispose() {}
}

class LocalTrack extends Track {
  LocalMediaTrack track;

  void createRenderer() {}
  void removeRenderer() {}
  void dispose() {}
}

/// Member = Connection
class CallMember {
  RemoteMemberId? id; // `null` == local?

  RxList<Track> tracks = RxList();

  /// Indicator whether this [CallMember] is connected to the media room.
  RxBool connected = RxBool(false);

  RxBool isHandRaised = RxBool(false);
}

class Call {
  RxList<CallMember> members = RxList();
}
