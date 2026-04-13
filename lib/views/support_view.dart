import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ghasele/services/api_service.dart';
import 'package:ghasele/theme/app_theme.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  List<dynamic> _myTickets = [];
  bool _isLoadingTickets = true;
  String? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadMyTickets();
  }

  Future<void> _loadMyTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id') ?? '';
      _token = prefs.getString('auth_token') ?? '';

      if (_userId!.isEmpty || _token!.isEmpty) {
        if (mounted) setState(() => _isLoadingTickets = false);
        return;
      }

      final result = await ApiService.getUserTickets(
        userId: _userId!,
        token: _token!,
      );

      if (mounted) {
        setState(() {
          if (result['success']) {
            _myTickets = result['data'] as List<dynamic>;
            // Sort by createdAt descending (newest first)
            _myTickets.sort((a, b) {
              final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(0);
              final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(0);
              return bDate.compareTo(aDate);
            });
          }
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tickets: $e');
      if (mounted) setState(() => _isLoadingTickets = false);
    }
  }

  void _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTicketView()),
    );

    // Reload tickets if a new one was created
    if (result == true) {
      setState(() => _isLoadingTickets = true);
      _loadMyTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.neutral50,
      body: _isLoadingTickets
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          : _myTickets.isEmpty
              ? _buildEmptyState(l10n)
              : RefreshIndicator(
                  onRefresh: _loadMyTickets,
                  color: AppTheme.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _myTickets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.support,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.neutral900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.myTickets,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.neutral500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final ticket = _myTickets[index - 1];
                      return _buildTicketCard(ticket, l10n);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateTicket,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newTicket, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 6,
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.noTickets,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.submitFirstTicket,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, AppLocalizations l10n) {
    final status = ticket['status'] ?? 'Open';
    final categoryValue = ticket['category'] ?? 'General';
    final subject = ticket['subject'] ?? l10n.subject;
    final createdAt = ticket['createdAt'] ?? '';

    // Map category value to localized name
    String categoryName = categoryValue;
    switch(categoryValue.toString().toLowerCase()) {
      case 'general': categoryName = l10n.general; break;
      case 'order issue': categoryName = l10n.orderIssue; break;
      case 'payment': categoryName = l10n.payment; break;
      case 'delivery': categoryName = l10n.delivery; break;
      case 'quality': categoryName = l10n.quality; break;
      case 'account': categoryName = l10n.account; break;
      case 'other': categoryName = l10n.other; break;
    }

    Color statusColor;
    Color statusBgColor;

    switch (status.toString().toLowerCase()) {
      case 'open':
        statusColor = const Color(0xFFD97706);
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      case 'in progress':
        statusColor = AppTheme.info;
        statusBgColor = AppTheme.info.withOpacity(0.1);
        break;
      case 'resolved':
        statusColor = AppTheme.success;
        statusBgColor = AppTheme.success.withOpacity(0.1);
        break;
      case 'closed':
        statusColor = AppTheme.neutral500;
        statusBgColor = AppTheme.neutral100;
        break;
      default:
        statusColor = AppTheme.neutral500;
        statusBgColor = AppTheme.neutral100;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetails(context, ticket, statusColor, statusBgColor, categoryName),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (createdAt.isNotEmpty)
                      Text(
                        _formatDate(createdAt, l10n),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutral400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 16, color: AppTheme.neutral400),
                    const SizedBox(width: 8),
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.neutral500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, Map<String, dynamic> ticket, Color statusColor, Color statusBgColor, String categoryName) {
    final l10n = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.neutral200,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  ticket['status'] ?? 'Open',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.neutral100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neutral700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            ticket['subject'] ?? l10n.subject,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.neutral900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildDetailSection(l10n.yourMessage, ticket['message'] ?? ''),
                          if (ticket['response'] != null && ticket['response'].toString().isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildResponseSection(l10n.supportResponse, ticket['response'].toString()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.neutral500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.neutral800,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.reply_rounded, color: AppTheme.primaryBlue, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.neutral900,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr, AppLocalizations l10n) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return l10n.today;
      } else if (difference.inDays == 1) {
        return l10n.yesterday;
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${l10n.daysAgo}';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}

class CreateTicketView extends StatefulWidget {
  const CreateTicketView({super.key});

  @override
  State<CreateTicketView> createState() => _CreateTicketViewState();
}

class _CreateTicketViewState extends State<CreateTicketView> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedCategory = 'Order Issue';
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _getCategories(AppLocalizations l10n) {
    return [
      {'name': l10n.general, 'icon': Icons.help_outline_rounded, 'value': 'General'},
      {'name': l10n.orderIssue, 'icon': Icons.shopping_bag_outlined, 'value': 'Order Issue'},
      {'name': l10n.payment, 'icon': Icons.payment_outlined, 'value': 'Payment'},
      {'name': l10n.delivery, 'icon': Icons.local_shipping_outlined, 'value': 'Delivery'},
      {'name': l10n.quality, 'icon': Icons.star_outline_rounded, 'value': 'Quality'},
      {'name': l10n.account, 'icon': Icons.person_outline_rounded, 'value': 'Account'},
      {'name': l10n.other, 'icon': Icons.more_horiz_rounded, 'value': 'Other'},
    ];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final token = prefs.getString('auth_token') ?? '';

      if (userId.isEmpty || token.isEmpty) {
        _showMessage(l10n.pleaseLogin, isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      final result = await ApiService.createTicket(
        userId: userId,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
        token: token,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (result['success']) {
          _showMessage(l10n.ticketSubmitted);
          Navigator.pop(context, true); // Return true to trigger refresh
        } else {
          _showMessage(result['message'] ?? l10n.failedToSubmit, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = _getCategories(l10n);

    if (!categories.any((c) => c['value'] == _selectedCategory)) {
        _selectedCategory = categories.first['value'] as String;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.newTicket,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutral900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(l10n.category),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.neutral50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.neutral200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryBlue),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['value'] as String,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(cat['icon'] as IconData, size: 18, color: AppTheme.primaryBlue),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat['name'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.neutral800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCategory = value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(l10n.subject),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _subjectController,
                      decoration: _inputDecoration(l10n.briefDescription),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return l10n.subjectRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildLabel(l10n.message),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 6,
                      decoration: _inputDecoration(l10n.describeIssue),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return l10n.messageRequired;
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppTheme.neutral500,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submitTicket(l10n),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  l10n.submitTicket,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.neutral400, fontSize: 15, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: AppTheme.neutral50,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
    );
  }
}
