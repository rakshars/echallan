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

  // Get all corruption complaints (for police)
  Future<List<Map<String, dynamic>>> getAllCorruptionComplaints() async {
    try {
      final response = await _supabase
          .from('corruption_complaints')
          .select()
          .order('created_at', ascending: false);
      final list = List<Map<String, dynamic>>.from(response);
      print('corruption_complaints fetched: ${list.length} rows');
      return list;
    } catch (e) {
      print('Error fetching all corruption complaints: $e');
      rethrow;
    }
  }

  // Update corruption complaint status
  Future<void> updateCorruptionComplaintStatus(String id, String status) async {
    try {
      await _supabase
          .from('corruption_complaints')
          .update({'status': status})
          .eq('id', id);
    } catch (e) {
      print('Error updating corruption complaint status: $e');
      rethrow;
    }
  }
}

