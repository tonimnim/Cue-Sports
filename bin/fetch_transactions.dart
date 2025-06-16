import 'dart:convert';
import 'dart:io';

// This script fetches transaction data from the Firestore database
void main() async {
  print('Fetch Transactions Tool');
  print('=====================');
  print('This script retrieves transaction data from Firestore');
  print('Script started at: ${DateTime.now()}\n');

  // Your Firebase project ID
  const projectId = 'poolbilliard-167ad';

  // The user ID to fetch transactions for (optional)
  // If empty, will fetch all transactions
  const userId = ''; // Set a specific userId here if needed

  // Create a FirestoreClient
  final firestore = FirestoreClient(projectId);

  try {
    if (userId.isEmpty) {
      // Fetch all transactions
      print('Fetching all transactions...');
      final transactionsResponse = await firestore.getDocuments('payments');
      await processTransactions(firestore, transactionsResponse);
    } else {
      // Fetch transactions for specific user
      print('Fetching transactions for user: $userId...');
      final transactionsResponse = await firestore.getDocumentsWithFilter(
        'payments',
        'userId',
        userId,
      );
      await processTransactions(firestore, transactionsResponse);
    }

    print('\nOperation completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// Process and display transactions
Future<void> processTransactions(
    FirestoreClient firestore, Map<String, dynamic> response) async {
  if (response['documents'] != null) {
    final documents = response['documents'] as List;

    print('\n===== TRANSACTIONS (${documents.length}) =====');

    if (documents.isEmpty) {
      print('No transactions found.');
      return;
    }

    for (int i = 0; i < documents.length; i++) {
      try {
        final doc = documents[i] as Map<String, dynamic>;

        // Extract the document ID from the path
        final String docPath = doc['name'] ?? '';
        final String transactionId = docPath.split('/').last;

        print('\nTransaction ${i + 1}: $transactionId');
        print('----------------------------');
        print('  Transaction ID: $transactionId');

        // Get transaction details with proper null handling
        final userId = firestore.getFieldValue(doc, 'userId') ?? 'Not provided';
        final type = firestore.getFieldValue(doc, 'type') ?? 'Unknown';
        final typeId = firestore.getFieldValue(doc, 'typeId') ?? 'Not provided';
        final amount = firestore.getFieldValue(doc, 'amount') ?? 0.0;
        final status = firestore.getFieldValue(doc, 'status') ?? 'Unknown';
        final phoneNumber = firestore.getFieldValue(doc, 'phoneNumber') ?? 'Not provided';
        final mpesaReceiptNumber = firestore.getFieldValue(doc, 'mpesaReceiptNumber') ?? 'Not provided';
        final orderId = firestore.getFieldValue(doc, 'orderId');
        final createdAt = firestore.getFieldValue(doc, 'createdAt');
        final completedAt = firestore.getFieldValue(doc, 'completedAt');
        final failedAt = firestore.getFieldValue(doc, 'failedAt');
        final errorMessage = firestore.getFieldValue(doc, 'errorMessage');

        print('  User ID: $userId');
        print('  Type: $type');
        print('  Type ID: $typeId');
        print('  Amount: $amount');
        print('  Status: $status');
        print('  Phone Number: $phoneNumber');
        print('  M-Pesa Receipt: $mpesaReceiptNumber');
        
        if (orderId != null) {
          print('  Order ID: $orderId');
        }
        
        if (createdAt != null) {
          print('  Created At: $createdAt');
        }
        
        if (completedAt != null) {
          print('  Completed At: $completedAt');
        }
        
        if (failedAt != null) {
          print('  Failed At: $failedAt');
        }
        
        if (errorMessage != null) {
          print('  Error Message: $errorMessage');
        }

        // Display all fields for debugging
        print('\n  All Fields:');
        if (doc['fields'] != null) {
          final fields = doc['fields'] as Map<String, dynamic>;
          fields.forEach((key, value) {
            final valueType = value.keys.first; // stringValue, integerValue, etc.
            final displayValue = value[valueType];
            print('    $key: $displayValue');
          });
        } else {
          print('    No fields found');
        }
      } catch (e) {
        print('\nError processing transaction ${i + 1}: $e');
      }
    }
  } else {
    print('No transactions found.');
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

  // Get documents with a field filter
  Future<Map<String, dynamic>> getDocumentsWithFilter(
      String collection, String field, String value) async {
    try {
      // Create a structured query
      final queryPayload = {
        'structuredQuery': {
          'from': [{'collectionId': collection}],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': field},
              'op': 'EQUAL',
              'value': {'stringValue': value}
            }
          },
          'orderBy': [{'field': {'fieldPath': 'createdAt'}, 'direction': 'DESCENDING'}]
        }
      };

      // Use the :runQuery endpoint
      final url = '$baseUrl:runQuery';
      final response = await _post(url, queryPayload);

      // Process the response to match the format of getDocuments
      final List<dynamic> queryResults = response;
      final List<dynamic> documents = [];

      for (final result in queryResults) {
        if (result.containsKey('document')) {
          documents.add(result['document']);
        }
      }

      return {'documents': documents};
    } catch (e) {
      // Check if the error is about missing index
      if (e.toString().contains('The query requires an index')) {
        print('\nERROR: This query requires a composite index.');
        print('You need to create an index for filtering by "$field" and ordering by "createdAt".');
        print('Please follow the link in the error message to create the required index.');
        print('\nAlternatively, trying to fetch documents without ordering...');
        
        // Try again without the orderBy clause
        return await getDocumentsWithoutOrdering(collection, field, value);
      }
      rethrow;
    }
  }

  // Get documents with a field filter but without ordering (doesn't require composite index)
  Future<Map<String, dynamic>> getDocumentsWithoutOrdering(
      String collection, String field, String value) async {
    // Create a structured query without orderBy
    final queryPayload = {
      'structuredQuery': {
        'from': [{'collectionId': collection}],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': 'EQUAL',
            'value': {'stringValue': value}
          }
        }
      }
    };

    // Use the :runQuery endpoint
    final url = '$baseUrl:runQuery';
    final response = await _post(url, queryPayload);

    // Process the response to match the format of getDocuments
    final List<dynamic> queryResults = response;
    final List<dynamic> documents = [];

    for (final result in queryResults) {
      if (result.containsKey('document')) {
        documents.add(result['document']);
      }
    }

    return {'documents': documents};
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
          final values = field['arrayValue']['values'];
          if (values == null) return [];
          
          return values.map((value) {
            final valueType = value.keys.first;
            return value[valueType];
          }).toList();
        case 'mapValue':
          if (field['mapValue']['fields'] == null) return {};
          
          final Map<String, dynamic> result = {};
          final fields = field['mapValue']['fields'] as Map<String, dynamic>;
          
          fields.forEach((key, value) {
            final valueType = value.keys.first;
            result[key] = value[valueType];
          });
          
          return result;
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

  // HTTP POST request
  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/json');
      request.write(json.encode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP Error: ${response.statusCode}, Body: $responseBody');
      }

      return json.decode(responseBody);
    } finally {
      client.close();
    }
  }

  // HTTP DELETE request
  Future<void> _delete(String url) async {
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(Uri.parse(url));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception(
            'HTTP Error: ${response.statusCode}, Body: $responseBody');
      }
    } finally {
      client.close();
    }
  }
}