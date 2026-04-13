import 'package:flutter/material.dart';
import 'package:ghasele/generated/l10n/app_localizations.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF025595), Color(0xFF0377C8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentBalance,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '125.50 ${l10n.jod}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addFunds),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF025595),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send),
                      label: Text(l10n.withdraw),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.recentTransactions,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildTransactionItem(
          icon: Icons.arrow_downward,
          iconColor: Colors.green,
          title: l10n.addedFunds,
          date: '2026-02-06',
          amount: '+100.00 ${l10n.jod}',
          isPositive: true,
        ),
        const Divider(),
        _buildTransactionItem(
          icon: Icons.local_laundry_service,
          iconColor: const Color(0xFF025595),
          title: '${l10n.orders} #12345',
          date: '2026-02-05',
          amount: '-45.00 ${l10n.jod}',
          isPositive: false,
        ),
        const Divider(),
        _buildTransactionItem(
          icon: Icons.local_laundry_service,
          iconColor: const Color(0xFF025595),
          title: '${l10n.orders} #12344',
          date: '2026-02-03',
          amount: '-60.00 ${l10n.jod}',
          isPositive: false,
        ),
        const Divider(),
        _buildTransactionItem(
          icon: Icons.arrow_downward,
          iconColor: Colors.green,
          title: l10n.addedFunds,
          date: '2026-02-01',
          amount: '+150.00 ${l10n.jod}',
          isPositive: true,
        ),
        const Divider(),
        _buildTransactionItem(
          icon: Icons.local_laundry_service,
          iconColor: const Color(0xFF025595),
          title: '${l10n.orders} #12343',
          date: '2026-02-01',
          amount: '-30.00 ${l10n.jod}',
          isPositive: false,
        ),
        const Divider(),
        _buildTransactionItem(
          icon: Icons.arrow_upward,
          iconColor: Colors.orange,
          title: '${l10n.refund} - ${l10n.orders} #12342',
          date: '2026-01-29',
          amount: '+50.00 ${l10n.jod}',
          isPositive: true,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String amount,
    required bool isPositive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
