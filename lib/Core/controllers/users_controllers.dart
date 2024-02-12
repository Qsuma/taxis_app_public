import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:taxis_app_public/Core/config/database/entities/login_data.dart';
import 'package:taxis_app_public/Core/config/database/entities/login_data_service.dart';
import 'package:taxis_app_public/Core/riverpod/declarations.dart';
import 'package:taxis_app_public/shared/widgets.dart';
class UserControllers {

  late Dio _dio;

  UserControllers() {
    _initializeDio();
  }

  Future<void> _initializeDio() async {
    final token = await LoginDataService().getToken();

    _dio = Dio(
      BaseOptions(
        baseUrl: Uri.https(dotenv.env['SERVER_URL']!).toString(),
        headers: {
          'Content-Type': 'application/json',
          'access-token': token,
          'Authorization': 'Bearer $token'
        },
        validateStatus: (status) => true,
      ),
    );
  }

  Future<bool> login(String username, String pass) async {
    authStatus.value = true;
    try {

      await _initializeDio();
      Response response = await _dio.post('/api/auth/signin',
        data: jsonEncode({'username': username, 'password': pass}));
      authStatus.value = false;

      if (response.statusCode == 201) {

        String gettoken = response.data['data']['jwtToken'];

        LoginDataService().saveData(
          LoginData()
            ..token = gettoken
            ..role = 'driver'  
        );

        showToast('Sesión iniciada correctamente', type: true);
        return true;
      }

      showToast('Ocurrió un problema al iniciar sesión. Verifique los datos por favor');

      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> save(String name, String email, String username, String password) async {
    authStatus.value = true;
    try {

      await _initializeDio();
      Response response = await _dio.post('/api/users/register',
        data: jsonEncode({
          "name": name,
          "email": email,
          "username": username,
          "password": password,
          "type": "driver",
          "driver_info": {
            "driver_licence": "",
            "circulation_licence": "",
            "dni": ""
          }
        }));
      authStatus.value = false;

      if (response.statusCode == 201) {
        showToast('Su cuenta ha sido creada exitosamente', type: true);
        return true;
      }

      showToast('Ocurrió un problema al crear su usuario. Verifique los datos por favor');

      return false;
    } on DioException catch (_) {
      return false;
    }
  }
  
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {

      await _initializeDio();
      EasyLoading.show(status: 'Cambiando contraseña...');

      Response response = await _dio.patch('/api/users/change-password',
        data: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword
        }));

      if (response.statusCode == 200) {
        EasyLoading.showSuccess('La contraseña ha sido cambiada correctamente');
        return true;
      }
      
      EasyLoading.showError('Ocurrió un problema al intentar cambiar su contraseña');
      return false;

    } on DioException catch (e) {
      EasyLoading.showError(e.toString());
      return false;
    }
  }

}