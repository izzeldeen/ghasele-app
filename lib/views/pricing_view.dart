import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';

class PricingView extends StatefulWidget {
  const PricingView({Key? key}) : super(key: key);

  @override
  State<PricingView> createState() => _PricingViewState();
}

class _PricingViewState extends State<PricingView> {
  List<dynamic> _itemTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItemTypes();
  }

  Future<void> _fetchItemTypes() async {
    try {
      final result = await ApiService.getItemTypes();
      if (result['success'] && result['data'] != null) {
        if (mounted) {
          setState(() {
            _itemTypes = result['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching item types: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _itemTypes.isEmpty
              ? Center(child: Text(l10n.loading)) // Or a better empty state
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _itemTypes.length,
                  itemBuilder: (context, index) {
                    final item = _itemTypes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['typeName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.neutral900,
                                    fontSize: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.dry_cleaning_rounded,
                                    color: AppTheme.primaryBlue,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _buildPriceRow(
                              l10n.cleaning,
                              item['cleaningPrice'].toString(),
                              l10n.jod,
                              Icons.local_laundry_service_rounded,
                            ),
                            const SizedBox(height: 12),
                            _buildPriceRow(
                              l10n.ironing,
                              item['ironPrice'].toString(),
                              l10n.jod,
                              Icons.iron,
                            ),
                            const SizedBox(height: 12),
                            _buildPriceRow(
                              l10n.both,
                              item['bothPrice'].toString(),
                              l10n.jod,
                              Icons.auto_awesome,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPriceRow(String label, String price, String currency, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.neutral500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.neutral600,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          price,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          currency,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.neutral400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
