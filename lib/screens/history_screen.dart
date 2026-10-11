import 'package:flutter/material.dart';

const Color historyAccent = Color(0xFF00F5A0);
const Color historyPanel = Color(0xFF111A25);

class TripHistory {
  final String id;
  final DateTime date;
  final double distance;
  final double maxSpeed;
  final double averageSpeed;
  final Duration duration;

  const TripHistory({
    required this.id,
    required this.date,
    required this.distance,
    required this.maxSpeed,
    required this.averageSpeed,
    required this.duration,
  });
}

class HistoryScreen extends StatelessWidget {
  final List<TripHistory> trips;
  final ValueChanged<String>? onDeleteTrip;

  const HistoryScreen({
    super.key,
    required this.trips,
    this.onDeleteTrip,
  });

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m ${seconds}s';
  }

  String formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}  '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = trips.fold<double>(
      0,
      (sum, trip) => sum + trip.distance,
    );

    final bestSpeed = trips.fold<double>(
      0,
      (best, trip) =>
          trip.maxSpeed > best ? trip.maxSpeed : best,
    );

    final totalDuration = trips.fold<Duration>(
      Duration.zero,
      (sum, trip) => sum + trip.duration,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: trips.isEmpty
          ? _emptyState(context)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'TOTAL DISTANCE',
                        '${totalDistance.toStringAsFixed(2)} km',
                        Icons.route,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'BEST SPEED',
                        '${bestSpeed.round()} km/h',
                        Icons.speed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _summaryCard(
                  'TOTAL TRIP TIME',
                  formatDuration(totalDuration),
                  Icons.timer_outlined,
                ),
                const SizedBox(height: 25),
                Text(
                  'YOUR JOURNEYS (${trips.length})',
                  style: const TextStyle(
                    color: historyAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                ...trips.map((trip) => _tripCard(context, trip)),
              ],
            ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.route,
              color: historyAccent,
              size: 75,
            ),
            const SizedBox(height: 20),
            const Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your saved journeys will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripCard(BuildContext context, TripHistory trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: historyPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: historyAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  formatDate(trip.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onDeleteTrip != null)
                IconButton(
                  tooltip: 'Delete trip',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete trip?'),
                        content: const Text(
                          'Do you want to delete this trip?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      onDeleteTrip!(trip.id);
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${trip.distance.toStringAsFixed(2)} km',
            style: const TextStyle(
              color: historyAccent,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 28, color: Colors.white12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'MAX SPEED',
                  '${trip.maxSpeed.round()} km/h',
                ),
              ),
              Expanded(
                child: _miniStat(
                  'AVG SPEED',
                  '${trip.averageSpeed.round()} km/h',
                ),
              ),
              Expanded(
                child: _miniStat(
                  'DURATION',
                  formatDuration(trip.duration),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: historyPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: historyAccent, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
