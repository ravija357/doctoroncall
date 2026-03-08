import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:doctoroncall/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:doctoroncall/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doctoroncall/features/auth/data/models/user_model.dart';
import 'auth_repository_test.mocks.dart';

@GenerateMocks([AuthRemoteDataSource])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('AuthRepositoryImpl', () {
    final tUserModel = UserModel(
      id: '1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@test.com',
      role: 'patient',
    );

    test('should return UserModel when login is successful', () async {
      // arrange
      when(
        mockRemoteDataSource.login(any, any),
      ).thenAnswer((_) async => tUserModel);
      // act
      final result = await repository.login('test@test.com', 'password');
      // assert
      expect(result, equals(tUserModel));
      verify(mockRemoteDataSource.login('test@test.com', 'password'));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should call logout on remote data source', () async {
      // arrange
      when(
        mockRemoteDataSource.logout(),
      ).thenAnswer((_) async => Future.value());
      // act
      await repository.logout();
      // assert
      verify(mockRemoteDataSource.logout());
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });
}
