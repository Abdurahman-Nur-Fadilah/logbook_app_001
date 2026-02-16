import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});
  @override
  State<CounterView> createState() => _CounterViewState();
}

  class _CounterViewState extends State<CounterView> {
    late final CounterController _controller;

    @override
    void initState() {
      super.initState();
      _controller = CounterController(username: widget.username);
      _loadCounter();
    }
  
  Future<void> _loadCounter() async {
    await _controller.loadLastValue();
    setState(() {});
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
                      // Tombol Batal
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Menutup dialog saja
                        child: const Text("Batal"),
                      ),
                      // Tombol Ya, Logout
                      TextButton(
                        onPressed: () {
                          // Menutup dialog
                          Navigator.pop(context); 
                          
                          // 2. Navigasi kembali ke Onboarding (Membersihkan Stack)
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Selamat Datang: ${widget.username}!"),
            const SizedBox(height: 10),
            const Text("Total Hitungan Anda:"),
            Text(
              '${_controller.value}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),

            const SizedBox(height: 20),
            
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Masukkan nilai step',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final int? newStep = int.tryParse(value);
                if (newStep != null && newStep > 0) {
                  setState(() {
                    _controller.setstep(newStep);
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text("Log Aktivitas:"),

            Expanded(
              child: ListView.builder(
                itemCount: _controller.log.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_controller.log[index]['message'], style: TextStyle(color: _controller.log[index]['color'])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () async {
              await _controller.increment();
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () async {
              await _controller.decrement();
              setState(() {});
            },
            child: const Icon(Icons.remove),
          ),
            FloatingActionButton(onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tekan Reset untuk mengatur ulang counter!'),
                action: SnackBarAction(label: 'Reset', onPressed: () async {
                  await _controller.reset();
                  setState(() {});
                }),
                duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
