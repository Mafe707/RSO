import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://yalbvqrbytbeasehimtk.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhbGJ2cXJieXRiZWFzZWhpbXRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTAxNzksImV4cCI6MjA5MjY4NjE3OX0.KUpZPynlTqfWqEOGcfpIdsP-HoghZyhyYQndraYmEuY';
  
  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}