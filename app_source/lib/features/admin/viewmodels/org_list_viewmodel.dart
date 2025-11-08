import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/models/admin/admin_organization.dart';

class OrgListViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService = locator<AdminApiService>();

  List<AdminOrganization> _organizations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdminOrganization> get organizations => _organizations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrganizations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _organizations = await _adminApiService.getOrganizations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load organizations: $e';
      notifyListeners();
    }
  }

  void refresh() {
    fetchOrganizations();
  }
}
