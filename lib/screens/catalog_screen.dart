import 'package:flutter/material.dart';
import '../models/catalog_item.dart';
import '../storage/local_db.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'catalog_form_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<CatalogItem> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _items = LocalDB.instance.getCatalogItems());
  }

  Future<void> _openForm({CatalogItem? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CatalogFormScreen(existing: existing)),
    );
    _reload();
  }

  Future<void> _confirmDelete(CatalogItem i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${i.description}" from the catalog on this device.'),
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
      await LocalDB.instance.deleteCatalogItem(i.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items Catalog')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.line),
                    const SizedBox(height: 12),
                    const Text('No catalog items yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Add reusable products/services with their rate & unit.',
                        style: TextStyle(color: AppColors.inkSoft)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final it = _items[idx];
                return Card(
                  child: ListTile(
                    title: Text(it.description.isEmpty ? '(no description)' : it.description,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${it.unit}${it.grade.isNotEmpty ? '  •  ${it.grade}' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatRupees(it.rate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                          onPressed: () => _confirmDelete(it),
                        ),
                      ],
                    ),
                    onTap: () => _openForm(existing: it),
                  ),
                );
              },
            ),
    );
  }
}
