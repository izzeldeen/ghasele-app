import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';
import 'package:ghasele/models/service_price.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';

class PricingView extends StatefulWidget {
  const PricingView({super.key});

  @override
  State<PricingView> createState() => PricingViewState();
}

class PricingViewState extends State<PricingView> {
  List<dynamic> _itemTypes = [];
  bool _isLoading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetchItemTypes();
  }

  /// Re-reads the prices. Called on every visit to the tab: IndexedStack keeps this page
  /// alive, so without it a failed first load (or a price changed in the admin since)
  /// would stay on screen until the app restarts.
  Future<void> refresh() => _fetchItemTypes();

  Future<void> _fetchItemTypes() async {
    // Keep the current list visible while refreshing; only a first load shows the spinner.
    if (_itemTypes.isEmpty && mounted) {
      setState(() {
        _isLoading = true;
        _failed = false;
      });
    }
    try {
      final result = await ApiService.getItemTypes();
      if (!mounted) return;
      if (result['success'] && result['data'] != null) {
        setState(() {
          _itemTypes = result['data'];
          _failed = false;
          _isLoading = false;
        });
      } else {
        debugPrint('Error fetching item types: ${result['message']}');
        setState(() {
          _failed = _itemTypes.isEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching item types: $e');
      if (mounted) {
        setState(() {
          _failed = _itemTypes.isEmpty;
          _isLoading = false;
        });
      }
    }
  }

  /// Shown when the first load fails or the list is empty. Scrollable so pull-to-refresh
  /// still works on it.
  Widget _buildMessage(String message, {bool showRetry = false}) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.neutral600,
                      fontSize: 15,
                    ),
                  ),
                  if (showRetry) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _fetchItemTypes,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.tryAgain),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchItemTypes,
              child: _failed
                  ? _buildMessage(l10n.connectionError, showRetry: true)
                  : _itemTypes.isEmpty
                  ? _buildMessage(l10n.noPrices)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
                            // One row per item: the name, then its price beside the icon.
                            // The price is a single phrase built by [ServicePrice] - "1.25 دينار",
                            // "من 3 إلى 10 دينار" or "يبدأ من 3 دينار" - so the currency stays
                            // inside a range rather than trailing it.
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['typeName'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.neutral900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  ServicePrice.fromJson(
                                    item as Map<String, dynamic>,
                                    baseKey: 'price',
                                    maxKey: 'maxPrice',
                                  ).label(l10n),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.dry_cleaning_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
