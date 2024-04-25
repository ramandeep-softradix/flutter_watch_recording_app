import 'package:shared_preferences/shared_preferences.dart';


class Prefs {
  static const String audioList = "audioList";
  static const String isLogin = "isLogin";

  Future<void> saveBoolToLocalStorage(bool value, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> getBoolFromLocalStorage(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<String?> saveAudioListToLocalStorage(List<String> value, String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<List<String>> getAudioListFromLocalStorage(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  Future<void> removeKeyFromLocalStorage(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
