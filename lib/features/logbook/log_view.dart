import 'package:flutter/material.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late Future<List<LogModel>> _logsFuture;
  bool _isOffline = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  void _refreshLogs() {
    setState(() {
      _isOffline = false;
      _logsFuture = MongoService().getLogs();
    });
  }

  void _showAddLogDialog() {
    _categoryController.text = LogController.categories[0];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: "Judul Catatan")),
            TextField(controller: _contentController, decoration: const InputDecoration(hintText: "Isi Deskripsi")),
            DropdownButtonFormField<String>(
              initialValue: _categoryController.text,
              items: LogController.categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _categoryController.text = v!),
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              await _controller.addLog(_titleController.text, _contentController.text, _categoryController.text);
              _titleController.clear(); _contentController.clear(); _categoryController.clear();
              Navigator.pop(context);
              _refreshLogs();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditLogDialog(LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _categoryController.text = log.category;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _contentController),
            DropdownButtonFormField<String>(
              initialValue: _categoryController.text,
              items: LogController.categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _categoryController.text = v!),
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              await _controller.updateLog(log, _titleController.text, _contentController.text, _categoryController.text);
              _titleController.clear(); _contentController.clear(); _categoryController.clear();
              Navigator.pop(context);
              _refreshLogs();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    _logsFuture = Future.value([]);
    Future.microtask(() async { await _initDatabase(); _refreshLogs(); });
  }

  Future<void> _initDatabase() async {
    try {
      await LogHelper.writeLog("UI: Memulai inisialisasi database...", source: "log_view.dart");
      await LogHelper.writeLog("UI: Menghubungi MongoService.connect()...", source: "log_view.dart");
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist."),
      );
      await LogHelper.writeLog("UI: Koneksi MongoService BERHASIL.", source: "log_view.dart");
    } catch (e) {
      await LogHelper.writeLog("UI: Error - $e", source: "log_view.dart", level: 1);
      if (mounted) {
        setState(() => _isOffline = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Tidak dapat terhubung ke Cloud. Mode Offline."),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: "Coba Lagi",
            textColor: Colors.white,
            onPressed: () async { await _initDatabase(); _refreshLogs(); },
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LogBook1 - User: ${widget.username}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Konfirmasi Logout"),
                content: const Text("Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang."),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const OnboardingView()), (_) => false);
                    },
                    child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            MaterialBanner(
              backgroundColor: Colors.orange.shade100,
              content: const Text("Mode Offline - Tidak terhubung ke MongoDB Atlas", style: TextStyle(color: Colors.deepOrange)),
              leading: const Icon(Icons.wifi_off, color: Colors.deepOrange),
              actions: [
                TextButton(
                  onPressed: () async { await _initDatabase(); _refreshLogs(); },
                  child: const Text("Hubungkan Ulang"),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: "Cari catatan...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Menghubungkan ke MongoDB Atlas...")]));
                }
                if (snapshot.hasError) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text("Gagal terhubung ke Cloud.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Periksa koneksi internet atau IP Whitelist Atlas.", style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(onPressed: _refreshLogs, icon: const Icon(Icons.refresh), label: const Text("Coba Lagi")),
                  ]));
                }
                final allLogs = snapshot.data ?? [];
                final q = _searchController.text.toLowerCase();
                final currentLogs = q.isEmpty ? allLogs : allLogs.where((l) => l.title.toLowerCase().contains(q) || l.description.toLowerCase().contains(q)).toList();
                if (currentLogs.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(q.isNotEmpty ? "Tidak ditemukan log yang cocok dengan pencarian." : "Belum ada catatan di Cloud.",
                      style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                    if (q.isEmpty) ElevatedButton(onPressed: _showAddLogDialog, child: const Text("Buat Catatan Pertama")),
                  ]));
                }
                return RefreshIndicator(
                  onRefresh: () async => _refreshLogs(),
                  child: ListView.builder(
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      return Card(
                        color: _controller.getColorForCategory(log.category),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.cloud_done, color: Colors.green),
                          title: Text(log.title),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("${log.category}: ${log.description}"),
                            const SizedBox(height: 2),
                            Text(_controller.formatTimestamp(log.date), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ]),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditLogDialog(log)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await _controller.removeLog(log); _refreshLogs(); }),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddLogDialog, child: const Icon(Icons.add)),
    );
  }
}