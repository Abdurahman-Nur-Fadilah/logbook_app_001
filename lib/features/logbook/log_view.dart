import 'package:flutter/material.dart';
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

    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();
    final TextEditingController _categoryController = TextEditingController();

    void _showAddLogDialog() {
      _categoryController.text = LogController.categories[0]; 
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: "Judul Catatan"),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(hintText: "Isi Deskripsi"),
              ),
              DropdownButtonFormField<String>(
                initialValue: _categoryController.text,
                items: LogController.categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoryController.text = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _controller.addLog(
                  _titleController.text, 
                  _contentController.text,
                  _categoryController.text
                );
                
                setState(() {}); 
                
                _titleController.clear();
                _contentController.clear();
                _categoryController.clear();
                Navigator.pop(context);
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
                items: LogController.categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoryController.text = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                _controller.updateLog(log, _titleController.text, _contentController.text, _categoryController.text);
                _titleController.clear();
                _contentController.clear();
                _categoryController.clear();
                Navigator.pop(context);
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
      _controller.loadFromDisk();
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
            onPressed: () {
              // 1. Munculkan Dialog Konfirmasi
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text("Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); 
                          
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const OnboardingView()),
                            (route) => false,
                          );
                        },
                        child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _controller.setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogsNotifier,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/didntfound.png', width: 200, height: 200),
                        const SizedBox(height: 16),
                        Text(
                          _controller.isSearchActive
                            ? "Tidak ditemukan log yang cocok dengan pencarian."
                            : "Tidak ada apa apa disini, tambahkan log baru",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Card(
                      color: _controller.getColorForCategory(log.category),
                      child: ListTile(
                        leading: const Icon(Icons.note),
                        title: Text(log.title),
                        subtitle: Text('${log.category}: ${log.description}'),
                        trailing: Wrap(
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), 
                              onPressed: () => _showEditLogDialog(log)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), 
                              onPressed: () => _controller.removeLog(log)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),

    );
  }
}
