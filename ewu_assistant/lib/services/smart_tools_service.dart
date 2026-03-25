import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SmartToolsService {
  static const String _coursePlannerKey = 'smart_course_planner';
  static const String _examCountdownKey = 'smart_exam_countdown';
  static const String _facultyContactsKey = 'smart_faculty_contacts';

  Future<List<Map<String, dynamic>>> loadCoursePlannerItems() {
    return _readList(_coursePlannerKey);
  }

  Future<void> saveCoursePlannerItems(List<Map<String, dynamic>> items) {
    return _writeList(_coursePlannerKey, items);
  }

  Future<List<Map<String, dynamic>>> loadExamCountdownItems() {
    return _readList(_examCountdownKey);
  }

  Future<void> saveExamCountdownItems(List<Map<String, dynamic>> items) {
    return _writeList(_examCountdownKey, items);
  }

  Future<List<Map<String, dynamic>>> loadFacultyContacts() {
    return _readList(_facultyContactsKey);
  }

  Future<void> saveFacultyContacts(List<Map<String, dynamic>> items) {
    return _writeList(_facultyContactsKey, items);
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      return decoded.whereType<Map>().map((Map entry) {
        return entry.map(
          (dynamic key, dynamic value) =>
              MapEntry<String, dynamic>(key.toString(), value),
        );
      }).toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }
}
