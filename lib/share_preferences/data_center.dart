import 'package:shared_preferences/shared_preferences.dart';
import 'package:willo_desktop/share_preferences/share_preference_key.dart';

class DataCenter {
  DataCenter._create();

  static DataCenter? _instance;
  static SharedPreferences? prefs;

  static DataCenter? shared() {
    _instance ??= DataCenter._create();
    return _instance;
  }

  /// SET DATA TO DISK
  saveToken(String? token) async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString(accessToken, token ?? "");
  }

  saveUserName(String? value) async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString(userName, value ?? "");
  }

  savePassword(String? value) async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString(password, value ?? "");
  }

  saveCheckUser(bool? value) async {
    await prefs?.setBool(checkUser, value ?? false);
  }

  Future<void> saveListUser(List<String> stringList) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(saveListUserCode, stringList);
  }

  /// GET DATA FROM DISK
  Future<String> getToken() async {
    prefs = await SharedPreferences.getInstance();
    return prefs?.getString(accessToken) ?? "";
  }

  Future<String> getRequestUuidOnly() async {
    prefs = await SharedPreferences.getInstance();
    return prefs?.getString("requestUuidOnly") ?? "";
  }

  saveRequestUuidOnly(String? value) async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString("requestUuidOnly", value ?? "");
  }

  Future<String> getUserName() async {
    prefs = await SharedPreferences.getInstance();
    return prefs?.getString(userName) ?? "";
  }

  Future<String> getPassword() async {
    prefs = await SharedPreferences.getInstance();
    return prefs?.getString(password) ?? "";
  }

  Future<bool> getCheckUser() async {
    prefs = await SharedPreferences.getInstance();
    return prefs?.getBool(checkUser) ?? false;
  }

  Future<List<String>?> getListUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(saveListUserCode);
  }
}
