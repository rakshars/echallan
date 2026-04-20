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
}

