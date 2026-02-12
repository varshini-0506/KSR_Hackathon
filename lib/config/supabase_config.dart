class SupabaseConfig {
  // TODO: Replace with your actual Supabase credentials
  static const String supabaseUrl = 'https://jaixwsoyjucgusypmptc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphaXh3c295anVjZ3VzeXBtcHRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4ODIzNzksImV4cCI6MjA4NjQ1ODM3OX0.eIsWRQrF1-kMfRwJ89sazikwQ_9VfDO5Wv0wM0zvR-4';

  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL' && 
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  }
}
