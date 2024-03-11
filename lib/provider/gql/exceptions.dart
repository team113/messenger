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

import 'dart:io';

import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '/api/backend/schema.dart';
import '/domain/model/user.dart';
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
    Object? exception = parse(result, handleException);
    if (exception != null) throw exception;
  }

  /// Returns an exception of the given [result] with [handleException] if it
  /// has the specified error code or `null` if no exception was found.
  static Object? parse(QueryResult result,
      [Exception Function(Map<String, dynamic>)? handleException]) {
    if (result.hasException) {
      if (result.exception == null) {
        return Exception('err_unknown'.l10n);
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
          return const AuthorizationException();
        } else if (result.exception!.graphqlErrors.any(
            (e) => e.message.contains('Expected input scalar `UserPhone`'))) {
          return const InvalidScalarException<UserPhone>();
        }

        return GraphQlException(result.exception!.graphqlErrors);
      }

      if (result.exception!.linkException! is ServerException) {
        ServerException e = result.exception!.linkException! as ServerException;

        // If the original exception is "Failed to parse header value", then
        // it's `AuthorizationException`.
        if (e.originalException.toString() == 'Failed to parse header value') {
          return const AuthorizationException();
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
          if (found != null) throw const AuthorizationException();
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
  final List<GraphQLError> graphqlErrors;

  @override
  String toString() => 'GraphQlException($graphqlErrors)';

  @override
  String toMessage() {
    if (graphqlErrors.isEmpty) return 'err_unknown'.l10n;
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
  String toMessage() => 'err_network'.l10n;
}

/// Exception of an authentication absence or invalidity.
///
/// Thrown on header parsing errors or on 401 response status.
class AuthorizationException with LocalizedExceptionMixin implements Exception {
  const AuthorizationException();

  @override
  String toString() => 'AuthorizationException()';

  @override
  String toMessage() => 'err_unauthorized'.l10n;
}

/// Specific [GraphQlException] thrown on `NOT_CHAT_MEMBER` extension code.
class NotChatMemberException extends GraphQlException {
  NotChatMemberException([super.graphqlErrors]);

  @override
  String toString() => 'NotChatMemberException()';

  @override
  String toMessage() => 'err_not_member'.l10n;
}

/// Specific [GraphQlException] thrown on `STALE_VERSION` extension code.
class StaleVersionException extends GraphQlException {
  StaleVersionException([super.graphqlErrors]);

  @override
  String toString() => 'StaleVersionException()';

  @override
  String toMessage() => 'err_stale_version'.l10n;
}

/// Exception of a GraphQL re-subscription requirement.
///
/// Thrown on a GraphQL subscription timeout or on [AuthorizationException].
/// It's required to re-subscribe whenever this exception is thrown.
class ResubscriptionRequiredException implements Exception {
  const ResubscriptionRequiredException();

  @override
  String toString() => 'ResubscriptionRequiredException()';
}

/// Exception of an invalid GraphQL scalar being parsed when expecting the [T].
class InvalidScalarException<T> implements Exception {
  const InvalidScalarException();

  @override
  String toString() => 'InvalidScalarException<$T>()';
}

/// Exception of `Mutation.createSession` described in the [code].
class CreateSessionException with LocalizedExceptionMixin implements Exception {
  const CreateSessionException(this.code);

  /// Reason of why the mutation has failed.
  final CreateSessionErrorCode code;

  @override
  String toString() => 'CreateSessionException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateSessionErrorCode.wrongPassword:
        return 'err_incorrect_login_or_password'.l10n;
      case CreateSessionErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
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
  const CreateDialogException(this.code);

  /// Reason of why the mutation has failed.
  final CreateDialogChatErrorCode code;

  @override
  String toString() => 'CreateDialogException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateDialogChatErrorCode.blocked:
        return 'err_blocked'.l10n;
      case CreateDialogChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case CreateDialogChatErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case CreateDialogChatErrorCode.useMonolog:
        return 'err_use_monolog'.l10n;
    }
  }
}

/// Exception of `Mutation.createGroupChat` described in the [code].
class CreateGroupChatException
    with LocalizedExceptionMixin
    implements Exception {
  const CreateGroupChatException(this.code);

  /// Reason of why the mutation has failed.
  final CreateGroupChatErrorCode code;

  @override
  String toString() => 'CreateGroupException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateGroupChatErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case CreateGroupChatErrorCode.wrongMembersCount:
        return 'err_wrong_members_count'.l10n;
      case CreateGroupChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case CreateGroupChatErrorCode.blocked:
        return 'err_blocked_by_multiple'.l10n;
    }
  }
}

/// Exception of `Mutation.removeChatMember` described in the [code].
class RemoveChatMemberException
    with LocalizedExceptionMixin
    implements Exception {
  const RemoveChatMemberException(this.code);

  /// Reason of why the mutation has failed.
  final RemoveChatMemberErrorCode code;

  @override
  String toString() => 'RemoveChatMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RemoveChatMemberErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case RemoveChatMemberErrorCode.notGroup:
        return 'err_not_group'.l10n;
      case RemoveChatMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.startChatCall` described in the [code].
class StartChatCallException with LocalizedExceptionMixin implements Exception {
  const StartChatCallException(this.code);

  /// Reason of why the mutation has failed.
  final StartChatCallErrorCode code;

  @override
  String toString() => 'StartChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case StartChatCallErrorCode.blocked:
        return 'err_blocked'.l10n;
      case StartChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case StartChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.joinChatCall` described in the [code].
class JoinChatCallException with LocalizedExceptionMixin implements Exception {
  const JoinChatCallException(this.code);

  /// Reason of why the mutation has failed.
  final JoinChatCallErrorCode code;

  @override
  String toString() => 'JoinChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case JoinChatCallErrorCode.noCall:
        return 'err_call_not_found'.l10n;
      case JoinChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case JoinChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.leaveChatCall` described in the [code].
class LeaveChatCallException with LocalizedExceptionMixin implements Exception {
  const LeaveChatCallException(this.code);

  /// Reason of why the mutation has failed.
  final LeaveChatCallErrorCode code;

  @override
  String toString() => 'LeaveChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case LeaveChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case LeaveChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case LeaveChatCallErrorCode.unknownDevice:
        return 'err_unknown_device'.l10n;
    }
  }
}

/// Exception of `Mutation.declineChatCall` described in the [code].
class DeclineChatCallException
    with LocalizedExceptionMixin
    implements Exception {
  const DeclineChatCallException(this.code);

  /// Reason of why the mutation has failed.
  final DeclineChatCallErrorCode code;

  @override
  String toString() => 'DeclineChatCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeclineChatCallErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case DeclineChatCallErrorCode.alreadyJoined:
        return 'err_call_already_joined'.l10n;
      case DeclineChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateUserLogin` described in the [code].
class UpdateUserLoginException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateUserLoginException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateUserLoginErrorCode code;

  @override
  String toString() => 'UpdateUserLoginException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserLoginErrorCode.occupied:
        return 'err_login_occupied'.l10n;
      case UpdateUserLoginErrorCode.artemisUnknown:
        return 'err_data_transfer'.l10n;
    }
  }
}

/// Exception of `Mutation.uploadAttachment` described in the [code].
class UploadAttachmentException
    with LocalizedExceptionMixin
    implements Exception {
  const UploadAttachmentException(this.code);

  /// Reason of why the mutation has failed.
  final UploadAttachmentErrorCode code;

  @override
  String toString() => 'UploadAttachmentException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UploadAttachmentErrorCode.malformed:
        return 'err_uploaded_file_malformed'.l10n;
      case UploadAttachmentErrorCode.noFilename:
        return 'err_no_filename'.l10n;
      case UploadAttachmentErrorCode.invalidSize:
        return 'err_size_too_big'.l10n;
      case UploadAttachmentErrorCode.invalidDimensions:
        return 'err_dimensions_too_big'.l10n;
      case UploadAttachmentErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateUserPassword` described in the [code].
class UpdateUserPasswordException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateUserPasswordException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateUserPasswordErrorCode code;

  @override
  String toString() => 'UpdateUserPasswordException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserPasswordErrorCode.wrongOldPassword:
        return 'err_wrong_old_password'.l10n;
      case UpdateUserPasswordErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.createChatContact` described in the [code].
class CreateChatContactException
    with LocalizedExceptionMixin
    implements Exception {
  const CreateChatContactException(this.code);

  /// Reason of why the mutation has failed.
  final CreateChatContactErrorCode code;

  @override
  String toString() => 'CreateChatContactException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateChatContactErrorCode.unknownUser:
        return 'err_contact_unknown_user'.l10n;
      case CreateChatContactErrorCode.unknownChat:
        return 'err_contact_unknown_chat'.l10n;
      case CreateChatContactErrorCode.notGroup:
        return 'err_contact_not_group'.l10n;
      case CreateChatContactErrorCode.wrongRecordsCount:
        return 'err_contact_too_many'.l10n;
      case CreateChatContactErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.validateUserPasswordRecoveryCode` described in the
/// [code].
class ValidateUserPasswordRecoveryCodeException
    with LocalizedExceptionMixin
    implements Exception {
  const ValidateUserPasswordRecoveryCodeException(this.code);

  /// Reason of why the mutation has failed.
  final ValidateUserPasswordRecoveryErrorCode code;

  @override
  String toString() => 'ValidateUserPasswordRecoveryCodeException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ValidateUserPasswordRecoveryErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ValidateUserPasswordRecoveryErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.l10n;
    }
  }
}

/// Exception of `Mutation.resetUserPassword` described in the [code].
class ResetUserPasswordException
    with LocalizedExceptionMixin
    implements Exception {
  const ResetUserPasswordException(this.code);

  /// Reason of why the mutation has failed.
  final ResetUserPasswordErrorCode code;

  @override
  String toString() => 'ResetUserPasswordException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResetUserPasswordErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ResetUserPasswordErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.l10n;
    }
  }
}

/// Exception of `Mutation.addChatMember` described in the [code].
class AddChatMemberException with LocalizedExceptionMixin implements Exception {
  const AddChatMemberException(this.code);

  /// Reason of why the mutation has failed.
  final AddChatMemberErrorCode code;

  @override
  String toString() => 'AddChatMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddChatMemberErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case AddChatMemberErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case AddChatMemberErrorCode.blocked:
        return 'err_blocked'.l10n;
      case AddChatMemberErrorCode.notGroup:
        return 'err_not_group'.l10n;
      case AddChatMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.renameChat` described in the [code].
class RenameChatException with LocalizedExceptionMixin implements Exception {
  const RenameChatException(this.code);

  /// Reason of why the mutation has failed.
  final RenameChatErrorCode code;

  @override
  String toString() => 'RenameChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RenameChatErrorCode.unknownChat:
        return 'err_contact_unknown_chat'.l10n;
      case RenameChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case RenameChatErrorCode.dialog:
        return 'err_dialog'.l10n;
    }
  }
}

/// Exception of `Mutation.postChatMessage` described in the [code].
class PostChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  const PostChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  final PostChatMessageErrorCode code;

  @override
  String toString() => 'PostChatMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case PostChatMessageErrorCode.blocked:
        return 'err_blocked'.l10n;
      case PostChatMessageErrorCode.noTextAndNoAttachment:
        return 'err_no_text_and_no_attachment'.l10n;
      case PostChatMessageErrorCode.wrongAttachmentsCount:
        return 'err_wrong_attachments_items_count'.l10n;
      case PostChatMessageErrorCode.wrongReplyingChatItemsCount:
        return 'err_wrong_replying_item_count'.l10n;
      case PostChatMessageErrorCode.unknownAttachment:
        return 'err_unknown_attachment'.l10n;
      case PostChatMessageErrorCode.unknownReplyingChatItem:
        return 'err_unknown_replying_chat_item'.l10n;
      case PostChatMessageErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case PostChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.hideChat` described in the [code].
class HideChatException with LocalizedExceptionMixin implements Exception {
  const HideChatException(this.code);

  /// Reason of why the mutation has failed.
  final HideChatErrorCode code;

  @override
  String toString() => 'HideChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case HideChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case HideChatErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.updateChatContactName` described in the [code].
class UpdateChatContactNameException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateChatContactNameException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateChatContactNameErrorCode code;

  @override
  String toString() => 'UpdateChatContactNameException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateChatContactNameErrorCode.unknownChatContact:
        return 'err_unknown_contact'.l10n;
      case UpdateChatContactNameErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.addUserEmail` described in the [code].
class AddUserEmailException with LocalizedExceptionMixin implements Exception {
  const AddUserEmailException(this.code);

  /// Reason of why the mutation has failed.
  final AddUserEmailErrorCode code;

  @override
  String toString() => 'AddUserEmailException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddUserEmailErrorCode.artemisUnknown:
        return 'err_data_transfer'.l10n;
      case AddUserEmailErrorCode.busy:
        return 'err_you_already_has_unconfirmed_email'.l10n;
      case AddUserEmailErrorCode.tooMany:
        return 'err_too_many_emails'.l10n;
    }
  }
}

/// Exception of `Mutation.resendUserEmailConfirmation` described in the [code].
class ResendUserEmailConfirmationException
    with LocalizedExceptionMixin
    implements Exception {
  const ResendUserEmailConfirmationException(this.code);

  /// Reason of why the mutation has failed.
  final ResendUserEmailConfirmationErrorCode code;

  @override
  String toString() => 'ResendUserEmailConfirmationException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResendUserEmailConfirmationErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ResendUserEmailConfirmationErrorCode.codeLimitExceeded:
        return 'err_code_limit_exceeded'.l10n;
      case ResendUserEmailConfirmationErrorCode.noUnconfirmed:
        return 'err_no_unconfirmed_email'.l10n;
    }
  }
}

/// Exception of `Mutation.resendUserPhoneConfirmation` described in the [code].
class ResendUserPhoneConfirmationException
    with LocalizedExceptionMixin
    implements Exception {
  const ResendUserPhoneConfirmationException(this.code);

  /// Reason of why the mutation has failed.
  final ResendUserPhoneConfirmationErrorCode code;

  @override
  String toString() => 'ResendUserPhoneConfirmationException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ResendUserPhoneConfirmationErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ResendUserPhoneConfirmationErrorCode.codeLimitExceeded:
        return 'err_code_limit_exceeded'.l10n;
      case ResendUserPhoneConfirmationErrorCode.noUnconfirmed:
        return 'err_no_unconfirmed_phone'.l10n;
    }
  }
}

/// Exception of `Mutation.confirmUserEmail` described in the [code].
class ConfirmUserEmailException
    with LocalizedExceptionMixin
    implements Exception {
  const ConfirmUserEmailException(this.code);

  /// Reason of why the mutation has failed.
  final ConfirmUserEmailErrorCode code;

  @override
  String toString() => 'ConfirmUserEmailException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ConfirmUserEmailErrorCode.artemisUnknown:
        return 'err_data_transfer'.l10n;
      case ConfirmUserEmailErrorCode.occupied:
        return 'err_email_occupied'.l10n;
      case ConfirmUserEmailErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.l10n;
    }
  }
}

/// Exception of `Mutation.confirmUserPhone` described in the [code].
class ConfirmUserPhoneException
    with LocalizedExceptionMixin
    implements Exception {
  const ConfirmUserPhoneException(this.code);

  /// Reason of why the mutation has failed.
  final ConfirmUserPhoneErrorCode code;

  @override
  String toString() => 'ConfirmUserPhoneException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ConfirmUserPhoneErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ConfirmUserPhoneErrorCode.occupied:
        return 'err_wrong_recovery_code'.l10n;
      case ConfirmUserPhoneErrorCode.wrongCode:
        return 'err_wrong_recovery_code'.l10n;
    }
  }
}

/// Exception of `Mutation.addUserPhone` described in the [code].
class AddUserPhoneException with LocalizedExceptionMixin implements Exception {
  const AddUserPhoneException(this.code);

  /// Reason of why the mutation has failed.
  final AddUserPhoneErrorCode code;

  @override
  String toString() => 'AddUserPhoneException($code)';

  @override
  String toMessage() {
    switch (code) {
      case AddUserPhoneErrorCode.artemisUnknown:
        return 'err_data_transfer'.l10n;
      case AddUserPhoneErrorCode.busy:
        return 'err_you_already_has_unconfirmed_phone'.l10n;
      case AddUserPhoneErrorCode.tooMany:
        return 'err_too_many_phones'.l10n;
    }
  }
}

/// Exception of `Mutation.readChat` described in the [code].
class ReadChatException with LocalizedExceptionMixin implements Exception {
  const ReadChatException(this.code);

  /// Reason of why the mutation has failed.
  final ReadChatErrorCode code;

  @override
  String toString() => 'ReadChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ReadChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ReadChatErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case ReadChatErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
    }
  }
}

/// Exception of `Mutation.hideChatItem` described in the [code].
class HideChatItemException with LocalizedExceptionMixin implements Exception {
  const HideChatItemException(this.code);

  /// Reason of why the mutation has failed.
  final HideChatItemErrorCode code;

  @override
  String toString() => 'HideChatItemException($code)';

  @override
  String toMessage() {
    switch (code) {
      case HideChatItemErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case HideChatItemErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
    }
  }
}

/// Exception of `Mutation.deleteChatMessage` described in the [code].
class DeleteChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  const DeleteChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  final DeleteChatMessageErrorCode code;

  @override
  String toString() => 'DeleteChatMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case DeleteChatMessageErrorCode.notAuthor:
        return 'err_not_author'.l10n;
      case DeleteChatMessageErrorCode.quoted:
        return 'err_quoted_message'.l10n;
      case DeleteChatMessageErrorCode.read:
        return 'err_message_was_read'.l10n;
      case DeleteChatMessageErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
    }
  }
}

/// Exception of `Mutation.deleteChatForward` described in the [code].
class DeleteChatForwardException
    with LocalizedExceptionMixin
    implements Exception {
  const DeleteChatForwardException(this.code);

  /// Reason of why the mutation has failed.
  final DeleteChatForwardErrorCode code;

  @override
  String toString() => 'DeleteChatForwardException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatForwardErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case DeleteChatForwardErrorCode.notAuthor:
        return 'err_not_author'.l10n;
      case DeleteChatForwardErrorCode.quoted:
        return 'err_quoted_message'.l10n;
      case DeleteChatForwardErrorCode.read:
        return 'err_message_was_read'.l10n;
      case DeleteChatForwardErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
    }
  }
}

/// Exception of `Mutation.toggleChatCallHand` described in the [code].
class ToggleChatCallHandException
    with LocalizedExceptionMixin
    implements Exception {
  const ToggleChatCallHandException(this.code);

  /// Reason of why the mutation has failed.
  final ToggleChatCallHandErrorCode code;

  @override
  String toString() => 'ToggleChatCallHandException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ToggleChatCallHandErrorCode.notCallMember:
        return 'err_not_call_member'.l10n;
      case ToggleChatCallHandErrorCode.noCall:
        return 'err_call_not_found'.l10n;
      case ToggleChatCallHandErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case ToggleChatCallHandErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.redialChatCallMember` described in the [code].
class RedialChatCallMemberException
    with LocalizedExceptionMixin
    implements Exception {
  const RedialChatCallMemberException(this.code);

  /// Reason of why the mutation has failed.
  final RedialChatCallMemberErrorCode code;

  @override
  String toString() => 'RedialChatCallMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RedialChatCallMemberErrorCode.notCallMember:
        return 'err_not_call_member'.l10n;
      case RedialChatCallMemberErrorCode.noCall:
        return 'err_call_not_found'.l10n;
      case RedialChatCallMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case RedialChatCallMemberErrorCode.notChatMember:
        return 'err_not_member'.l10n;
      case RedialChatCallMemberErrorCode.notGroup:
        return 'err_contact_not_group'.l10n;
      case RedialChatCallMemberErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.createChatDirectLink` described in the [code].
class CreateChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  const CreateChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  final CreateChatDirectLinkErrorCode code;

  @override
  String toString() => 'CreateChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case CreateChatDirectLinkErrorCode.occupied:
        return 'err_chat_direct_link_occupied'.l10n;
      case CreateChatDirectLinkErrorCode.notGroup:
        return 'err_contact_not_group'.l10n;
      case CreateChatDirectLinkErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.deleteChatDirectLink` described in the [code].
class DeleteChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  const DeleteChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  final DeleteChatDirectLinkErrorCode code;

  @override
  String toString() => 'DeleteChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case DeleteChatDirectLinkErrorCode.notGroup:
        return 'err_contact_not_group'.l10n;
      case DeleteChatDirectLinkErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.useChatDirectLink` described in the [code].
class UseChatDirectLinkException
    with LocalizedExceptionMixin
    implements Exception {
  const UseChatDirectLinkException(this.code);

  /// Reason of why the mutation has failed.
  final UseChatDirectLinkErrorCode code;

  @override
  String toString() => 'UseChatDirectLinkException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UseChatDirectLinkErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case UseChatDirectLinkErrorCode.blocked:
        return 'err_you_are_blocked'.l10n;
      case UseChatDirectLinkErrorCode.unknownDirectLink:
        return 'err_unknown_chat_direct_link'.l10n;
    }
  }
}

/// Exception of `Mutation.editChatMessage` described in the [code].
class EditChatMessageException
    with LocalizedExceptionMixin
    implements Exception {
  const EditChatMessageException(this.code);

  /// Reason of why the mutation has failed.
  final EditChatMessageErrorCode code;

  @override
  String toString() => 'EditChatMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case EditChatMessageErrorCode.uneditable:
        return 'err_uneditable_message'.l10n;
      case EditChatMessageErrorCode.blocked:
        return 'err_blocked'.l10n;
      case EditChatMessageErrorCode.notAuthor:
        return 'err_not_author'.l10n;
      case EditChatMessageErrorCode.wrongAttachmentsCount:
        return 'err_wrong_attachments_items_count'.l10n;
      case EditChatMessageErrorCode.wrongReplyingChatItemsCount:
        return 'err_wrong_replying_item_count'.l10n;
      case EditChatMessageErrorCode.unknownAttachment:
        return 'err_unknown_attachment'.l10n;
      case EditChatMessageErrorCode.unknownReplyingChatItem:
        return 'err_unknown_replying_chat_item'.l10n;
      case EditChatMessageErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
      case EditChatMessageErrorCode.noTextAndNoAttachment:
        return 'err_no_text_and_no_attachment'.l10n;
      case EditChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateUserAvatar` described in the [code].
class UpdateUserAvatarException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateUserAvatarException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateUserAvatarErrorCode code;

  @override
  String toString() => 'UpdateUserAvatarException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserAvatarErrorCode.invalidCropCoordinates:
        return 'err_invalid_crop_coordinates'.l10n;
      case UpdateUserAvatarErrorCode.invalidCropPoints:
        return 'err_invalid_crop_points'.l10n;
      case UpdateUserAvatarErrorCode.malformed:
        return 'err_uploaded_file_malformed'.l10n;
      case UpdateUserAvatarErrorCode.unsupportedFormat:
        return 'err_unsupported_format'.l10n;
      case UpdateUserAvatarErrorCode.invalidSize:
        return 'err_size_too_big'.l10n;
      case UpdateUserAvatarErrorCode.invalidDimensions:
        return 'err_dimensions_too_big'.l10n;
      case UpdateUserAvatarErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateUserCallCover` described in the [code].
class UpdateUserCallCoverException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateUserCallCoverException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateUserCallCoverErrorCode code;

  @override
  String toString() => 'UpdateUserCallCoverException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateUserCallCoverErrorCode.invalidCropCoordinates:
        return 'err_invalid_crop_coordinates'.l10n;
      case UpdateUserCallCoverErrorCode.invalidCropPoints:
        return 'err_invalid_crop_points'.l10n;
      case UpdateUserCallCoverErrorCode.malformed:
        return 'err_uploaded_file_malformed'.l10n;
      case UpdateUserCallCoverErrorCode.unsupportedFormat:
        return 'err_unsupported_format'.l10n;
      case UpdateUserCallCoverErrorCode.invalidSize:
        return 'err_size_too_big'.l10n;
      case UpdateUserCallCoverErrorCode.invalidDimensions:
        return 'err_dimensions_too_big'.l10n;
      case UpdateUserCallCoverErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.toggleMyUserMute` described in the [code].
class ToggleMyUserMuteException
    with LocalizedExceptionMixin
    implements Exception {
  const ToggleMyUserMuteException(this.code);

  /// Reason of why the mutation has failed.
  final ToggleMyUserMuteErrorCode code;

  @override
  String toString() => 'ToggleMyUserMuteException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ToggleMyUserMuteErrorCode.tooShort:
        return 'err_too_short'.l10n;
      case ToggleMyUserMuteErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.transformDialogCallIntoGroupCall` described in the
/// [code].
class TransformDialogCallIntoGroupCallException
    with LocalizedExceptionMixin
    implements Exception {
  const TransformDialogCallIntoGroupCallException(this.code);

  /// Reason of why the mutation has failed.
  final TransformDialogCallIntoGroupCallErrorCode code;

  @override
  String toString() => 'TransformDialogCallIntoGroupCallException($code)';

  @override
  String toMessage() {
    switch (code) {
      case TransformDialogCallIntoGroupCallErrorCode.blocked:
        return 'err_blocked_by_multiple'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.notDialog:
        return 'err_not_dialog'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.noCall:
        return 'err_call_not_found'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.wrongMembersCount:
        return 'err_wrong_members_count'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case TransformDialogCallIntoGroupCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.forwardChatItems` described in the [code].
class ForwardChatItemsException
    with LocalizedExceptionMixin
    implements Exception {
  const ForwardChatItemsException(this.code);

  /// Reason of why the mutation has failed.
  final ForwardChatItemsErrorCode code;

  @override
  String toString() => 'ForwardChatItemsException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ForwardChatItemsErrorCode.blocked:
        return 'err_blocked'.l10n;
      case ForwardChatItemsErrorCode.noTextAndNoAttachment:
        return 'err_no_text_and_no_attachment'.l10n;
      case ForwardChatItemsErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case ForwardChatItemsErrorCode.wrongItemsCount:
        return 'err_wrong_items_count'.l10n;
      case ForwardChatItemsErrorCode.unknownForwardedAttachment:
        return 'err_unknown_forwarded_attachment'.l10n;
      case ForwardChatItemsErrorCode.unsupportedForwardedItem:
        return 'err_unsupported_forwarded_item'.l10n;
      case ForwardChatItemsErrorCode.unknownForwardedItem:
        return 'err_unknown_forwarded_item'.l10n;
      case ForwardChatItemsErrorCode.unknownAttachment:
        return 'err_unknown_attachment'.l10n;
      case ForwardChatItemsErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateChatAvatar` described in the [code].
class UpdateChatAvatarException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateChatAvatarException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateChatAvatarErrorCode code;

  @override
  String toString() => 'UpdateChatAvatarException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateChatAvatarErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case UpdateChatAvatarErrorCode.invalidCropCoordinates:
        return 'err_invalid_crop_coordinates'.l10n;
      case UpdateChatAvatarErrorCode.invalidCropPoints:
        return 'err_invalid_crop_points'.l10n;
      case UpdateChatAvatarErrorCode.malformed:
        return 'err_uploaded_file_malformed'.l10n;
      case UpdateChatAvatarErrorCode.unsupportedFormat:
        return 'err_unsupported_format'.l10n;
      case UpdateChatAvatarErrorCode.invalidSize:
        return 'err_size_too_big'.l10n;
      case UpdateChatAvatarErrorCode.invalidDimensions:
        return 'err_dimensions_too_big'.l10n;
      case UpdateChatAvatarErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case UpdateChatAvatarErrorCode.dialog:
        return 'err_dialog'.l10n;
    }
  }
}

/// Exception of `Mutation.toggleChatMute` described in the [code].
class ToggleChatMuteException
    with LocalizedExceptionMixin
    implements Exception {
  const ToggleChatMuteException(this.code);

  /// Reason of why the mutation has failed.
  final ToggleChatMuteErrorCode code;

  @override
  String toString() => 'ToggleChatMuteException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ToggleChatMuteErrorCode.tooShort:
        return 'err_too_short'.l10n;
      case ToggleChatMuteErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case ToggleChatMuteErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ToggleChatMuteErrorCode.monolog:
        return 'err_monolog'.l10n;
    }
  }
}

/// Exception of `Mutation.favoriteChat` described in the [code].
class FavoriteChatException with LocalizedExceptionMixin implements Exception {
  const FavoriteChatException(this.code);

  /// Reason of why the mutation has failed.
  final FavoriteChatErrorCode code;

  @override
  String toString() => 'FavoriteChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case FavoriteChatErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case FavoriteChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.unfavoriteChat` described in the [code].
class UnfavoriteChatException
    with LocalizedExceptionMixin
    implements Exception {
  const UnfavoriteChatException(this.code);

  /// Reason of why the mutation has failed.
  final UnfavoriteChatErrorCode code;

  @override
  String toString() => 'UnfavoriteChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UnfavoriteChatErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case UnfavoriteChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.favoriteChatContact` described in the [code].
class FavoriteChatContactException
    with LocalizedExceptionMixin
    implements Exception {
  const FavoriteChatContactException(this.code);

  /// Reason of why the mutation has failed.
  final FavoriteChatContactErrorCode code;

  @override
  String toString() => 'FavoriteChatContactException($code)';

  @override
  String toMessage() {
    switch (code) {
      case FavoriteChatContactErrorCode.unknownChatContact:
        return 'err_unknown_chat'.l10n;
      case FavoriteChatContactErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.unfavoriteChatContact` described in the [code].
class UnfavoriteChatContactException
    with LocalizedExceptionMixin
    implements Exception {
  const UnfavoriteChatContactException(this.code);

  /// Reason of why the mutation has failed.
  final UnfavoriteChatContactErrorCode code;

  @override
  String toString() => 'UnfavoriteChatContactException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UnfavoriteChatContactErrorCode.unknownChatContact:
        return 'err_unknown_chat'.l10n;
      case UnfavoriteChatContactErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.blockUser` described in the [code].
class BlockUserException with LocalizedExceptionMixin implements Exception {
  const BlockUserException(this.code);

  /// Reason of why the mutation has failed.
  final BlockUserErrorCode code;

  @override
  String toString() => 'BlockUserErrorCode($code)';

  @override
  String toMessage() {
    switch (code) {
      case BlockUserErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case BlockUserErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.unblockUser` described in the [code].
class UnblockUserException with LocalizedExceptionMixin implements Exception {
  const UnblockUserException(this.code);

  /// Reason of why the mutation has failed.
  final UnblockUserErrorCode code;

  @override
  String toString() => 'UnblockUserException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UnblockUserErrorCode.unknownUser:
        return 'err_unknown_user'.l10n;
      case UnblockUserErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.clearChat` described in the [code].
class ClearChatException with LocalizedExceptionMixin implements Exception {
  const ClearChatException(this.code);

  /// Reason of why the mutation has failed.
  final ClearChatErrorCode code;

  @override
  String toString() => 'ClearChatException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ClearChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case ClearChatErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
      case ClearChatErrorCode.unknownChatItem:
        return 'err_unknown_chat_item'.l10n;
    }
  }
}

/// Exception of `Mutation.removeChatCallMember` described in the [code].
class RemoveChatCallMemberException
    with LocalizedExceptionMixin
    implements Exception {
  const RemoveChatCallMemberException(this.code);

  /// Reason of why the mutation has failed.
  final RemoveChatCallMemberErrorCode code;

  @override
  String toString() => 'RemoveChatCallMemberException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RemoveChatCallMemberErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
      case RemoveChatCallMemberErrorCode.notGroup:
        return 'err_not_group'.l10n;
      case RemoveChatCallMemberErrorCode.notMember:
        return 'err_not_member'.l10n;
      case RemoveChatCallMemberErrorCode.unknownChat:
        return 'err_unknown_chat'.l10n;
    }
  }
}

/// Exception of `Mutation.registerFcmDevice` described in the [code].
class RegisterFcmDeviceException
    with LocalizedExceptionMixin
    implements Exception {
  const RegisterFcmDeviceException(this.code);

  /// Reason of why the mutation has failed.
  final RegisterFcmDeviceErrorCode code;

  @override
  String toString() => 'RegisterFcmDeviceException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RegisterFcmDeviceErrorCode.invalidRegistrationToken:
        return 'err_invalid_registration_token'.l10n;
      case RegisterFcmDeviceErrorCode.unknownRegistrationToken:
        return 'err_unknown_registration_token'.l10n;
      case RegisterFcmDeviceErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}
