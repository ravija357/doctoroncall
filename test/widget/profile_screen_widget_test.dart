import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/screens/shared/image_upload_screen.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.users);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen loads successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const ProfileScreen()),
      );

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Profile avatar is visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const ProfileScreen()),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('Update Profile Image text is visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const ProfileScreen()),
      );

      expect(find.text('Update Profile Image'), findsOneWidget);
    });

    testWidgets('Navigates to ImageUploadScreen on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const ProfileScreen()),
      );

      await tester.tap(find.text('Update Profile Image'));
      await tester.pumpAndSettle();

      expect(find.byType(ImageUploadScreen), findsOneWidget);
    });
  });

  group('ImageUploadScreen Widget Tests', () {
    testWidgets('Choose Image button is visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(const ImageUploadScreen()),
      );

      expect(find.text('Choose Image'), findsOneWidget);
    });
  });
}
