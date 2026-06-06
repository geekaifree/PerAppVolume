import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const PerAppVolumeApp());

class PerAppVolumeApp extends StatelessWidget {
  const PerAppVolumeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '分应用音量控制', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true, brightness: Brightness.dark),
    home: const VolumeHomePage(),
  );
}

class AppVolume {
  String id, name, icon;
  double volume;
  bool muted;
  AppVolume({required this.id, required this.name, required this.icon, this.volume = 0.7, this.muted = false});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'icon': icon, 'volume': volume, 'muted': muted};
  factory AppVolume.fromJson(Map<String, dynamic> j) => AppVolume(id: j['id'], name: j['name'], icon: j['icon'], volume: j['volume']?.toDouble() ?? 0.7, muted: j['muted'] ?? false);
}

class VolumeHomePage extends StatefulWidget {
  const VolumeHomePage({super.key});
  @override
  State<VolumeHomePage> createState() => _VolumeHomePageState();
}

class _VolumeHomePageState extends State<VolumeHomePage> {
  List<AppVolume> _apps = [];
  double _masterVolume = 0.8;
  bool _masterMuted = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final d = p.getString('app_volumes');
    if (d != null) setState(() => _apps = (json.decode(d) as List).map((e) => AppVolume.fromJson(e)).toList());
    else {
      _apps = [
        AppVolume(id: '1', name: '浏览器', icon: '🌐', volume: 0.8),
        AppVolume(id: '2', name: '音乐播放器', icon: '🎵', volume: 1.0),
        AppVolume(id: '3', name: '视频播放器', icon: '🎬', volume: 0.9),
        AppVolume(id: '4', name: '游戏', icon: '🎮', volume: 0.6),
        AppVolume(id: '5', name: '通讯软件', icon: '💬', volume: 0.7),
        AppVolume(id: '6', name: '系统通知', icon: '🔔', volume: 0.5),
        AppVolume(id: '7', name: '终端', icon: '💻', volume: 0.4),
        AppVolume(id: '8', name: '邮件', icon: '📧', volume: 0.3),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('app_volumes', json.encode(_apps.map((e) => e.toJson()).toList()));
  }

  void _setMasterVolume(double v) { setState(() => _masterVolume = v); }
  void _toggleMasterMute() { setState(() => _masterMuted = !_masterMuted); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔊 分应用音量控制'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() { for (var a in _apps) { a.volume = 0.7; a.muted = false; } }); _save(); }, tooltip: '重置'),
      ]),
      body: Column(children: [
        // 主音量
        Card(margin: const EdgeInsets.all(12), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            IconButton(icon: Icon(_masterMuted ? Icons.volume_off : Icons.volume_up, color: _masterMuted ? Colors.red : null), onPressed: _toggleMasterMute, iconSize: 32),
            const SizedBox(width: 8),
            const Text('主音量', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            Text('${(_masterVolume * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          Slider(value: _masterMuted ? 0 : _masterVolume, onChanged: _setMasterVolume, activeColor: _masterMuted ? Colors.grey : null),
        ]))),
        const Divider(height: 1),
        // 应用音量列表
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), itemCount: _apps.length, itemBuilder: (ctx, i) {
          final app = _apps[i];
          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Column(children: [
            Row(children: [
              Text(app.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${(app.volume * 100).toInt()}%', style: TextStyle(color: app.muted ? Colors.red : Colors.grey, fontSize: 12)),
              ])),
              IconButton(icon: Icon(app.muted ? Icons.volume_off : Icons.volume_up, color: app.muted ? Colors.red : Colors.grey, size: 20), onPressed: () { setState(() => app.muted = !app.muted); _save(); }),
              IconButton(icon: const Icon(Icons.equalizer, size: 20), onPressed: () => _showEq(app)),
            ]),
            Slider(value: app.muted ? 0 : app.volume, onChanged: (v) { setState(() => app.volume = v); _save(); }, activeColor: app.muted ? Colors.grey : null),
          ])));
        })),
      ]),
    );
  }

  void _showEq(AppVolume app) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('${app.icon} ${app.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['低音', '中音', '高音'].map((label) => Column(children: [
        SizedBox(height: 120, child: RotatedBox(quarterTurns: -1, child: Slider(value: 0.5, onChanged: (_) {}))),
        Text(label, style: const TextStyle(fontSize: 12)),
      ])).toList()),
      const SizedBox(height: 16),
      FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('完成')),
    ])));
  }
}
