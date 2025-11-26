import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // URL base de tu API desplegada
  static const String baseUrl = 'https://proyecto-backend-primera-evaluacion.onrender.com/api';
  
  final storage = const FlutterSecureStorage();

  // Headers comunes
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers con autenticación
  Future<Map<String, String>> get authHeaders async {
    final token = await storage.read(key: 'access_token');
    print('🔑 Token recuperado del storage: ${token?.substring(0, 20)}...'); // Solo primeros 20 caracteres
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LOGIN - Obtener tokens JWT
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = '$baseUrl/token/';
      print('🔐 Intentando login en: $url');
      print('👤 Usuario: $username');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Tiempo de espera agotado');
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardar tokens de forma segura
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);
        
        // Verificar que se guardó correctamente
        final savedToken = await storage.read(key: 'access_token');
        print('✅ Login exitoso - Token guardado: ${savedToken?.substring(0, 20)}...');
        
        return {'success': true, 'data': data};
      } else {
        print('❌ Login fallido');
        final errorBody = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'detail': 'Error desconocido'};
        return {
          'success': false,
          'error': errorBody,
          'statusCode': response.statusCode,
        };
      }
    } on TimeoutException catch (e) {
      print('⏱️ TimeoutException: $e');
      return {
        'success': false, 
        'error': 'Tiempo de espera agotado',
      };
    } catch (e) {
      print('💥 Excepción en login: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // REFRESH TOKEN
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      
      if (refreshToken == null) {
        print('❌ No hay refresh token disponible');
        return false;
      }

      print('🔄 Intentando refrescar token...');
      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: headers,
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        print('✅ Token refrescado exitosamente');
        return true;
      }
      print('❌ Error al refrescar token: ${response.statusCode}');
      return false;
    } catch (e) {
      print('💥 Error en refreshToken: $e');
      return false;
    }
  }

  // GET Request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      final headers = await authHeaders;
      
      print('📡 GET Request a: $url');
      print('📋 Headers: ${headers.keys.join(", ")}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 401) {
        print('⚠️ Token expirado o inválido, intentando refrescar...');
        // Token expirado, intentar refrescar
        final refreshed = await refreshToken();
        if (refreshed) {
          // Reintentar la petición
          print('🔄 Reintentando petición GET...');
          return get(endpoint);
        }
        return {'success': false, 'error': 'Unauthorized - Token inválido'};
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      print('💥 Error en GET: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await authHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return post(endpoint, data);
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await authHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return put(endpoint, data);
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await authHeaders,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      } else if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return delete(endpoint);
        }
        return {'success': false, 'error': 'Unauthorized'};
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // LOGOUT
  Future<void> logout() async {
    print('👋 Cerrando sesión...');
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  // Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'access_token');
    return token != null;
  }
}