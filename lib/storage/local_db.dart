import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/company_profile.dart';
import '../models/client.dart';
import '../models/catalog_item.dart';
import '../models/terms_preset.dart';
import '../models/quote_doc.dart';
import '../utils/ids.dart';

/// All data is stored using Hive, a local key-value database that writes
/// its files into this device's own private app-storage folder.
/// Nothing here ever leaves the device or syncs to any account/cloud —
/// each phone/tablet/laptop running this app keeps its own independent data.
///
/// Box names:
///   'app'        -> counters, admin-activation flag, activeProfileId, lastBackupAt
///   'profiles'   -> CompanyProfile records keyed by id (multiple allowed)
///   'clients'    -> Client records keyed by id
///   'catalog'    -> CatalogItem records keyed by id
///   'terms'      -> TermsPreset records keyed by id
///   'documents'  -> QuoteDoc (quotations + invoices) records keyed by id
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  late Box appBox;
  late Box profilesBox;
  late Box clientsBox;
  late Box catalogBox;
  late Box termsBox;
  late Box documentsBox;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();

    appBox = await Hive.openBox('app');
    profilesBox = await Hive.openBox('profiles');
    clientsBox = await Hive.openBox('clients');
    catalogBox = await Hive.openBox('catalog');
    termsBox = await Hive.openBox('terms');
    documentsBox = await Hive.openBox('documents');

    await _migrateLegacySingleProfile();

    _ready = true;
  }

  /// Older versions of the app stored exactly one company profile under
  /// appBox['companyProfile']. If that's present and the new multi-profile
  /// box is still empty, migrate it once so existing data isn't lost.
  Future<void> _migrateLegacySingleProfile() async {
    if (profilesBox.isNotEmpty) return;
    final legacy = appBox.get('companyProfile');
    if (legacy == null) return;
    final profile = CompanyProfile.fromMap(Map<dynamic, dynamic>.from(legacy));
    profile.id = generateId();
    await profilesBox.put(profile.id, profile.toMap());
    await appBox.put('activeProfileId', profile.id);
  }

  // ---------------- Company profiles (multiple allowed) ----------------
  List<CompanyProfile> getProfiles() =>
      profilesBox.values.map((m) => CompanyProfile.fromMap(Map<dynamic, dynamic>.from(m))).toList();

  Future<void> saveProfile(CompanyProfile p) async {
    if (p.id.isEmpty) p.id = generateId();
    await profilesBox.put(p.id, p.toMap());
    // First profile ever created automatically becomes the active one.
    if (appBox.get('activeProfileId') == null) {
      await setActiveProfileId(p.id);
    }
  }

  Future<void> deleteProfile(String id) async {
    await profilesBox.delete(id);
    if (appBox.get('activeProfileId') == id) {
      final remaining = getProfiles();
      await appBox.put('activeProfileId', remaining.isEmpty ? null : remaining.first.id);
    }
  }

  String? getActiveProfileId() => appBox.get('activeProfileId');

  Future<void> setActiveProfileId(String id) async => appBox.put('activeProfileId', id);

  /// Returns the active profile, falling back to the first available
  /// profile, or a blank one if none exist yet.
  CompanyProfile getActiveProfile() {
    final profiles = getProfiles();
    if (profiles.isEmpty) return CompanyProfile();
    final activeId = getActiveProfileId();
    return profiles.firstWhere((p) => p.id == activeId, orElse: () => profiles.first);
  }

  /// Looks up a specific profile by id (used when reprinting an old
  /// document so it keeps showing the profile that issued it). Falls back
  /// to the active profile if the id is blank or no longer exists.
  CompanyProfile getProfileById(String id) {
    final profiles = getProfiles();
    if (profiles.isEmpty) return CompanyProfile();
    return profiles.firstWhere((p) => p.id == id, orElse: () => getActiveProfile());
  }

  // ---------------- Counters (for Ref. No. generation) ----------------
  int nextCounter(String key) {
    final counters = Map<String, dynamic>.from(appBox.get('counters') ?? {});
    final current = (counters[key] ?? 0) as int;
    final next = current + 1;
    counters[key] = next;
    appBox.put('counters', counters);
    return next;
  }

  // ---------------- Backup reminder tracking ----------------
  DateTime? getLastBackupAt() {
    final raw = appBox.get('lastBackupAt');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastBackupAtNow() async {
    await appBox.put('lastBackupAt', DateTime.now().toIso8601String());
  }

  // ---------------- Clients ----------------
  List<Client> getClients() =>
      clientsBox.values.map((m) => Client.fromMap(Map<dynamic, dynamic>.from(m))).toList();

  Future<void> saveClient(Client c) async => clientsBox.put(c.id, c.toMap());
  Future<void> deleteClient(String id) async => clientsBox.delete(id);

  // ---------------- Catalog items ----------------
  List<CatalogItem> getCatalogItems() =>
      catalogBox.values.map((m) => CatalogItem.fromMap(Map<dynamic, dynamic>.from(m))).toList();

  Future<void> saveCatalogItem(CatalogItem i) async => catalogBox.put(i.id, i.toMap());
  Future<void> deleteCatalogItem(String id) async => catalogBox.delete(id);

  // ---------------- Terms presets ----------------
  List<TermsPreset> getTermsPresets() =>
      termsBox.values.map((m) => TermsPreset.fromMap(Map<dynamic, dynamic>.from(m))).toList();

  Future<void> saveTermsPreset(TermsPreset t) async => termsBox.put(t.id, t.toMap());
  Future<void> deleteTermsPreset(String id) async => termsBox.delete(id);

  // ---------------- Quotations / Invoices ----------------
  List<QuoteDoc> getDocuments() =>
      documentsBox.values.map((m) => QuoteDoc.fromMap(Map<dynamic, dynamic>.from(m))).toList();

  Future<void> saveDocument(QuoteDoc d) async => documentsBox.put(d.id, d.toMap());
  Future<void> deleteDocument(String id) async => documentsBox.delete(id);

  // ---------------- Backup / Restore (manual export-import, no auto-sync) ----------------
  /// Dumps every box's contents into a single plain JSON-able map.
  /// This is the explicit, user-triggered way to move data between devices —
  /// there is no automatic cloud sync, by design.
  Map<String, dynamic> exportAll() {
    return {
      'app': {
        'counters': appBox.get('counters'),
        'activeProfileId': appBox.get('activeProfileId'),
      },
      'profiles': profilesBox.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'clients': clientsBox.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'catalog': catalogBox.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'terms': termsBox.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'documents': documentsBox.toMap().map((k, v) => MapEntry(k.toString(), v)),
      'exportedAt': DateTime.now().toIso8601String(),
      'app_name': 'EasyQuote',
    };
  }

  /// Restores from a previously exported map. This OVERWRITES current
  /// on-device data for each box present in the backup file.
  Future<void> importAll(Map<String, dynamic> data) async {
    final app = data['app'] as Map?;
    if (app != null) {
      if (app['counters'] != null) await appBox.put('counters', app['counters']);
      if (app['activeProfileId'] != null) await appBox.put('activeProfileId', app['activeProfileId']);
    }
    Future<void> restoreBox(Box box, String key) async {
      final m = data[key] as Map?;
      if (m == null) return;
      await box.clear();
      for (final entry in m.entries) {
        await box.put(entry.key, entry.value);
      }
    }

    await restoreBox(profilesBox, 'profiles');
    await restoreBox(clientsBox, 'clients');
    await restoreBox(catalogBox, 'catalog');
    await restoreBox(termsBox, 'terms');
    await restoreBox(documentsBox, 'documents');
  }
}
