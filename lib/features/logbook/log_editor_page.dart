import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final LogController controller;
  final Map<String, String> currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.description ?? '');
    _selectedCategory = widget.log?.category ?? LogController.categories[0];
    _isPublic = widget.log?.isPublic ?? false;
    _descController.addListener(() => setState(() {}));
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _descController.text;
    final selection = _descController.selection;
    if (!selection.isValid) return;

    final selected = selection.textInside(text);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selected$suffix',
    );
    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selected.length + suffix.length,
      ),
    );
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong')),
      );
      return;
    }

    if (widget.log == null) {
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        widget.currentUser['uid']!,
        widget.currentUser['teamId']!,
        _selectedCategory,
        _isPublic,
      );
    } else {
      widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? 'Catatan Baru' : 'Edit Catatan'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Editor'), Tab(text: 'Pratinjau')],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Column(
              children: [
                // Toolbar Markdown
                Container(
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Bold',
                        icon: const Icon(Icons.format_bold),
                        onPressed: () => _wrapSelection('**', '**'),
                      ),
                      IconButton(
                        tooltip: 'Italic',
                        icon: const Icon(Icons.format_italic),
                        onPressed: () => _wrapSelection('*', '*'),
                      ),
                      IconButton(
                        tooltip: 'Strikethrough',
                        icon: const Icon(Icons.format_strikethrough),
                        onPressed: () => _wrapSelection('~~', '~~'),
                      ),
                      IconButton(
                        tooltip: 'Code',
                        icon: const Icon(Icons.code),
                        onPressed: () => _wrapSelection('`', '`'),
                      ),
                      IconButton(
                        tooltip: 'Heading',
                        icon: const Icon(Icons.title),
                        onPressed: () => _wrapSelection('# ', ''),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Judul'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: LogController.categories.map((v) =>
                                DropdownMenuItem(value: v, child: Text(v))
                              ).toList(),
                              onChanged: (v) => setState(() => _selectedCategory = v!),
                              decoration: const InputDecoration(labelText: 'Kategori'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              const Text('Publik', style: TextStyle(fontSize: 12)),
                              Switch(
                                value: _isPublic,
                                onChanged: (v) => setState(() => _isPublic = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Tulis laporan dengan format Markdown...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}