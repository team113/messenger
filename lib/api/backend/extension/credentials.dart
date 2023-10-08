import '/api/backend/schema.graphql.dart';
import '/domain/model/session.dart';

/// Extension adding [Credentials] models construction from a
/// [SignUp$Mutation] response.
extension SignUpCredentials on SignUp$Mutation {
  Credentials toModel() {
    return Credentials(
      Session(
        createUser.session.token,
        createUser.session.expireAt,
      ),
      RememberedSession(
        createUser.remembered!.token,
        createUser.remembered!.expireAt,
      ),
      createUser.user.id,
    );
  }
}

/// Extension adding [Credentials] models construction from a
///  [SignIn$Mutation$CreateSession$CreateSessionOk] response.
extension SignInCredentials on SignIn$Mutation$CreateSession$CreateSessionOk {
  Credentials toModel() {
    return Credentials(
      Session(
        session.token,
        session.expireAt,
      ),
      RememberedSession(
        remembered!.token,
        remembered!.expireAt,
      ),
      user.id,
    );
  }
}
