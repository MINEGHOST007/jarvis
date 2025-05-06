import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class UserIdService {
  static const String _userIdKey = 'user_id';

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    userId = 'user-${1000 + Random().nextInt(9000)}';
    await prefs.setString(_userIdKey, userId);
    return userId;
  }

  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }
}
