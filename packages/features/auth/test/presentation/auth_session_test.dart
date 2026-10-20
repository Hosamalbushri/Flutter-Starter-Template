import 'package:architecture/architecture.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:shared_contracts/shared_contracts.dart';

import '../support.dart';

void main() {
  test(
    'expiration clears UI session once and allows a later sign-in',
    () async {
      final signIn = MockSignIn();
      final register = MockRegister();
      final signOut = MockSignOut();
      final restore = MockRestoreSession();
      final expire = MockExpireSession();
      final analytics = MockAnalyticsService();
      final termination = SessionTerminationNotifier();
      stubAnalyticsService(analytics);
      when(expire.call).thenAnswer((_) async => const Ok(null));
      when(
        () => signIn((username: 'alice', password: 'password')),
      ).thenAnswer((_) async => const Ok(testUser));
      final bloc = AuthBloc(
        signIn: signIn,
        register: register,
        signOut: signOut,
        restoreSession: restore,
        expireSession: expire,
        analytics: analytics,
      );
      final session = AuthSession(bloc, termination);
      addTearDown(session.dispose);
      addTearDown(bloc.close);

      bloc.add(
        const AuthSignInRequested(username: 'alice', password: 'password'),
      );
      await bloc.stream.firstWhere((state) => state is AuthAuthenticated);
      expect(session.status, SessionStatus.authenticated);

      termination
        ..notifyTerminated()
        ..notifyTerminated();
      await bloc.stream.firstWhere((state) => state is AuthInitial);
      expect(session.status, SessionStatus.unauthenticated);
      verify(expire.call).called(1);

      termination.reset();
      bloc.add(
        const AuthSignInRequested(username: 'alice', password: 'password'),
      );
      await bloc.stream.firstWhere((state) => state is AuthAuthenticated);
      expect(session.status, SessionStatus.authenticated);
    },
  );
}
