import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event.dart';
import '../models/session.dart';
import '../models/attendee_profile.dart';
import 'database_service.dart';

enum CheckInType {
  event,
  session,
  booth,
}

class CheckIn {
  final String id;
  final String eventId;
  final String? sessionId;
  final String? boothId;
  final String attendeeId;
  final CheckInType type;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? location;
  final Map<String, dynamic> metadata;

  CheckIn({
    required this.id,
    required this.eventId,
    this.sessionId,
    this.boothId,
    required this.attendeeId,
    required this.type,
    required this.checkInTime,
    this.checkOutTime,
    this.location,
    this.metadata = const {},
  });

  bool get isCheckedOut => checkOutTime != null;
  Duration? get duration => checkOutTime?.difference(checkInTime);

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      sessionId: json['sessionId'],
      boothId: json['boothId'],
      attendeeId: json['attendeeId'] ?? '',
      type: CheckInType.values.firstWhere(
        (e) => e.toString() == 'CheckInType.${json['type']}',
        orElse: () => CheckInType.event,
      ),
      checkInTime: DateTime.parse(json['checkInTime'] ?? DateTime.now().toIso8601String()),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      location: json['location'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'sessionId': sessionId,
      'boothId': boothId,
      'attendeeId': attendeeId,
      'type': type.toString().split('.').last,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'location': location,
      'metadata': metadata,
    };
  }
}

class CheckInService {
  final DatabaseService _databaseService = DatabaseService();

  Future<String> generateQRCode({
    required String eventId,
    String? sessionId,
    String? boothId,
    required CheckInType type,
  }) async {
    final qrData = {
      'eventId': eventId,
      'sessionId': sessionId,
      'boothId': boothId,
      'type': type.toString().split('.').last,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(qrData);
  }

  Future<String> generateAttendeeQRCode(String attendeeId, String eventId) async {
    final qrData = {
      'attendeeId': attendeeId,
      'eventId': eventId,
      'type': 'attendee',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(qrData);
  }

  Future<CheckIn?> processQRScan({
    required String qrData,
    required String attendeeId,
    String? location,
  }) async {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      
      if (data['type'] == 'attendee') {
        return null;
      }

      final eventId = data['eventId'] as String;
      final sessionId = data['sessionId'] as String?;
      final boothId = data['boothId'] as String?;
      final type = CheckInType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => CheckInType.event,
      );

      return await checkIn(
        eventId: eventId,
        sessionId: sessionId,
        boothId: boothId,
        attendeeId: attendeeId,
        type: type,
        location: location,
      );
    } catch (e) {
      return null;
    }
  }

  Future<CheckIn> checkIn({
    required String eventId,
    String? sessionId,
    String? boothId,
    required String attendeeId,
    required CheckInType type,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now();

    final checkIn = CheckIn(
      id: now.millisecondsSinceEpoch.toString(),
      eventId: eventId,
      sessionId: sessionId,
      boothId: boothId,
      attendeeId: attendeeId,
      type: type,
      checkInTime: now,
      location: location,
      metadata: metadata ?? {},
    );

    final checkInData = checkIn.toJson();
    checkInData['metadata'] = jsonEncode(metadata ?? {});

    await db.insert('check_ins', checkInData);
    return checkIn;
  }

  Future<void> checkOut(String checkInId) async {
    final db = await _databaseService.database;
    await db.update(
      'check_ins',
      {'checkOutTime': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [checkInId],
    );
  }

  Future<CheckIn?> getActiveCheckIn({
    required String attendeeId,
    required String eventId,
    String? sessionId,
    required CheckInType type,
  }) async {
    final db = await _databaseService.database;
    String whereClause = 'attendeeId = ? AND eventId = ? AND type = ? AND checkOutTime IS NULL';
    List<String> whereArgs = [attendeeId, eventId, type.toString().split('.').last];

    if (sessionId != null) {
      whereClause += ' AND sessionId = ?';
      whereArgs.add(sessionId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CheckIn.fromJson(maps.first);
    }
    return null;
  }

  Future<List<CheckIn>> getAttendeeCheckIns(String attendeeId, String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: 'attendeeId = ? AND eventId = ?',
      whereArgs: [attendeeId, eventId],
      orderBy: 'checkInTime DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckIn.fromJson(maps[i]);
    });
  }

  Future<List<CheckIn>> getEventCheckIns(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'checkInTime DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckIn.fromJson(maps[i]);
    });
  }

  Future<List<CheckIn>> getSessionCheckIns(String sessionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'checkInTime DESC',
    );

    return List.generate(maps.length, (i) {
      return CheckIn.fromJson(maps[i]);
    });
  }

  Future<bool> isAttendeeCheckedIn({
    required String attendeeId,
    required String eventId,
    String? sessionId,
    required CheckInType type,
  }) async {
    final checkIn = await getActiveCheckIn(
      attendeeId: attendeeId,
      eventId: eventId,
      sessionId: sessionId,
      type: type,
    );
    return checkIn != null;
  }

  Future<Map<String, dynamic>> getEventCheckInStats(String eventId) async {
    final db = await _databaseService.database;
    
    final totalCheckInsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM check_ins WHERE eventId = ? AND type = ?',
      [eventId, CheckInType.event.toString().split('.').last],
    );
    final totalCheckIns = totalCheckInsResult.first['count'] as int;

    final currentlyCheckedInResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM check_ins WHERE eventId = ? AND type = ? AND checkOutTime IS NULL',
      [eventId, CheckInType.event.toString().split('.').last],
    );
    final currentlyCheckedIn = currentlyCheckedInResult.first['count'] as int;

    final uniqueAttendeesResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT attendeeId) as count FROM check_ins WHERE eventId = ? AND type = ?',
      [eventId, CheckInType.event.toString().split('.').last],
    );
    final uniqueAttendees = uniqueAttendeesResult.first['count'] as int;

    final peakHourResult = await db.rawQuery('''
      SELECT strftime('%H', checkInTime) as hour, COUNT(*) as count 
      FROM check_ins 
      WHERE eventId = ? AND type = ?
      GROUP BY hour 
      ORDER BY count DESC 
      LIMIT 1
    ''', [eventId, CheckInType.event.toString().split('.').last]);

    String? peakHour;
    if (peakHourResult.isNotEmpty) {
      peakHour = '${peakHourResult.first['hour']}:00';
    }

    return {
      'totalCheckIns': totalCheckIns,
      'currentlyCheckedIn': currentlyCheckedIn,
      'uniqueAttendees': uniqueAttendees,
      'peakHour': peakHour,
    };
  }

  Future<Map<String, dynamic>> getSessionAttendanceStats(String sessionId) async {
    final db = await _databaseService.database;
    
    final attendanceResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM check_ins WHERE sessionId = ? AND type = ?',
      [sessionId, CheckInType.session.toString().split('.').last],
    );
    final attendance = attendanceResult.first['count'] as int;

    final avgDurationResult = await db.rawQuery('''
      SELECT AVG(
        CASE 
          WHEN checkOutTime IS NOT NULL 
          THEN (julianday(checkOutTime) - julianday(checkInTime)) * 24 * 60 
          ELSE NULL 
        END
      ) as avg_minutes
      FROM check_ins 
      WHERE sessionId = ? AND type = ?
    ''', [sessionId, CheckInType.session.toString().split('.').last]);

    final avgDuration = avgDurationResult.first['avg_minutes'] as double?;

    return {
      'attendance': attendance,
      'averageDurationMinutes': avgDuration?.round(),
    };
  }

  Future<List<Map<String, dynamic>>> getHourlyCheckInData(String eventId, DateTime date) async {
    final db = await _databaseService.database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        strftime('%H', checkInTime) as hour,
        COUNT(*) as count
      FROM check_ins 
      WHERE eventId = ? 
        AND type = ? 
        AND date(checkInTime) = ?
      GROUP BY hour 
      ORDER BY hour
    ''', [eventId, CheckInType.event.toString().split('.').last, dateStr]);

    return result.map((row) => {
      'hour': int.parse(row['hour'] as String),
      'count': row['count'] as int,
    }).toList();
  }

  Future<void> bulkCheckIn(List<String> attendeeIds, String eventId, {String? location}) async {
    final db = await _databaseService.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      for (final attendeeId in attendeeIds) {
        final checkIn = CheckIn(
          id: '${now.millisecondsSinceEpoch}_$attendeeId',
          eventId: eventId,
          attendeeId: attendeeId,
          type: CheckInType.event,
          checkInTime: now,
          location: location,
        );

        final checkInData = checkIn.toJson();
        checkInData['metadata'] = jsonEncode({});
        await txn.insert('check_ins', checkInData);
      }
    });
  }

  Future<List<String>> exportCheckInData(String eventId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await _databaseService.database;
    
    String whereClause = 'eventId = ?';
    List<String> whereArgs = [eventId];

    if (startDate != null) {
      whereClause += ' AND checkInTime >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND checkInTime <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'check_ins',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'checkInTime ASC',
    );

    final csvLines = <String>['Attendee ID,Event ID,Session ID,Type,Check In Time,Check Out Time,Duration (minutes),Location'];
    
    for (final map in maps) {
      final checkIn = CheckIn.fromJson(map);
      final duration = checkIn.duration?.inMinutes.toString() ?? '';
      
      csvLines.add([
        checkIn.attendeeId,
        checkIn.eventId,
        checkIn.sessionId ?? '',
        checkIn.type.toString().split('.').last,
        checkIn.checkInTime.toIso8601String(),
        checkIn.checkOutTime?.toIso8601String() ?? '',
        duration,
        checkIn.location ?? '',
      ].join(','));
    }

    return csvLines;
  }
}