import 'dart:convert';
import 'dart:io';

// This script fetches orders from the Firestore database and provides tools to clean up duplicate orders
void main() async {
  print('Fetch Orders Tool');
  print('===============');
  print('This script retrieves orders from Firestore and helps clean up duplicates');
  print('Script started at: ${DateTime.now()}\n');

  // Your Firebase project ID
  const projectId = 'poolbilliard-167ad';

  // The user ID to fetch orders for (optional)
  const userId = 'ImVtpfI8obSnwRXG8q9LHMN5u5G2';

  // Create a FirestoreClient
  final firestore = FirestoreClient(projectId);

  try {
    // Show menu of available operations
    print('Available operations:');
    print('1. Fetch orders for a specific user');
    print('2. Find duplicate orders (by transactionId)');
    print('3. Delete empty orders');
    print('4. Delete all orders (DANGER!)');
    print('\nEnter operation number (1-4): ');
    
    final input = stdin.readLineSync();
    
    switch(input) {
      case '1':
        // Fetch orders for the specific user
        print('Fetching orders for user: $userId...');
        final ordersResponse = await firestore.getDocumentsWithFilter(
          'orders',
          'userId',
          userId,
        );
        await displayOrders(ordersResponse, firestore, userId);
        break;
        
      case '2':
        // Find and handle duplicate orders
        await findAndHandleDuplicateOrders(firestore);
        break;
        
      case '3':
        // Delete empty orders
        print('Deleting orders with zero items...');
        await deleteEmptyOrders(firestore);
        print('Empty orders deleted successfully!');
        break;
        
      case '4':
        // Confirm before deleting all orders
        print('\nWARNING: This will delete ALL orders in the database!');
        print('Type "CONFIRM" to proceed: ');
        final confirmation = stdin.readLineSync();
        
        if (confirmation == 'CONFIRM') {
          await deleteAllOrders(firestore);
          print('All orders deleted successfully!');
        } else {
          print('Operation cancelled.');
        }
        break;
        
      default:
        print('Invalid option selected.');
    }
    
    print('\nOperation completed successfully!');
  } catch (e) {
    print('Error: $e');
  }
}

// Function to display orders from a response
Future<void> displayOrders(Map<String, dynamic> ordersResponse, FirestoreClient firestore, String userId) async {
  if (ordersResponse['documents'] != null) {
    final documents = ordersResponse['documents'] as List;

    print('\n===== ORDERS FOR USER $userId (${documents.length}) =====');

    if (documents.isEmpty) {
      print('No orders found for this user.');
      return;
    }

    for (int i = 0; i < documents.length; i++) {
      try {
        final doc = documents[i] as Map<String, dynamic>;

        // Extract the document ID from the path
        final String docPath = doc['name'] ?? '';
        final String orderId = docPath.split('/').last;

        print('\nOrder ${i + 1}: $orderId');
        print('----------------------------');
        print('  Order ID: $orderId');

        // Get order details with proper null handling
        final orderNumber = firestore.getFieldValue(doc, 'orderNumber') ?? 'Not provided';
        final amount = firestore.getFieldValue(doc, 'amount') ?? 0.0;
        final status = firestore.getFieldValue(doc, 'status') ?? 'Unknown';
        final paymentMethod = firestore.getFieldValue(doc, 'paymentMethod') ?? 'Not provided';
        final mpesaReceipt = firestore.getFieldValue(doc, 'mpesa_receipt') ?? 'Not provided';
        final transactionDate = firestore.getFieldValue(doc, 'transaction_date');
        final txnUnique = firestore.getFieldValue(doc, 'txn_unique') ?? 'Not provided';

        print('  Order Number: $orderNumber');
        print('  Amount: $amount');
        print('  Status: $status');
        print('  Payment Method: $paymentMethod');
        print('  M-Pesa Receipt: $mpesaReceipt');
        print('  Transaction ID: $txnUnique');
        
        if (transactionDate != null) {
          print('  Transaction Date: $transactionDate');
        }

        // Get items if available
        final items = firestore.getFieldValue(doc, 'items');
        if (items != null && items is List) {
          print('\n  Items:');
          for (int j = 0; j < items.length; j++) {
            final item = items[j];
            final productName = item['name'] ?? 'Unknown Product';
            final productPrice = item['price'] ?? 0.0;
            final quantity = item['quantity'] ?? 1;
            
            print('    ${j + 1}. $productName - $quantity x $productPrice');
          }
        } else {
          print('\n  No items found in this order');
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
        print('\nError processing order ${i + 1}: $e');
      }
    }
  } else {
    print('No orders found for user: $userId');
  }
}

// Function to find and handle duplicate orders
Future<void> findAndHandleDuplicateOrders(FirestoreClient firestore) async {
  try {
    print('Searching for duplicate orders by transaction ID...');
    
    // Get all orders
    final allOrdersResponse = await firestore.getDocuments('orders');
    
    if (allOrdersResponse['documents'] == null || (allOrdersResponse['documents'] as List).isEmpty) {
      print('No orders found to check for duplicates.');
      return;
    }
    
    final documents = allOrdersResponse['documents'] as List;
    print('Found ${documents.length} orders to analyze');
    
    // Map to store transaction IDs and their corresponding orders
    final Map<String, List<Map<String, dynamic>>> transactionMap = {};
    
    // Group orders by transaction ID
    for (final doc in documents) {
      final txnUnique = firestore.getFieldValue(doc, 'txn_unique');
      
      if (txnUnique != null && txnUnique.toString().isNotEmpty) {
        if (!transactionMap.containsKey(txnUnique)) {
          transactionMap[txnUnique] = [];
        }
        transactionMap[txnUnique]!.add(doc);
      }
    }
    
    // Find duplicates (transaction IDs with more than one order)
    final duplicates = transactionMap.entries
        .where((entry) => entry.value.length > 1)
        .toList();
    
    if (duplicates.isEmpty) {
      print('No duplicate orders found!');
      return;
    }
    
    print('\nFound ${duplicates.length} transaction IDs with duplicate orders:');
    
    // Display each set of duplicates
    for (int i = 0; i < duplicates.length; i++) {
      final entry = duplicates[i];
      final txnId = entry.key;
      final orders = entry.value;
      
      print('\n${i + 1}. Transaction ID: $txnId (${orders.length} orders)');
      
      // Display each duplicate order
      for (int j = 0; j < orders.length; j++) {
        final doc = orders[j];
        final String docPath = doc['name'] ?? '';
        final String orderId = docPath.split('/').last;
        final status = firestore.getFieldValue(doc, 'status') ?? 'Unknown';
        final amount = firestore.getFieldValue(doc, 'amount') ?? 0.0;
        final createdAt = firestore.getFieldValue(doc, 'createdAt') ?? 'Unknown';
        
        print('  ${j + 1}. Order ID: $orderId');
        print('     Status: $status');
        print('     Amount: $amount');
        print('     Created: $createdAt');
      }
      
      // Ask what to do with these duplicates
      print('\n  Options:');
      print('  1. Keep all duplicates');
      print('  2. Keep only the first order (delete others)');
      print('  3. Skip to next duplicate set');
      print('\n  Enter option (1-3): ');
      
      final input = stdin.readLineSync();
      
      if (input == '2') {
        // Keep only the first order, delete the rest
        for (int j = 1; j < orders.length; j++) {
          final doc = orders[j];
          final String docPath = doc['name'] ?? '';
          final String orderId = docPath.split('/').last;
          
          await firestore.deleteDocument('orders', orderId);
          print('  Deleted duplicate order: $orderId');
        }
      } else if (input == '3') {
        print('  Skipping to next duplicate set');
        continue;
      } else {
        print('  Keeping all duplicates');
      }
    }
    
    print('\nDuplicate order analysis complete!');
  } catch (e) {
    print('Error finding duplicate orders: $e');
    rethrow;
  }
}

// Function to delete all orders
Future<void> deleteAllOrders(FirestoreClient firestore) async {
  try {
    // Get all orders
    final allOrdersResponse = await firestore.getDocuments('orders');
    
    if (allOrdersResponse['documents'] != null) {
      final documents = allOrdersResponse['documents'] as List;
      print('Found ${documents.length} orders to delete');
      
      // Delete each order
      for (final doc in documents) {
        final String docPath = doc['name'] ?? '';
        final String orderId = docPath.split('/').last;
        
        // Delete the order
        await firestore.deleteDocument('orders', orderId);
        print('Deleted order: $orderId');
      }
    } else {
      print('No orders found to delete');
    }
  } catch (e) {
    print('Error deleting orders: $e');
    rethrow;
  }
}

// Function to delete orders with zero items
Future<void> deleteEmptyOrders(FirestoreClient firestore) async {
  try {
    // Get all orders
    final allOrdersResponse = await firestore.getDocuments('orders');
    
    if (allOrdersResponse['documents'] != null) {
      final documents = allOrdersResponse['documents'] as List;
      print('Found ${documents.length} orders to check');
      
      int deletedCount = 0;
      
      // Check each order and delete if it has zero items
      for (final doc in documents) {
        final String docPath = doc['name'] ?? '';
        final String orderId = docPath.split('/').last;
        
        // Get items if available
        final items = firestore.getFieldValue(doc, 'items');
        
        // Delete the order if items is null, empty list, or all items have quantity 0
        bool shouldDelete = false;
        
        if (items == null || (items is List && items.isEmpty)) {
          shouldDelete = true;
        } else if (items is List) {
          // Check if all items have quantity 0
          bool allItemsZeroQuantity = true;
          for (final item in items) {
            final quantity = item['quantity'] ?? 0;
            if (quantity > 0) {
              allItemsZeroQuantity = false;
              break;
            }
          }
          shouldDelete = allItemsZeroQuantity;
        }
        
        if (shouldDelete) {
          // Delete the order
          await firestore.deleteDocument('orders', orderId);
          print('Deleted empty order: $orderId');
          deletedCount++;
        }
      }
      
      print('Deleted $deletedCount empty orders out of ${documents.length} total orders');
    } else {
      print('No orders found to check');
    }
  } catch (e) {
    print('Error deleting empty orders: $e');
    rethrow;
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

  // Get a single document by ID
  Future<Map<String, dynamic>> getDocument(
      String collection, String documentId) async {
    final url = '$baseUrl/$collection/$documentId';
    return _get(url);
  }
  
  // Delete a document by ID
  Future<void> deleteDocument(String collection, String documentId) async {
    final url = '$baseUrl/$collection/$documentId';
    await _delete(url);
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