// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:io';

import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '/api/backend/schema.dart';
import '/l10n/l10n.dart';
import '/util/localized_exception.dart';

/// [GraphQlProvider] exceptions parser.
///
/// - Throws [ConnectionException] on [SocketException] or `XMLHttpRequest`
///   error.
/// - Throws [AuthorizationException] on headers failure or response 401 status.
/// - Throws [GraphQlException] on anything related to GraphQL or server error.
/// - May throw scheme-defined exception on `handleException` if the response
///   has `data` fields (it's up to `handleException` optional callback to parse
///   them).
/// - Re-throws [LinkException] if the exception hasn't been expected (network
///   error).
///
/// All expected exceptions are mixins of [LocalizedExceptionMixin].
class GraphQlProviderExceptions {
  /// [parse]s exceptions of the given [result] and throws if any.
  static void fire(QueryResult result,
      [Exception Function(Map<String, dynamic>)? handleException]) {
    Exception? exception = parse(result, handleException);
    if (exception != null) throw exception;
  }

  /// Returns an exception of the given [result] with [handleException] if it
  /// has the specified error code or `null` if no exception was found.
  static Exception? parse(QueryResult result,
      [Exception Function(Map<String, dynamic>)? handleException]) {
    if (result.hasException) {
      if (result.exception == null) {
        return Exception('err_unknown'.td);
      }

      // If no exceptions lay in `linkException`, then it is `GraphQlException`.
      if (result.exception!.linkException == null) {
        // If `GraphQlException` contains `NOT_CHAT_MEMBER` code, then it's a
        // specific `NotChatMemberException`.
        if (result.exception!.graphqlErrors.firstWhereOrNull(
                (e) => e.extensions?['code'] == 'NOT_CHAT_MEMBER') !=
            null) {
          return NotChatMemberException(result.exception!.graphqlErrors);
        } else if (result.exception!.graphqlErrors.firstWhereOrNull(
                (e) => e.extensions?['code'] == 'STALE_VERSION') !=
            null) {
          // If `GraphQlException` contains `STALE_VERSION` code, then it's a
          // specific `StaleVersionException`.
          return StaleVersionException(result.exception!.graphqlErrors);
        } else if (result.exception!.graphqlErrors.firstWhereOrNull((e) =>
                e.extensions?['code'] == 'SESSION_EXPIRED' ||
                e.extensions?['code'] == 'AUTHENTICATION_REQUIRED' ||
                e.extensions?['code'] == 'AUTHENTICATION_FAILED') !=
            null) {
          return AuthorizationException();
        }

        return GraphQlException(result.exception!.graphqlErrors);
      }

      if (result.exception!.linkException! is ServerException) {
        ServerException e = result.exception!.linkException! as ServerException;

        // If the original exception is "Failed to parse header value", then
        // it's `AuthorizationException`.
        if (e.originalException.toString() == 'Failed to parse header value') {
          return AuthorizationException();
        }

        // If it's `SocketException` or "XMLHttpRequest error." then it's
        // `ConnectionException`.
        if (e.originalException is SocketException ||
            e.originalException.toString() == 'XMLHttpRequest error.') {
          return ConnectionException(e.originalException);
        }

        // If there are `errors`, then it's a backend unspecified error.
        // It might be an internal error, bad request or request error.
        if (e.parsedResponse?.errors != null) {
          var found = e.parsedResponse!.errors!.firstWhereOrNull(
              (v) => v.extensions != null && (v.extensions!['status'] == 401));
          if (found != null) throw AuthorizationException();
          return GraphQlException(e.parsedResponse!.errors!);
        }

        // If any `data` is available, then try to handle the exception as it
        // may be the specified backend error.
        if (e.parsedResponse?.data != null) {
          if (handleException != null) {
            return handleException(e.parsedResponse!.data!);
          }
        }
      }

      // If nothing was triggered, then re-throw the original exception.
      return result.exception!.linkException!.originalException;
    }

    return null;
  }
}

/// General GraphQL or server exception caused by handling the query issues.
///
/// Can be thrown on GraphQL parser errors (variable mismatch, syntax error,
/// etc) or on server errors (internal errors, bad requests, invalid values,
/// etc).
class GraphQlException with LocalizedExceptionMixin implements Exception {
  GraphQlException([Iterable<GraphQLError> graphqlErrors = const []])
      : graphqlErrors = graphqlErrors.toList();

  /// Any GraphQL errors returned from the operation.
  List<GraphQLError> graphqlErrors = [];

  @override
  String toString() => 'GraphQlException($graphqlErrors)';

  @override
  String toMessage() {
    if (graphqlErrors.isEmpty) return 'err_unknown'.td;
    if (graphqlErrors.length == 1) return graphqlErrors.first.message;
    return graphqlErrors.map((e) => e.message).toList().toString();
  }
}

/// Connection exception that mainly means connection refused case.
///
/// Can be thrown on [SocketException] or `XMLHttpRequest`.
class ConnectionException with LocalizedExceptionMixin implements Exception {
  const ConnectionException(this.exception);

  /// Original exception causing this [ConnectionException].
  final dynamic exception;

  @override
  String toString() => 'ConnectionException($exception)';

  @override
  String toMessage() => 'err_network'.td;
}

/// Exception of an authentication absence or invalidity.
///
/// Thrown on header parsing errors or on 401 response status.
class AuthorizationException with LocalizedExceptionMixin implements Exception {
  @override
  String toString() => 'AuthException()';

  @override
  String toMessage() => 'err_unauthorized'.td;
}

/// Specific [GraphQlException] thrown on `NOT_CHAT_MEMBER` extension code.
class NotChatMemberException extends GraphQlException {
  NotChatMemberException([Iterable<GraphQLError> graphqlErrors = const []])
      : super(graphqlErrors);

  @override
  String toString() => 'NotChatMemberException()';

  @override
  String toMessage() => 'err_not_member'.td;
}

/// Specific [GraphQlException] thrown on `STALE_VERSION` extension code.
class StaleVersionException extends GraphQlException {
  StaleVersionException([Iterable<GraphQLError> graphqlErrors = const []])
      : super(graphqlErrors);

  @override
  String toString() => 'StaleVersionException()';

  @override
  String toMessage() => 'err_stale_version'.td;
}

/// Exception of a GraphQL re-subscription requirement.
///
/// Thrown on a GraphQL subscription timeout or on [AuthorizationException].
/// It's required to re-subscribe whenever this exception is thrown.
class ResubscriptionRequiredException implements Exception {
  @override
  String toString() => 'ResubscriptionRequiredException()';
}

/// Exception of `Mutation.createSession` described in the [code].
class CreateSessionException with LocalizedExceptionMixin implements Exception {
  CreateSessionException(this.code);

  /// Reason of why the mutation has failed.
  CreateSessionErrorCode code;

  @override
  String toString() => 'CreateSessionException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateSessionErrorCode.unknownUser:
        return 'err_account_not_found'.td;
      case CreateSessionErrorCode.wrongPassword:
        return 'err_incorrect_password'.td;
      case CreateSessionErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.renewSession` described in the [code].
class RenewSessionException implements Exception {
  RenewSessionException(this.code);

  /// Reason of why the mutation has failed.
  RenewSessionErrorCode code;

  @override
  String toString() => 'RenewSessionException($code)';
}

/// Exception of `Mutation.createChatDialog` described in the [code].
class CreateDialogException with LocalizedExceptionMixin implements Exception {
  CreateDialogException(this.code);

  /// Reason of why the mutation has failed.
  CreateDialogChatErrorCode code;

  @override
  String toString() => 'CreateDialogException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateDialogChatErrorCode.blacklisted:
        return 'err_blacklisted'.td;
      case CreateDialogChatErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case CreateDialogChatErrorCode.unknownUser:
        return 'err_unknown_user'.td;
    }
  }
}

/// Exception of `Mutation.createGroupChat` described in the [code].
class CreateGroupChatException
    with LocalizedExceptionMixin
    implements Exception {
  CreateGroupChatException(this.code);

  /// Reason of why the mutation has failed.
  CreateGroupChatErrorCode code;

  @override
  String toString() => 'CreateGroupException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateGroupChatErrorCode.unknownUser:
        return 'err_unknown_user'.td;
      case CreateGroupChatErrorCode.wrongMembersCount:
        return 'err_wrong_members_count'.td;
      case CreateGroupChatErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case CreateGroupChatErrorCode.blacklisted:
        return 'err_blacklisted'.td;
    }
  }
}

/// Exception of `Mutation.removeChatMember` described in the [code].
class RemoveChatMemberException
    with LocalizedExceptionMixin
    implements Exception {
  RemoveChatMemberException(this.code);

  /// Reason of why the mutation has failed.
  RemoveChatMemberErrorCode code;

  @override
  String toString() => 'RemoveChatMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RemoveChatMemberErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case RemoveChatMemberErrorCode.notGroup:
        return 'err_not_group'.td;
      case RemoveChatMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
    }
  }
}

/// Exception of `Mutation.startChatCall` described in the [code].
class StartChatCallException with LocalizedExceptionMixin implements Exception {
  StartChatCallException(this.code);

  /// Reason of why the mutation has failed.
  StartChatCallErrorCode code;

  @override
  String toString() => 'StartChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case StartChatCallErrorCode.blacklisted:
        return 'err_blacklisted'.td;
      case StartChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case StartChatCallErrorCode.monolog:
        return 'err_call_monolog'.td;
      case StartChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.joinChatCall` described in the [code].
class JoinChatCallException with LocalizedExceptionMixin implements Exception {
  JoinChatCallException(this.code);

  /// Reason of why the mutation has failed.
  JoinChatCallErrorCode code;

  @override
  String toString() => 'JoinChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case JoinChatCallErrorCode.noCall:
        return 'err_call_not_found'.td;
      case JoinChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case JoinChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.leaveChatCall` described in the [code].
class LeaveChatCallException with LocalizedExceptionMixin implements Exception {
  LeaveChatCallException(this.code);

  /// Reason of why the mutation has failed.
  LeaveChatCallErrorCode code;

  @override
  String toString() => 'LeaveChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case LeaveChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case LeaveChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case LeaveChatCallErrorCode.unknownDevice:
        return 'err_unknown_device'.td;
    }
  }
}

/// Exception of `Mutation.declineChatCall` described in the [code].
class DeclineChatCallException
    with LocalizedExceptionMixin
    implements Exception {
  DeclineChatCallException(this.code);

  /// Reason of why the mutation has failed.
  DeclineChatCallErrorCode code;

  @override
  String toString() => 'LeaveChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeclineChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case DeclineChatCallErrorCode.alreadyJoined:
        return 'err_call_already_joined'.td;
      case DeclineChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.updateUserLogin` described in the [code].
class UpdateUserLoginException
    with LocalizedExceptionMixin
    implements Exception {
  UpdateUserLoginException(this.code);

  /// Reason of why the mutation has failed.
  UpdateUserLoginErrorCode code;

  @override
  String toString() => 'UpdateUserLoginException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserLoginErrorCode.occupied:
        return 'err_login_occupied'.td;
      case UpdateUserLoginErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.uploadAttachment` described in the [code].
class UploadAttachmentException
    with LocalizedExceptionMixin
    implements Exception {
  UploadAttachmentException(this.code);

  /// Reason of why the mutation has failed.
  UploadAttachmentErrorCode code;

  @override
  String toString() => 'UploadAttachmentException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UploadAttachmentErrorCode.malformed:
        return 'err_uploaded_file_malformed'.td;
      case UploadAttachmentErrorCode.noFilename:
        return 'err_no_filename'.td;
      case UploadAttachmentErrorCode.tooBigSize:
        return 'err_size_too_big'.td;
      case UploadAttachmentErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.updateUserPassword` described in the [code].
class UpdateUserPasswordException
    with LocalizedExceptionMixin
    implements Exception {
  UpdateUserPasswordException(this.code);

  /// Reason of why the mutation has failed.
  UpdateUserPasswordErrorCode code;

  @override
  String toString() => 'UpdateUserPasswordException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserPasswordErrorCode.wrongOldPassword:
        return 'err_wrong_old_password'.td;
      case UpdateUserPasswordErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.createChatContact` described in the [code].
class CreateChatContactException
    with LocalizedExceptionMixin
    implements Exception {
  CreateChatContactException(this.code);

  /// Reason of why the mutation has failed.
  CreateChatContactErrorCode code;

  @override
  String toString() => 'CreateChatContactException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateChatContactErrorCode.unknownUser:
        return 'err_contact_unknown_user'.td;
      case CreateChatContactErrorCode.unknownChat:
        return 'err_contact_unknown_chat'.td;
      case CreateChatContactErrorCode.notGroup:
        return 'err_contact_not_group'.td;
      case CreateChatContactErrorCode.wrongRecordsCount:
        return 'err_contact_too_many'.td;
      case CreateChatContactErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.recoverUserPassword` described in the [code].
class RecoverUserPasswordException
    with LocalizedExceptionMixin
    implements Exception {
  RecoverUserPasswordException(this.code);

  /// Reason of why the mutation has failed.
  RecoverUserPasswordErrorCode code;

  @override
  String toString() => 'RecoverUserPasswordException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RecoverUserPasswordErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case RecoverUserPasswordErrorCode.codeLimitExceeded:
        return 'err_code_limit_exceed'.td;
      case RecoverUserPasswordErrorCode.nowhereToSend:
        return 'err_nowhere_to_send'.td;
      case RecoverUserPasswordErrorCode.unknownUser:
        return 'err_unknown_user'.td;
    }
  }
}

/// Exception of `Mutation.validateUserPasswordRecoveryCode` described in the
/// [code].
class ValidateUserPasswordRecoveryCodeException
    with LocalizedExceptionMixin
    implements Exception {
  ValidateUserPasswordRecoveryCodeException(this.code);

  /// Reason of why the mutation has failed.
  ValidateUserPasswordRecoveryErrorCode code;

  @override
  String toString() => 'ValidateUserPasswordRecoveryCodeException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ValidateUserPasswordRecoveryErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ValidateUserPasswordRecoveryErrorCode.unknownUser:
        return 'err_unknown_user'.td;
      case ValidateUserPasswordRecoveryErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.td;
    }
  }
}

/// Exception of `Mutation.resetUserPassword` described in the [code].
class ResetUserPasswordException
    with LocalizedExceptionMixin
    implements Exception {
  ResetUserPasswordException(this.code);

  /// Reason of why the mutation has failed.
  ResetUserPasswordErrorCode code;

  @override
  String toString() => 'ResetUserPasswordException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResetUserPasswordErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ResetUserPasswordErrorCode.unknownUser:
        return 'err_unknown_user'.td;
      case ResetUserPasswordErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.td;
    }
  }
}

/// Exception of `Mutation.addChatMember` described in the [code].
class AddChatMemberException with LocalizedExceptionMixin implements Exception {
  AddChatMemberException(this.code);

  /// Reason of why the mutation has failed.
  AddChatMemberErrorCode code;

  @override
  String toString() => 'AddChatMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddChatMemberErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case AddChatMemberErrorCode.unknownUser:
        return 'err_unknown_user'.td;
      case AddChatMemberErrorCode.blacklisted:
        return 'err_blacklisted'.td;
      case AddChatMemberErrorCode.notGroup:
        return 'err_not_group'.td;
      case AddChatMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
    }
  }
}

/// Exception of `Mutation.renameChat` described in the [code].
class RenameChatException with LocalizedExceptionMixin implements Exception {
  RenameChatException(this.code);

  /// Reason of why the mutation has failed.
  RenameChatErrorCode code;

  @override
  String toString() => 'RenameChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RenameChatErrorCode.unknownChat:
        return 'err_contact_unknown_chat'.td;
      case RenameChatErrorCode.notGroup:
        return 'err_contact_not_group'.td;
      case RenameChatErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.postChatMessage` described in the [code].
class PostChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  PostChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  PostChatMessageErrorCode code;

  @override
  String toString() => 'PostChatMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case PostChatMessageErrorCode.blacklisted:
        return 'err_blacklisted'.td;
      case PostChatMessageErrorCode.noTextAndNoAttachment:
        return 'err_no_text_and_no_attachment'.td;
      case PostChatMessageErrorCode.unknownAttachment:
        return 'err_unknown_attachment'.td;
      case PostChatMessageErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case PostChatMessageErrorCode.unknownReplyingChatItem:
        return 'err_unknown_replying_chat_item'.td;
      case PostChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.hideChat` described in the [code].
class HideChatException with LocalizedExceptionMixin implements Exception {
  HideChatException(this.code);

  /// Reason of why the mutation has failed.
  HideChatErrorCode code;

  @override
  String toString() => 'HideChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case HideChatErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case HideChatErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
    }
  }
}

/// Exception of `Mutation.updateChatContactName` described in the [code].
class UpdateChatContactNameException
    with LocalizedExceptionMixin
    implements Exception {
  UpdateChatContactNameException(this.code);

  /// Reason of why the mutation has failed.
  UpdateChatContactNameErrorCode code;

  @override
  String toString() => 'UpdateChatContactNameException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateChatContactNameErrorCode.unknownChatContact:
        return 'err_unknown_contact'.td;
      case UpdateChatContactNameErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.addUserEmail` described in the [code].
class AddUserEmailException with LocalizedExceptionMixin implements Exception {
  AddUserEmailException(this.code);

  /// Reason of why the mutation has failed.
  AddUserEmailErrorCode code;

  @override
  String toString() => 'AddUserEmailException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddUserEmailErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case AddUserEmailErrorCode.busy:
        return 'err_you_already_has_unconfirmed_email'.td;
      case AddUserEmailErrorCode.occupied:
        return 'err_email_occupied'.td;
      case AddUserEmailErrorCode.tooMany:
        return 'err_too_many_emails'.td;
    }
  }
}

/// Exception of `Mutation.resendUserEmailConfirmation` described in the [code].
class ResendUserEmailConfirmationException
    with LocalizedExceptionMixin
    implements Exception {
  ResendUserEmailConfirmationException(this.code);

  /// Reason of why the mutation has failed.
  ResendUserEmailConfirmationErrorCode code;

  @override
  String toString() => 'ResendUserEmailConfirmationException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResendUserEmailConfirmationErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ResendUserEmailConfirmationErrorCode.codeLimitExceeded:
        return 'err_code_limit_exceeded'.td;
      case ResendUserEmailConfirmationErrorCode.noUnconfirmed:
        return 'err_no_unconfirmed_email'.td;
    }
  }
}

/// Exception of `Mutation.resendUserPhoneConfirmation` described in the [code].
class ResendUserPhoneConfirmationException
    with LocalizedExceptionMixin
    implements Exception {
  ResendUserPhoneConfirmationException(this.code);

  /// Reason of why the mutation has failed.
  ResendUserPhoneConfirmationErrorCode code;

  @override
  String toString() => 'ResendUserPhoneConfirmationException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResendUserPhoneConfirmationErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ResendUserPhoneConfirmationErrorCode.codeLimitExceeded:
        return 'err_code_limit_exceeded'.td;
      case ResendUserPhoneConfirmationErrorCode.noUnconfirmed:
        return 'err_no_unconfirmed_phone'.td;
    }
  }
}

/// Exception of `Mutation.confirmUserEmail` described in the [code].
class ConfirmUserEmailException
    with LocalizedExceptionMixin
    implements Exception {
  ConfirmUserEmailException(this.code);

  /// Reason of why the mutation has failed.
  ConfirmUserEmailErrorCode code;

  @override
  String toString() => 'ConfirmUserEmailException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ConfirmUserEmailErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ConfirmUserEmailErrorCode.occupied:
        return 'err_email_occupied'.td;
      case ConfirmUserEmailErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.td;
    }
  }
}

/// Exception of `Mutation.confirmUserPhone` described in the [code].
class ConfirmUserPhoneException
    with LocalizedExceptionMixin
    implements Exception {
  ConfirmUserPhoneException(this.code);

  /// Reason of why the mutation has failed.
  ConfirmUserPhoneErrorCode code;

  @override
  String toString() => 'ConfirmUserPhoneException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ConfirmUserPhoneErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ConfirmUserPhoneErrorCode.occupied:
        return 'err_phone_occupied'.td;
      case ConfirmUserPhoneErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.td;
    }
  }
}

/// Exception of `Mutation.addUserPhone` described in the [code].
class AddUserPhoneException with LocalizedExceptionMixin implements Exception {
  AddUserPhoneException(this.code);

  /// Reason of why the mutation has failed.
  AddUserPhoneErrorCode code;

  @override
  String toString() => 'AddUserPhoneException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddUserPhoneErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case AddUserPhoneErrorCode.occupied:
        return 'err_phone_occupied'.td;
      case AddUserPhoneErrorCode.busy:
        return 'err_you_already_has_unconfirmed_phone'.td;
      case AddUserPhoneErrorCode.tooMany:
        return 'err_too_many_phones'.td;
    }
  }
}

/// Exception of `Mutation.readChat` described in the [code].
class ReadChatException with LocalizedExceptionMixin implements Exception {
  ReadChatException(this.code);

  /// Reason of why the mutation has failed.
  ReadChatErrorCode code;

  @override
  String toString() => 'ReadChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ReadChatErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case ReadChatErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case ReadChatErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.td;
    }
  }
}

/// Exception of `Mutation.hideChatItem` described in the [code].
class HideChatItemException with LocalizedExceptionMixin implements Exception {
  HideChatItemException(this.code);

  /// Reason of why the mutation has failed.
  HideChatItemErrorCode code;

  @override
  String toString() => 'HideChatItemException($code)';

  @override
  String toMessage() {
    switch (code) {
      case HideChatItemErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case HideChatItemErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.td;
    }
  }
}

/// Exception of `Mutation.deleteChatMessage` described in the [code].
class DeleteChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  DeleteChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  DeleteChatMessageErrorCode code;

  @override
  String toString() => 'DeleteChatMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case DeleteChatMessageErrorCode.notAuthor:
        return 'err_not_author'.td;
      case DeleteChatMessageErrorCode.quoted:
        return 'err_quoted_message'.td;
      case DeleteChatMessageErrorCode.read:
        return 'err_message_was_read'.td;
      case DeleteChatMessageErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.td;
    }
  }
}

/// Exception of `Mutation.deleteChatForward` described in the [code].
class DeleteChatForwardException
    with LocalizedExceptionMixin
    implements Exception {
  DeleteChatForwardException(this.code);

  /// Reason of why the mutation has failed.
  DeleteChatForwardErrorCode code;

  @override
  String toString() => 'DeleteChatForwardException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatForwardErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case DeleteChatForwardErrorCode.notAuthor:
        return 'err_not_author'.td;
      case DeleteChatForwardErrorCode.quoted:
        return 'err_quoted_message'.td;
      case DeleteChatForwardErrorCode.read:
        return 'err_message_was_read'.td;
      case DeleteChatForwardErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.td;
    }
  }
}

/// Exception of `Mutation.toggleChatCallHand` described in the [code].
class ToggleChatCallHandException
    with LocalizedExceptionMixin
    implements Exception {
  ToggleChatCallHandException(this.code);

  /// Reason of why the mutation has failed.
  ToggleChatCallHandErrorCode code;

  @override
  String toString() => 'ToggleChatCallHandException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ToggleChatCallHandErrorCode.notCallMember:
        return 'err_not_call_member'.td;
      case ToggleChatCallHandErrorCode.noCall:
        return 'err_call_not_found'.td;
      case ToggleChatCallHandErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case ToggleChatCallHandErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.createChatDirectLink` described in the [code].
class CreateChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  CreateChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  CreateChatDirectLinkErrorCode code;

  @override
  String toString() => 'CreateChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case CreateChatDirectLinkErrorCode.occupied:
        return 'err_chat_direct_link_occupied'.td;
      case CreateChatDirectLinkErrorCode.notGroup:
        return 'err_contact_not_group'.td;
      case CreateChatDirectLinkErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
    }
  }
}

/// Exception of `Mutation.deleteChatDirectLink` described in the [code].
class DeleteChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  DeleteChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  DeleteChatDirectLinkErrorCode code;

  @override
  String toString() => 'DeleteChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case DeleteChatDirectLinkErrorCode.notGroup:
        return 'err_contact_not_group'.td;
      case DeleteChatDirectLinkErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
    }
  }
}

/// Exception of `Mutation.useChatDirectLink` described in the [code].
class UseChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  UseChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  UseChatDirectLinkErrorCode code;

  @override
  String toString() => 'UseChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UseChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case UseChatDirectLinkErrorCode.blacklisted:
        return 'err_you_are_blacklisted'.td;
      case UseChatDirectLinkErrorCode.unknownDirectLink:
        return 'err_unknown_chat_direct_link'.td;
    }
  }
}

/// Exception of `Mutation.editChatMessageText` described in the [code].
class EditChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  EditChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  EditChatMessageTextErrorCode code;

  @override
  String toString() => 'EditChatMessageTextException($code)';

  @override
  String toMessage() {
    switch (code) {
      case EditChatMessageTextErrorCode.uneditable:
        return 'err_uneditable_message'.td;
      case EditChatMessageTextErrorCode.notAuthor:
        return 'err_not_author'.td;
      case EditChatMessageTextErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.td;
      case EditChatMessageTextErrorCode.noTextAndNoAttachment:
        return 'err_no_text_and_no_attachment'.td;
      case EditChatMessageTextErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.updateUserAvatar` described in the [code].
class UpdateUserAvatarException
    with LocalizedExceptionMixin
    implements Exception {
  UpdateUserAvatarException(this.code);

  /// Reason of why the mutation has failed.
  UpdateUserAvatarErrorCode code;

  @override
  String toString() => 'UpdateUserAvatarException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserAvatarErrorCode.invalidCropCoordinates:
        return 'err_invalid_crop_coordinates'.td;
      case UpdateUserAvatarErrorCode.invalidCropPoints:
        return 'err_invalid_crop_points'.td;
      case UpdateUserAvatarErrorCode.unknownGalleryItem:
        return 'err_unknown_gallery_item'.td;
      case UpdateUserAvatarErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.updateUserCallCover` described in the [code].
class UpdateUserCallCoverException
    with LocalizedExceptionMixin
    implements Exception {
  UpdateUserCallCoverException(this.code);

  /// Reason of why the mutation has failed.
  UpdateUserCallCoverErrorCode code;

  @override
  String toString() => 'UpdateUserCallCoverException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserCallCoverErrorCode.invalidCropCoordinates:
        return 'err_invalid_crop_coordinates'.td;
      case UpdateUserCallCoverErrorCode.invalidCropPoints:
        return 'err_invalid_crop_points'.td;
      case UpdateUserCallCoverErrorCode.unknownGalleryItem:
        return 'err_unknown_gallery_item'.td;
      case UpdateUserCallCoverErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}

/// Exception of `Mutation.uploadUserGalleryItem` described in the [code].
class UploadUserGalleryItemException
    with LocalizedExceptionMixin
    implements Exception {
  UploadUserGalleryItemException(this.code);

  /// Reason of why the mutation has failed.
  UploadUserGalleryItemErrorCode code;

  @override
  String toString() => 'UploadUserGalleryItemException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UploadUserGalleryItemErrorCode.malformed:
        return 'err_uploaded_file_malformed'.td;
      case UploadUserGalleryItemErrorCode.unsupportedFormat:
        return 'err_unsupported_format'.td;
      case UploadUserGalleryItemErrorCode.artemisUnknown:
        return 'err_unknown'.td;
      case UploadUserGalleryItemErrorCode.tooBigSize:
        return 'err_size_too_big'.td;
      case UploadUserGalleryItemErrorCode.tooBigDimensions:
        return 'err_dimensions_too_big'.td;
    }
  }
}

/// Exception of `Mutation.transformDialogCallIntoGroupCall` described in the
/// [code].
class TransformDialogCallIntoGroupCallException
    with LocalizedExceptionMixin
    implements Exception {
  TransformDialogCallIntoGroupCallException(this.code);

  /// Reason of why the mutation has failed.
  TransformDialogCallIntoGroupCallErrorCode code;

  @override
  String toString() => 'TransformDialogCallIntoGroupCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case TransformDialogCallIntoGroupCallErrorCode.blacklisted:
        return 'err_blacklisted'.td;
      case TransformDialogCallIntoGroupCallErrorCode.notDialog:
        return 'err_not_dialog'.td;
      case TransformDialogCallIntoGroupCallErrorCode.noCall:
        return 'err_call_not_found'.td;
      case TransformDialogCallIntoGroupCallErrorCode.wrongMembersCount:
        return 'err_wrong_members_count'.td;
      case TransformDialogCallIntoGroupCallErrorCode.unknownChat:
        return 'err_unknown_chat'.td;
      case TransformDialogCallIntoGroupCallErrorCode.unknownUser:
        return 'err_unknown_user'.td;
      case TransformDialogCallIntoGroupCallErrorCode.artemisUnknown:
        return 'err_unknown'.td;
    }
  }
}
