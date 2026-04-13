import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/widgets/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderSuccessView extends StatefulWidget {
  const OrderSuccessView({super.key});

  @override
  State<OrderSuccessView> createState() => _OrderSuccessViewState();
}

class _OrderSuccessViewState extends State<OrderSuccessView> {
  bool _isSaving = false;
  bool _isAlreadySaved = false;
  Map<String, dynamic>? _args;
  bool _checkedSavedStatus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedSavedStatus) {
      _args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (_args != null) {
        _checkIfAlreadySaved();
      }
      _checkedSavedStatus = true;
    }
  }

  Future<void> _checkIfAlreadySaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) return;

      final result = await ApiService.getUserLocations(
        userId: userId,
        token: token,
      );

      if (result['success'] && result['data'] != null) {
        final List locations = result['data'];
        final double lat = _args!['lat'];
        final double lng = _args!['lng'];

        final exists = locations.any((loc) {
          final double? lLat = loc['lat']?.toDouble();
          final double? lLng = loc['long']?.toDouble();
          if (lLat == null || lLng == null) return false;
          return (lLat - lat).abs() < 0.0001 && (lLng - lng).abs() < 0.0001;
        });

        if (mounted) {
          setState(() {
            _isAlreadySaved = exists;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking saved status: $e');
    }
  }

  Future<void> _saveLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveLocation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.locationNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(_args!['address'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.of(context).pop();

              setState(() => _isSaving = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final String? token = prefs.getString('auth_token');
                final String? userId = prefs.getString('user_id');

                if (token != null && userId != null) {
                  final result = await ApiService.addUserLocation(
                    userId: userId,
                    name: nameController.text,
                    lat: _args!['lat'],
                    lng: _args!['lng'],
                    token: token,
                  );

                  if (result['success']) {
                    CustomToast.show(context, message: 'Location saved', type: ToastType.success);
                    setState(() {
                      _isAlreadySaved = true;
                    });
                  } else {
                    CustomToast.show(context, message: 'Failed to save location', type: ToastType.error);
                  }
                }
              } catch (e) {
                CustomToast.show(context, message: 'Error: $e', type: ToastType.error);
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF025595),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.orderSuccessTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF025595),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.orderSuccessMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                // Save Location Prompt
                if (!_isAlreadySaved && _args != null) ...[
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF025595).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF025595).withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF025595),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.saveLocation,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF025595),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.askSaveLocation,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _saveLocation,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF025595)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l10n.saveLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false, arguments: 0), // Index 0 is Orders
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF025595),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(l10n.goToMyOrders, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false),
                  child: Text(
                    l10n.backToHome,
                    style: const TextStyle(
                      color: Color(0xFF025595),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
