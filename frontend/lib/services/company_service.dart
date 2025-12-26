import 'dart:convert';
import '../models/company_model.dart';
import 'api_service.dart';

class CompanyService {
  Future<Company> getCompany() async {
    final response = await ApiService.get('/company', includeAuth: true);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Company.fromJson(data);
    } else {
      throw Exception('Failed to load company: ${response.body}');
    }
  }

  Future<Company> updateCompany({
    String? name,
    String? industry,
    String? size,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (industry != null) body['industry'] = industry;
    if (size != null) body['size'] = size;

    final response = await ApiService.put(
      '/company',
      body,
      includeAuth: true,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Company.fromJson(data);
    } else {
      throw Exception('Failed to update company: ${response.body}');
    }
  }
}

