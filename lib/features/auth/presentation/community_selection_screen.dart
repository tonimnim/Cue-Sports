import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme.dart';
import '../domain/entities/community.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../../../widget/buttons/primary_button.dart';
import '../../../widget/display/loading_indicator.dart';

/// Screen for selecting a community after code verification
class CommunitySelectionScreen extends StatefulWidget {
  static const String routeName = '/community-selection';
  final String email;
  final bool isPlayer; // Whether the user is registering as a player
  final String? userId; // User ID for payment
  final String? phoneNumber; // Phone number for payment

  const CommunitySelectionScreen({
    Key? key,
    required this.email,
    required this.isPlayer,
    this.userId,
    this.phoneNumber,
  }) : super(key: key);

  @override
  State<CommunitySelectionScreen> createState() =>
      _CommunitySelectionScreenState();
}

class _CommunitySelectionScreenState extends State<CommunitySelectionScreen> {
  String? _selectedCommunityId;
  List<Community> _communities = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load communities on screen init
    _loadCommunities();
  }

  void _loadCommunities() {
    setState(() {
      _errorMessage = null;
    });
    context.read<AuthBloc>().add(FetchCommunitiesEvent());
  }

  void _continueToPayment() {
    if (_selectedCommunityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a community first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.isPlayer) {
      // For player, proceed to payment
      Navigator.of(context).pushNamed(
        '/payment',
        arguments: {
          'paymentType': 'registration',
          'typeId': _selectedCommunityId ?? '',
          'userId': widget.userId ?? '',
          'amount': 500.0, // Registration fee
          'prefillPhoneNumber': widget.phoneNumber ?? '',
        },
      );
    } else {
      // For fan, proceed directly to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Communities',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Failed to load communities. Please check your internet connection and try again.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCommunities,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Debug button to setup database
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/database-setup');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Setup Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Allow user to continue without selecting a community
                // This creates a fallback path
                setState(() {
                  _selectedCommunityId = 'default';
                });
                _continueToPayment();
              },
              child: const Text(
                'Continue without community selection',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Communities Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'There are currently no billiard communities available in your area. You can still continue and join a community later.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCommunities,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Allow user to continue without selecting a community
                setState(() {
                  _selectedCommunityId = 'none';
                });
                _continueToPayment();
              },
              child: const Text(
                'Continue without community',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Your Community'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            setState(() {
              _errorMessage = state.message;
              _isLoading = false;
            });
            // Don't show snackbar anymore since we handle it in the UI
          } else if (state is CommunitiesLoaded) {
            setState(() {
              _communities = state.communities;
              _errorMessage = null;

              // Select first community by default if available
              if (_communities.isNotEmpty && _selectedCommunityId == null) {
                _selectedCommunityId = _communities[0].id;
              }

              _isLoading = false;
            });
          } else if (state is CommunitiesLoading) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
        },
        builder: (context, state) {
          // Show error state
          if (_errorMessage != null && !_isLoading) {
            return _buildErrorState();
          }

          // Show loading state
          if (_isLoading) {
            return const Center(child: LoadingIndicator());
          }

          // Show empty state
          if (_communities.isEmpty) {
            return _buildEmptyState();
          }

          // Show normal community selection
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  'Select Your Local Community',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Explanation
                const Text(
                  'Choose the billiard community closest to you. This will help you connect with local players and events.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Community selection card
                Card(
                  color: Colors.white10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Community',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCommunityId,
                          decoration: const InputDecoration(
                            hintText: 'Select a community',
                            filled: true,
                            fillColor: Colors.black26,
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: Colors.grey[800],
                          style: const TextStyle(color: Colors.white),
                          items: _communities.map((community) {
                            return DropdownMenuItem<String>(
                              value: community.id,
                              child: Text(
                                community.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedCommunityId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Continue button
                PrimaryButton(
                  text: widget.isPlayer ? 'Continue to Payment' : 'Continue',
                  onPressed: _continueToPayment,
                  isLoading: false,
                ),

                // Additional info for players
                if (widget.isPlayer)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      'Player registration requires a one-time payment of KSh 500.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 26), // 0.1 * 255 ≈ 26
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
