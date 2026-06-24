import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload an image or video to Supabase Storage
  Future<String?> uploadMedia(File file, String userId, String fileName) async {
    try {
      final String fullPath = '$userId/$fileName';
      
      // Upload the file to the 'violation_media' bucket
      await _supabase.storage.from('violation_media').upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Return the public URL for the uploaded file
      return _supabase.storage.from('violation_media').getPublicUrl(fullPath);
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  // Create a new violation report in the database
  Future<void> createViolationReport({
    required String userId,
    required String numberPlate,
    required List<String> violationTypes,
    required String locationText,
    required double locationLat,
    required double locationLng,
    required String description,
    required String? imagePath,
    required String? videoPath,
  }) async {
    try {
      await _supabase.from('violations').insert({
        'user_id': userId,
        'number_plate': numberPlate,
        'violation_types': violationTypes,
        'location_text': locationText,
        // Assuming your DB has these numeric columns, otherwise we can optionally omit them or store as text/json
        // Or store in the location_text as string
        'description': description,
        'image_path': imagePath,
        'video_path': videoPath,
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating violation: $e');
      rethrow;
    }
  }

  // Get violations as a Future instead of a Stream to bypass real-time timeouts
  Future<List<Map<String, dynamic>>> getViolations() async {
    try {
      final response = await _supabase
          .from('violations')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching violations: $e');
      rethrow;
    }
  }

  // Get violations for a specific user
  Future<List<Map<String, dynamic>>> getUserViolations(String userId) async {
    try {
      final response = await _supabase
          .from('violations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user violations: $e');
      rethrow;
    }
  }

  // Get a stream of all violations
  Stream<List<Map<String, dynamic>>> getViolationsStream() {
    return _supabase
        .from('violations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  // Update violation status
  Future<void> updateViolationStatus(String id, String status) async {
    try {
      await _supabase
          .from('violations')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  // Get all emergency reports
  Future<List<Map<String, dynamic>>> getEmergencyReports() async {
    try {
      final response = await _supabase
          .from('violations')
          .select()
          .eq('status', 'emergency')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching emergency reports: $e');
      rethrow;
    }
  }

  // Create an emergency accident report (no auth required)
  Future<void> createEmergencyReport({
    required String accidentId,
    required String accidentName,
    required String witnessContact,
    required String description,
    required String locationText,
    required double locationLat,
    required double locationLng,
    required String? imagePath,
  }) async {
    try {
      await _supabase.from('violations').insert({
        'user_id': '00000000-0000-0000-0000-000000000000',
        'number_plate': accidentId,
        'violation_types': ['Accident'],
        'location_text': locationText,
        'description':
            'EMERGENCY: $accidentName\nWitness Contact: $witnessContact\n$description',
        'image_path': imagePath,
        'video_path': null,
        'status': 'emergency',
      });
    } catch (e) {
      print('Error creating emergency report: $e');
      rethrow;
    }
  }

  // ========== Corruption Complaints ==========

  // Upload a supporting document for corruption complaint
  Future<String?> uploadCorruptionDocument(File file, String userId, String fileName) async {
    try {
      final String fullPath = 'corruption/$userId/$fileName';
      await _supabase.storage.from('violation_media').upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _supabase.storage.from('violation_media').getPublicUrl(fullPath);
    } catch (e) {
      print('Error uploading corruption document: $e');
      return null;
    }
  }

  // Create a new corruption complaint
  Future<void> createCorruptionComplaint({
    required String userId,
    required String complainantName,
    required String complainantAddress,
    required String complainantPhone,
    required String publicServantName,
    required String publicServantAddress,
    required String complaintFacts,
    required String grievanceNature,
    String? witnessDetails,
    String? documentDescription,
    String? documentPath,
    String? documentSource,
    required bool previousComplaint,
    String? previousComplaintDetails,
    String? remarks,
    required String parentName,
    required int age,
    required String profession,
    required String residentialAddress,
    required String taluk,
    required String district,
    String? presentTaluk,
    String? presentDistrict,
    required String place,
  }) async {
    try {
      await _supabase.from('corruption_complaints').insert({
        'user_id': userId,
        'complainant_name': complainantName,
        'complainant_address': complainantAddress,
        'complainant_phone': complainantPhone,
        'public_servant_name': publicServantName,
        'public_servant_address': publicServantAddress,
        'complaint_facts': complaintFacts,
        'grievance_nature': grievanceNature,
        'witness_details': witnessDetails,
        'document_description': documentDescription,
        'document_path': documentPath,
        'document_source': documentSource,
        'previous_complaint': previousComplaint,
        'previous_complaint_details': previousComplaintDetails,
        'remarks': remarks,
        'parent_name': parentName,
        'age': age,
        'profession': profession,
        'residential_address': residentialAddress,
        'taluk': taluk,
        'district': district,
        'present_taluk': presentTaluk,
        'present_district': presentDistrict,
        'place': place,
        'complaint_date': DateTime.now().toIso8601String().split('T')[0],
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating corruption complaint: $e');
      rethrow;
    }
  }

  // Get corruption complaints for a specific user
  Future<List<Map<String, dynamic>>> getUserCorruptionComplaints(String userId) async {
    try {
      final response = await _supabase
          .from('corruption_complaints')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user corruption complaints: $e');
      rethrow;
    }
  }

  // ========== Vehicle Registry ==========

  // Register a vehicle with owner contact info
  Future<void> registerVehicle({
    required String numberPlate,
    required String ownerName,
    String? ownerEmail,
    String? ownerPhone,
  }) async {
    try {
      await _supabase.from('vehicle_registry').upsert({
        'number_plate': numberPlate.toUpperCase().replaceAll(RegExp(r'[\s-]'), ''),
        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'owner_phone': ownerPhone,
      }, onConflict: 'number_plate');
    } catch (e) {
      print('Error registering vehicle: $e');
      rethrow;
    }
  }

  // Look up a vehicle owner by number plate
  Future<Map<String, dynamic>?> getVehicleOwner(String numberPlate) async {
    try {
      final normalized = numberPlate.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
      final response = await _supabase
          .from('vehicle_registry')
          .select()
          .eq('number_plate', normalized)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error looking up vehicle owner: $e');
      return null;
    }
  }

  // Get all registered vehicles
  Future<List<Map<String, dynamic>>> getAllRegisteredVehicles() async {
    try {
      final response = await _supabase
          .from('vehicle_registry')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching registered vehicles: $e');
      rethrow;
    }
  }

  // Delete a vehicle registration
  Future<void> deleteRegisteredVehicle(String id) async {
    try {
      await _supabase.from('vehicle_registry').delete().eq('id', id);
    } catch (e) {
      print('Error deleting vehicle registration: $e');
      rethrow;
    }
  }

  // ========== Violation Notifications ==========

  // Create a notification record when a vehicle owner is notified
  Future<void> createViolationNotification({
    required String numberPlate,
    String? ownerEmail,
    String? ownerPhone,
    required String notificationSummary,
  }) async {
    try {
      await _supabase.from('violation_notifications').insert({
        'number_plate': numberPlate,
        'owner_email': ownerEmail,
        'owner_phone': ownerPhone,
        'notification_summary': notificationSummary,
        'status': 'sent',
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Check the vehicle registry and notify the owner if registered.
  /// Returns the owner info map if found, null otherwise.
  Future<Map<String, dynamic>?> notifyVehicleOwnerIfRegistered({
    required String numberPlate,
    required List<String> violationTypes,
    required String location,
    String? description,
  }) async {
    final owner = await getVehicleOwner(numberPlate);
    if (owner == null) return null;

    final summary = 'Violation Report Against ${numberPlate.toUpperCase()}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━\n'
        'Violation(s): ${violationTypes.join(", ")}\n'
        'Location: $location\n'
        '${description != null && description.isNotEmpty ? "Description: $description\n" : ""}'
        'Date: ${DateTime.now().toLocal().toString().split('.')[0]}\n'
        '━━━━━━━━━━━━━━━━━━━━━━━\n'
        'This is an automated notification from CitiWatch.';

    await createViolationNotification(
      numberPlate: numberPlate,
      ownerEmail: owner['owner_email'],
      ownerPhone: owner['owner_phone'],
      notificationSummary: summary,
    );

    return owner;
  }

  // ========== User Profiles (for Leaderboard) ==========

  // Insert or update a user profile (called during registration)
  Future<void> upsertUserProfile({
    required String userId,
    required String fullName,
    required String role,
  }) async {
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'full_name': fullName,
        'role': role,
      }, onConflict: 'id');
    } catch (e) {
      print('Error upserting user profile: $e');
      // Don't rethrow — profile creation is secondary to registration
    }
  }

  // ========== Leaderboard ==========

  /// Fetch leaderboard data: each citizen's total, approved, and rejected report counts.
  /// Returns a list sorted by total count descending.
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      // Get all non-emergency violations
      final violations = await _supabase
          .from('violations')
          .select('user_id, status')
          .neq('status', 'emergency');

      // Get all user profiles
      final profiles = await _supabase
          .from('user_profiles')
          .select()
          .eq('role', 'Citizen');

      // Build a map: userId → { total, approved, rejected }
      final Map<String, Map<String, int>> counts = {};
      for (final v in violations) {
        final uid = v['user_id'] as String;
        if (uid == '00000000-0000-0000-0000-000000000000') continue; // skip anonymous
        counts.putIfAbsent(uid, () => {'total': 0, 'approved': 0, 'rejected': 0});
        counts[uid]!['total'] = (counts[uid]!['total'] ?? 0) + 1;
        if (v['status'] == 'approved') {
          counts[uid]!['approved'] = (counts[uid]!['approved'] ?? 0) + 1;
        } else if (v['status'] == 'rejected') {
          counts[uid]!['rejected'] = (counts[uid]!['rejected'] ?? 0) + 1;
        }
      }

      // Build profile lookup
      final Map<String, String> profileNames = {};
      for (final p in profiles) {
        profileNames[p['id'] as String] = p['full_name'] as String;
      }

      // Merge into a leaderboard list
      final leaderboard = counts.entries.map((e) {
        return {
          'user_id': e.key,
          'full_name': profileNames[e.key] ?? 'Unknown Citizen',
          'total': e.value['total'] ?? 0,
          'approved': e.value['approved'] ?? 0,
          'rejected': e.value['rejected'] ?? 0,
        };
      }).toList();

      // Sort by total descending
      leaderboard.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

      return leaderboard;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      rethrow;
    }
  }
}

