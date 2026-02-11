import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook1 - Counter dengan SRP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:"),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),

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

          ////
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 20),
          FloatingActionButton(
            onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
            FloatingActionButton(onPressed: () async {
              bool? confirmReset = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Reset'),
                  content: const Text('Apakah Anda yakin ingin mereset counter?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Ya'),
                    ),
                  ],
                ),
              );
              if (confirmReset == true) {
                setState(() => _controller.reset());
              }
            },
            child: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}
