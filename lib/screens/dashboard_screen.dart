import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';
import 'announcements_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardData? _data;
  String? _error;
  bool _loading = true;

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
      final data = await EdmateService(session.api).dashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Announcements',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => session.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(_error!, textAlign: TextAlign.center)),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ),
                    ],
                  )
                : _buildBody(context, _data!),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardData data) {
    final emp = data.employee;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE8EEFC),
                  backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                  child: emp.photoUrl == null
                      ? Text(
                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, color: Color(0xFF3B82F6)),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(emp.designation, style: TextStyle(color: Colors.grey[600])),
                      Text(emp.department, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Your Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _kpiCard(context, 'Not Started', data.taskCounts['notStarted'] ?? 0, Colors.blueGrey, 'Not Started'),
            _kpiCard(context, 'In Progress', data.taskCounts['inProgress'] ?? 0, const Color(0xFF3B82F6), 'Inprogress'),
            _kpiCard(context, 'Past Due', data.taskCounts['pastDue'] ?? 0, Colors.redAccent, 'Past Due'),
            _kpiCard(context, 'Completed', data.taskCounts['completed'] ?? 0, Colors.green, 'Completed'),
          ],
        ),
        if (data.isPermanent && data.leaveBalance.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Leave Balance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: data.leaveBalance.map((lb) {
                  final pct = (lb.balance / 15).clamp(0, 1).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(lb.type, style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          child: LinearPercentIndicator(
                            lineHeight: 10,
                            percent: pct,
                            backgroundColor: const Color(0xFFE8EEFC),
                            progressColor: const Color(0xFF3B82F6),
                            barRadius: const Radius.circular(6),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${lb.balance.toStringAsFixed(1)}d', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _kpiCard(BuildContext context, String label, int value, Color color, String statusFilter) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TasksScreen(initialStatus: statusFilter)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
