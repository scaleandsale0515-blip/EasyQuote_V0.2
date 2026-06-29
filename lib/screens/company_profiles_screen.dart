import 'package:flutter/material.dart';
import '../models/company_profile.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import 'company_profile_form_screen.dart';

class CompanyProfilesScreen extends StatefulWidget {
  const CompanyProfilesScreen({super.key});

  @override
  State<CompanyProfilesScreen> createState() => _CompanyProfilesScreenState();
}

class _CompanyProfilesScreenState extends State<CompanyProfilesScreen> {
  List<CompanyProfile> _profiles = [];
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _profiles = LocalDB.instance.getProfiles();
      _activeId = LocalDB.instance.getActiveProfileId();
    });
  }

  Future<void> _openForm({CompanyProfile? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CompanyProfileFormScreen(existing: existing)),
    );
    _reload();
  }

  Future<void> _setActive(CompanyProfile p) async {
    await LocalDB.instance.setActiveProfileId(p.id);
    _reload();
  }

  Future<void> _confirmDelete(CompanyProfile p) async {
    if (_profiles.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need at least one company profile.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this profile?'),
        content: Text('Remove "${p.name.isEmpty ? '(unnamed)' : p.name}" from this device. '
            'Documents already created with it keep working, but won\'t show its letterhead correctly.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await LocalDB.instance.deleteProfile(p.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company Profiles')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _profiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_outlined, size: 48, color: AppColors.line),
                    const SizedBox(height: 12),
                    const Text('No company profile yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Tap + to set up your company details.', style: TextStyle(color: AppColors.inkSoft)),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'The ACTIVE profile is used as the default letterhead for new '
                    'quotations/invoices. You can still pick a different profile per '
                    'document when creating it.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                ),
                const SizedBox(height: 8),
                ..._profiles.map((p) {
                  final isActive = p.id == _activeId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isActive ? AppColors.ok : AppColors.line,
                      ),
                      title: Text(p.name.isEmpty ? '(unnamed profile)' : p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(isActive ? 'Active' : 'Tap to set active',
                          style: TextStyle(fontSize: 12, color: isActive ? AppColors.ok : AppColors.inkSoft)),
                      onTap: () => isActive ? _openForm(existing: p) : _setActive(p),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openForm(existing: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _confirmDelete(p),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
