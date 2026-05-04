import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  // Helper function to launch external browser
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              "https://raw.githubusercontent.com/doffn/doffneri/refs/heads/main/staticfiles/fevi.ico",
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "DoffRemote",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "STB to Internet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),

          const Divider(height: 40),

          // Horizontal Social/Link Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                icon: Icons.web,
                url: "https://doffneri.vercel.app",
                tooltip: "Website",
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: Icons.code,
                url: "https://github.com/doffn",
                tooltip: "GitHub",
              ),
              const SizedBox(width: 20),
              _buildSocialIcon(
                icon: Icons.telegram,
                url: "https://t.me/doffn",
                tooltip: "Telegram",
              ),
            ],
          ),

          const Divider(height: 40),

          _buildInfoTile(
            title: "Developer",
            content: "Dawit Neri",
            icon: Icons.person,
          ),
          _buildInfoTile(
            title: "Purpose",
            content:
                "Connect your Lifestar STB to the Internet and stream videos directly.",
            icon: Icons.tv,
          ),
          _buildInfoTile(
            title: "Technical Focus",
            content: "Network discovery & remote control for STB devices.",
            icon: Icons.settings_suggest,
          ),

          const SizedBox(height: 40),
          const Text(
            "© 2026 Built by Dawit Neri",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for horizontal icons
  Widget _buildSocialIcon(
      {required IconData icon, required String url, required String tooltip}) {
    return IconButton(
      icon: Icon(icon, color: Colors.blue.shade700, size: 30),
      tooltip: tooltip,
      onPressed: () => _launchURL(url),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
