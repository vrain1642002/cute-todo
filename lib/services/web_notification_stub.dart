/// Stub for non-web platforms
Future<void> showWebNotification(String title, String body) async {
  // No-op on mobile
}

Future<void> requestWebNotificationPermission() async {
  // No-op on mobile
}
