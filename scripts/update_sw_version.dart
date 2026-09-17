// scripts/update_sw_version.dart
// ignore_for_file: avoid_print
// Auto-increments version in pubspec.yaml and updates offline_worker.js CACHE_NAME

import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found.');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  String? currentVersion;
  int versionLineIndex = -1;

  // 1. Find and update version in pubspec.yaml
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim().startsWith('version:')) {
      versionLineIndex = i;
      currentVersion = lines[i].split(':').last.trim();
      break;
    }
  }

  if (currentVersion == null || versionLineIndex == -1) {
    stderr.writeln('Error: No version line found in pubspec.yaml');
    exit(1);
  }

  // Parse version (e.g., 1.0.0+1)
  final parts = currentVersion.split('+');
  String baseVersion = parts[0];
  int buildNumber = 1;

  if (parts.length > 1) {
    buildNumber = int.tryParse(parts[1]) ?? 1;
  }

  // Increment build number
  final newBuildNumber = buildNumber + 1;
  final newVersion = '$baseVersion+$newBuildNumber';

  // Update pubspec.yaml content
  lines[versionLineIndex] = 'version: $newVersion';
  pubspecFile.writeAsStringSync(lines.join('\n'));
  print('✅ Version bumped: $currentVersion -> $newVersion');

  // 2. Update offline_worker.js CACHE_NAME
  final swFile = File('web/offline_worker.js');
  if (!swFile.existsSync()) {
    stderr.writeln('Error: web/offline_worker.js not found.');
    exit(1);
  }

  final swContent = swFile.readAsStringSync();
  final cacheName = 'flutter-app-cache-v$newVersion';

  final updatedSwContent = swContent.replaceFirst(
    RegExp(r"const CACHE_NAME = '[^']*';"),
    "const CACHE_NAME = '$cacheName';",
  );

  swFile.writeAsStringSync(updatedSwContent);
  print('✅ CACHE_NAME updated to: $cacheName');
}
