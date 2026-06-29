import 'package:flutter/material.dart';
import '../models/client.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _clients = LocalDB.instance.getClients());
  }

  Future<void> _openForm({Client? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientFormScreen(existing: existing)),
    );
    _reload();
  }

  Future<void> _confirmDelete(Client c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('This will remove "${c.companyName}" from this device. This can\'t be undone.'),
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
      await LocalDB.instance.deleteClient(c.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _clients.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: AppColors.line),
                    const SizedBox(height: 12),
                    const Text('No clients yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Tap + to add your first client.', style: TextStyle(color: AppColors.inkSoft)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = _clients[i];
                return Card(
                  child: ListTile(
                    title: Text(c.companyName.isEmpty ? '(unnamed)' : c.companyName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      [
                        if (c.contactPerson.isNotEmpty) c.contactPerson,
                        if (c.phone.isNotEmpty) c.phone,
                      ].join('  •  '),
                    ),
                    onTap: () => _openForm(existing: c),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      onPressed: () => _confirmDelete(c),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
