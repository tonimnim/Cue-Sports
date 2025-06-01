import 'dart:convert';
import 'dart:io';

// This script fetches users from the Firestore database
void main() async {
  print('Fetch Users Tool');
  print('===============');
  print('This script retrieves users from Firestore');
  print('Script started at: ${DateTime.now()}\n');

  // Your Firebase project ID
  const projectId = 'poolbilliard-167ad';

  // Create a FirestoreClient
  final firestore = FirestoreClient(projectId);

  try {
    // Fetch and display all users
    print('Fetching all users...');
    final allUsersResponse = await firestore.getDocuments('users');

    if (allUsersResponse['documents'] != null) {
      final documents = allUsersResponse['documents'] as List;

      print('\n===== ALL USERS (${documents.length}) =====');

      for (int i = 0; i < documents.length; i++) {
        try {
          final doc = documents[i] as Map<String, dynamic>;
          final docName = doc['name'] ?? 'Unknown Document';

          print('\nUser ${i + 1}: $docName');
          print('----------------------------');

          // Extract the document ID from the path
          final String docPath = doc['name'] ?? '';
          final String docId = docPath.split('/').last;
          print('  Document ID: $docId');

          // Get all fields with proper null handling
          final name = firestore.getFieldValue(doc, 'name') ?? 'Not provided';
          final email = firestore.getFieldValue(doc, 'email') ?? 'Not provided';
          final phone = firestore.getFieldValue(doc, 'phone') ?? 'Not provided';
          final userType =
              firestore.getFieldValue(doc, 'userType') ?? 'Not specified';

          // Handle isPaid with null safety
          final dynamic isPaidValue = firestore.getFieldValue(doc, 'isPaid');
          final String isPaidStatus = isPaidValue == null
              ? 'Unknown'
              : (isPaidValue == true ? 'Paid' : 'Not Paid');

          // Get optional fields
          final communityId = firestore.getFieldValue(doc, 'communityId');
          final paymentReceipt =
              firestore.getFieldValue(doc, 'paymentReceiptNumber');
          final isVerified = firestore.getFieldValue(doc, 'isVerified');

          print('  Name: $name');
          print('  Email: $email');
          print('  Phone: $phone');
          print('  User Type: $userType');
          print('  Paid Status: $isPaidStatus');

          if (communityId != null) {
            print('  Community ID: $communityId');
          }

          if (paymentReceipt != null) {
            print('  Payment Receipt: $paymentReceipt');
          }

          if (isVerified != null) {
            print('  Verified: ${isVerified ? 'Yes' : 'No'}');
          }

          // Display fields directly from the document
          print('\n  All Fields:');
          if (doc['fields'] != null) {
            final fields = doc['fields'] as Map<String, dynamic>;
            fields.forEach((key, value) {
              final valueType =
                  value.keys.first; // stringValue, integerValue, etc.
              final displayValue = value[valueType];
              print('    $key: $displayValue');
            });
          } else {
            print('    No fields found');
          }
        } catch (e) {
          print('\nError processing user ${i + 1}: $e');
        }
      }
    } else {
      print('No users found in database.');
    }

    print('\nOperation completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// A simple client for Firestore REST API
class FirestoreClient {
  final String projectId;
  final String baseUrl;

  FirestoreClient(this.projectId)
      : baseUrl =
            'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // Get all documents from a collection
  Future<Map<String, dynamic>> getDocuments(String collection) async {
    final url = '$baseUrl/$collection';
    return _get(url);
  }

  // Get a single document by ID
  Future<Map<String, dynamic>> getDocument(
      String collection, String documentId) async {
    final url = '$baseUrl/$collection/$documentId';
    return _get(url);
  }

  // Extract field value from a Firestore document
  dynamic getFieldValue(Map<String, dynamic> document, String fieldName) {
    try {
      final fields = document['fields'] as Map<String, dynamic>;
      if (!fields.containsKey(fieldName)) return null;

      final field = fields[fieldName] as Map<String, dynamic>;
      final valueType = field.keys.first; // stringValue, integerValue, etc.

      // Convert based on value type
      switch (valueType) {
        case 'stringValue':
          return field['stringValue'];
        case 'integerValue':
          return int.tryParse(field['integerValue'].toString());
        case 'doubleValue':
          return field['doubleValue'];
        case 'booleanValue':
          return field['booleanValue'];
        case 'timestampValue':
          return field['timestampValue'];
        case 'arrayValue':
          return field['arrayValue']['values'] ?? [];
        default:
          return null;
      }
    } catch (e) {
      print('Error extracting field $fieldName: $e');
      return null;
    }
  }

  // HTTP GET request
  Future<Map<String, dynamic>> _get(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP Error: ${response.statusCode}, Body: $responseBody');
      }

      return json.decode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
