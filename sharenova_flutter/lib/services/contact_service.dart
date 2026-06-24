// ignore_for_file: unused_import, avoid_print, use_build_context_synchronously

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to fetch contacts from the device.
/// On iOS and Android this uses the flutter_contacts plugin.
class ContactService {
  /// Request permission and then return all contacts.
  /// Returns a list of [Contact] objects. If permission is denied, returns an empty list.
  Future<List<Contact>> getContacts() async {
    try {
      final status = await Permission.contacts.status;
      if (!status.isGranted) {
        final result = await Permission.contacts.request();
        if (!result.isGranted) return [];
      }
      
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
        return contacts;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }
}

