import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    // 10.0.2.2 is the special IP address for the Android emulator 
    // to access the host's localhost (127.0.0.1)
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080";
    }
    // For iOS and Web, localhost works fine
    return "http://localhost:8080";
  }
}
