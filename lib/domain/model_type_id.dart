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

/// Type ID's of all `Hive` models just to keep them in one place.
///
/// They should not change with time to not break on already stored data by
/// previous versions of application. Add new entries to the end.
class ModelTypeId {
  static const myUser = 0;
  static const session = 2;
  static const chatDirectLink = 3;
  static const myUserEmails = 4;
  static const cropArea = 5;
  static const cropPoint = 6;
  static const userCallCover = 7;
  static const userAvatar = 8;
  static const myUserPhones = 9;
  static const muteDuration = 10;
  static const chat = 11;
  static const original = 13;
  static const square = 14;
  static const chatContactsCursor = 15;
  static const myUserVersion = 16;
  static const accessToken = 17;
  static const userId = 18;
  static const userNum = 19;
  static const userLogin = 20;
  static const userName = 21;
  static const userEmail = 23;
  static const userPhone = 24;
  static const chatDirectLinkSlug = 25;
  static const chatDirectLinkVersion = 26;
  static const userTextStatus = 27;
  static const usersCursor = 28;
  static const userVersion = 29;
  static const chatContactId = 30;
  static const chatContactFavoritePosition = 31;
  static const chatContactVersion = 32;
  static const chatId = 33;
  static const user = 34;
  static const chatContact = 35;
  static const hiveChatContact = 36;
  static const hiveMyUser = 37;
  static const hiveUser = 38;
  static const chatContactsListVersion = 39;
  static const sessionData = 40;
  static const recentChatsCursor = 41;
  static const chatVersion = 42;
  static const chatAvatar = 43;
  static const chatName = 44;
  static const chatMember = 45;
  static const lastChatRead = 46;
  static const chatItemId = 47;
  static const chatCall = 48;
  static const chatMessageText = 49;
  static const hiveChat = 50;
  static const chatCallRoomJoinLink = 51;
  static const chatCallMember = 52;
  static const chatItemVersion = 53;
  static const sessionVersion = 54;
  static const rememberedSession = 55;
  static const rememberedToken = 56;
  static const rememberedSessionVersion = 57;
  static const chatInfo = 58;
  static const chatMessage = 59;
  static const chatForward = 60;
  static const attachmentId = 61;
  static const imageAttachment = 62;
  static const fileAttachment = 63;
  static const chatItemsCursor = 64;
  static const hiveChatInfo = 65;
  static const hiveChatCall = 66;
  static const hiveChatMessage = 67;
  static const hiveChatForward = 68;
  static const incomingChatCallsCursor = 69;
  static const credentials = 70;
  static const mediaSettings = 71;
  static const chatCallDeviceId = 72;
  static const preciseDateTime = 73;
  static const applicationSettings = 74;
  static const sendingStatus = 75;
  static const nativeFile = 76;
  static const localAttachment = 77;
  static const mediaType = 78;
  static const hiveBackground = 79;
  static const plainFile = 80;
  static const chatCallCredentials = 81;
  static const chatFavoritePosition = 82;
  static const favoriteChatsListVersion = 83;
  static const blocklistCursor = 84;
  static const windowPreferences = 85;
  static const blocklistReason = 86;
  static const chatMembersDialedAll = 87;
  static const chatMembersDialedConcrete = 88;
  static const chatInfoActionAvatarUpdated = 89;
  static const chatInfoActionCreated = 90;
  static const chatInfoActionMemberAdded = 91;
  static const chatInfoActionMemberRemoved = 92;
  static const chatInfoActionNameUpdated = 93;
  static const chatMessageQuote = 94;
  static const chatCallQuote = 95;
  static const chatInfoQuote = 96;
  static const blocklistRecord = 97;
  static const rect = 98;
  static const cacheInfo = 99;
  static const imageFile = 100;
  static const favoriteChatsCursor = 101;
  static const thumbhash = 102;
  static const favoriteChatContactsCursor = 103;
  static const callButtonsPosition = 104;
  static const hiveBlocklistRecord = 105;
  static const userBio = 106;
  static const hiveChatMember = 107;
  static const chatMembersCursor = 108;
  static const nestedChatContact = 109;
}
