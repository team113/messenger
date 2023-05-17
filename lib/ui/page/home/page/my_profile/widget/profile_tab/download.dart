// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';

import '../dense.dart';
import '../download_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.download] section.
class ProfileDownloads extends StatelessWidget {
  const ProfileDownloads({super.key});

  @override
  Widget build(BuildContext context) {
    return const Dense(
      Column(
        children: [
          DownloadButton(
            asset: 'windows',
            width: 21.93,
            height: 22,
            title: 'Windows',
            link: 'messenger-windows.zip',
          ),
          SizedBox(height: 8),
          DownloadButton(
            asset: 'apple',
            width: 23,
            height: 29,
            title: 'macOS',
            link: 'messenger-macos.zip',
          ),
          SizedBox(height: 8),
          DownloadButton(
            asset: 'linux',
            width: 18.85,
            height: 22,
            title: 'Linux',
            link: 'messenger-linux.zip',
          ),
          SizedBox(height: 8),
          DownloadButton(
            asset: 'apple',
            width: 23,
            height: 29,
            title: 'iOS',
            link: 'messenger-ios.zip',
          ),
          SizedBox(height: 8),
          DownloadButton(
            asset: 'google',
            width: 20.33,
            height: 22.02,
            title: 'Android',
            link: 'messenger-android.apk',
          ),
        ],
      ),
    );
  }
}
