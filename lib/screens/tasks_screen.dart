import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final String? initialStatus;
  const TasksScreen({super.key, this.initialStatus});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const _statuses = ['All', 'Not Started', 'Inprogress', 'Past Due', 'Completed', 'Cancelled'];
  late String _selected = widget.initialStatus ?? 'All';

  List<TaskItem> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<Session>();
      final tasks = await EdmateService(session.api)
          .tasks(status: _selected == 'All' ? null : _selected);
      if (mounted) setState(() => _tasks = tasks);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Past Due':
        return Colors.redAccent;
      case 'Inprogress':
        return const Color(0xFF3B82F6);
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _statuses[i];
                final selected = s == _selected;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selected = s);
                    _load();
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _tasks.isEmpty
                        ? const Center(child: Text('No tasks here.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _tasks.length,
                              itemBuilder: (context, i) {
                                final t = _tasks[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (t.endDate != null)
                                          Text('Due ${DateFormat.yMMMd().format(t.endDate!)}',
                                              style: const TextStyle(fontSize: 12)),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: t.workCompleted / 100,
                                            minHeight: 6,
                                            backgroundColor: Colors.grey.shade200,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(t.status).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        t.status,
                                        style: TextStyle(color: _statusColor(t.status), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    isThreeLine: true,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)),
                                      );
                                      _load();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
