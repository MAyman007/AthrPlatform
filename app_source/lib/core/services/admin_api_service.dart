import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin/admin_stats.dart';
import '../models/admin/admin_organization.dart';
import '../models/admin/admin_user.dart';
import '../models/admin/admin_incident.dart';

class AdminApiService {
  static const String _baseUrl = 'https://athr-admin.mohamedayman.net';

  /// Check if an email belongs to an authorized admin
  Future<bool> isAdmin(String email) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/is-admin?email=${Uri.encodeComponent(email)}',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_admin'] as bool? ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get admin dashboard statistics
  Future<AdminStats> getAdminStats() async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/stats');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AdminStats.fromJson(data);
      }

      throw Exception('Failed to load admin stats: ${response.statusCode}');
    } catch (e) {
      print('Error fetching admin stats: $e');
      rethrow;
    }
  }

  /// Get list of all organizations
  Future<List<AdminOrganization>> getOrganizations() async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/organizations');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AdminOrganization.fromJson(json)).toList();
      }

      throw Exception('Failed to load organizations: ${response.statusCode}');
    } catch (e) {
      print('Error fetching organizations: $e');
      rethrow;
    }
  }

  /// Get users for a specific organization
  Future<List<AdminUser>> getUsersForOrg(String orgId) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/organizations/$orgId/users');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AdminUser.fromJson(json)).toList();
      }

      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      print('Error fetching users for org $orgId: $e');
      rethrow;
    }
  }

  /// Get incidents for a specific organization
  Future<List<AdminIncident>> getIncidentsForOrg(String orgId) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/organizations/$orgId/incidents');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AdminIncident.fromJson(json)).toList();
      }

      throw Exception('Failed to load incidents: ${response.statusCode}');
    } catch (e) {
      print('Error fetching incidents for org $orgId: $e');
      rethrow;
    }
  }
}
