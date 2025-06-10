import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme.dart';
import '../domain/entities/community.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../../../widget/buttons/primary_button.dart';
import '../../../widget/display/loading_indicator.dart';
import '../../payment/domain/entities/payment.dart' as payment_entity;

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

  @override
  void initState() {
    super.initState();
    // Load communities on screen init
    _loadCommunities();
  }

  void _loadCommunities() {
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
      // For player, proceed to unified payment
      Navigator.of(context).pushNamed(
        '/unified-payment',
        arguments: {
          'paymentType': payment_entity.PaymentType.registration,
          'typeId': _selectedCommunityId ?? '',
          'userId': widget.userId ?? '',
          'amount': 500.0, // Registration fee
          'prefillPhoneNumber': widget.phoneNumber ?? '',
          'metadata': {
            'communityId': _selectedCommunityId,
            'userType': 'player',
          },
          'onSuccess': () {
            // Navigate to home after successful payment
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
        },
      );
    } else {
      // For fan, proceed directly to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CommunitiesLoaded) {
            setState(() {
              _communities = state.communities;

              // Select first community by default if available
              if (_communities.isNotEmpty && _selectedCommunityId == null) {
                _selectedCommunityId = _communities[0].id;
              }

              _isLoading = false;
            });
          } else if (state is CommunitiesLoading) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        builder: (context, state) {
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

                // Loading indicator or dropdown
                if (_isLoading)
                  const Center(child: LoadingIndicator())
                else if (_communities.isEmpty)
                  const Center(
                    child: Text(
                      'No communities available. Please try again later.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
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
                  isLoading: _isLoading,
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
