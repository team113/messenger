// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:xml/xml.dart';

import '/config.dart';
import '/domain/service/disposable_service.dart';
import '/l10n/l10n.dart';
import '/provider/hive/skipped_version.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/ui/widget/upgrade_popup/view.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';

/// Worker fetching [Config.appcast] file and prompting [UpgradePopupView] on
/// new [Release]s available.
class UpgradeWorker extends DisposableService {
  UpgradeWorker(this._skippedLocal);

  /// [SkippedVersionHiveProvider] for maintaining the skipped [Release]s.
  final SkippedVersionHiveProvider? _skippedLocal;

  /// [Duration] to display the [UpgradePopupView] after, when [_schedulePopup]
  /// is triggered.
  static const Duration _popupDelay = Duration(seconds: 1);

  @override
  void onReady() {
    Log.debug('onReady()', '$runtimeType');

    // Web gets its updates out of the box with a simple page refresh.
    if (!PlatformUtils.isWeb) {
      _fetchUpdates();
    }

    super.onReady();
  }

  /// Skips the [release], meaning no popups will be prompted for this one.
  Future<void> skip(Release release) async {
    Log.debug('skip($release)', '$runtimeType');
    await _skippedLocal?.set(release.name);
  }

  /// Fetches the [Config.appcast] file to [_schedulePopup], if new [Release] is
  /// detected.
  Future<void> _fetchUpdates() async {
    Log.debug('_fetchUpdates()', '$runtimeType');

    if (Config.appcast.isEmpty) {
      return;
    }

    try {
      final response = await (await PlatformUtils.dio).get(Config.appcast);

      if (response.statusCode != 200 || response.data == null) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'Status code ${response.statusCode}',
        );
      }

      final XmlDocument document = XmlDocument.parse(response.data);
      final XmlElement? rss = document.findElements('rss').firstOrNull;
      final XmlElement? channel = rss?.findElements('channel').firstOrNull;

      if (channel != null) {
        final Iterable<XmlElement> items = channel.findElements('item');

        if (items.isNotEmpty) {
          final Release release =
              Release.fromXml(items.first, language: L10n.chosen.value);

          Log.debug(
            'Comparing `${release.name}` to `${Pubspec.ref}`',
            '$runtimeType',
          );

          Version? ours;
          try {
            ours = Version.parse(Pubspec.ref ?? '');
          } catch (e) {
            // No-op.
          }

          Version? their;
          try {
            their = Version.parse(release.name);
          } catch (e) {
            // No-op.
          }

          final bool critical = ours?.isCritical(their) ?? false;
          print('ours: $ours vs their: $their, critical: $critical');
          final bool skipped =
              !critical && _skippedLocal?.get() == release.name;
          if (release.name != Pubspec.ref && !skipped) {
            _schedulePopup(release, critical: critical);
          }
        }
      }
    } catch (e) {
      Log.info('Failed to fetch releases: $e', '$runtimeType');
    }
  }

  /// Schedules an [UpgradePopupView] prompt displaying.
  void _schedulePopup(Release release, {bool critical = false}) {
    Log.debug('_schedulePopup($release)', '$runtimeType');

    Future.delayed(_popupDelay, () {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        await UpgradePopupView.show(
          router.context!,
          release: release,
          critical: critical,
        );
      });
    });
  }
}

/// Application release information.
class Release {
  const Release({
    required this.name,
    required this.description,
    required this.publishedAt,
    required this.assets,
  });

  /// Constructs a [Release] from the provided [XmlElement].
  ///
  /// If [xml] contains language attributes specified for `description`, then
  /// this will try to use the [language] specified (or English, if `null`).
  factory Release.fromXml(XmlElement xml, {Language? language}) {
    language ??= L10n.languages.first;

    String title = xml.findElements('title').first.innerText;

    // Omit the leading `v` of the release version, if any.
    if (title.startsWith('v')) {
      title = title.substring(1);
    }

    final String? description = xml
            .findElements('description')
            .firstWhereOrNull(
              (e) => e.attributes.any(
                (p) =>
                    p.name.qualified == 'xml:lang' &&
                    p.value == language?.locale.languageCode,
              ),
            )
            ?.innerText ??
        xml.findElements('description').firstOrNull?.innerText;
    final String date = xml.findElements('pubDate').first.innerText;
    final List<ReleaseArtifact> assets = xml
        .findElements('enclosure')
        .map((e) => ReleaseArtifact.fromXml(e))
        .toList();

    return Release(
      name: title,
      description: (description?.isEmpty ?? true) ? null : description,
      publishedAt: Rfc822ToDateTime.tryParse(date) ?? DateTime.now(),
      assets: assets,
    );
  }

  /// Title of this [Release] (usually a version).
  final String name;

  /// Release notes of this [Release].
  final String? description;

  /// [DateTime] when this [Release] was published.
  final DateTime publishedAt;

  /// [ReleaseArtifact] attached to this [Release].
  final List<ReleaseArtifact> assets;

  @override
  String toString() {
    return 'Release(name: $name, description: $description, publishedAt: $publishedAt, assets: $assets)';
  }
}

/// Artifact of the [Release].
class ReleaseArtifact {
  const ReleaseArtifact({required this.url, required this.os});

  /// Constructs a [ReleaseArtifact] from the provided [xml].
  factory ReleaseArtifact.fromXml(XmlElement xml) {
    final String url = xml.getAttribute('url')!;
    final String os = xml.getAttribute('sparkle:os')!;

    return ReleaseArtifact(url: url, os: os);
  }

  /// URL of the binary this [ReleaseArtifact] is about.
  final String url;

  /// Operating system this [ReleaseArtifact] is for.
  final String os;

  @override
  String toString() => 'ReleaseArtifact(url: $url, os: $os)';
}

/// Extension adding parsing of RFC-822 date format to [DateTime].
extension Rfc822ToDateTime on DateTime {
  /// Month abbreviations to their respective numbers.
  static const Map<String, String> _months = {
    'Jan': '01',
    'Feb': '02',
    'Mar': '03',
    'Apr': '04',
    'May': '05',
    'Jun': '06',
    'Jul': '07',
    'Aug': '08',
    'Sep': '09',
    'Oct': '10',
    'Nov': '11',
    'Dec': '12',
  };

  /// Possible days of the week.
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Tries parsing the [input] being a RFC-822 date to the [DateTime].
  ///
  /// If fails to do so, then returns `null`.
  ///
  /// Examples of the valid [input]s:
  /// - `Wed, 20 Mar 2024 12:00:03 +0300`
  /// - `Sun, 1 Jun 2024 15:10:51 +0000`
  /// - `Tue, 5 Dec 2000 01:02:03 GMT`
  /// - `1 Sep 2007 23:23:59 +0100`
  static DateTime? tryParse(String input) {
    // Replace the possible GMT to the +0000.
    input = input.replaceFirst('GMT', '+0000');

    final List<String> splits = input.split(' ');

    // Completely ignore the day of the week part.
    final int i = _days.any((e) => splits[0].startsWith(e)) ? 1 : 0;

    final String day = splits[i].padLeft(2, '0');
    final String? month = _months[splits[i + 1]];
    if (month == null) {
      return null;
    }

    final String year = splits[i + 2];
    final String time = splits[i + 3];
    final String zone = splits.elementAtOrNull(i + 4) ?? '+0000';

    return DateTime.tryParse('$year-$month-$day $time $zone');
  }
}

/// Extension adding ability to determine critical [Version]s, meaning the ones
/// user can't skip.
extension CriticalVersionExtension on Version {
  /// Indicates whether this [Version] is considered critical compared to the
  /// [other], meaning the one user can't skip.
  ///
  /// Algorithm determining whether the [other] is consider critical follows the
  /// rules, which is easier to demonstrate with the following examples:
  /// - `0.1.0` -> `0.1.1` => `false`;
  /// - `0.1.0` -> `0.2.0` => `true`;
  /// - `0.1.0` -> `1.0.0` => `true`;
  /// - `1.0.0` -> `1.0.1` => `false`;
  /// - `1.0.0` -> `1.1.0` => `false`.
  ///
  /// And the suffixes:
  /// - `0.1.0-alpha` -> `0.1.0` => `true`;
  /// - `0.1.0-alpha` -> `0.1.0.alpha.1` => `true`;
  /// - `0.1.0-alpha.1` -> `0.1.0.alpha.2` => `true`;
  /// - `0.1.0-alpha.2` -> `0.1.0.alpha.2.1` => `false`;
  /// - `0.1.0-alpha.3` -> `0.1.0.beta.1` => `true`;
  /// - `0.1.0` -> `0.2.0-rc` => `false`;
  /// - `0.1.0` -> `1.0.0-beta` => `false`;
  /// - `1.0.0-beta` -> `1.0.0-rc` => `true`.
  bool isCritical(Version? other) {
    if (other == null) {
      return false;
    }

    // If ours version is higher than the [other], then this isn't a critical
    // release.
    if (this > other) {
      return false;
    }

    // First of all, compare pre-releases.
    //
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) {
      // If the compared version is a pre-release and ours isn't, then the
      // compared is never critical, as we shouldn't update to pre-releases from
      // stable version.
      //
      // Example: `1.0.0` -> `2.0.0-alpha.1` => `false`.
      return false;
    } else if (preRelease.isNotEmpty && other.preRelease.isEmpty) {
      // If our version is a pre-release and the compared one isn't, then the
      // compared is considered critical.
      //
      // Example: `1.0.0-alpha.1` -> `1.0.0` => `true`.
      return true;
    } else if (preRelease.isNotEmpty && other.preRelease.isNotEmpty) {
      // Both versions contain pre-release labels, thus compare their respective
      // major/minor numbers first.
      //
      // Differences in major number are always considered critical.
      //
      // Example: `1.0.0-alpha` -> `2.0.0-alpha` => `true`.
      if (major < other.major) {
        return true;
      }

      if (major == 0) {
        // If major is `0`, then differences in minor number are considered
        // critical.
        //
        // Example: `0.1.0-alpha` -> `0.2.0-alpha` => `true`.
        if (minor < other.minor) {
          return true;
        }
      }

      // If pre-releases are equal to each other, then this isn't a critical
      // release.
      if (const ListEquality().equals(preRelease, other.preRelease)) {
        return false;
      }

      final ourFirst = preRelease.first;
      final theirFirst = other.preRelease.first;

      if (ourFirst is Comparable && theirFirst is Comparable) {
        // First pre-release parts are equal (`alpha` and `alpha`, for example).
        if (ourFirst == theirFirst) {
          final ourSecond = preRelease.elementAtOrNull(1);
          final theirSecond = other.preRelease.elementAtOrNull(1);

          if (ourSecond is Comparable && theirSecond is Comparable) {
            // Second pre-release parts are equal (`1` and `1`, for example).
            if (ourSecond == theirSecond) {
              // If the second parts are equal, then the deeper parts are
              // different, which isn't considered a critical release.
              //
              // Example: `0.1.0-alpha.1` -> `0.1.0-alpha.1.1` => `false`.
              // Example: `0.1.0-alpha.1.1.2` -> `0.1.0-alpha.1.1.3` => `false`.
              // Example: `0.1.0-alpha.1.5` -> `0.1.0-alpha.1.6` => `false`.
              return false;
            } else {
              // If our second pre-release part is lower than the second
              // pre-release part of the other version, then this is critical.
              //
              // Example: `0.1.0-alpha.1` -> `0.1.0-alpha.2` => `true`.
              return ourSecond.compareTo(theirSecond) < 0;
            }
          }
        } else {
          // If our first pre-release part is lower than the first pre-release
          // part of the other version, then this is critical.
          //
          // Example: `0.1.0-alpha` -> `0.1.0-beta` => `true`.
          return ourFirst.compareTo(theirFirst) < 0;
        }
      }
    }

    // If the compared versions contain no pre-releases, then proceed comparing
    // major/minor numbers.
    //
    // Differences in major number are always considered critical.
    //
    // Example: `1.0.0` -> `2.0.0` => `true`.
    if (major < other.major) {
      return true;
    }

    if (major == 0) {
      // If major is `0`, then differences in minor number are considered
      // critical.
      //
      // Example: `0.1.0` -> `0.2.0` => `true`.
      if (minor < other.minor) {
        return true;
      }
    }

    return false;
  }
}

// class SemVer implements Comparable<SemVer> {
//   SemVer(this.major, this.minor, this.patch, [this.suffix]);

//   factory SemVer.parse(String value) {
//     final match = _regExp.allMatches(value).firstOrNull;

//     print(match?.groups([1, 2, 3, 4, 5]));

//     if (match == null) {
//       throw const FormatException('Does not match validation RegExp');
//     }

//     final String? suffix = match.group(5);

//     final int major = int.tryParse(match.group(4) ?? '') ?? 0;

//     final split = match.group(2)?.split('.') ?? [];
//     final int minor = int.tryParse(split.elementAtOrNull(1) ?? '') ?? 0;
//     final int patch = int.tryParse(split.elementAtOrNull(2) ?? '') ?? 0;

//     return SemVer(major, minor, patch, suffix);
//   }

//   final int major;
//   final int minor;
//   final int patch;
//   final String? suffix;

//   static final RegExp _regExp = RegExp(
//     r'^(((([0-9]+)\.[0-9]+)\.[0-9]+)(-.+)?)$',
//   );

//   @override
//   int compareTo(SemVer other) {
//     var result = major.compareTo(other.major);
//     if (result == 0) {
//       result = minor.compareTo(other.minor);
//       if (result == 0) {
//         result = patch.compareTo(other.patch);
//         if (result == 0) {
//           if (suffix != null && other.suffix == null) {
//             return 1;
//           } else if (suffix == null && other.suffix != null) {
//             return -1;
//           } else if (suffix == null && other.suffix == null) {
//             return 0;
//           } else if (suffix != null && other.suffix != null) {
//             return suffix!.compareTo(other.suffix!);
//           }
//         }
//       }
//     }

//     return result;
//   }

//   @override
//   String toString() => '$major.$minor.$patch${suffix ?? ''}';

//   /// Indicates whether this [SemVer] is considered critical compared to the
//   /// [other].
//   ///
//   /// Algorithm determining whether the [other] is consider critical follows the
//   /// rules, which is easier to demonstrate with the following examples:
//   /// - 0.1.0 -> 0.1.1 => `false`;
//   /// - 0.1.0 -> 0.2.0 => `true`;
//   /// - 0.1.0 -> 1.0.0 => `true`;
//   /// - 1.0.0 -> 1.0.1 => `false`;
//   /// - 1.0.0 -> 1.1.0 => `false`.
//   ///
//   /// And the suffixes:
//   /// - 0.1.0-alpha -> 0.1.0 => `true`;
//   /// - 0.1.0-alpha -> 0.1.0.alpha.1 => `true`;
//   /// - 0.1.0-alpha.1 -> 0.1.0.alpha.2 => `true`;
//   /// - 0.1.0-alpha.2 -> 0.1.0.alpha.2.1 => `false`;
//   /// - 0.1.0-alpha.3 -> 0.1.0.beta.1 => `true`;
//   /// - 0.1.0 -> 0.2.0-rc => `false`;
//   /// - 0.1.0 -> 1.0.0-beta => `false`;
//   /// - 1.0.0-beta -> 1.0.0-rc => `true`.
//   bool isCritical(SemVer other) {
//     if (suffix != other.suffix) {
//       if (suffix != null && other.suffix == null) {
//         return true;
//       } else if (suffix == null && other.suffix != null) {
//         return false;
//       } else if (suffix != null && other.suffix != null) {
//         final compare = suffix!.compareTo(other.suffix!) < 0;
//         if (compare) {
//           final String? aVersion = suffix!.contains('.')
//               ? suffix!.substring(suffix!.indexOf('.') + 1)
//               : null;
//           final String? aRelease = aVersion == null
//               ? suffix
//               : suffix!.substring(0, suffix!.indexOf('.'));

//           final String? bVersion = other.suffix!.contains('.')
//               ? other.suffix!.substring(other.suffix!.indexOf('.') + 1)
//               : null;
//           final String? bRelease = bVersion == null
//               ? other.suffix
//               : other.suffix!.substring(0, other.suffix!.indexOf('.'));

//           // Check if minor...
//           if (aRelease == bRelease) {
//             print(
//                 'aRelease($aRelease) vs bRelease($bRelease), aVersion($aVersion) vs bVersion($bVersion)');
//             if (aVersion != null && bVersion != null) {
//               final aNumber = double.tryParse(aVersion) ?? 0;
//               final bNumber = double.tryParse(bVersion) ?? 0;
//               return aNumber.floor() < bNumber.floor() ||
//                   !bVersion.contains('.');
//             }
//           }
//         }

//         return compare;
//       }
//     }

//     if (major < other.major) {
//       return true;
//     }

//     if (major == 0) {
//       if (minor < other.minor) {
//         return true;
//       }
//     }

//     return false;
//   }
// }
