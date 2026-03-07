import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/screens/shared/image_upload_screen.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/core/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'profile_screen_widget_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  ApiClient,
  ChatRemoteDataSource,
  BiometricService,
  FlutterSecureStorage,
])
void main() {
  final sl = GetIt.instance;
  late MockAuthRepository mockAuthRepository;
  late MockApiClient mockApiClient;
  late MockChatRemoteDataSource mockChatRemoteDataSource;
  late MockBiometricService mockBiometricService;
  late MockFlutterSecureStorage mockSecureStorage;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.users);

    mockAuthRepository = MockAuthRepository();
    mockApiClient = MockApiClient();
    mockChatRemoteDataSource = MockChatRemoteDataSource();
    mockBiometricService = MockBiometricService();
    mockSecureStorage = MockFlutterSecureStorage();

    if (!sl.isRegistered<AuthRepository>()) {
      sl.registerSingleton<AuthRepository>(mockAuthRepository);
    }
    if (!sl.isRegistered<ApiClient>()) {
      sl.registerSingleton<ApiClient>(mockApiClient);
    }
    if (!sl.isRegistered<ChatRemoteDataSource>()) {
      sl.registerSingleton<ChatRemoteDataSource>(mockChatRemoteDataSource);
    }
    if (!sl.isRegistered<BiometricService>()) {
      sl.registerSingleton<BiometricService>(mockBiometricService);
    }
    if (!sl.isRegistered<FlutterSecureStorage>()) {
      sl.registerSingleton<FlutterSecureStorage>(mockSecureStorage);
    }

    // Stub necessary methods
    when(
      mockSecureStorage.read(key: anyNamed('key')),
    ).thenAnswer((_) async => null);
  });

  tearDownAll(() async {
    await Hive.close();
    await sl.reset();
  });

  Widget wrapWithMaterial(Widget child) {
    return ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen loads successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileScreen()));

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Profile avatar is visible', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileScreen()));

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    // The icon/gesture detector for updating image
    testWidgets('Update Profile Image icon is visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileScreen()));

      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('Navigates to ImageUploadScreen on tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileScreen()));

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ImageUploadScreen), findsOneWidget);
    });
  });

  group('ImageUploadScreen Widget Tests', () {
    testWidgets('Choose & Upload Image button is visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithMaterial(const ImageUploadScreen()));

      expect(find.text('Choose & Upload Image'), findsOneWidget);
    });
  });
}
