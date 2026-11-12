// lib/core/utils/user_helper.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Backend ekata yawana user_id eka.
/// Supabase login wela inna user ge id eka gannawa.
/// Login nathnam (ho Supabase initialize wela nathnam) 'demo_user' use karanawa.
String currentUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id ?? 'demo_user';
  } catch (_) {
    return 'demo_user';
  }
}
