import 'dart:async';
import 'package:flutter/material.dart';
import 'lucky_stb.dart';

class ScanTab extends StatefulWidget {
  final LuckySTB lucky;
  final String? selectedIp;
  final List<String> devices;
  final bool isScanning;
  final String scanStatus;
  final Function(bool scanning, String status, List<String> deviceList)
      onStateChanged;
  final Function(String ip) onDeviceSelected;

  const ScanTab({
    super.key,
    required this.lucky,
    required this.selectedIp,
    required this.devices,
    required this.isScanning,
    required this.scanStatus,
    required this.onStateChanged,
    required this.onDeviceSelected,
  });

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  String? checkingIp;
  Timer? _connectionMonitor;

  /// 🔥 SCAN
  Future<void> scanDevices() async {
    widget.onStateChanged(true, "Scanning network...", []);
    try {
      final potentialDevices = await widget.lucky.discoverDevicesFast();
      widget.onStateChanged(
          false,
          potentialDevices.isNotEmpty
              ? "Found ${potentialDevices.length} device(s)"
              : "No devices found",
          potentialDevices);
    } catch (_) {
      widget.onStateChanged(false, "Scan failed", []);
    }
  }

  /// 🔌 MONITOR CONNECTION
  void startConnectionMonitor(String ip) {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 2), (_) async {
      final alive = await widget.lucky.isAlive(ip);
      if (!alive) {
        _connectionMonitor?.cancel();
        if (mounted) {
          widget.onDeviceSelected("");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Device disconnected")),
          );
        }
      }
    });
  }

  /// 📡 CONNECT DEVICE
  Future<void> selectDevice(String ip) async {
    setState(() => checkingIp = ip);

    try {
      final alive = await widget.lucky
          .isAlive(ip)
          .timeout(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() => checkingIp = null);

      if (alive) {
        await widget.lucky.connect(ip);
        widget.onDeviceSelected(ip);
        startConnectionMonitor(ip);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connected successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Device not reachable")),
        );
      }
    } catch (_) {
      setState(() => checkingIp = null);
    }
  }

  Widget buildStatusDot(String ip) {
    if (checkingIp == ip) return const Icon(Icons.sync, color: Colors.orange);
    if (widget.selectedIp == ip)
      return const Icon(Icons.circle, color: Colors.green, size: 12);
    return const Icon(Icons.circle, color: Colors.grey, size: 12);
  }

  @override
  void dispose() {
    _connectionMonitor?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Device Scanner",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          /// 🔍 SCAN BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isScanning ? null : scanDevices,
              icon: widget.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(widget.isScanning ? "Scanning..." : "Scan Network"),
            ),
          ),

          const SizedBox(height: 10),

          /// 📢 STATUS
          Text(
            widget.scanStatus,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),

          const SizedBox(height: 10),

          /// ✅ CONNECTED DEVICE CARD (with disconnect)
          if (widget.selectedIp != null && widget.selectedIp!.isNotEmpty)
            Card(
              color: Colors.green.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.tv, color: Colors.green),
                title: Text("Connected: ${widget.selectedIp}"),
                subtitle: const Text("Active device"),
                trailing: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    await widget.lucky.disconnect();
                    _connectionMonitor?.cancel();
                    widget.onDeviceSelected("");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Disconnected successfully")),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 10),

          /// 📋 DEVICE LIST
          Expanded(
            child: widget.devices.isEmpty
                ? const Center(child: Text("No devices found"))
                : ListView.builder(
                    itemCount: widget.devices.length,
                    itemBuilder: (context, index) {
                      final ip = widget.devices[index];
                      final isSelected = widget.selectedIp == ip;

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        child: ListTile(
                          leading: buildStatusDot(ip),
                          title: Text(ip),
                          subtitle:
                              Text(isSelected ? "Connected" : "Tap to connect"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (checkingIp == ip)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (isSelected)
                                IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await widget.lucky.disconnect();
                                    _connectionMonitor?.cancel();
                                    widget.onDeviceSelected("");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Disconnected successfully")),
                                    );
                                  },
                                ),
                            ],
                          ),
                          onTap: () => selectDevice(ip),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
