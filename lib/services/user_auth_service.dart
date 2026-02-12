import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'user_location_service.dart';
import '../config/supabase_config.dart';

class UserAuthService {
  static final UserAuthService _instance = UserAuthService._internal();
  factory UserAuthService() => _instance;
  UserAuthService._internal();

  final SupabaseService _supabase = SupabaseService();
  final UserLocationService _locationService = UserLocationService();
  UserModel? _currentUser;

  /// Login user by phone or email
  Future<UserModel?> loginUser({
    String? phone,
    String? email,
    String? name,
  }) async {
    try {
      // Ensure Supabase is initialized
      if (!SupabaseConfig.isConfigured) {
        print('ERROR: Supabase not configured');
        throw Exception('Supabase credentials not configured');
      }
      
      try {
        await _supabase.initialize(
          supabaseUrl: SupabaseConfig.supabaseUrl,
          supabaseAnonKey: SupabaseConfig.supabaseAnonKey,
        );
      } catch (e) {
        // Already initialized, ignore
        print('Supabase already initialized or error: $e');
      }
      
      final client = _supabase.client;
      
      // Normalize input (trim whitespace, lowercase email)
      final normalizedPhone = phone?.trim();
      final normalizedEmail = email?.trim().toLowerCase();
      
      print('Attempting login with: phone=$normalizedPhone, email=$normalizedEmail');
      
      // Try to find existing user
      UserModel? user;
      
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        print('Searching for user by phone: $normalizedPhone');
        try {
          final response = await client
              .from('users')
              .select()
              .eq('phone', normalizedPhone)
              .maybeSingle();
          
          print('Phone search response: $response');
          
          if (response != null) {
            user = UserModel.fromJson(response as Map<String, dynamic>);
            print('Found user by phone: ${user.name} (${user.id})');
          } else {
            print('No user found with phone: $normalizedPhone');
          }
        } catch (e) {
          print('Error searching by phone: $e');
        }
      } else if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
        print('Searching for user by email: $normalizedEmail');
        try {
          // Try exact match first
          var response = await client
              .from('users')
              .select()
              .eq('email', normalizedEmail)
              .maybeSingle();
          
          print('Email search response (exact): $response');
          
          // If not found, try case-insensitive search
          if (response == null) {
            print('Trying case-insensitive email search...');
            final allUsers = await client.from('users').select();
            print('All users in database: $allUsers');
            
            if (allUsers != null && allUsers is List) {
              for (var userData in allUsers) {
                final userEmail = (userData as Map<String, dynamic>)['email']?.toString().toLowerCase();
                if (userEmail == normalizedEmail) {
                  response = userData;
                  print('Found user with case-insensitive match');
                  break;
                }
              }
            }
          }
          
          if (response != null) {
            user = UserModel.fromJson(response as Map<String, dynamic>);
            print('Found user by email: ${user.name} (${user.id})');
          } else {
            print('No user found with email: $normalizedEmail');
          }
        } catch (e) {
          print('Error searching by email: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      }

      // If user doesn't exist, create new user
      if (user == null) {
        print('User not found, creating new user...');
        try {
          final newUserResponse = await client.from('users').insert({
            'phone': normalizedPhone,
            'email': normalizedEmail,
            'name': name ?? (normalizedPhone ?? normalizedEmail ?? 'User'),
            'is_online': true,
          }).select().single();

          user = UserModel.fromJson(newUserResponse as Map<String, dynamic>);
          print('Created new user: ${user.name} (${user.id})');
        } catch (e) {
          print('Error creating new user: $e');
          print('Error type: ${e.runtimeType}');
          rethrow;
        }
      } else {
        // Update user to online
        print('Updating user to online status...');
        try {
          await client.from('users').update({
            'is_online': true,
          }).eq('id', user.id);
          
          // Reload user data
          final updatedResponse = await client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();
          user = UserModel.fromJson(updatedResponse as Map<String, dynamic>);
          print('User updated to online: ${user.name}');
        } catch (e) {
          print('Error updating user status: $e');
          // Continue anyway with existing user data
        }
      }

      if (user == null) {
        print('ERROR: User is null after login attempt');
        return null;
      }

      _currentUser = user;

      // Start location updates for this user
      print('Starting location updates for user: ${user.id}');
      try {
        await _locationService.startLocationUpdates(user.id);
        print('Location updates started successfully');
      } catch (e) {
        print('Error starting location updates: $e');
        // Continue anyway - location updates are optional
      }

      print('Login successful for user: ${user.name}');
      return user;
    } catch (e, stackTrace) {
      print('❌ Error logging in user: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    if (_currentUser != null) {
      await _locationService.stopLocationUpdates();
      
      // Mark user as offline
      try {
        await _supabase.client.from('users').update({
          'is_online': false,
        }).eq('id', _currentUser!.id);
      } catch (e) {
        print('Error marking user offline: $e');
      }
    }
    
    _currentUser = null;
  }

  /// Get current logged in user
  UserModel? getCurrentUser() => _currentUser;

  /// Set current user (for demo/testing)
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }
}
