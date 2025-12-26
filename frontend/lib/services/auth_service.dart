import 'dart:convert';
import '../services/api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await ApiService.saveToken(data['access_token']);
      return data;
    } else {
      String errorMessage = 'Login failed';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> signupStep1(String name, String email, String? phone, String password) async {
    final response = await ApiService.post('/auth/signup/step1', {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Signup step 1 failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signupStep2(String userId, String companyName, String companyType, {String? industry, String? size}) async {
    final response = await ApiService.post('/auth/signup/step2', {
      'userId': userId,
      'companyName': companyName,
      'companyType': companyType,
      if (industry != null) 'industry': industry,
      if (size != null) 'size': size,
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await ApiService.saveToken(data['access_token']);
      }
      return data;
    } else {
      throw Exception('Signup step 2 failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signupStep3(String userId, List<String>? memberEmails) async {
    final response = await ApiService.post('/auth/signup/step3', {
      'userId': userId,
      if (memberEmails != null && memberEmails.isNotEmpty) 'memberEmails': memberEmails,
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Signup step 3 failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> completeSignup({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String companyName,
    required String companyType,
    String? industry,
    String? size,
    List<String>? memberEmails,
  }) async {
    final response = await ApiService.post('/auth/signup/complete', {
      'name': name,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'companyName': companyName,
      'companyType': companyType,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (size != null && size.isNotEmpty) 'size': size,
      if (memberEmails != null && memberEmails.isNotEmpty) 'memberEmails': memberEmails,
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await ApiService.saveToken(data['access_token']);
      }
      return data;
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String userId, String otp) async {
    final response = await ApiService.post('/auth/verify-otp', {
      'userId': userId,
      'otp': otp,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await ApiService.saveToken(data['access_token']);
      }
      return data;
    } else {
      String errorMessage = 'OTP verification failed';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> resendOtp(String userId) async {
    final response = await ApiService.post('/auth/resend-otp', {
      'userId': userId,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      String errorMessage = 'Failed to resend OTP';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
  }
}

