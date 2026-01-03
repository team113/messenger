// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
  static void fire(
    QueryResult result, [
    Exception Function(Map<String, dynamic>)? handleException,
  ]) {
    Object? exception = parse(result, handleException);
    if (exception != null) throw exception;
  }

  /// Returns an exception of the given [result] with [handleException] if it
  /// has the specified error code or `null` if no exception was found.
  static Object? parse(
    QueryResult result, [
    Exception Function(Map<String, dynamic>)? handleException,
  ]) {
    if (result.hasException) {
      if (result.exception == null) {
        return Exception('err_unknown'.l10n);
      }

      // If no exceptions lay in `linkException`, then it is `GraphQlException`.
      if (result.exception!.linkException == null) {
        // If `GraphQlException` contains `NOT_CHAT_MEMBER` code, then it's a
        // specific `NotChatMemberException`.
        if (result.exception!.graphqlErrors.firstWhereOrNull(
              (e) => e.extensions?['code'] == 'NOT_CHAT_MEMBER',
            ) !=
            null) {
          return NotChatMemberException(result.exception!.graphqlErrors);
        } else if (result.exception!.graphqlErrors.firstWhereOrNull(
              (e) => e.extensions?['code'] == 'STALE_VERSION',
            ) !=
            null) {
          // If `GraphQlException` contains `STALE_VERSION` code, then it's a
          // specific `StaleVersionException`.
          return StaleVersionException(result.exception!.graphqlErrors);
        } else if (result.exception!.graphqlErrors.firstWhereOrNull(
              (e) =>
                  e.extensions?['code'] == 'SESSION_EXPIRED' ||
                  e.extensions?['code'] == 'AUTHENTICATION_REQUIRED' ||
                  e.extensions?['code'] == 'AUTHENTICATION_FAILED',
            ) !=
            null) {
          return const AuthorizationException();
        } else if (result.exception!.graphqlErrors.any(
          (e) => e.message.contains('Expected input scalar `UserPhone`'),
        )) {
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
            (v) => v.extensions != null && (v.extensions!['status'] == 401),
          );
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
  String toMessage() => toString();
}

/// Specific [GraphQlException] thrown on `STALE_VERSION` extension code.
class StaleVersionException extends GraphQlException {
  StaleVersionException([super.graphqlErrors]);

  @override
  String toString() => 'StaleVersionException()';

  @override
  String toMessage() => toString();
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
      case CreateSessionErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case CreateSessionErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.refreshSession` described in the [code].
class RefreshSessionException implements Exception {
  RefreshSessionException(this.code);

  /// Reason of why the mutation has failed.
  RefreshSessionErrorCode code;

  @override
  String toString() => 'RefreshSessionException($code)';
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
      case CreateDialogChatErrorCode.useMonolog:
        return toString();
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
        return toString();

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
      case RemoveChatMemberErrorCode.unknownChat:
        return toString();
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
      case StartChatCallErrorCode.unknownUser:
        return toString();

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
      case JoinChatCallErrorCode.unknownChat:
        return toString();

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
      case LeaveChatCallErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;

      case LeaveChatCallErrorCode.unknownChat:
      case LeaveChatCallErrorCode.unknownDevice:
        return toString();
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
      case DeclineChatCallErrorCode.alreadyJoined:
        return toString();

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
        return 'err_wrong_password'.l10n;
      case UpdateUserPasswordErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case UpdateUserPasswordErrorCode.confirmationRequired:
        return toString();
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
      case CreateChatContactErrorCode.unknownChat:
      case CreateChatContactErrorCode.notGroup:
      case CreateChatContactErrorCode.wrongRecordsCount:
        return toString();

      case CreateChatContactErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
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

      case AddChatMemberErrorCode.blocked:
        return 'err_blocked'.l10n;

      case AddChatMemberErrorCode.unknownUser:
      case AddChatMemberErrorCode.notGroup:
      case AddChatMemberErrorCode.unknownChat:
        return toString();
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
      case RenameChatErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;

      case RenameChatErrorCode.unknownChat:
      case RenameChatErrorCode.dialog:
        return toString();
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

      case PostChatMessageErrorCode.noContent:
      case PostChatMessageErrorCode.notEnoughFunds:
      case PostChatMessageErrorCode.unallowedDonation:
      case PostChatMessageErrorCode.unknownAttachment:
      case PostChatMessageErrorCode.wrongAttachmentsCount:
      case PostChatMessageErrorCode.unknownReplyingChatItem:
      case PostChatMessageErrorCode.wrongReplyingChatItemsCount:
      case PostChatMessageErrorCode.unknownChat:
      case PostChatMessageErrorCode.unknownUser:
        return toString();

      case PostChatMessageErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.toggleChatArchivation` described in the [code].
class ToggleChatArchivationException
    with LocalizedExceptionMixin
    implements Exception {
  const ToggleChatArchivationException(this.code);

  /// Reason of why the mutation has failed.
  final ToggleChatArchivationErrorCode code;

  @override
  String toString() => 'ToggleChatArchivationException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ToggleChatArchivationErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;

      case ToggleChatArchivationErrorCode.unknownChat:
        return toString();
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
        return toString();
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
        return toString();

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

      case AddUserEmailErrorCode.occupied:
        return 'err_email_occupied'.l10n;

      case AddUserEmailErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;

      case AddUserEmailErrorCode.tooMany:
        return 'err_too_many_emails'.l10n;

      case AddUserEmailErrorCode.busy:
        return toString();
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

      case AddUserPhoneErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;

      case AddUserPhoneErrorCode.occupied:
      case AddUserPhoneErrorCode.tooMany:
      case AddUserPhoneErrorCode.busy:
        return toString();
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
      case ReadChatErrorCode.unknownChatItem:
        return toString();
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
        return toString();
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
      case DeleteChatMessageErrorCode.quoted:
      case DeleteChatMessageErrorCode.uneditable:
        return 'err_message_was_read'.l10n;

      case DeleteChatMessageErrorCode.unknownChatItem:
        return toString();
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
      case DeleteChatForwardErrorCode.quoted:
      case DeleteChatForwardErrorCode.uneditable:
        return 'err_message_was_read'.l10n;

      case DeleteChatForwardErrorCode.unknownChatItem:
        return toString();
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
      case ToggleChatCallHandErrorCode.noCall:
      case ToggleChatCallHandErrorCode.unknownChat:
        return toString();

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
      case RedialChatCallMemberErrorCode.noCall:
      case RedialChatCallMemberErrorCode.unknownChat:
      case RedialChatCallMemberErrorCode.unknownUser:
      case RedialChatCallMemberErrorCode.notChatMember:
      case RedialChatCallMemberErrorCode.notGroup:
        return toString();

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
      case CreateChatDirectLinkErrorCode.unknownChat:
        return toString();
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
      case DeleteChatDirectLinkErrorCode.unknownChat:
        return toString();
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
        return 'label_unknown_chat_direct_link'.l10n;
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

      case EditChatMessageErrorCode.unknownReplyingChatItem:
      case EditChatMessageErrorCode.unknownChatItem:
      case EditChatMessageErrorCode.wrongReplyingChatItemsCount:
      case EditChatMessageErrorCode.wrongAttachmentsCount:
      case EditChatMessageErrorCode.unknownAttachment:
      case EditChatMessageErrorCode.notAuthor:
      case EditChatMessageErrorCode.noContent:
        return toString();

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
      case UpdateUserAvatarErrorCode.invalidCropPoints:
        return toString();

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
      case UpdateUserCallCoverErrorCode.invalidCropPoints:
        return toString();

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
        return toString();

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

      case TransformDialogCallIntoGroupCallErrorCode.wrongMembersCount:
        return 'err_wrong_members_count'.l10n;

      case TransformDialogCallIntoGroupCallErrorCode.notDialog:
      case TransformDialogCallIntoGroupCallErrorCode.noCall:
      case TransformDialogCallIntoGroupCallErrorCode.unknownChat:
      case TransformDialogCallIntoGroupCallErrorCode.unknownUser:
        return toString();

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

      case ForwardChatItemsErrorCode.unknownChat:
      case ForwardChatItemsErrorCode.unknownUser:
      case ForwardChatItemsErrorCode.unknownForwardedAttachment:
      case ForwardChatItemsErrorCode.noQuotedContent:
      case ForwardChatItemsErrorCode.notEnoughFunds:
      case ForwardChatItemsErrorCode.unallowedDonation:
      case ForwardChatItemsErrorCode.unknownForwardedDonation:
      case ForwardChatItemsErrorCode.wrongItemsCount:
      case ForwardChatItemsErrorCode.unsupportedForwardedItem:
      case ForwardChatItemsErrorCode.unknownAttachment:
      case ForwardChatItemsErrorCode.unknownForwardedItem:
        return toString();

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

      case UpdateChatAvatarErrorCode.unknownChat:
      case UpdateChatAvatarErrorCode.invalidCropCoordinates:
      case UpdateChatAvatarErrorCode.invalidCropPoints:
      case UpdateChatAvatarErrorCode.dialog:
        return toString();
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
      case ToggleChatMuteErrorCode.monolog:
      case ToggleChatMuteErrorCode.unknownChat:
        return toString();

      case ToggleChatMuteErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
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
        return toString();

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
        return toString();

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
        return toString();

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
        return toString();

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
        return toString();

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
        return toString();

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
      case ClearChatErrorCode.unknownChatItem:
        return toString();
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
      case RemoveChatCallMemberErrorCode.notMember:
      case RemoveChatCallMemberErrorCode.unknownChat:
        return toString();
    }
  }
}

/// Exception of `Mutation.registerPushDevice` described in the [code].
class RegisterPushDeviceException
    with LocalizedExceptionMixin
    implements Exception {
  const RegisterPushDeviceException(this.code);

  /// Reason of why the mutation has failed.
  final RegisterPushDeviceErrorCode? code;

  @override
  String toString() => 'RegisterPushDeviceException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RegisterPushDeviceErrorCode.occupied:
        return toString();

      case RegisterPushDeviceErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;

      case RegisterPushDeviceErrorCode.unknownDeviceToken:
      case RegisterPushDeviceErrorCode.unavailable:
        return toString();

      case null:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.deleteSession` described in the [code].
class DeleteSessionException with LocalizedExceptionMixin implements Exception {
  const DeleteSessionException(this.code);

  /// Reason of why the mutation has failed.
  final DeleteSessionErrorCode code;

  @override
  String toString() => 'DeleteSessionException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteSessionErrorCode.wrongPassword:
        return 'err_wrong_password'.l10n;
      case DeleteSessionErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case DeleteSessionErrorCode.confirmationRequired:
        return toString();
      case DeleteSessionErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.createSession` described in the [code].
class SignUpException with LocalizedExceptionMixin implements Exception {
  const SignUpException(this.code);

  /// Reason of why the mutation has failed.
  final CreateUserErrorCode code;

  @override
  String toString() => 'SignUpException($code)';

  @override
  String toMessage() {
    switch (code) {
      case CreateUserErrorCode.occupied:
        return 'err_login_occupied'.l10n;
      case CreateUserErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.deleteMyUser` described in the [code].
class DeleteMyUserException with LocalizedExceptionMixin implements Exception {
  const DeleteMyUserException(this.code);

  /// Reason of why the mutation has failed.
  final DeleteMyUserErrorCode code;

  @override
  String toString() => 'DeleteMyUserException($code)';

  @override
  String toMessage() {
    switch (code) {
      case DeleteMyUserErrorCode.confirmationRequired:
        return toString();
      case DeleteMyUserErrorCode.wrongPassword:
        return 'err_wrong_password'.l10n;
      case DeleteMyUserErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case DeleteMyUserErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.removeUserEmail` described in the [code].
class RemoveUserEmailException
    with LocalizedExceptionMixin
    implements Exception {
  const RemoveUserEmailException(this.code);

  /// Reason of why the mutation has failed.
  final RemoveUserEmailErrorCode code;

  @override
  String toString() => 'RemoveUserEmailException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RemoveUserEmailErrorCode.confirmationRequired:
        return toString();
      case RemoveUserEmailErrorCode.wrongPassword:
        return 'err_wrong_password'.l10n;
      case RemoveUserEmailErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case RemoveUserEmailErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.removeUserPhone` described in the [code].
class RemoveUserPhoneException
    with LocalizedExceptionMixin
    implements Exception {
  const RemoveUserPhoneException(this.code);

  /// Reason of why the mutation has failed.
  final RemoveUserPhoneErrorCode code;

  @override
  String toString() => 'DeleteUsePhoneException($code)';

  @override
  String toMessage() {
    switch (code) {
      case RemoveUserPhoneErrorCode.confirmationRequired:
        return toString();
      case RemoveUserPhoneErrorCode.wrongPassword:
        return 'err_wrong_password'.l10n;
      case RemoveUserPhoneErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case RemoveUserPhoneErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.validateConfirmationCode` described in the [code].
class ValidateConfirmationCodeException
    with LocalizedExceptionMixin
    implements Exception {
  const ValidateConfirmationCodeException(this.code);

  /// Reason of why the mutation has failed.
  final ValidateConfirmationCodeErrorCode code;

  @override
  String toString() => 'ValidateConfirmationCodeException($code)';

  @override
  String toMessage() {
    switch (code) {
      case ValidateConfirmationCodeErrorCode.wrongCode:
        return 'err_wrong_code'.l10n;
      case ValidateConfirmationCodeErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}

/// Exception of `Mutation.updateWelcomeMessage` described in the [code].
class UpdateWelcomeMessageException
    with LocalizedExceptionMixin
    implements Exception {
  const UpdateWelcomeMessageException(this.code);

  /// Reason of why the mutation has failed.
  final UpdateWelcomeMessageErrorCode code;

  @override
  String toString() => 'UpdateWelcomeMessageException($code)';

  @override
  String toMessage() {
    switch (code) {
      case UpdateWelcomeMessageErrorCode.wrongAttachmentsCount:
      case UpdateWelcomeMessageErrorCode.unknownAttachment:
      case UpdateWelcomeMessageErrorCode.noContent:
        return toString();

      case UpdateWelcomeMessageErrorCode.artemisUnknown:
        return 'err_unknown'.l10n;
    }
  }
}
