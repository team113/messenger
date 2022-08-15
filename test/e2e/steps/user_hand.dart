// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/hand_status.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Raises or lowers hand by provided user in call with the authenticated
/// [MyUser].
///
/// Examples:
/// - Then Bob raise hand
/// - Then Bob lower hand
final StepDefinitionGeneric raiseHand = and2<TestUser, HandStatus, CustomWorld>(
  '{user} {hand} hand',
  (user, handStatus, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    if (handStatus == HandStatus.lower) {
      await provider.toggleChatCallHand(customUser.chat!, false);
    } else {
      await provider.toggleChatCallHand(customUser.chat!, true);
    }

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
