import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/models/admin/admin_user.dart';

class OrgDetailViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();
  final String orgId;

  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  OrgDetailViewModel({required this.orgId});

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _adminApiService.getUsersForOrg(orgId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load users: $e';
      notifyListeners();
    }
  }

  void refresh() {
    fetchUsers();
  }
}
