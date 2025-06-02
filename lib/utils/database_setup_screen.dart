import 'package:flutter/material.dart';
import '../firebase/populate_sample_communities.dart';

/// Screen for database setup and testing
/// This is a utility screen for developers to set up initial data
class DatabaseSetupScreen extends StatefulWidget {
  static const String routeName = '/database-setup';

  const DatabaseSetupScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseSetupScreen> createState() => _DatabaseSetupScreenState();
}

class _DatabaseSetupScreenState extends State<DatabaseSetupScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _populateCommunities() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Adding sample communities...';
    });

    try {
      await PopulateSampleCommunities.addSampleCommunities();
      setState(() {
        _statusMessage = '✅ Successfully added sample communities!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkCommunities() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking existing communities...';
    });

    try {
      await PopulateSampleCommunities.checkExistingCommunities();
      setState(() {
        _statusMessage = '✅ Check complete! See console for details.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCommunities() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing all communities...';
    });

    try {
      await PopulateSampleCommunities.clearAllCommunities();
      setState(() {
        _statusMessage = '✅ All communities cleared!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Setup'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Database Setup Utilities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            const Text(
              'Use these tools to set up initial data for testing the community features.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Status message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('❌')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('❌')
                        ? Colors.red
                        : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 20),

            // Add sample communities button
            ElevatedButton(
              onPressed: _isLoading ? null : _populateCommunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Sample Communities'),
            ),
            const SizedBox(height: 12),

            // Check communities button
            ElevatedButton(
              onPressed: _isLoading ? null : _checkCommunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Check Existing Communities'),
            ),
            const SizedBox(height: 12),

            // Clear communities button
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                              'Are you sure you want to delete ALL communities? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _clearCommunities();
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Clear All Communities'),
            ),

            const Spacer(),

            // Back to app button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back to App'),
            ),
          ],
        ),
      ),
    );
  }
}
