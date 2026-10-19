import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskDetail? _detail;
  bool _loading = true;
  String? _error;
  double _progress = 0;
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  bool _savingProgress = false;

  late EdmateService _service;

  @override
  void initState() {
    super.initState();
    _service = EdmateService(context.read<Session>().api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.taskDetail(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _progress = detail.task.workCompleted.toDouble();
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    setState(() => _savingProgress = true);
    try {
      String? newStatus;
      if (_progress >= 100) {
        newStatus = 'Completed';
      } else if (_progress > 0) {
        newStatus = 'Inprogress';
      }
      await _service.updateTask(widget.taskId, workCompleted: _progress.round(), status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress updated.')));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addComment(widget.taskId, text);
      _commentCtrl.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context, _detail!),
    );
  }

  Widget _buildBody(BuildContext context, TaskDetail detail) {
    final task = detail.task;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  if (task.priority != null) Chip(label: Text(task.priority!)),
                  Chip(label: Text(task.status)),
                ],
              ),
              const SizedBox(height: 12),
              if (task.assignDate != null || task.endDate != null)
                Row(
                  children: [
                    if (task.assignDate != null)
                      Expanded(child: Text('Assigned: ${DateFormat.yMMMd().format(task.assignDate!)}', style: const TextStyle(fontSize: 13))),
                    if (task.endDate != null)
                      Expanded(child: Text('Due: ${DateFormat.yMMMd().format(task.endDate!)}', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              if (detail.description != null && detail.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(detail.description!),
              ],
              const SizedBox(height: 20),
              const Text('Your Progress', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _progress,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_progress.round()}%',
                      onChanged: (v) => setState(() => _progress = v),
                    ),
                  ),
                  SizedBox(width: 48, child: Text('${_progress.round()}%', textAlign: TextAlign.center)),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _savingProgress ? null : _saveProgress,
                  child: _savingProgress
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Progress'),
                ),
              ),
              const Divider(height: 32),
              const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (detail.comments.isEmpty) const Text('No comments yet.', style: TextStyle(color: Colors.grey)),
              ...detail.comments.map((c) => Align(
                    alignment: c.isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: c.isAdmin ? Colors.grey.shade200 : const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.author, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(c.text),
                          if (c.createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(DateFormat.yMMMd().add_jm().format(c.createdAt!),
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(hintText: 'Write a comment...'),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _sendComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
