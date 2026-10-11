import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TripRecord {
final String id;
final DateTime date;
final double distance;
final double maxSpeed;
final double averageSpeed;
final int duration;

const TripRecord({
required this.id,
required this.date,
required this.distance,
required this.maxSpeed,
required this.averageSpeed,
required this.duration,
});

Map<String, dynamic> toJson() {
return {
'id': id,
'date': date.toIso8601String(),
'distance': distance,
'maxSpeed': maxSpeed,
'averageSpeed': averageSpeed,
'duration': duration,
};
}

factory TripRecord.fromJson(Map<String, dynamic> json) {
return TripRecord(
id: json['id'] as String,
date: DateTime.parse(json['date'] as String),
distance: (json['distance'] as num).toDouble(),
maxSpeed: (json['maxSpeed'] as num).toDouble(),
averageSpeed: (json['averageSpeed'] as num).toDouble(),
duration: (json['duration'] as num).toInt(),
);
}
}

class TripStorage {
static const String _key = 'speedx_trip_history';

static Future<List<TripRecord>> getTrips() async {
final prefs = await SharedPreferences.getInstance();
final savedData = prefs.getString(_key);

if (savedData == null || savedData.isEmpty) {
  return [];
}

try {
  final List<dynamic> decoded = jsonDecode(savedData) as List<dynamic>;

  return decoded
      .map(
        (item) => TripRecord.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList();
} catch (_) {
  return [];
}

}

static Future<bool> saveTrip(TripRecord trip) async {
final trips = await getTrips();

trips.insert(0, trip);

final prefs = await SharedPreferences.getInstance();

return prefs.setString(
  _key,
  jsonEncode(trips.map((trip) => trip.toJson()).toList()),
);

}

static Future<bool> deleteTrip(String id) async {
final trips = await getTrips();

trips.removeWhere((trip) => trip.id == id);

final prefs = await SharedPreferences.getInstance();

return prefs.setString(
  _key,
  jsonEncode(trips.map((trip) => trip.toJson()).toList()),
);

}

static Future<bool> clearHistory() async {
final prefs = await SharedPreferences.getInstance();
return prefs.remove(_key);
}
}
