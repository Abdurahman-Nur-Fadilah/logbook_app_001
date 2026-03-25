import 'package:flutter/material.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final Map<String, String> currentUser;
  const LogView({super.key, required this.currentUser});
  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  bool _isLoading = false;
  bool _isOffline = false;

  final TextEditingController _searchController = TextEditingController();

  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);
    try {
      await LogHelper.writeLog('UI: Memulai inisialisasi database...', source: 'log_view.dart');
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.'),
      );
      await LogHelper.writeLog('UI: Koneksi MongoService BERHASIL.', source: 'log_view.dart');
      await _controller.loadLogs();
    } catch (e) {
      await LogHelper.writeLog('UI: Error - $e', source: 'log_view.dart', level: 1);
      if (mounted) {
        setState(() => _isOffline = true);
        await _controller.loadLogs();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Tidak dapat terhubung ke Cloud. Mode Offline.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () async { await _initDatabase(); },
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.currentUser['uid'] ?? '';
    final username = widget.currentUser['username'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('LogBook - $username'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Konfirmasi Logout'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const OnboardingView()), (_) => false);
                    },
                    child: const Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
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
              content: const Text('Mode Offline - Menggunakan data lokal',
                style: TextStyle(color: Colors.deepOrange)),
              leading: const Icon(Icons.wifi_off, color: Colors.deepOrange),
              actions: [
                TextButton(
                  onPressed: () async { await _initDatabase(); },
                  child: const Text('Hubungkan Ulang'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memuat data...'),
                  ]))
                : ValueListenableBuilder<List<LogModel>>(
                    valueListenable: _controller.logsNotifier,
                    builder: (context, allLogs, _) {
                      // Filter visibilitas: tampilkan log milik sendiri ATAU yang public
                      final visibleLogs = allLogs.where((log) =>
                        log.authorId == uid || log.isPublic
                      ).toList();

                      // Filter search
                      final q = _searchController.text.toLowerCase();
                      final currentLogs = q.isEmpty
                          ? visibleLogs
                          : visibleLogs.where((l) =>
                              l.title.toLowerCase().contains(q) ||
                              l.description.toLowerCase().contains(q)).toList();

                      if (currentLogs.isEmpty) {
                        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            q.isNotEmpty
                                ? 'Tidak ditemukan log yang cocok.'
                                : 'Belum ada catatan.',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          if (q.isEmpty)
                            ElevatedButton(
                              onPressed: () => _goToEditor(),
                              child: const Text('Buat Catatan Pertama'),
                            ),
                        ]));
                      }

                      return RefreshIndicator(
                        onRefresh: () => _controller.loadLogs(),
                        child: ListView.builder(
                          itemCount: currentLogs.length,
                          itemBuilder: (context, index) {
                            final log = currentLogs[index];
                            final bool isOwner = log.authorId == uid;

                            return Card(
                              color: _controller.getColorForCategory(log.category),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  log.id != null ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                  color: log.id != null ? Colors.green : Colors.orange,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(log.title)),
                                    Icon(
                                      log.isPublic ? Icons.public : Icons.lock,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${log.authorId} • ${_controller.formatTimestamp(log.date)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                trailing: isOwner ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _goToEditor(log: log),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _controller.removeLog(log);
                                    },
                                  ),
                                ]) : null,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}