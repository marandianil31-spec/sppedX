import 'package:flutter/material.dart';
import '../services/trip_storage.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TripRecord> trips = [];
  bool isLoading = true;

  static const Color background = Color(0xFF0B111B);
  static const Color cardColor = Color(0xFF18212F);
  static const Color accent = Color(0xFF35D9FF);

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    setState(() {
      isLoading = true;
    });

    final savedTrips = await TripStorage.getTrips();

    if (!mounted) return;

    setState(() {
      trips = savedTrips;
      isLoading = false;
    });
  }

  Future<void> deleteTrip(String id) async {
    await TripStorage.deleteTrip(id);

    if (!mounted) return;

    await loadTrips();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip deleted successfully'),
      ),
    );
  }

  Future<void> clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Clear History?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'All saved trips will be deleted.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'DELETE ALL',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await TripStorage.clearHistory();

    if (!mounted) return;

    await loadTrips();
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }

    return '${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = trips.fold<double>(
      0,
      (sum, trip) => sum + trip.distance,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text(
          'Trip History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : trips.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route,
                          size: 78,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No Trips Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your completed trips will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: loadTrips,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadTrips,
                  color: accent,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF173B55),
                              Color(0xFF18212F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.route,
                              color: accent,
                              size: 36,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL DISTANCE',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${totalDistance.toStringAsFixed(2)} km',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${trips.length}',
                                  style: const TextStyle(
                                    color: accent,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'TRIPS',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'YOUR TRIPS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...trips.map((trip) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.06,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formatDate(trip.date),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDuration(trip.duration),
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        deleteTrip(trip.id),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                color: Colors.white12,
                                height: 26,
                              ),
                              Row(
                                children: [
                                  stat(
                                    'DISTANCE',
                                    '${trip.distance.toStringAsFixed(2)} km',
                                  ),
                                  stat(
                                    'MAX SPEED',
                                    trip.maxSpeed.toStringAsFixed(1),
                                    unit: 'km/h',
                                  ),
                                  stat(
                                    'AVG SPEED',
                                    trip.averageSpeed.toStringAsFixed(1),
                                    unit: 'km/h',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget stat(
    String title,
    String value, {
    String unit = '',
  }) {
    return Expanded(
      child: Column(
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
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}
