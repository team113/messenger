import '../store/event/my_user.dart';

class EventPool {
  void add(MyUserEvent event) {}
  bool ignore(MyUserEvent event) {
    return DisplaceEventType.fromKind(event.kind) != null;
  }
}

enum DisplaceEventType {
  myUserToggleMute;

  static DisplaceEventType? fromKind(dynamic kind) {
    if (kind is MyUserEventKind) {
      return switch (kind) {
        MyUserEventKind.userMuted => myUserToggleMute,
        MyUserEventKind.unmuted => myUserToggleMute,
        _ => null,
      };
    }
    return null;
  }
}
