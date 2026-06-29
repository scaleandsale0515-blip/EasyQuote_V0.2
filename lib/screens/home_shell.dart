import 'package:flutter/material.dart';
import '../models/quote_doc.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import 'company_profiles_screen.dart';
import 'app_terms_screen.dart';
import 'clients_screen.dart';
import 'catalog_screen.dart';
import 'terms_screen.dart';
import 'documents_list_screen.dart';
import 'dashboard_screen.dart';
import 'backup_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _tabs = [
    _NavItem('Dashboard', Icons.space_dashboard_outlined),
    _NavItem('Quotations', Icons.request_quote_outlined),
    _NavItem('Invoices', Icons.receipt_long_outlined),
    _NavItem('More', Icons.menu_outlined),
  ];

  Widget _bodyFor(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const DocumentsListScreen(docType: DocType.quotation);
      case 2:
        return const DocumentsListScreen(docType: DocType.invoice);
      default:
        return const _MoreMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bodyFor(_tab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: _tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final profile = LocalDB.instance.getActiveProfile();
    return Scaffold(
      appBar: AppBar(title: Text(profile.name.isEmpty ? 'EasyQuote' : profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _tile(context, 'Company Profiles', Icons.business_outlined, const CompanyProfilesScreen()),
          _tile(context, 'Clients', Icons.people_outline, const ClientsScreen()),
          _tile(context, 'Items Catalog', Icons.inventory_2_outlined, const CatalogScreen()),
          _tile(context, 'Terms Templates', Icons.description_outlined, const TermsScreen()),
          const Divider(height: 28),
          _tile(context, 'Backup & Restore', Icons.swap_horiz_outlined, const BackupScreen()),
          _tile(context, 'Terms & Conditions', Icons.gavel_outlined, const AppTermsScreen()),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'All data on this screen lives only on this device. EasyQuote does '
              'not sync to any account or cloud service.',
              style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, IconData icon, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.blueprint),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
