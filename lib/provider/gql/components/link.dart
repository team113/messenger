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

import 'dart:async';

import 'package:graphql/client.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/link.dart';
import '/store/model/link.dart';
import '/util/log.dart';

/// [DirectLink] related functionality.
mixin LinkGraphQlMixin {
  GraphQlClient get client;

  /// Uses the specified [DirectLink] by the authenticated [MyUser], creating a
  /// new [Chat]-dialog, or joining an existing [Chat]-group.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns the created or modified [Chat].
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [ChatItemPostedEvent] ([ChatInfo] with either a [ChatInfoActionCreated]
  /// or a [ChatInfoActionMemberAdded]).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the authenticated
  /// [MyUser] is already a member of the [Chat]-group or has already a created
  /// [Chat]-dialog with the User the specified [DirectLink] leads to.
  Future<UseDirectLink$Mutation$UseDirectLink$UseDirectLinkOk> useDirectLink(
    DirectLinkSlug slug,
  ) async {
    Log.debug('useDirectLink($slug)', '$runtimeType');

    final variables = UseDirectLinkArguments(slug: slug);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UseDirectLink',
        document: UseDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UseDirectLinkException(
        (UseDirectLink$Mutation.fromJson(data).useDirectLink
                as UseDirectLink$Mutation$UseDirectLink$UseDirectLinkError)
            .code,
      ),
    );
    return (UseDirectLink$Mutation.fromJson(result.data!).useDirectLink
        as UseDirectLink$Mutation$UseDirectLink$UseDirectLinkOk);
  }

  /// Creates, updates or disabled the specified [DirectLink] owned by the
  /// authenticated [MyUser].
  ///
  /// [MyUser] can have multiple [DirectLink]s leading to himself or any other
  /// [DirectLinkLocation].
  ///
  /// If the [location] argument is `null` or absent, then the specified
  /// [DirectLink] will be disabled.
  ///
  /// Disabled [DirectLink]s can be re-enabled again by the authenticated
  /// [MyUser], but can never ever leak to somebody else.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// The following [DirectLinkEvent]s may be produced on success:
  /// - [DirectLinkCreatedEvent], [DirectLinkEnabledEvent],
  /// [DirectLinkLocationUpdatedEvent] (if the [location] argument is not
  /// `null`);
  /// - [DirectLinkDisabledEvent] (if the location argument is `null` or
  /// absent).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [DirectLinkEvent]s) if the specified
  /// [DirectLink] exists, enabled and leads to the specified
  /// [DirectLinkLocation] already, or is disabled already.
  Future<DirectLinkVersionedEventsMixin?> updateDirectLink(
    DirectLinkSlug slug,
    DirectLinkLocationInput? location,
  ) async {
    Log.debug('updateDirectLink($slug, location: $location)', '$runtimeType');

    final variables = UpdateDirectLinkArguments(slug: slug, location: location);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UpdateDirectLink',
        document: UpdateDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateDirectLinkException(
        (UpdateDirectLink$Mutation.fromJson(data).updateDirectLink
                as UpdateDirectLink$Mutation$UpdateDirectLink$UpdateDirectLinkError)
            .code,
      ),
    );
    return (UpdateDirectLink$Mutation.fromJson(result.data!).updateDirectLink
        as DirectLinkVersionedEventsMixin?);
  }

  /// Creates, updates or disables the current [DirectLink] of the specified
  /// [Chat]-group.
  ///
  /// [Chat]-group can have only a single enabled [DirectLink] at the time. The
  /// previous enabled [DirectLink] (if there is any already) will be
  /// automatically disabled.
  ///
  /// If the [slug] argument is `null` or absent, then the current enabled
  /// [DirectLink] of the specified [Chat]-group will be disabled.
  ///
  /// Disabled [DirectLink]s can be re-enabled again for the specified
  /// [Chat]-group, but can never ever leak to somebody else.
  ///
  /// Authentication
  ///
  /// Mandatory.
  ///
  /// Result
  ///
  /// Only the following [DirectLinkEvent]s may be produced on success:
  /// - [DirectLinkCreatedEvent], [DirectLinkEnabledEvent],
  /// [DirectLinkDisabledEvent] (if the [slug] argument is not `null`);
  /// - [DirectLinkDisabledEvent] (if the [slug] argument is `null` or absent).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [DirectLinkEvent]s) if the specified
  /// [Chat]-group has an enabled [DirectLink] with such [DirectLinkSlug]
  /// already, or has no enabled [DirectLink] already.
  Future<DirectLinkVersionedEventsMixin?> updateGroupDirectLink(
    ChatId groupId,
    DirectLinkSlug? slug,
  ) async {
    Log.debug('updateGroupDirectLink($groupId, $slug)', '$runtimeType');

    final variables = UpdateGroupDirectLinkArguments(
      slug: slug,
      groupId: groupId,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UpdateGroupDirectLink',
        document: UpdateGroupDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UpdateGroupDirectLinkException(
        (UpdateGroupDirectLink$Mutation.fromJson(data).updateGroupDirectLink
                as UpdateGroupDirectLink$Mutation$UpdateGroupDirectLink$UpdateGroupDirectLinkError)
            .code,
      ),
    );
    return (UpdateGroupDirectLink$Mutation.fromJson(
          result.data!,
        ).updateGroupDirectLink
        as DirectLinkVersionedEventsMixin?);
  }

  /// Returns [DirectLink]s owned by the authenticated [MyUser] or the specified
  /// [Chat]-group, filtered by the provided criteria.
  ///
  /// Searching `by.slug` is exact, returning only a single [DirectLink] and
  /// making the pagination meaningless.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Sorting
  ///
  /// Returned [DirectLink]s are sorted depending on the provided arguments:
  /// - If the `by.slug` argument is specified, then an exact [DirectLink] is
  /// returned.
  /// - Otherwise, the returned [DirectLink]s are sorted primarily by their
  /// [DirectLink.createdAt] field, and secondary by their [DirectLink.slug]
  /// field, in descending order.
  Future<DirectLinks$Query$DirectLinks> directLinks({
    ChatId? chatId,
    DirectLinksFilter? by,
    DirectLinksPagination? pagination,
  }) async {
    Log.debug(
      'updateGroupDirectLink(chatId: $chatId, by: $by, pagination: $pagination)',
      '$runtimeType',
    );

    final variables = DirectLinksArguments(
      chatId: chatId,
      by: by,
      pagination: pagination,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'DirectLinks',
        document: DirectLinksQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return DirectLinks$Query.fromJson(result.data!).directLinks;
  }

  /// Subscribes to [DirectLinkEvent]s owned by the authenticated [MyUser] or
  /// the specified [Chat]-group.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Result
  ///
  /// If the [ver] argument is not specified (or is `null`) an initial state of
  /// the `DirectLinksList` will be emitted after SubscriptionInitialized and
  /// before any other [DirectLinkEvent]s (and won't be emitted ever again until
  /// this subscription completes). This allows to skip calling the
  /// [directLinks] before establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return a `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [directLinks];
  /// - or a re-subscription should be done without specifying the [ver]
  /// argument (so a fresh [ver] may be obtained in the emitted initial state of
  /// the `DirectLinksList`).
  ///
  /// ### Completion
  ///
  /// Finite.
  ///
  /// Completes without re-subscription necessity when:
  /// - The [Chat]-group does not exist (emits nothing, completes immediately
  /// after being established).
  /// - The authenticated [MyUser] is not a member of the [Chat]-group at th
  ///  moment of subscribing (emits nothing, completes immediately after being
  /// established).
  /// - The authenticated [MyUser] is no longer a member of the [Chat]-group
  /// (completes immediately after leaving the [Chat]-group).
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated Session expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  ///
  /// ### Idempotency
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some [DirectLink], so a
  /// client side is expected to handle all the events idempotently considering
  /// the [DtoDirectLink.ver].
  Stream<QueryResult> directLinksEvents({
    ChatId? chatId,
    DirectLinkVersion? ver,
    FutureOr<DirectLinkVersion?> Function()? onVer,
  }) {
    Log.debug('directLinksEvents($chatId, $ver, onVer)', '$runtimeType');

    final variables = DirectLinksEventsArguments(chatId: chatId, ver: ver);
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'DirectLinksEvents',
        document: DirectLinksEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      ver: onVer,
    );
  }
}
