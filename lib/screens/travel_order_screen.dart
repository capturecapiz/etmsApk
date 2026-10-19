import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_order.dart';
import '../services/session.dart';
import '../services/edmate_service.dart';
import '../services/api_client.dart';

class TravelOrderScreen extends StatefulWidget {
  const TravelOrderScreen({super.key});

  @override
  State<TravelOrderScreen> createState() => _TravelOrderScreenState();
}

class _TravelOrderScreenState extends State<TravelOrderScreen> {
  List<TravelOrder> _orders = [];
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
      final orders = await EdmateService(session.api).travelOrders();
      if (mounted) setState(() => _orders = orders);
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
    final df = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Order')),
      // View-only, matching my-travel-order.php: Admin creates and prints
      // Travel Orders (see manage-travel-order.php) — staff see their own
      // here but don't request one from this app, same as the web portal.
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _orders.isEmpty
                      ? ListView(children: const [SizedBox(height: 120), Center(child: Text('No travel orders yet.'))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, i) {
                            final o = _orders[i];
                            return Card(
                              child: ListTile(
                                title: Text(o.destination, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(o.purpose, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (o.dateFrom != null && o.dateTo != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text('${df.format(o.dateFrom!)} - ${df.format(o.dateTo!)}', style: const TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(o.status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(o.status, style: TextStyle(color: _statusColor(o.status), fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
