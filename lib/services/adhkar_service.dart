import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/dhikr.dart';

class AdhkarService {
  /// Asynchronously loads Adhkar directly from the JSON asset file
  static Future<List<Dhikr>> loadAdhkar(String category) async {
    final String response = await rootBundle.loadString(
      'assets/data/adhkar.json',
    );
    final List<dynamic> data = json.decode(response);

    return data
        .map((e) => Dhikr.fromJson(e))
        .where((d) => d.category == category)
        .toList();
  }
}
