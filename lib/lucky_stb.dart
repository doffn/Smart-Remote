import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class LuckySTB {
  List<String> stbDevices = [];
  String? connectedIp;

  static const int port = 8000;
  int _failCount = 0;
  static const int maxFails = 3;

  /// ------------------ LOAD SAVED CONNECTION ------------------
  Future<String?> loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString("connected_ip");
    if (ip != null) connectedIp = ip;
    print("🔁 Restored saved IP: $ip (not validating yet)");
    return ip;
  }

  /// ------------------ SAVE CONNECTION ------------------
  Future<void> saveConnection(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("connected_ip", ip);
    connectedIp = ip;
    _failCount = 0;
  }

  /// ------------------ REMOVE CONNECTION ------------------
  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("connected_ip");
    connectedIp = null;
    _failCount = 0;
    print("⚡ Device disconnected manually");
  }

  /// ------------------ SOFT CHECK ------------------
  Future<bool> isAlive(String ip) async {
    try {
      final res = await http
          .post(Uri.parse("http://$ip:$port/api/v1/key"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"key": ""}))
          .timeout(const Duration(milliseconds: 1200));

      if (res.statusCode == 200) {
        _failCount = 0;
        return true;
      }
    } catch (_) {}

    _failCount++;

    if (_failCount < maxFails) {
      print("⚠️ Temporary failure ($_failCount/$maxFails), still connected");
      return true;
    }

    if (connectedIp == ip) connectedIp = null;

    print("❌ Device truly unreachable");
    return false;
  }

  /// ------------------ CONNECT ------------------
  Future<bool> connect(String ip) async {
    connectedIp = ip;
    _failCount = 0;
    await saveConnection(ip);
    return true;
  }

  /// ------------------ GET SUBNET ------------------
  Future<String?> _getLocalSubnet() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    if (ip == null || ip == "0.0.0.0" || !ip.contains('.')) return null;
    return ip.substring(0, ip.lastIndexOf('.'));
  }

  /// ------------------ PROBE ------------------
  Future<String?> _probeIp(String ip) async {
    try {
      final res = await http
          .post(Uri.parse("http://$ip:$port/api/v1/key"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"key": ""}))
          .timeout(const Duration(milliseconds: 700));

      if (res.statusCode == 200) return ip;
    } catch (_) {}
    return null;
  }

  /// ------------------ SCAN (FAST + SMART) ------------------
  Future<List<String>> discoverDevicesFast() async {
    final subnet = await _getLocalSubnet();
    if (subnet == null) return [];

    final found = <String>[];

    // STEP 1: Check existing connection FIRST
    if (connectedIp != null) {
      final alive = await isAlive(connectedIp!);
      if (alive) {
        print("⚡ Using existing connection: $connectedIp");
        stbDevices = [connectedIp!];
        return stbDevices;
      }
    }

    // STEP 2: Aggressive parallel scan
    const int batchSize = 40;

    for (int i = 1; i < 255; i += batchSize) {
      final futures = <Future<String?>>[];

      for (int j = i; j < i + batchSize && j < 255; j++) {
        futures.add(_probeIp("$subnet.$j"));
      }

      final results = await Future.wait(futures);

      final valid = results.whereType<String>().toList();

      if (valid.isNotEmpty) {
        found.addAll(valid);
        print("⚡ Found device(s) early: $valid");
        break; // STOP EARLY (SPEED BOOST)
      }
    }

    stbDevices = found.toSet().toList();
    print("🎯 Devices Found: $stbDevices");
    return stbDevices;
  }

  /// ------------------ SEND KEY ------------------
  Future<bool> sendKey(String key, {String? ip}) async {
    final targetIp = ip ?? connectedIp;
    if (targetIp == null) return false;

    try {
      final res = await http
          .post(Uri.parse("http://$targetIp:$port/api/v1/key"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"key": key}))
          .timeout(const Duration(seconds: 2));

      _failCount = 0;
      return res.statusCode == 200;
    } catch (_) {
      _failCount++;
      return _failCount < maxFails;
    }
  }

  /// ------------------ CAST ------------------
  Future<bool> cast(String videoUrl, {String? ip}) async {
    final targetIp = ip ?? connectedIp;
    if (targetIp == null) return false;

    if (videoUrl.contains(".mp4") ||
        videoUrl.contains(".m3u8") ||
        videoUrl.contains("googlevideo.com")) {
      return _play(videoUrl, ip: targetIp);
    }

    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(videoUrl);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final stream = manifest.muxed.withHighestBitrate();
      final url = stream!.url.toString();
      yt.close();
      return _play(url, ip: targetIp);
    } catch (_) {
      yt.close();
      return _play(videoUrl, ip: targetIp);
    }
  }

  /// ------------------ PLAY ------------------
  Future<bool> _play(String uri, {String? ip}) async {
    final targetIp = ip ?? connectedIp;
    if (targetIp == null) return false;

    try {
      final res = await http
          .post(Uri.parse("http://$targetIp:$port/api/v1/play"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "stream_type": "net",
                "media_type": "video",
                "action": "play",
                "uri": uri,
                "time": 0
              }))
          .timeout(const Duration(seconds: 4));

      _failCount = 0;
      return res.statusCode == 200;
    } catch (_) {
      _failCount++;
      return _failCount < maxFails;
    }
  }
}
