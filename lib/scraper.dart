import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UniversalVideoScraper {
  static const String _ua =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36";

  static const String _apiEndpoint =
      "Extractor End point API for external processing";  // External scraper code endpoint

  WebViewController? webViewController;

  UniversalVideoScraper({this.webViewController});

  Future<Map<String, dynamic>> extract({Function(String)? onProgress}) async {
    if (webViewController == null) {
      return {"status": 400, "message": "WebViewController not set"};
    }

    final url = await webViewController!.currentUrl();
    if (url == null || url.isEmpty || !url.startsWith("http")) {
      return {"status": 400, "message": "Invalid URL"};
    }

    onProgress?.call("Starting extraction...");

    /// ---------- DIRECT ----------
    onProgress?.call("Checking for direct video link...");
    final direct = _directCheck(url);
    if (direct != null) {
      onProgress?.call("Direct link found");
      return _success("Direct Stream", direct, "Direct");
    }

    final lower = url.toLowerCase();

    /// ---------- YOUTUBE ----------
    if (lower.contains("youtube") || lower.contains("youtu.be")) {
      onProgress?.call("Trying YouTube extraction...");
      final yt = await _scrapeYouTube(url);
      if (yt['status'] == 200) {
        onProgress?.call("YouTube extraction successful");
        return yt;
      }

      onProgress?.call("YouTube failed, trying Invidious...");
      final inv = await _scrapeInvidious(url);
      if (inv['status'] == 200) {
        onProgress?.call("Invidious extraction successful");
        return inv;
      }
    }

    /// ---------- API ----------
    onProgress?.call("Trying API extraction...");
    final api = await _apiExtract(url);
    if (api['status'] == 200) {
      onProgress?.call("API extraction successful");
      return api;
    }

    /// ---------- SCRAPING ----------
    try {
      onProgress?.call("Trying HTML scraping...");
      try {
        final html = await _htmlScrape(url);
        onProgress?.call("HTML scraping successful");
        return html;
      } catch (_) {
        onProgress?.call("HTML scraping failed, trying Regex scraping...");
        try {
          final regex = await _regexScrape(url);
          onProgress?.call("Regex scraping successful");
          return regex;
        } catch (_) {
          onProgress?.call("Regex scraping failed, trying JSON scraping...");
          final json = await _jsonScrape(url);
          onProgress?.call("JSON scraping successful");
          return json;
        }
      }
    } catch (_) {
      onProgress?.call("No stream found");
      return {"status": 500, "message": "No stream found"};
    }
  }

  String? _directCheck(String url) {
    if (url.contains(".m3u8") ||
        url.contains(".mp4") ||
        url.contains("googlevideo.com") ||
        url.contains("videoplayback")) {
      return url;
    }
    return null;
  }

  Future<Map<String, dynamic>> _scrapeYouTube(String url) async {
    final yt = YoutubeExplode();

    try {
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final muxed = manifest.muxed;

      if (muxed.isNotEmpty) {
        final stream = muxed.withHighestBitrate();
        return _success(
          video.title,
          stream.url.toString(),
          "YouTube",
          thumb: video.thumbnails.highResUrl,
        );
      }
    } catch (e) {
      return {"status": 500, "message": "YT extraction failed: $e"};
    } finally {
      yt.close();
    }

    return {"status": 500};
  }

  Future<Map<String, dynamic>> _scrapeInvidious(String url) async {
    try {
      final id = _extractVideoId(url);
      if (id == null) throw "No video ID";

      final res = await http.get(
        Uri.parse("https://inv.nadeko.net/api/v1/videos/$id"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final formats = data["formatStreams"];
        if (formats != null && formats.isNotEmpty) {
          final stream = formats[0];
          return _success(
            data["title"] ?? "YouTube",
            stream["url"],
            "Invidious",
            thumb: data["videoThumbnails"]?[0]?["url"],
          );
        }
      }
    } catch (_) {}
    return {"status": 500};
  }

  String? _extractVideoId(String url) {
    final reg = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})');
    return reg.firstMatch(url)?.group(1);
  }

  Future<Map<String, dynamic>> _apiExtract(String url) async {
    try {
      final res = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"url": url}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final d = data['data'];

        if (d != null && d['direct_url'] != null) {
          return _success(
            d['title'] ?? "Video",
            d['direct_url'],
            "API",
          );
        }
      }
    } catch (_) {}

    return {"status": 500};
  }

  Future<Map<String, dynamic>> _htmlScrape(String url) async {
    final res = await http.get(Uri.parse(url), headers: {"User-Agent": _ua});
    final body = res.body;

    final videoMatch = RegExp(r'<video[^>]+src="([^"]+)"').firstMatch(body);
    final sourceMatch = RegExp(r'<source[^>]+src="([^"]+)"').firstMatch(body);

    final found = videoMatch?.group(1) ?? sourceMatch?.group(1);

    if (found != null) {
      return _success("HTML Video", found, "HTML");
    }

    throw "No HTML stream found";
  }

  Future<Map<String, dynamic>> _regexScrape(String url) async {
    final res = await http.get(Uri.parse(url), headers: {"User-Agent": _ua});

    final match = RegExp(
      r'''https?:\/\/[^\s"\'<>]+?\.(m3u8|mp4|webm)[^\s"\'<>]*''',
      caseSensitive: false,
    ).firstMatch(res.body);

    if (match != null) {
      return _success("Detected Stream", match.group(0)!, "Regex");
    }

    throw "No Regex stream found";
  }

  Future<Map<String, dynamic>> _jsonScrape(String url) async {
    final res = await http.get(Uri.parse(url), headers: {"User-Agent": _ua});

    final match = RegExp(r'file"\s*:\s*"([^"]+)"').firstMatch(res.body);

    if (match != null) {
      return _success("Player Source", match.group(1)!, "JSON");
    }

    throw "No JSON stream found";
  }

  Map<String, dynamic> _success(String title, String url, String extractor,
      {String? thumb}) {
    return {
      "status": 200,
      "data": {
        "title": title,
        "direct_url": url,
        "extractor": extractor,
        "thumbnail": thumb
      }
    };
  }
}
