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

// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get.dart';
// import 'package:graphql/client.dart';
// import 'package:messenger/api/backend/schema.dart';
// import 'package:messenger/domain/model/contact.dart';
// import 'package:messenger/domain/model/user.dart';
// import 'package:messenger/domain/repository/contact.dart';
// import 'package:messenger/domain/service/contact.dart';
// import 'package:messenger/provider/drift/credentials.dart';
// import 'package:messenger/provider/drift/drift.dart';
// import 'package:messenger/provider/drift/user.dart';
// import 'package:messenger/provider/drift/version.dart';
// import 'package:messenger/provider/gql/exceptions.dart';
// import 'package:messenger/provider/gql/graphql.dart';
// import 'package:messenger/store/contact.dart';
// import 'package:messenger/store/user.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';

// import 'contact_rename_test.mocks.dart';

// @GenerateNiceMocks([MockSpec<GraphQlProvider>()])
void main() async {
  // final CommonDriftProvider common = CommonDriftProvider.memory();
  // final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  // final credentialsProvider = Get.put(CredentialsDriftProvider(common));
  // final userProvider = Get.put(UserDriftProvider(common, scoped));
  // final sessionProvider = Get.put(VersionDriftProvider(common));
  // final graphQlProvider = Get.put(MockGraphQlProvider());
  // when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  // when(graphQlProvider.favoriteChatsEvents(any))
  //     .thenAnswer((_) => const Stream.empty());
  // when(graphQlProvider.contactsEvents(any))
  //     .thenAnswer((_) => const Stream.empty());

  // setUp(() async {
  //   Get.reset();
  //   await credentialsProvider.clear();
  // });

  // var chatContact = {
  //   '__typename': 'ChatContact',
  //   'id': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
  //   'name': 'test',
  //   'users': [],
  //   'groups': [],
  //   'emails': [],
  //   'phones': [],
  //   'favoritePosition': null,
  //   'ver': '0'
  // };

  // var chatContactsData = {
  //   'nodes': [chatContact],
  //   'ver': '0'
  // };

  // var chatContacts = {
  //   'chatContacts': {
  //     'edges': [],
  //     'pageInfo': {
  //       'endCursor': 'endCursor',
  //       'hasNextPage': false,
  //       'startCursor': 'startCursor',
  //       'hasPreviousPage': false,
  //     },
  //     'ver': '0',
  //   }
  // };

  // var favoriteChatContacts = {
  //   'favoriteChatContacts': {
  //     'edges': [],
  //     'pageInfo': {
  //       'endCursor': 'endCursor',
  //       'hasNextPage': false,
  //       'startCursor': 'startCursor',
  //       'hasPreviousPage': false,
  //     },
  //     'ver': '0',
  //   }
  // };

  // var updateChatContact = {
  //   'updateChatContactName': {
  //     '__typename': 'ChatContactEventsVersioned',
  //     'events': [
  //       {
  //         '__typename': 'EventChatContactNameUpdated',
  //         'contactId': '08164fb1-ff60-49f6-8ff2-7fede51c3aed',
  //         'name': 'newname',
  //         'at': DateTime.now().toString(),
  //       }
  //     ],
  //     'ver': '1',
  //     'listVer': '1',
  //   }
  // };

  // Future<ContactService> init(GraphQlProvider graphQlProvider) async {
  //   UserRepository userRepo = UserRepository(graphQlProvider, userProvider);

  //   AbstractContactRepository contactRepository =
  //       Get.put<AbstractContactRepository>(
  //     ContactRepository(
  //       graphQlProvider,
  //       userRepo,
  //       sessionProvider,
  //       me: const UserId('me'),
  //     ),
  //   );

  //   return Get.put(ContactService(contactRepository));
  // }

  // test('ContactService successfully renames contact', () async {
  //   when(graphQlProvider.contactsEvents(any)).thenAnswer(
  //     (_) => Stream.fromIterable([
  //       QueryResult.internal(
  //         parserFn: (_) => null,
  //         source: null,
  //         data: {
  //           'chatContactsEvents': {
  //             '__typename': 'ChatContactsList',
  //             'chatContacts': chatContactsData,
  //             'favoriteChatContacts': {'nodes': []},
  //           }
  //         },
  //       )
  //     ]),
  //   );

  //   when(graphQlProvider.chatContacts(
  //     first: anyNamed('first'),
  //     noFavorite: true,
  //     before: null,
  //     after: null,
  //     last: null,
  //   )).thenAnswer((_) =>
  //       Future.value(Contacts$Query.fromJson(chatContacts).chatContacts));

  //   when(graphQlProvider.favoriteChatContacts(
  //     first: anyNamed('first'),
  //     before: null,
  //     after: null,
  //     last: null,
  //   )).thenAnswer(
  //     (_) => Future.value(FavoriteContacts$Query.fromJson(favoriteChatContacts)
  //         .favoriteChatContacts),
  //   );

  //   when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  //   when(
  //     graphQlProvider.changeContactName(
  //       const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //       UserName('newname'),
  //     ),
  //   ).thenAnswer(
  //     (_) => Future.value(UpdateChatContactName$Mutation.fromJson(
  //       updateChatContact,
  //     ).updateChatContactName
  //         as UpdateChatContactName$Mutation$UpdateChatContactName$ChatContactEventsVersioned),
  //   );

  //   ContactService contactService = await init(graphQlProvider);

  //   await contactService.changeContactName(
  //     const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //     UserName('newname'),
  //   );

  //   verify(
  //     graphQlProvider.changeContactName(
  //       const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //       UserName('newname'),
  //     ),
  //   );
  // });

  // test('ContactService throws UpdateChatContactNameException on contact rename',
  //     () async {
  //   when(graphQlProvider.contactsEvents(any)).thenAnswer(
  //     (_) => Stream.fromIterable([
  //       QueryResult.internal(
  //         parserFn: (_) => null,
  //         source: null,
  //         data: {
  //           'chatContactsEvents': {
  //             '__typename': 'ChatContactsList',
  //             'chatContacts': chatContactsData,
  //             'favoriteChatContacts': {'nodes': []},
  //           }
  //         },
  //       )
  //     ]),
  //   );

  //   when(
  //     graphQlProvider.changeContactName(
  //       const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //       UserName('newname'),
  //     ),
  //   ).thenThrow(
  //     const UpdateChatContactNameException(
  //         UpdateChatContactNameErrorCode.unknownChatContact),
  //   );

  //   ContactService contactService = await init(graphQlProvider);

  //   expect(
  //     () async => await contactService.changeContactName(
  //       const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //       UserName('newname'),
  //     ),
  //     throwsA(isA<UpdateChatContactNameException>()),
  //   );

  //   verify(
  //     graphQlProvider.changeContactName(
  //       const ChatContactId('08164fb1-ff60-49f6-8ff2-7fede51c3aed'),
  //       UserName('newname'),
  //     ),
  //   );
  // });

  // tearDown(() async => await Future.wait([common.close(), scoped.close()]));
}
