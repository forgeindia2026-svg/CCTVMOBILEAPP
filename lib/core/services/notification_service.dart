import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'storage_service.dart';

class NotificationService {
  static socket_io.Socket? _socket;
  static GlobalKey<ScaffoldMessengerState>? messengerKey;

  static void initialize(GlobalKey<ScaffoldMessengerState> key) {
    messengerKey = key;
    connectSocket();
  }

  static Future<void> connectSocket() async {
    final userEmail = await StorageService.getUserEmail();
    
    // Choose active backend socket server address
    final socketUrl = 'https://65.0.45.64.sslip.io';

    try {
      _socket?.dispose();
      _socket = socket_io.io(
        socketUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('🔔 Live Notification Socket Connected: ${_socket!.id}');

        // Register socket to user & role rooms
        if (userEmail != null && userEmail.isNotEmpty) {
          _socket!.emit('join_user', userEmail.toLowerCase());
        }
        _socket!.emit('join_role', 'customer');
      });

      // Listen for Live Order Status Update Push Notifications from Admin
      _socket!.on('order:status_updated', (data) {
        debugPrint('🔔 Live Notification Received: $data');
        if (data is Map) {
          final orderCode = data['orderCode'] ?? data['orderNumber'] ?? 'Order';
          final status = data['status'] ?? 'Updated';

          showPushNotification(
            title: '🔔 Live Order Update',
            message: '$orderCode status updated to: $status',
            icon: Icons.local_shipping,
          );
        }
      });

      // Listen for Automated Job Assignment Notifications
      _socket!.on('job:assigned', (data) {
        if (data is Map) {
          final techName = data['techName'] ?? 'Technician';
          showPushNotification(
            title: '🛠️ Technician Assigned!',
            message: '$techName has been assigned for your CCTV installation.',
            icon: Icons.engineering,
          );
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Live Notification Socket Disconnected');
      });
    } catch (e) {
      debugPrint('Error connecting Notification Socket: $e');
    }
  }

  static void showPushNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active,
  }) {
    if (messengerKey?.currentState != null) {
      messengerKey!.currentState!.hideCurrentMaterialBanner();
      messengerKey!.currentState!.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF0F172A),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF166534), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  static void disconnect() {
    _socket?.disconnect();
  }
}
