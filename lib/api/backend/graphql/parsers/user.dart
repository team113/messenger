// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/store/model/my_user.dart';
import '/store/model/user.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// UserId

UserId fromGraphQLUserIdToDartUserId(String v) => UserId(v);
String fromDartUserIdToGraphQLUserId(UserId v) => v.val;
List<UserId> fromGraphQLListUserIdToDartListUserId(List<Object?> v) =>
    v.map((e) => fromGraphQLUserIdToDartUserId(e as String)).toList();
List<String> fromDartListUserIdToGraphQLListUserId(List<UserId> v) =>
    v.map((e) => fromDartUserIdToGraphQLUserId(e)).toList();
List<UserId>? fromGraphQLListNullableUserIdToDartListNullableUserId(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserIdToDartUserId(e as String)).toList();
List<String>? fromDartListNullableUserIdToGraphQLListNullableUserId(
        List<UserId>? v) =>
    v?.map((e) => fromDartUserIdToGraphQLUserId(e)).toList();

UserId? fromGraphQLUserIdNullableToDartUserIdNullable(String? v) =>
    v == null ? null : UserId(v);
String? fromDartUserIdNullableToGraphQLUserIdNullable(UserId? v) => v?.val;
List<UserId?> fromGraphQLListUserIdNullableToDartListUserIdNullable(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLUserIdNullableToDartUserIdNullable(e as String?))
        .toList();
List<String?> fromDartListUserIdNullableToGraphQLListUserIdNullable(
        List<UserId?> v) =>
    v.map((e) => fromDartUserIdNullableToGraphQLUserIdNullable(e)).toList();
List<UserId?>?
    fromGraphQLListNullableUserIdNullableToDartListNullableUserIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserIdNullableToDartUserIdNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserIdNullableToGraphQLListNullableUserIdNullable(
            List<UserId?>? v) =>
        v
            ?.map((e) => fromDartUserIdNullableToGraphQLUserIdNullable(e))
            .toList();

// UserNum

UserNum fromGraphQLUserNumToDartUserNum(String v) => UserNum(v);
String fromDartUserNumToGraphQLUserNum(UserNum v) => v.val;
List<UserNum> fromGraphQLListUserNumToDartListUserNum(List<Object?> v) =>
    v.map((e) => fromGraphQLUserNumToDartUserNum(e as String)).toList();
List<String> fromDartListUserNumToGraphQLListUserNum(List<UserNum> v) =>
    v.map((e) => fromDartUserNumToGraphQLUserNum(e)).toList();
List<UserNum>? fromGraphQLListNullableUserNumToDartListNullableUserNum(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserNumToDartUserNum(e as String)).toList();
List<String>? fromDartListNullableUserNumToGraphQLListNullableUserNum(
        List<UserNum>? v) =>
    v?.map((e) => fromDartUserNumToGraphQLUserNum(e)).toList();

UserNum? fromGraphQLUserNumNullableToDartUserNumNullable(String? v) =>
    v == null ? null : UserNum(v);
String? fromDartUserNumNullableToGraphQLUserNumNullable(UserNum? v) => v?.val;
List<UserNum?> fromGraphQLListUserNumNullableToDartListUserNumNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserNumNullableToDartUserNumNullable(e as String?))
        .toList();
List<String?> fromDartListUserNumNullableToGraphQLListUserNumNullable(
        List<UserNum?> v) =>
    v.map((e) => fromDartUserNumNullableToGraphQLUserNumNullable(e)).toList();
List<UserNum?>?
    fromGraphQLListNullableUserNumNullableToDartListNullableUserNumNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserNumNullableToDartUserNumNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserNumNullableToGraphQLListNullableUserNumNullable(
            List<UserNum?>? v) =>
        v
            ?.map((e) => fromDartUserNumNullableToGraphQLUserNumNullable(e))
            .toList();

// UserLogin

UserLogin fromGraphQLUserLoginToDartUserLogin(String v) =>
    UserLogin.unchecked(v);
String fromDartUserLoginToGraphQLUserLogin(UserLogin v) => v.val;
List<UserLogin> fromGraphQLListUserLoginToDartListUserLogin(List<Object?> v) =>
    v.map((e) => fromGraphQLUserLoginToDartUserLogin(e as String)).toList();
List<String> fromDartListUserLoginToGraphQLListUserLogin(List<UserLogin> v) =>
    v.map((e) => fromDartUserLoginToGraphQLUserLogin(e)).toList();
List<UserLogin>? fromGraphQLListNullableUserLoginToDartListNullableUserLogin(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserLoginToDartUserLogin(e as String)).toList();
List<String>? fromDartListNullableUserLoginToGraphQLListNullableUserLogin(
        List<UserLogin>? v) =>
    v?.map((e) => fromDartUserLoginToGraphQLUserLogin(e)).toList();

UserLogin? fromGraphQLUserLoginNullableToDartUserLoginNullable(String? v) =>
    v == null ? null : UserLogin.unchecked(v);
String? fromDartUserLoginNullableToGraphQLUserLoginNullable(UserLogin? v) =>
    v?.val;
List<UserLogin?> fromGraphQLListUserLoginNullableToDartListUserLoginNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserLoginNullableToDartUserLoginNullable(e as String?))
        .toList();
List<String?> fromDartListUserLoginNullableToGraphQLListUserLoginNullable(
        List<UserLogin?> v) =>
    v
        .map((e) => fromDartUserLoginNullableToGraphQLUserLoginNullable(e))
        .toList();
List<UserLogin?>?
    fromGraphQLListNullableUserLoginNullableToDartListNullableUserLoginNullable(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUserLoginNullableToDartUserLoginNullable(
                e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserLoginNullableToGraphQLListNullableUserLoginNullable(
            List<UserLogin?>? v) =>
        v
            ?.map((e) => fromDartUserLoginNullableToGraphQLUserLoginNullable(e))
            .toList();

// UserName

UserName fromGraphQLUserNameToDartUserName(String v) => UserName.unchecked(v);
String fromDartUserNameToGraphQLUserName(UserName v) => v.val;
List<UserName> fromGraphQLListUserNameToDartListUserName(List<Object?> v) =>
    v.map((e) => fromGraphQLUserNameToDartUserName(e as String)).toList();
List<String> fromDartListUserNameToGraphQLListUserName(List<UserName> v) =>
    v.map((e) => fromDartUserNameToGraphQLUserName(e)).toList();
List<UserName>? fromGraphQLListNullableUserNameToDartListNullableUserName(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserNameToDartUserName(e as String)).toList();
List<String>? fromDartListNullableUserNameToGraphQLListNullableUserName(
        List<UserName>? v) =>
    v?.map((e) => fromDartUserNameToGraphQLUserName(e)).toList();

UserName? fromGraphQLUserNameNullableToDartUserNameNullable(String? v) =>
    v == null ? null : UserName.unchecked(v);
String? fromDartUserNameNullableToGraphQLUserNameNullable(UserName? v) =>
    v?.val;
List<UserName?> fromGraphQLListUserNameNullableToDartListUserNameNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserNameNullableToDartUserNameNullable(e as String?))
        .toList();
List<String?> fromDartListUserNameNullableToGraphQLListUserNameNullable(
        List<UserName?> v) =>
    v.map((e) => fromDartUserNameNullableToGraphQLUserNameNullable(e)).toList();
List<UserName?>?
    fromGraphQLListNullableUserNameNullableToDartListNullableUserNameNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserNameNullableToDartUserNameNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserNameNullableToGraphQLListNullableUserNameNullable(
            List<UserName?>? v) =>
        v
            ?.map((e) => fromDartUserNameNullableToGraphQLUserNameNullable(e))
            .toList();

// UserBio

UserBio fromGraphQLUserBioToDartUserBio(String v) => UserBio.unchecked(v);
String fromDartUserBioToGraphQLUserBio(UserBio v) => v.val;
List<UserBio> fromGraphQLListUserBioToDartListUserBio(List<Object?> v) =>
    v.map((e) => fromGraphQLUserBioToDartUserBio(e as String)).toList();
List<String> fromDartListUserBioToGraphQLListUserBio(List<UserBio> v) =>
    v.map((e) => fromDartUserBioToGraphQLUserBio(e)).toList();
List<UserBio>? fromGraphQLListNullableUserBioToDartListNullableUserBio(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserBioToDartUserBio(e as String)).toList();
List<String>? fromDartListNullableUserBioToGraphQLListNullableUserBio(
        List<UserBio>? v) =>
    v?.map((e) => fromDartUserBioToGraphQLUserBio(e)).toList();

UserBio? fromGraphQLUserBioNullableToDartUserBioNullable(String? v) =>
    v == null ? null : UserBio.unchecked(v);
String? fromDartUserBioNullableToGraphQLUserBioNullable(UserBio? v) => v?.val;
List<UserBio?> fromGraphQLListUserBioNullableToDartListUserBioNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserBioNullableToDartUserBioNullable(e as String?))
        .toList();
List<String?> fromDartListUserBioNullableToGraphQLListUserBioNullable(
        List<UserBio?> v) =>
    v.map((e) => fromDartUserBioNullableToGraphQLUserBioNullable(e)).toList();
List<UserBio?>?
    fromGraphQLListNullableUserBioNullableToDartListNullableUserBioNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserBioNullableToDartUserBioNullable(e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserBioNullableToGraphQLListNullableUserBioNullable(
            List<UserBio?>? v) =>
        v
            ?.map((e) => fromDartUserBioNullableToGraphQLUserBioNullable(e))
            .toList();

// UserPassword

UserPassword fromGraphQLUserPasswordToDartUserPassword(String v) =>
    UserPassword.unchecked(v);
String fromDartUserPasswordToGraphQLUserPassword(UserPassword v) => v.val;
List<UserPassword> fromGraphQLListUserPasswordToDartListUserPassword(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLUserPasswordToDartUserPassword(e as String))
        .toList();
List<String> fromDartListUserPasswordToGraphQLListUserPassword(
        List<UserPassword> v) =>
    v.map((e) => fromDartUserPasswordToGraphQLUserPassword(e)).toList();
List<UserPassword>?
    fromGraphQLListNullableUserPasswordToDartListNullableUserPassword(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUserPasswordToDartUserPassword(e as String))
            .toList();
List<String>? fromDartListNullableUserPasswordToGraphQLListNullableUserPassword(
        List<UserPassword>? v) =>
    v?.map((e) => fromDartUserPasswordToGraphQLUserPassword(e)).toList();

UserPassword? fromGraphQLUserPasswordNullableToDartUserPasswordNullable(
        String? v) =>
    v == null ? null : UserPassword.unchecked(v);
String? fromDartUserPasswordNullableToGraphQLUserPasswordNullable(
        UserPassword? v) =>
    v?.val;
List<UserPassword?>
    fromGraphQLListUserPasswordNullableToDartListUserPasswordNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLUserPasswordNullableToDartUserPasswordNullable(
                    e as String?))
            .toList();
List<String?> fromDartListUserPasswordNullableToGraphQLListUserPasswordNullable(
        List<UserPassword?> v) =>
    v
        .map(
            (e) => fromDartUserPasswordNullableToGraphQLUserPasswordNullable(e))
        .toList();
List<UserPassword?>?
    fromGraphQLListNullableUserPasswordNullableToDartListNullableUserPasswordNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserPasswordNullableToDartUserPasswordNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserPasswordNullableToGraphQLListNullableUserPasswordNullable(
            List<UserPassword?>? v) =>
        v
            ?.map((e) =>
                fromDartUserPasswordNullableToGraphQLUserPasswordNullable(e))
            .toList();

// UserEmail

UserEmail fromGraphQLUserEmailToDartUserEmail(String v) =>
    UserEmail.unchecked(v);
String fromDartUserEmailToGraphQLUserEmail(UserEmail v) => v.val;
List<UserEmail> fromGraphQLListUserEmailToDartListUserEmail(List<Object?> v) =>
    v.map((e) => fromGraphQLUserEmailToDartUserEmail(e as String)).toList();
List<String> fromDartListUserEmailToGraphQLListUserEmail(List<UserEmail> v) =>
    v.map((e) => fromDartUserEmailToGraphQLUserEmail(e)).toList();
List<UserEmail>? fromGraphQLListNullableUserEmailToDartListNullableUserEmail(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserEmailToDartUserEmail(e as String)).toList();
List<String>? fromDartListNullableUserEmailToGraphQLListNullableUserEmail(
        List<UserEmail>? v) =>
    v?.map((e) => fromDartUserEmailToGraphQLUserEmail(e)).toList();

UserEmail? fromGraphQLUserEmailNullableToDartUserEmailNullable(String? v) =>
    v == null ? null : UserEmail.unchecked(v);
String? fromDartUserEmailNullableToGraphQLUserEmailNullable(UserEmail? v) =>
    v?.val;
List<UserEmail?> fromGraphQLListUserEmailNullableToDartListUserEmailNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserEmailNullableToDartUserEmailNullable(e as String?))
        .toList();
List<String?> fromDartListUserEmailNullableToGraphQLListUserEmailNullable(
        List<UserEmail?> v) =>
    v
        .map((e) => fromDartUserEmailNullableToGraphQLUserEmailNullable(e))
        .toList();
List<UserEmail?>?
    fromGraphQLListNullableUserEmailNullableToDartListNullableUserEmailNullable(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUserEmailNullableToDartUserEmailNullable(
                e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserEmailNullableToGraphQLListNullableUserEmailNullable(
            List<UserEmail?>? v) =>
        v
            ?.map((e) => fromDartUserEmailNullableToGraphQLUserEmailNullable(e))
            .toList();

// UserPhone

UserPhone fromGraphQLUserPhoneToDartUserPhone(String v) =>
    UserPhone.unchecked(v);
String fromDartUserPhoneToGraphQLUserPhone(UserPhone v) => v.val;
List<UserPhone> fromGraphQLListUserPhoneToDartListUserPhone(List<Object?> v) =>
    v.map((e) => fromGraphQLUserPhoneToDartUserPhone(e as String)).toList();
List<String> fromDartListUserPhoneToGraphQLListUserPhone(List<UserPhone> v) =>
    v.map((e) => fromDartUserPhoneToGraphQLUserPhone(e)).toList();
List<UserPhone>? fromGraphQLListNullableUserPhoneToDartListNullableUserPhone(
        List<Object?>? v) =>
    v?.map((e) => fromGraphQLUserPhoneToDartUserPhone(e as String)).toList();
List<String>? fromDartListNullableUserPhoneToGraphQLListNullableUserPhone(
        List<UserPhone>? v) =>
    v?.map((e) => fromDartUserPhoneToGraphQLUserPhone(e)).toList();

UserPhone? fromGraphQLUserPhoneNullableToDartUserPhoneNullable(String? v) =>
    v == null ? null : UserPhone.unchecked(v);
String? fromDartUserPhoneNullableToGraphQLUserPhoneNullable(UserPhone? v) =>
    v?.val;
List<UserPhone?> fromGraphQLListUserPhoneNullableToDartListUserPhoneNullable(
        List<Object?> v) =>
    v
        .map((e) =>
            fromGraphQLUserPhoneNullableToDartUserPhoneNullable(e as String?))
        .toList();
List<String?> fromDartListUserPhoneNullableToGraphQLListUserPhoneNullable(
        List<UserPhone?> v) =>
    v
        .map((e) => fromDartUserPhoneNullableToGraphQLUserPhoneNullable(e))
        .toList();
List<UserPhone?>?
    fromGraphQLListNullableUserPhoneNullableToDartListNullableUserPhoneNullable(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUserPhoneNullableToDartUserPhoneNullable(
                e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserPhoneNullableToGraphQLListNullableUserPhoneNullable(
            List<UserPhone?>? v) =>
        v
            ?.map((e) => fromDartUserPhoneNullableToGraphQLUserPhoneNullable(e))
            .toList();

// ChatDirectLinkSlug

ChatDirectLinkSlug fromGraphQLChatDirectLinkSlugToDartChatDirectLinkSlug(
        String v) =>
    ChatDirectLinkSlug.unchecked(v);
String fromDartChatDirectLinkSlugToGraphQLChatDirectLinkSlug(
        ChatDirectLinkSlug v) =>
    v.val;
List<ChatDirectLinkSlug>
    fromGraphQLListChatDirectLinkSlugToDartListChatDirectLinkSlug(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLChatDirectLinkSlugToDartChatDirectLinkSlug(
                e as String))
            .toList();
List<String> fromDartListChatDirectLinkSlugToGraphQLListChatDirectLinkSlug(
        List<ChatDirectLinkSlug> v) =>
    v
        .map((e) => fromDartChatDirectLinkSlugToGraphQLChatDirectLinkSlug(e))
        .toList();
List<ChatDirectLinkSlug>?
    fromGraphQLListNullableChatDirectLinkSlugToDartListNullableChatDirectLinkSlug(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLChatDirectLinkSlugToDartChatDirectLinkSlug(
                e as String))
            .toList();
List<String>?
    fromDartListNullableChatDirectLinkSlugToGraphQLListNullableChatDirectLinkSlug(
            List<ChatDirectLinkSlug>? v) =>
        v
            ?.map(
                (e) => fromDartChatDirectLinkSlugToGraphQLChatDirectLinkSlug(e))
            .toList();

ChatDirectLinkSlug?
    fromGraphQLChatDirectLinkSlugNullableToDartChatDirectLinkSlugNullable(
            String? v) =>
        v == null ? null : ChatDirectLinkSlug.unchecked(v);
String? fromDartChatDirectLinkSlugNullableToGraphQLChatDirectLinkSlugNullable(
        ChatDirectLinkSlug? v) =>
    v?.val;
List<ChatDirectLinkSlug?>
    fromGraphQLListChatDirectLinkSlugNullableToDartListChatDirectLinkSlugNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatDirectLinkSlugNullableToDartChatDirectLinkSlugNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatDirectLinkSlugNullableToGraphQLListChatDirectLinkSlugNullable(
            List<ChatDirectLinkSlug?> v) =>
        v
            .map((e) =>
                fromDartChatDirectLinkSlugNullableToGraphQLChatDirectLinkSlugNullable(
                    e))
            .toList();
List<ChatDirectLinkSlug?>?
    fromGraphQLListNullableChatDirectLinkSlugNullableToDartListNullableChatDirectLinkSlugNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatDirectLinkSlugNullableToDartChatDirectLinkSlugNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatDirectLinkSlugNullableToGraphQLListNullableChatDirectLinkSlugNullable(
            List<ChatDirectLinkSlug?>? v) =>
        v
            ?.map((e) =>
                fromDartChatDirectLinkSlugNullableToGraphQLChatDirectLinkSlugNullable(
                    e))
            .toList();

// ConfirmationCode

ConfirmationCode fromGraphQLConfirmationCodeToDartConfirmationCode(String v) =>
    ConfirmationCode.unchecked(v);
String fromDartConfirmationCodeToGraphQLConfirmationCode(ConfirmationCode v) =>
    v.val;
List<ConfirmationCode>
    fromGraphQLListConfirmationCodeToDartListConfirmationCode(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLConfirmationCodeToDartConfirmationCode(e as String))
            .toList();
List<String> fromDartListConfirmationCodeToGraphQLListConfirmationCode(
        List<ConfirmationCode> v) =>
    v.map((e) => fromDartConfirmationCodeToGraphQLConfirmationCode(e)).toList();
List<ConfirmationCode>?
    fromGraphQLListNullableConfirmationCodeToDartListNullableConfirmationCode(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLConfirmationCodeToDartConfirmationCode(e as String))
            .toList();
List<String>?
    fromDartListNullableConfirmationCodeToGraphQLListNullableConfirmationCode(
            List<ConfirmationCode>? v) =>
        v
            ?.map((e) => fromDartConfirmationCodeToGraphQLConfirmationCode(e))
            .toList();

ConfirmationCode?
    fromGraphQLConfirmationCodeNullableToDartConfirmationCodeNullable(
            String? v) =>
        v == null ? null : ConfirmationCode.unchecked(v);
String? fromDartConfirmationCodeNullableToGraphQLConfirmationCodeNullable(
        ConfirmationCode? v) =>
    v?.val;
List<ConfirmationCode?>
    fromGraphQLListConfirmationCodeNullableToDartListConfirmationCodeNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLConfirmationCodeNullableToDartConfirmationCodeNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListConfirmationCodeNullableToGraphQLListConfirmationCodeNullable(
            List<ConfirmationCode?> v) =>
        v
            .map((e) =>
                fromDartConfirmationCodeNullableToGraphQLConfirmationCodeNullable(
                    e))
            .toList();
List<ConfirmationCode?>?
    fromGraphQLListNullableConfirmationCodeNullableToDartListNullableConfirmationCodeNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLConfirmationCodeNullableToDartConfirmationCodeNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableConfirmationCodeNullableToGraphQLListNullableConfirmationCodeNullable(
            List<ConfirmationCode?>? v) =>
        v
            ?.map((e) =>
                fromDartConfirmationCodeNullableToGraphQLConfirmationCodeNullable(
                    e))
            .toList();

// MyUserVersion

MyUserVersion fromGraphQLMyUserVersionToDartMyUserVersion(String v) =>
    MyUserVersion(v);
String fromDartMyUserVersionToGraphQLMyUserVersion(MyUserVersion v) =>
    v.toString();
List<MyUserVersion> fromGraphQLListMyUserVersionToDartListMyUserVersion(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLMyUserVersionToDartMyUserVersion(e as String))
        .toList();
List<String> fromDartListMyUserVersionToGraphQLListMyUserVersion(
        List<MyUserVersion> v) =>
    v.map((e) => fromDartMyUserVersionToGraphQLMyUserVersion(e)).toList();
List<MyUserVersion>?
    fromGraphQLListNullableMyUserVersionToDartListNullableMyUserVersion(
            List<Object?>? v) =>
        v
            ?.map(
                (e) => fromGraphQLMyUserVersionToDartMyUserVersion(e as String))
            .toList();
List<String>?
    fromDartListNullableMyUserVersionToGraphQLListNullableMyUserVersion(
            List<MyUserVersion>? v) =>
        v?.map((e) => fromDartMyUserVersionToGraphQLMyUserVersion(e)).toList();

MyUserVersion? fromGraphQLMyUserVersionNullableToDartMyUserVersionNullable(
        String? v) =>
    v == null ? null : MyUserVersion(v);
String? fromDartMyUserVersionNullableToGraphQLMyUserVersionNullable(
        MyUserVersion? v) =>
    v?.toString();
List<MyUserVersion?>
    fromGraphQLListMyUserVersionNullableToDartListMyUserVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLMyUserVersionNullableToDartMyUserVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListMyUserVersionNullableToGraphQLListMyUserVersionNullable(
            List<MyUserVersion?> v) =>
        v
            .map((e) =>
                fromDartMyUserVersionNullableToGraphQLMyUserVersionNullable(e))
            .toList();
List<MyUserVersion?>?
    fromGraphQLListNullableMyUserVersionNullableToDartListNullableMyUserVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLMyUserVersionNullableToDartMyUserVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableMyUserVersionNullableToGraphQLListNullableMyUserVersionNullable(
            List<MyUserVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartMyUserVersionNullableToGraphQLMyUserVersionNullable(e))
            .toList();

// UserTextStatus

UserTextStatus fromGraphQLUserTextStatusToDartUserTextStatus(String v) =>
    UserTextStatus.unchecked(v);
String fromDartUserTextStatusToGraphQLUserTextStatus(UserTextStatus v) => v.val;
List<UserTextStatus> fromGraphQLListUserTextStatusToDartListUserTextStatus(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLUserTextStatusToDartUserTextStatus(e as String))
        .toList();
List<String> fromDartListUserTextStatusToGraphQLListUserTextStatus(
        List<UserTextStatus> v) =>
    v.map((e) => fromDartUserTextStatusToGraphQLUserTextStatus(e)).toList();
List<UserTextStatus>?
    fromGraphQLListNullableUserTextStatusToDartListNullableUserTextStatus(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserTextStatusToDartUserTextStatus(e as String))
            .toList();
List<String>?
    fromDartListNullableUserTextStatusToGraphQLListNullableUserTextStatus(
            List<UserTextStatus>? v) =>
        v
            ?.map((e) => fromDartUserTextStatusToGraphQLUserTextStatus(e))
            .toList();

UserTextStatus? fromGraphQLUserTextStatusNullableToDartUserTextStatusNullable(
        String? v) =>
    v == null ? null : UserTextStatus.unchecked(v);
String? fromDartUserTextStatusNullableToGraphQLUserTextStatusNullable(
        UserTextStatus? v) =>
    v?.val;
List<UserTextStatus?>
    fromGraphQLListUserTextStatusNullableToDartListUserTextStatusNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLUserTextStatusNullableToDartUserTextStatusNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListUserTextStatusNullableToGraphQLListUserTextStatusNullable(
            List<UserTextStatus?> v) =>
        v
            .map((e) =>
                fromDartUserTextStatusNullableToGraphQLUserTextStatusNullable(
                    e))
            .toList();
List<UserTextStatus?>?
    fromGraphQLListNullableUserTextStatusNullableToDartListNullableUserTextStatusNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserTextStatusNullableToDartUserTextStatusNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserTextStatusNullableToGraphQLListNullableUserTextStatusNullable(
            List<UserTextStatus?>? v) =>
        v
            ?.map((e) =>
                fromDartUserTextStatusNullableToGraphQLUserTextStatusNullable(
                    e))
            .toList();

// ChatDirectLinkVersion

ChatDirectLinkVersion
    fromGraphQLChatDirectLinkVersionToDartChatDirectLinkVersion(String v) =>
        ChatDirectLinkVersion(v);
String fromDartChatDirectLinkVersionToGraphQLChatDirectLinkVersion(
        ChatDirectLinkVersion v) =>
    v.toString();
List<ChatDirectLinkVersion>
    fromGraphQLListChatDirectLinkVersionToDartListChatDirectLinkVersion(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatDirectLinkVersionToDartChatDirectLinkVersion(
                    e as String))
            .toList();
List<String>
    fromDartListChatDirectLinkVersionToGraphQLListChatDirectLinkVersion(
            List<ChatDirectLinkVersion> v) =>
        v
            .map((e) =>
                fromDartChatDirectLinkVersionToGraphQLChatDirectLinkVersion(e))
            .toList();
List<ChatDirectLinkVersion>?
    fromGraphQLListNullableChatDirectLinkVersionToDartListNullableChatDirectLinkVersion(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatDirectLinkVersionToDartChatDirectLinkVersion(
                    e as String))
            .toList();
List<String>?
    fromDartListNullableChatDirectLinkVersionToGraphQLListNullableChatDirectLinkVersion(
            List<ChatDirectLinkVersion>? v) =>
        v
            ?.map((e) =>
                fromDartChatDirectLinkVersionToGraphQLChatDirectLinkVersion(e))
            .toList();

ChatDirectLinkVersion?
    fromGraphQLChatDirectLinkVersionNullableToDartChatDirectLinkVersionNullable(
            String? v) =>
        v == null ? null : ChatDirectLinkVersion(v);
String?
    fromDartChatDirectLinkVersionNullableToGraphQLChatDirectLinkVersionNullable(
            ChatDirectLinkVersion? v) =>
        v?.toString();
List<ChatDirectLinkVersion?>
    fromGraphQLListChatDirectLinkVersionNullableToDartListChatDirectLinkVersionNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLChatDirectLinkVersionNullableToDartChatDirectLinkVersionNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListChatDirectLinkVersionNullableToGraphQLListChatDirectLinkVersionNullable(
            List<ChatDirectLinkVersion?> v) =>
        v
            .map((e) =>
                fromDartChatDirectLinkVersionNullableToGraphQLChatDirectLinkVersionNullable(
                    e))
            .toList();
List<ChatDirectLinkVersion?>?
    fromGraphQLListNullableChatDirectLinkVersionNullableToDartListNullableChatDirectLinkVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLChatDirectLinkVersionNullableToDartChatDirectLinkVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableChatDirectLinkVersionNullableToGraphQLListNullableChatDirectLinkVersionNullable(
            List<ChatDirectLinkVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartChatDirectLinkVersionNullableToGraphQLChatDirectLinkVersionNullable(
                    e))
            .toList();

// UserVersion

UserVersion fromGraphQLUserVersionToDartUserVersion(String v) => UserVersion(v);
String fromDartUserVersionToGraphQLUserVersion(UserVersion v) => v.toString();
List<UserVersion> fromGraphQLListUserVersionToDartListUserVersion(
        List<Object?> v) =>
    v.map((e) => fromGraphQLUserVersionToDartUserVersion(e as String)).toList();
List<String> fromDartListUserVersionToGraphQLListUserVersion(
        List<UserVersion> v) =>
    v.map((e) => fromDartUserVersionToGraphQLUserVersion(e)).toList();
List<UserVersion>?
    fromGraphQLListNullableUserVersionToDartListNullableUserVersion(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUserVersionToDartUserVersion(e as String))
            .toList();
List<String>? fromDartListNullableUserVersionToGraphQLListNullableUserVersion(
        List<UserVersion>? v) =>
    v?.map((e) => fromDartUserVersionToGraphQLUserVersion(e)).toList();

UserVersion? fromGraphQLUserVersionNullableToDartUserVersionNullable(
        String? v) =>
    v == null ? null : UserVersion(v);
String? fromDartUserVersionNullableToGraphQLUserVersionNullable(
        UserVersion? v) =>
    v?.toString();
List<UserVersion?>
    fromGraphQLListUserVersionNullableToDartListUserVersionNullable(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLUserVersionNullableToDartUserVersionNullable(
                e as String?))
            .toList();
List<String?> fromDartListUserVersionNullableToGraphQLListUserVersionNullable(
        List<UserVersion?> v) =>
    v
        .map((e) => fromDartUserVersionNullableToGraphQLUserVersionNullable(e))
        .toList();
List<UserVersion?>?
    fromGraphQLListNullableUserVersionNullableToDartListNullableUserVersionNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUserVersionNullableToDartUserVersionNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableUserVersionNullableToGraphQLListNullableUserVersionNullable(
            List<UserVersion?>? v) =>
        v
            ?.map((e) =>
                fromDartUserVersionNullableToGraphQLUserVersionNullable(e))
            .toList();

// UsersCursor

UsersCursor fromGraphQLUsersCursorToDartUsersCursor(String v) => UsersCursor(v);
String fromDartUsersCursorToGraphQLUsersCursor(UsersCursor v) => v.toString();
List<UsersCursor> fromGraphQLListUsersCursorToDartListUsersCursor(
        List<Object?> v) =>
    v.map((e) => fromGraphQLUsersCursorToDartUsersCursor(e as String)).toList();
List<String> fromDartListUsersCursorToGraphQLListUsersCursor(
        List<UsersCursor> v) =>
    v.map((e) => fromDartUsersCursorToGraphQLUsersCursor(e)).toList();
List<UsersCursor>?
    fromGraphQLListNullableUsersCursorToDartListNullableUsersCursor(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLUsersCursorToDartUsersCursor(e as String))
            .toList();
List<String>? fromDartListNullableUsersCursorToGraphQLListNullableUsersCursor(
        List<UsersCursor>? v) =>
    v?.map((e) => fromDartUsersCursorToGraphQLUsersCursor(e)).toList();

UsersCursor? fromGraphQLUsersCursorNullableToDartUsersCursorNullable(
        String? v) =>
    v == null ? null : UsersCursor(v);
String? fromDartUsersCursorNullableToGraphQLUsersCursorNullable(
        UsersCursor? v) =>
    v?.toString();
List<UsersCursor?>
    fromGraphQLListUsersCursorNullableToDartListUsersCursorNullable(
            List<Object?> v) =>
        v
            .map((e) => fromGraphQLUsersCursorNullableToDartUsersCursorNullable(
                e as String?))
            .toList();
List<String?> fromDartListUsersCursorNullableToGraphQLListUsersCursorNullable(
        List<UsersCursor?> v) =>
    v
        .map((e) => fromDartUsersCursorNullableToGraphQLUsersCursorNullable(e))
        .toList();
List<UsersCursor?>?
    fromGraphQLListNullableUsersCursorNullableToDartListNullableUsersCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLUsersCursorNullableToDartUsersCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableUsersCursorNullableToGraphQLListNullableUsersCursorNullable(
            List<UsersCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartUsersCursorNullableToGraphQLUsersCursorNullable(e))
            .toList();

// BlacklistCursor

BlacklistCursor fromGraphQLBlacklistCursorToDartBlacklistCursor(String v) =>
    BlacklistCursor(v);
String fromDartBlacklistCursorToGraphQLBlacklistCursor(BlacklistCursor v) =>
    v.toString();
List<BlacklistCursor> fromGraphQLListBlacklistCursorToDartListBlacklistCursor(
        List<Object?> v) =>
    v
        .map(
            (e) => fromGraphQLBlacklistCursorToDartBlacklistCursor(e as String))
        .toList();
List<String> fromDartListBlacklistCursorToGraphQLListBlacklistCursor(
        List<BlacklistCursor> v) =>
    v.map((e) => fromDartBlacklistCursorToGraphQLBlacklistCursor(e)).toList();
List<BlacklistCursor>?
    fromGraphQLListNullableBlacklistCursorToDartListNullableBlacklistCursor(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLBlacklistCursorToDartBlacklistCursor(e as String))
            .toList();
List<String>?
    fromDartListNullableBlacklistCursorToGraphQLListNullableBlacklistCursor(
            List<BlacklistCursor>? v) =>
        v
            ?.map((e) => fromDartBlacklistCursorToGraphQLBlacklistCursor(e))
            .toList();

BlacklistCursor?
    fromGraphQLBlacklistCursorNullableToDartBlacklistCursorNullable(
            String? v) =>
        v == null ? null : BlacklistCursor(v);
String? fromDartBlacklistCursorNullableToGraphQLBlacklistCursorNullable(
        BlacklistCursor? v) =>
    v?.toString();
List<BlacklistCursor?>
    fromGraphQLListBlacklistCursorNullableToDartListBlacklistCursorNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLBlacklistCursorNullableToDartBlacklistCursorNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListBlacklistCursorNullableToGraphQLListBlacklistCursorNullable(
            List<BlacklistCursor?> v) =>
        v
            .map((e) =>
                fromDartBlacklistCursorNullableToGraphQLBlacklistCursorNullable(
                    e))
            .toList();
List<BlacklistCursor?>?
    fromGraphQLListNullableBlacklistCursorNullableToDartListNullableBlacklistCursorNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLBlacklistCursorNullableToDartBlacklistCursorNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableBlacklistCursorNullableToGraphQLListNullableBlacklistCursorNullable(
            List<BlacklistCursor?>? v) =>
        v
            ?.map((e) =>
                fromDartBlacklistCursorNullableToGraphQLBlacklistCursorNullable(
                    e))
            .toList();
