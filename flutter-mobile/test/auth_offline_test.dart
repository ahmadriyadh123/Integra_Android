import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:sekolah/auth/local/auth_local_storage.dart';
import 'package:sekolah/auth/models/auth_model.dart';
import 'package:sekolah/auth/repositories/auth_repository.dart';
import 'package:sekolah/auth/services/auth_service.dart';
import 'package:sekolah/auth/viewmodel/auth_viewmodel.dart';

@GenerateMocks([AuthService, AuthRepository, AuthLocalStorage])
void main() {
  group('Offline-First Login Tests', () {
    late MockAuthService mockAuthService;
    late MockAuthRepository mockAuthRepository;
    late MockAuthLocalStorage mockLocalStorage;
    late AuthViewModel viewModel;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAuthRepository = MockAuthRepository();
      mockLocalStorage = MockAuthLocalStorage();
      
      viewModel = AuthViewModel(
        repository: mockAuthRepository,
        localStorage: mockLocalStorage,
      );
    });

    test('restoreSessionFromHive loads auth from local storage without API call', () async {
      // Arrange: Setup saved auth result in local storage
      final savedAuthData = {
        'access_token': 'test_token_123',
        'token_type': 'bearer',
        'user': {
          'user_id': 1,
          'partner_id': 2,
          'student_id': 3,
          'nis': '12345',
          'name': 'Test User',
          'username': 'testuser',
          'email': 'test@example.com',
          'is_portal': false,
        }
      };

      when(mockLocalStorage.loadAuth()).thenAnswer((_) async => savedAuthData);

      // Act: Restore session from Hive
      final result = await viewModel.restoreSessionFromHive();

      // Assert:
      // 1. Should return true (session restored)
      expect(result, true);
      
      // 2. Should NOT call repository.login() (no API call)
      verifyNever(mockAuthRepository.login(any, any));
      
      // 3. Token should be set from loaded auth result
      expect(viewModel.token, 'test_token_123');
      
      // 4. User should be parsed correctly
      expect(viewModel.user?.username, 'testuser');
    });

    test('restoreSessionFromHive returns false if no saved auth in Hive', () async {
      // Arrange: No saved auth in local storage
      when(mockLocalStorage.loadAuth()).thenAnswer((_) async => null);

      // Act
      final result = await viewModel.restoreSessionFromHive();

      // Assert
      expect(result, false);
      verifyNever(mockAuthRepository.login(any, any));
    });

    test('login stores full auth result to Hive for offline restore', () async {
      // Arrange: Mock API login response
      final loginResponse = AuthResult(
        accessToken: 'new_token_456',
        tokenType: 'bearer',
        user: UserProfile(
          userId: 2,
          partnerId: 3,
          studentId: 4,
          nis: '54321',
          name: 'New User',
          username: 'newuser',
          email: 'new@example.com',
          isPortal: false,
        ),
      );

      when(mockAuthRepository.login('newuser', 'password123'))
          .thenAnswer((_) async => loginResponse);
      
      when(mockLocalStorage.saveAuth(any, username: anyNamed('username'), password: anyNamed('password')))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await viewModel.login('newuser', 'password123');

      // Assert
      expect(result, true);
      
      // Should save auth to Hive for offline restore
      verify(mockLocalStorage.saveAuth(
        any,
        username: 'newuser',
        password: 'password123',
      )).called(1);
    });

    test('validateSession handles network timeout gracefully', () async {
      // Arrange: Mock timeout exception
      when(mockAuthRepository.validateSession('test_token'))
          .thenThrow(Exception('Network timeout'));

      // Act: Validate should handle timeout without throwing
      expect(
        () => viewModel._validateSessionInBackground(),
        returnsNormally,
      );
    });

    test('validateSession throws on invalid token', () async {
      // Arrange: Mock invalid token exception
      when(mockAuthRepository.validateSession('invalid_token'))
          .thenThrow(Exception('Token invalid or expired'));

      // Act & Assert: Should handle exception and logout
      expect(
        () => viewModel._validateSessionInBackground(),
        returnsNormally,
      );
    });

    test('offline login flow: load from Hive, parse, validate in background', () async {
      // Simulate complete offline login flow
      
      // Step 1: Save auth after online login
      final authResult = AuthResult(
        accessToken: 'offline_token',
        tokenType: 'bearer',
        user: UserProfile(
          userId: 1,
          partnerId: 2,
          studentId: 3,
          nis: '12345',
          name: 'Offline User',
          username: 'offlineuser',
          email: 'offline@example.com',
          isPortal: false,
        ),
      );

      when(mockAuthRepository.login('offlineuser', 'pass123'))
          .thenAnswer((_) async => authResult);
      when(mockLocalStorage.saveAuth(any, username: anyNamed('username'), password: anyNamed('password')))
          .thenAnswer((_) async => Future.value());

      // First login (online)
      await viewModel.login('offlineuser', 'pass123');
      
      // Step 2: App restarts, load from Hive
      final savedAuthData = {
        'access_token': 'offline_token',
        'token_type': 'bearer',
        'user': {
          'user_id': 1,
          'partner_id': 2,
          'student_id': 3,
          'nis': '12345',
          'name': 'Offline User',
          'username': 'offlineuser',
          'email': 'offline@example.com',
          'is_portal': false,
        }
      };

      when(mockLocalStorage.loadAuth()).thenAnswer((_) async => savedAuthData);

      // Restore from Hive
      final restored = await viewModel.restoreSessionFromHive();
      
      // Step 3: Verify flow
      expect(restored, true);
      expect(viewModel.token, 'offline_token');
      
      // API was only called once (initial login), not on restore
      verify(mockAuthRepository.login('offlineuser', 'pass123')).called(1);
    });
  });
}
