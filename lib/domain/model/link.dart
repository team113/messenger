// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import '/config.dart';
import '/util/new_type.dart';
import 'chat.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'link.g.dart';

/// Direct link to a [Chat].
@JsonSerializable()
class DirectLink implements Comparable<DirectLink> {
  DirectLink({
    required this.slug,
    required this.location,
    this.isEnabled = true,
    required this.createdAt,
    this.visitors = 0,
  });

  /// Constructs a [DirectLink] from the provided [json].
  factory DirectLink.fromJson(Map<String, dynamic> json) =>
      _$DirectLinkFromJson(json);

  /// Unique slug associated with this [DirectLink].
  DirectLinkSlug slug;

  /// Location this [DirectLink] leads to.
  final DirectLinkLocation location;

  /// Indicator whether this [DirectLink] is enabled.
  final bool isEnabled;

  /// [PreciseDateTime] when this [DirectLink] was created.
  PreciseDateTime createdAt;

  /// Count of unique visitors visited the [DirectLink].
  final int visitors;

  @override
  bool operator ==(Object other) =>
      other is DirectLink &&
      slug == other.slug &&
      isEnabled == other.isEnabled &&
      location == other.location &&
      createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(slug, location, isEnabled, createdAt);

  /// Returns a [Map] representing this [DirectLink].
  Map<String, dynamic> toJson() => _$DirectLinkToJson(this);

  @override
  int compareTo(DirectLink other) {
    final at = other.createdAt.compareTo(createdAt);
    if (at != 0) {
      return at;
    }

    return other.slug.val.compareTo(slug.val);
  }
}

/// Possible locations where a [DirectLink] can lead to.
abstract class DirectLinkLocation {
  const DirectLinkLocation();

  /// Constructs a [DirectLinkLocation] from the provided [json].
  factory DirectLinkLocation.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'DirectLinkLocationUser' => DirectLinkLocationUser.fromJson(json),
        'DirectLinkLocationGroup' => DirectLinkLocationGroup.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Returns a [Map] representing this [DirectLinkLocation].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (DirectLinkLocationUser) => (this as DirectLinkLocationUser).toJson(),
    const (DirectLinkLocationGroup) =>
      (this as DirectLinkLocationGroup).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// Location of a [DirectLink] leading to a [Chat]-dialog with some [User].
@JsonSerializable()
class DirectLinkLocationUser extends DirectLinkLocation {
  const DirectLinkLocationUser(this.responder);

  /// Constructs a [DirectLinkLocationUser] from the provided [json].
  factory DirectLinkLocationUser.fromJson(Map<String, dynamic> json) =>
      _$DirectLinkLocationUserFromJson(json);

  /// [User] the [DirectLink] leads to a [Chat]-dialog with.
  final UserId responder;

  @override
  bool operator ==(Object other) =>
      other is DirectLinkLocationUser && responder == other.responder;

  @override
  int get hashCode => responder.hashCode;

  /// Returns a [Map] representing this [DirectLinkLocationUser].
  @override
  Map<String, dynamic> toJson() =>
      _$DirectLinkLocationUserToJson(this)
        ..['runtimeType'] = 'DirectLinkLocationUser';
}

/// Location of a [DirectLink] leading to some [Chat]-group.
@JsonSerializable()
class DirectLinkLocationGroup extends DirectLinkLocation {
  const DirectLinkLocationGroup(this.group);

  /// Constructs a [DirectLinkLocationGroup] from the provided [json].
  factory DirectLinkLocationGroup.fromJson(Map<String, dynamic> json) =>
      _$DirectLinkLocationGroupFromJson(json);

  /// [Chat]-group the [DirectLink] leads to.
  final ChatId group;

  @override
  bool operator ==(Object other) =>
      other is DirectLinkLocationGroup && group == other.group;

  @override
  int get hashCode => group.hashCode;

  /// Returns a [Map] representing this [DirectLinkLocationGroup].
  @override
  Map<String, dynamic> toJson() =>
      _$DirectLinkLocationGroupToJson(this)
        ..['runtimeType'] = 'DirectLinkLocationGroup';
}

/// Slug of a [DirectLink].
class DirectLinkSlug extends NewType<String> {
  const DirectLinkSlug._(super.val);

  DirectLinkSlug(String value) : super(value.trim()) {
    if (val.length > 100) {
      throw const FormatException('Must contain no more than 100 characters');
    } else if (val.isEmpty) {
      throw const FormatException('Must not be empty');
    } else if (!_regExp.hasMatch(val)) {
      throw FormatException('Does not match validation RegExp: `$val`');
    }
  }

  /// Creates an object without any validation.
  const factory DirectLinkSlug.unchecked(String val) = DirectLinkSlug._;

  /// Constructs a [DirectLinkSlug] from the provided [val].
  factory DirectLinkSlug.fromJson(String val) = DirectLinkSlug.unchecked;

  /// Creates a random [DirectLinkSlug] of the provided [length].
  factory DirectLinkSlug.generate([int length = 10]) {
    final Random r = Random();
    const String chars = 'abcdefghijklmnopqrstuvwxyz1234567890_-';

    return DirectLinkSlug(
      List.generate(length, (i) {
        // `-` and `_` being the last or first might not be parsed as a link by
        // some applications.
        if (i == 0 || i == length - 1) {
          final str = chars.replaceFirst('-', '').replaceFirst('_', '');
          return str[r.nextInt(str.length)];
        }

        return chars[r.nextInt(chars.length)];
      }).join(),
    );
  }

  /// Regular expression for basic [DirectLinkSlug] validation.
  static final RegExp _regExp = RegExp(r'^[A-Za-z0-9_-]{1,100}$');

  /// Parses the provided [val] as a [DirectLinkSlug], if [val] meets the
  /// validation, or returns `null` otherwise.
  ///
  /// If [val] starts with [Config.link], then that part is omitted.
  static DirectLinkSlug? tryParse(String val) {
    if (val.startsWith(Config.link)) {
      val = val.substring(Config.link.length);
    }

    if (val.startsWith(Config.origin)) {
      val = val.substring(Config.origin.length);
    }

    if (val.startsWith('https://')) {
      val = val.substring('https://'.length);
    }

    if (val.startsWith('http://')) {
      val = val.substring('http://'.length);
    }

    if (val.startsWith(Config.link)) {
      val = val.substring(Config.link.length);
    }

    if (val.startsWith(Config.origin)) {
      val = val.substring(Config.origin.length);
    }

    if (val.startsWith('/')) {
      val = val.substring(1);
    }

    try {
      return DirectLinkSlug(val);
    } catch (_) {
      return null;
    }
  }

  /// Returns a [String] representing this [DirectLinkSlug].
  String toJson() => val;
}
