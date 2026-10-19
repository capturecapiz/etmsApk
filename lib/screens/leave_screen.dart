import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/leave_models.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import 'leave_apply_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveBalance> _balances = [];
  List<LeaveApplication> _applications = [];
  bool _isPermanent = true;
  bool _loading = true;
  String? _error;

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
      final types = await _service.leaveTypes();
      final apps = await _service.leaveList();
      if (mounted) {
        setState(() {
          _balances = types.types;
          _isPermanent = types.isPermanent;
          _applications = apps;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Disapproved':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave')),
      floatingActionButton: _isPermanent
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LeaveApplyScreen(balances: _balances)),
                );
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Apply for Leave'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : !_isPermanent
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Leave management is available to Permanent employees only, same as on the web portal.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text('Leave Balance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: _balances
                                    .map((b) => ListTile(
                                          dense: true,
                                          title: Text(b.type),
                                          trailing: Text('${b.balance.toStringAsFixed(2)} days',
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('My Applications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_applications.isEmpty) const Text('No leave applications yet.', style: TextStyle(color: Colors.grey)),
                          ..._applications.map((a) => Card(
                                child: ListTile(
                                  title: Text(a.type),
                                  subtitle: Text(
                                    a.dateFrom != null && a.dateTo != null
                                        ? '${DateFormat.yMMMd().format(a.dateFrom!)} - ${DateFormat.yMMMd().format(a.dateTo!)} (${a.days} day${a.days == 1 ? '' : 's'})'
                                        : '${a.days} day(s)',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(a.status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(a.status, style: TextStyle(color: _statusColor(a.status), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
    );
  }
}
