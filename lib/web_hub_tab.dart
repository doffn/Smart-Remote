import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import 'lucky_stb.dart';
import 'scraper.dart';

class WebApp {
  final String name;
  final String url;
  final String logo;

  WebApp(this.name, this.url, this.logo);

  Map<String, dynamic> toJson() => {"name": name, "url": url, "logo": logo};

  factory WebApp.fromJson(Map<String, dynamic> json) =>
      WebApp(json["name"], json["url"], json["logo"]);
}

class WebHubTab extends StatefulWidget {
  final LuckySTB lucky;
  final String? selectedIp;

  const WebHubTab({super.key, required this.lucky, this.selectedIp});

  @override
  State<WebHubTab> createState() => _WebHubTabState();
}

class _WebHubTabState extends State<WebHubTab> {
  final TextEditingController searchController = TextEditingController();

  List<WebApp> apps = [];
  List<WebApp> recent = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
    _loadRecent();
  }

  /// ---------------- LOAD APPS ----------------
  Future<void> _loadApps() async {
    const remoteUrl = "LIST OF APP JSON ENDPOINT";    //create a json endpoint for the list of apps
    List<WebApp> loadedApps = [];

    try {
      final response = await http.get(Uri.parse(remoteUrl));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonObj = jsonDecode(response.body);

        List data = [];
        if (jsonObj is Map &&
            jsonObj['data'] != null &&
            jsonObj['data']['apps'] != null) {
          data = jsonObj['data']['apps'];
        }

        if (data.isNotEmpty) {
          loadedApps = data.map((e) => WebApp.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load remote apps: $e");
    }

    // fallback to local JSON
    if (loadedApps.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString('assets/apps.json');
        final jsonObj = jsonDecode(jsonStr);

        List data = [];
        if (jsonObj is List) {
          data = jsonObj;
        } else if (jsonObj is Map && jsonObj['apps'] != null) {
          data = jsonObj['apps'];
        }

        if (data.isNotEmpty) {
          loadedApps = data.map((e) => WebApp.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint("❌ Failed to load local apps.json: $e");
      }
    }

    if (mounted) {
      setState(() {
        apps = loadedApps;
      });
    }
  }

  /// ---------------- RECENT ----------------
  Future<void> _saveRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = recent.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("recent_apps", list);
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("recent_apps") ?? [];
    if (mounted) {
      setState(() {
        recent = list.map((e) => WebApp.fromJson(jsonDecode(e))).toList();
      });
    }
  }

  List<WebApp> get filtered {
    final q = searchController.text.toLowerCase();
    if (q.isEmpty) return apps;
    return apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  void openApp(WebApp app) {
    setState(() {
      recent.removeWhere((e) => e.url == app.url);
      recent.insert(0, app);
      if (recent.length > 4) recent.removeLast();
    });

    _saveRecent();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebScreen(
          title: app.name,
          url: app.url,
          lucky: widget.lucky,
          targetIp: widget.selectedIp,
        ),
      ),
    );
  }

  void addCustomUrl() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add URL"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "https://..."),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final url = controller.text.trim();
              if (url.startsWith("http")) {
                openApp(WebApp(
                  "Custom",
                  url,
                  "https://cdn-icons-png.flaticon.com/512/565/565547.png",
                ));
              }
            },
            child: const Text("OPEN"),
          )
        ],
      ),
    );
  }

  Widget appCard(WebApp app) {
    return GestureDetector(
      onTap: () => openApp(app),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              app.logo,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.public, size: 50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            app.name,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search apps...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            if (recent.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Recent",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (_, i) => appCard(recent[i]),
                ),
              ),
              const Divider(),
            ],
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) => appCard(filtered[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addCustomUrl,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class WebScreen extends StatefulWidget {
  final String title, url;
  final LuckySTB lucky;
  final String? targetIp;

  const WebScreen(
      {super.key,
      required this.title,
      required this.url,
      required this.lucky,
      this.targetIp});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController controller;
  bool isCasting = false;
  String progressText = "";
  final scraper = UniversalVideoScraper();

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => progressText = "");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // link scraper to controller
    scraper.webViewController = controller;
  }

  void doCast() async {
    if (isCasting) return;

    setState(() {
      isCasting = true;
      progressText = "Analyzing page content...";
    });

    try {
      final result = await scraper.extract(
        onProgress: (msg) {
          if (mounted) setState(() => progressText = msg);
        },
      );

      if (!mounted) return;

      if (result['status'] == 200) {
        final videoUrl = result['data']['direct_url'];
        final title = result['data']['title'] ?? "Video";

        if (widget.targetIp != null) {
          setState(() => progressText = "Connecting to TV...");
          await widget.lucky.cast(videoUrl, ip: widget.targetIp!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Playing on TV ✅")),
            );
          }
        } else {
          _showLinkDialog(title, videoUrl);
        }
      } else {
        _showError(result['message'] ?? "Could not find a video stream.");
      }
    } catch (e) {
      _showError("An error occurred during extraction.");
    } finally {
      if (mounted) setState(() => isCasting = false);
    }
  }

  void _showLinkDialog(String title, String url) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Found stream link:", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(color: Colors.blue, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied to clipboard")),
              );
            },
            child: const Text("COPY"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await controller.canGoBack()) {
          controller.goBack();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await controller.canGoBack()) {
                controller.goBack();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: WebViewWidget(controller: controller)),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (progressText.isNotEmpty || isCasting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isCasting)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            if (isCasting) const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                progressText,
                                style: const TextStyle(
                                    fontSize: 12, fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: isCasting ? null : doCast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cast),
                        label: Text(isCasting ? "EXTRACTING..." : "CAST TO TV"),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
