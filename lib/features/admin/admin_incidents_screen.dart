import 'package:digiQ/core/api/admin_api.dart';
import 'package:digiQ/core/api/incident_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _incidentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(incidentApiProvider);
  return api.getAllIncidents();
});

class AdminIncidentsScreen extends ConsumerWidget {
  const AdminIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(_incidentsProvider);
    final sosAsync = ref.watch(adminSosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incidents')),
      body: Column(
        children: [
          // 🚨 SOS SECTION (ALWAYS ON TOP)
          _SosSection(),

          // 📋 INCIDENTS BELOW
          Expanded(
            child: incidentsAsync.when(
              data: (incidents) {
                if (incidents.isEmpty) {
                  return const Center(child: Text('No incidents'));
                }

                return ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (_, index) {
                    final incident = incidents[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _TypeChip(type: incident['type']),
                                _StatusChip(status: incident['status']),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (incident['description'] != null &&
                                incident['description'].toString().isNotEmpty)
                              Text(
                                '"${incident['description'] ?? ''}"',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),
                            _MetaRow(
                              label: 'Passenger',
                              value: incident['passengerName'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 12),
                            _MetaRow(
                              label: 'Driver',
                              value: incident['driverName'] ?? 'Unknown',
                            ),
                            const SizedBox(height: 12),
                            _MetaRow(
                              label: 'Route',
                              value: incident['route'] != null
                                  ? '${incident['route']['fromLabel']} → ${incident['route']['toLabel']}'
                                  : 'Unknown',
                            ),
                            const SizedBox(height: 12),
                            _MetaRow(
                              label: 'Trip Date',
                              value: formatDate(incident['tripDate'] ?? ''),
                            ),
                            const SizedBox(height: 12),
                            _MetaRow(
                              label: 'Reported',
                              value: timeAgo(incident['createdAt']) ?? '',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Update status',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                DropdownButton<String>(
                                  value: incident['status'],
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'open', child: Text('Open')),
                                    DropdownMenuItem(
                                        value: 'in_review',
                                        child: Text('In Review')),
                                    DropdownMenuItem(
                                        value: 'resolved',
                                        child: Text('Resolved')),
                                  ],
                                  onChanged: (value) async {
                                    final api = ref.read(incidentApiProvider);

                                    await api.updateIncidentStatus(
                                      incidentId: incident['_id'],
                                      status: value!,
                                    );

                                    ref.invalidate(_incidentsProvider);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error loading incidents')),
            ),
          ),
        ],
      ),
      // body: incidentsAsync.when(
      //   data: (incidents) {
      //     if (incidents.isEmpty) {
      //       return const Center(child: Text('No incidents'));
      //     }

      //     return ListView.builder(
      //       itemCount: incidents.length,
      //       itemBuilder: (_, index) {
      //         final incident = incidents[index];

      //         return Card(
      //           margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //           shape: RoundedRectangleBorder(
      //             borderRadius: BorderRadius.circular(12),
      //           ),
      //           child: Padding(
      //             padding: const EdgeInsets.all(16),
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 // 🔹 HEADER ROW
      //                 Row(
      //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                   children: [
      //                     _TypeChip(type: incident['type']),
      //                     _StatusChip(status: incident['status']),
      //                   ],
      //                 ),

      //                 const SizedBox(height: 12),

      //                 // 🔹 DESCRIPTION
      //                 if (incident['description'] != null &&
      //                     incident['description'].toString().isNotEmpty)
      //                   Text(
      //                     '"${incident['description'] ?? ''}"',
      //                     style: const TextStyle(
      //                       fontSize: 15,
      //                       fontWeight: FontWeight.w500,
      //                     ),
      //                   ),
      //                 const SizedBox(height: 12),

      //                 _MetaRow(
      //                   label: 'Passenger',
      //                   value: incident['passengerName'] ?? 'Unknown',
      //                 ),

      //                 const SizedBox(height: 12),

      //                 _MetaRow(
      //                   label: 'Driver',
      //                   value: incident['driverName'] ?? 'Unknown',
      //                 ),
      //                 const SizedBox(
      //                   height: 12,
      //                 ),

      //                 _MetaRow(
      //                   label: 'Route',
      //                   value: incident['route'] != null
      //                       ? '${incident['route']['fromLabel']} → ${incident['route']['toLabel']}'
      //                       : 'Unknown',
      //                 ),
      //                 const SizedBox(
      //                   height: 12,
      //                 ),
      //                 _MetaRow(
      //                   label: 'Trip Date',
      //                   value: formatDate(
      //                     incident['tripDate'] ?? '',
      //                   ),
      //                 ),
      //                 const SizedBox(height: 12),

      //                 const SizedBox(height: 6),

      //                 _MetaRow(
      //                   label: 'Reported',
      //                   value: timeAgo(incident['createdAt']) ?? '',
      //                 ),

      //                 const SizedBox(height: 16),

      //                 // 🔹 ACTION
      //                 Row(
      //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                   children: [
      //                     const Text(
      //                       'Update status',
      //                       style: TextStyle(fontWeight: FontWeight.w600),
      //                     ),
      //                     DropdownButton<String>(
      //                       value: incident['status'],
      //                       items: const [
      //                         DropdownMenuItem(
      //                             value: 'open', child: Text('Open')),
      //                         DropdownMenuItem(
      //                             value: 'in_review', child: Text('In Review')),
      //                         DropdownMenuItem(
      //                             value: 'resolved', child: Text('Resolved')),
      //                       ],
      //                       onChanged: (value) async {
      //                         final api = ref.read(incidentApiProvider);

      //                         await api.updateIncidentStatus(
      //                           incidentId: incident['_id'],
      //                           status: value!,
      //                         );

      //                         ref.invalidate(_incidentsProvider);
      //                       },
      //                     ),
      //                   ],
      //                 ),
      //               ],
      //             ),
      //           ),
      //         );
      //       },
      //     );
      //   },
      //   loading: () => const Center(child: CircularProgressIndicator()),
      //   error: (_, __) => const Center(child: Text('Error loading incidents')),
      // ),
    );
  }
}

class _SosSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosAsync = ref.watch(adminSosProvider);

    return sosAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚨 ACTIVE EMERGENCIES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              ...alerts.map((a) => Card(
                    color: Colors.red.withOpacity(0.1),
                    child: ListTile(
                      title: Text('Trip: ${a['tripId']}'),
                      subtitle: Text('User: ${a['userId']}'),
                      //trailing: const Icon(Icons.warning, color: Colors.red),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        // onPressed: () async {
                        //   final api = ref.read(adminApiProvider);

                        //   await api.resolveSos(a['_id']);

                        //   // 🔁 refresh alerts after resolving
                        //   ref.invalidate(adminSosProvider);
                        // },
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Resolve Alert'),
                              content: const Text(
                                  'Mark this emergency as resolved?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Resolve'),
                                ),
                              ],
                            ),
                          );

                          if (!context.mounted || confirmed != true) return;

                          final api = ref.read(adminApiProvider);
                          await api.resolveSos(a['_id']);

                          ref.invalidate(adminSosProvider);
                        },
                        child: const Text(
                          'Resolve',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  Color _getColor() {
    switch (type) {
      case 'safety':
        return Colors.red;
      case 'payment':
        return Colors.blue;
      case 'driver_behavior':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    String _label() {
      switch (type) {
        case 'safety':
          return 'Safety Issue';
        case 'payment':
          return 'Payment Issue';
        case 'driver_behavior':
          return 'Driver Behaviour';
        default:
          return 'Other Issue';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';

  final date = DateTime.parse(iso).toLocal();

  return '${date.day}/${date.month}/${date.year}';
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _getColor() {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String timeAgo(String iso) {
  final date = DateTime.parse(iso).toLocal();
  final diff = DateTime.now().difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  return '${diff.inDays} days ago';
}
