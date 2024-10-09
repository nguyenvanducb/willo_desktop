import 'dart:developer' as developer;

class UtilLogger {
  static const String TAG = "LISTAR";

  static log([String tag = TAG, dynamic msg]) {}

  ///Singleton factory
  static final UtilLogger _instance = UtilLogger._internal();

  factory UtilLogger() {
    return _instance;
  }

  UtilLogger._internal();
}
