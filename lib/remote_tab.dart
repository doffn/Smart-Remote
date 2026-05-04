import 'package:flutter/material.dart';
import 'lucky_stb.dart';

class RemoteTab extends StatelessWidget {
  final LuckySTB lucky;
  final String? selectedIp;
  final bool isFullRemote;

  const RemoteTab({
    super.key,
    required this.lucky,
    required this.selectedIp,
    required this.isFullRemote,
  });

  // ✅ Fixed: use named parameter ip
  Future<void> sendKey(BuildContext context, String keyCode) async {
    if (selectedIp == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No device selected!")));
      return;
    }
    bool success = await lucky.sendKey(keyCode, ip: selectedIp!);
    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Device unreachable")));
    }
  }

  Widget _remoteBtn(BuildContext context, String label, String code,
      {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onPressed: () => sendKey(context, code),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _remoteIconBtn(BuildContext context, IconData icon, String code,
      {Color? color, double size = 56}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: color ?? Colors.blue.shade600,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, color: Colors.white),
        onPressed: () => sendKey(context, code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isFullRemote ? _buildFull(context) : _buildMini(context);
  }

  Widget _buildMini(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _remoteIconBtn(context, Icons.power_settings_new, "WEBK_POWER",
                  color: Colors.red),
              const SizedBox(width: 30),
              _remoteIconBtn(context, Icons.volume_off, "WEBK_MUTE",
                  color: Colors.blueGrey),
            ]),
            const SizedBox(height: 30),
            _remoteIconBtn(context, Icons.keyboard_arrow_up, "WEBK_UP"),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _remoteIconBtn(context, Icons.keyboard_arrow_left, "WEBK_LEFT"),
              _remoteIconBtn(context, Icons.check_circle, "WEBK_OK",
                  color: Colors.blue.shade900, size: 64),
              _remoteIconBtn(context, Icons.keyboard_arrow_right, "WEBK_RIGHT"),
            ]),
            _remoteIconBtn(context, Icons.keyboard_arrow_down, "WEBK_DOWN"),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _remoteIconBtn(context, Icons.menu, "WEBK_MENU"),
              _remoteIconBtn(context, Icons.home, "WEBK_MENU"),
              _remoteIconBtn(context, Icons.keyboard_return, "WEBK_EXIT"),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(children: [
            _remoteIconBtn(context, Icons.power_settings_new, "WEBK_POWER",
                color: Colors.red, size: 50),
            _remoteBtn(context, "TV/R", "WEBK_TV_RADIO"),
            _remoteIconBtn(context, Icons.volume_off, "WEBK_MUTE",
                size: 50, color: Colors.blueGrey),
          ]),
          const SizedBox(height: 10),
          for (var i = 0; i < 3; i++)
            Row(children: [
              for (var j = 1; j <= 3; j++)
                _remoteBtn(context, "${(i * 3) + j}", "WEBK_${(i * 3) + j}"),
            ]),
          Row(children: [
            _remoteBtn(context, "FAV", "WEBK_FAV"),
            _remoteBtn(context, "0", "WEBK_0"),
            _remoteBtn(context, "ZOOM", "WEBK_FIND"),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            _remoteBtn(context, "MENU", "WEBK_MENU"),
            _remoteBtn(context, "EPG", "WEBK_EPG"),
            _remoteBtn(context, "INFO", "WEBK_INFO"),
            _remoteBtn(context, "EXIT", "WEBK_EXIT"),
          ]),
          const SizedBox(height: 15),
          Row(
            children: [
              Column(children: [
                _remoteIconBtn(context, Icons.add, "WEBK_VOLUME_UP", size: 48),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text("VOL", style: TextStyle(fontSize: 10))),
                _remoteIconBtn(context, Icons.remove, "WEBK_VOLUME_DOWN",
                    size: 48),
              ]),
              Expanded(
                child: Column(children: [
                  _remoteIconBtn(context, Icons.keyboard_arrow_up, "WEBK_UP",
                      size: 48),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _remoteIconBtn(
                        context, Icons.keyboard_arrow_left, "WEBK_LEFT",
                        size: 48),
                    _remoteIconBtn(
                        context, Icons.radio_button_checked, "WEBK_OK",
                        size: 54, color: Colors.blue.shade900),
                    _remoteIconBtn(
                        context, Icons.keyboard_arrow_right, "WEBK_RIGHT",
                        size: 48),
                  ]),
                  _remoteIconBtn(
                      context, Icons.keyboard_arrow_down, "WEBK_DOWN",
                      size: 48),
                ]),
              ),
              Column(children: [
                _remoteIconBtn(context, Icons.add, "WEBK_PAGE_UP", size: 48),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text("PAGE", style: TextStyle(fontSize: 10))),
                _remoteIconBtn(context, Icons.remove, "WEBK_PAGE_DOWN",
                    size: 48),
              ]),
            ],
          ),
          const SizedBox(height: 15),
          Row(children: [
            _remoteBtn(context, "", "WEBK_RED", color: Colors.red),
            _remoteBtn(context, "", "WEBK_GREEN", color: Colors.green),
            _remoteBtn(context, "", "WEBK_YELLOW",
                color: Colors.yellow.shade700),
            _remoteBtn(context, "", "WEBK_BLUE", color: Colors.blue.shade900),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _remoteIconBtn(context, Icons.skip_previous, "WEBK_PREV", size: 48),
            _remoteIconBtn(context, Icons.skip_next, "WEBK_NEXT", size: 48),
            _remoteIconBtn(context, Icons.play_arrow, "WEBK_PLAY", size: 48),
            _remoteIconBtn(context, Icons.fiber_manual_record, "WEBK_REC",
                size: 48, color: Colors.red),
          ]),
        ],
      ),
    );
  }
}
