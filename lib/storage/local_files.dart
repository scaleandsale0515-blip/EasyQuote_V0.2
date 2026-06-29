import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/ids.dart';

/// Copies a picked image into this app's private local documents folder
/// (still entirely on-device — just outside Hive, since Hive isn't meant
/// for large binary blobs) and returns the saved file's path.
class LocalFiles {
  static Future<String> saveImage(File source, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${dir.path}/easyquote_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = source.path.split('.').last;
    final fileName = '${prefix}_${generateId()}.$ext';
    final dest = File('${imagesDir.path}/$fileName');
    await source.copy(dest.path);
    return dest.path;
  }

  static Future<Directory> exportsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/easyquote_exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir;
  }
}
