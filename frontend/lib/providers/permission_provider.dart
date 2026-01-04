import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/permission_context_model.dart';
import '../services/permissions_service.dart';
import '../services/api_service.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionContext? _context;
  bool _isLoading = false;
  String? _error;

  PermissionContext? get context => _context;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setContext(PermissionContext context) {
    _context = context;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _context = null;
    _error = null;
    notifyListeners();
  }

  /// Load permission context from backend
  /// Uses the /me endpoint which automatically uses the authenticated user's ID
  Future<void> loadPermissionContext() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get token to verify authentication
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token found. Please log in again.');
      }

      // Optionally decode JWT token to get companyId (for fallback)
      String? companyId;
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          // Add padding if needed
          String normalizedPayload = payload;
          switch (payload.length % 4) {
            case 1:
              normalizedPayload += '===';
              break;
            case 2:
              normalizedPayload += '==';
              break;
            case 3:
              normalizedPayload += '=';
              break;
          }
          final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
          final payloadJson = jsonDecode(decodedPayload) as Map<String, dynamic>;
          companyId = payloadJson['companyId'] as String?;
        }
      } catch (e) {
        // If token decoding fails, continue without companyId (backend will use it from token)
        print('Warning: Could not decode token for companyId: $e');
      }

      // Fetch permission context using /me endpoint (automatically uses authenticated user's ID)
      final permissionsService = PermissionsService();
      final permissionContext = await permissionsService.getMyPermissionContext(companyId: companyId);
      
      _context = permissionContext;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _context = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods
  bool get isAdmin => _context?.isAdmin ?? false;
  bool get isManager => _context?.isManager ?? false;
  bool get isLead => _context?.isLead ?? false;
  bool get isMember => _context?.isMember ?? false;

  bool get canManageStructure => _context?.permissions.canManageStructure ?? false;
  bool get canApproveListings => _context?.permissions.canApproveListings ?? false;
  bool get canAccessSettings => _context?.permissions.canAccessSettings ?? false;

  bool canApprove(double amount) {
    return _context?.canApprove(amount) ?? false;
  }

  bool get hasCompanyScope => _context?.hasCompanyScope ?? false;
  bool get hasDepartmentScope => _context?.hasDepartmentScope ?? false;
  bool get hasTeamScope => _context?.hasTeamScope ?? false;
}


