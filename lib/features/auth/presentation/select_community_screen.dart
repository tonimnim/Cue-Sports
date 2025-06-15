import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme.dart';
import '../domain/entities/community.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../../../widget/buttons/primary_button.dart';
// LoadingIndicator is used inline as CircularProgressIndicator
import '../../../widget/inputs/phone_text_field.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/di/injection_container.dart';

// Screen states for the community selection flow
enum ScreenState { selectingCommunity, payment }

/// Screen for selecting a community and handling payment in one screen
class SelectCommunityScreen extends StatefulWidget {
  static const String routeName = '/select-community';
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const SelectCommunityScreen({
    Key? key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  }) : super(key: key);

  @override
  State<SelectCommunityScreen> createState() => _SelectCommunityScreenState();
}

class _SelectCommunityScreenState extends State<SelectCommunityScreen> {
  ScreenState _currentState = ScreenState.selectingCommunity;

  // Community selection
  String? _selectedCommunityId;
  String _searchQuery = '';
  List<Community> _communities = [];
  List<Community> _filteredCommunities = [];
  bool _isLoading = false;

  // Payment
  final _mpesaPhoneController = TextEditingController();
  final _paymentFormKey = GlobalKey<FormState>();
  bool _useSamePhone = true;

  @override
  void initState() {
    super.initState();
    // Load communities on screen init
    _loadCommunities();
    // Initialize M-Pesa phone with user's phone
  }

  @override
  void dispose() {
    _mpesaPhoneController.dispose();
    super.dispose();
  }

  // Load communities from the database
  void _loadCommunities() {
    try {
      context.read<AuthBloc>().add(FetchCommunitiesEvent());
    } catch (e) {
      final logger = sl<LoggerService>();
      logger.e('Error loading communities: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load communities: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filter communities based on search query
  void _filterCommunities(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCommunities = List.from(_communities);
      } else {
        _filteredCommunities = _communities
            .where((community) =>
                community.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Select community and proceed to payment
  void _selectCommunity() {
    if (_selectedCommunityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a community first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _currentState = ScreenState.payment;
    });
  }

  // Process payment
  void _processPayment() {
    if (_paymentFormKey.currentState?.validate() != true) {
      return;
    }

    // Select the community first, then payment will be handled
    if (_selectedCommunityId != null) {
      context.read<AuthBloc>().add(
        SelectCommunityEvent(communityId: _selectedCommunityId!),
      );
    }
  }

  // Go back to community selection
  void _backToCommunitySelection() {
    setState(() {
      _currentState = ScreenState.selectingCommunity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_currentState == ScreenState.selectingCommunity
            ? 'Select Your Community'
            : 'Payment'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          if (_currentState == ScreenState.payment)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToCommunitySelection,
              tooltip: 'Back to Community Selection',
            ),
        ],
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
          } else if (state is EmailVerificationSent) {
            // Navigation will be handled by AuthWrapper
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent! Check your email.'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is AuthAuthenticated) {
            // User fully authenticated - navigate to home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          } else if (state is CommunitiesLoaded) {
            setState(() {
              _communities = state.communities;
              _filteredCommunities = List.from(_communities);
              _isLoading = false;
              
              // Select first community by default if available
              if (_communities.isNotEmpty && _selectedCommunityId == null) {
                _selectedCommunityId = _communities[0].id;
              }
            });
          } else if (state is CommunitiesLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is CommunitySelected) {
            // Community selected, start player registration
            context.read<AuthBloc>().add(
              StartPlayerRegistrationEvent(
                fullName: widget.fullName,
                email: widget.email,
                phoneNumber: widget.phoneNumber,
                password: widget.password,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          if (_currentState == ScreenState.selectingCommunity) {
            return _buildCommunitySelectionView(isLoading);
          } else {
            return _buildPaymentView(isLoading);
          }
        },
      ),
    );
  }

  // Build the community selection view
  Widget _buildCommunitySelectionView(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(color: Colors.grey.shade600),
              ),
              style: const TextStyle(color: Colors.black87),
              onChanged: _filterCommunities,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title with icon
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Choose a Community',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Explanation
          const Text(
            'Join a local pool billiards community to participate in events and tournaments.',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // Communities list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentColor),
                        const SizedBox(height: 16),
                        const Text('Loading communities...', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : _filteredCommunities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No communities available'
                                  : 'No communities match "$_searchQuery"',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isNotEmpty) ...[  
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _filteredCommunities = List.from(_communities);
                                  });
                                },
                                child: const Text('Clear search'),
                              ),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: _loadCommunities,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCommunities.length,
                        itemBuilder: (context, index) {
                          final community = _filteredCommunities[index];
                          final isSelected = community.id == _selectedCommunityId;
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedCommunityId = community.id;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    community.logoUrl.isNotEmpty
                                        ? CircleAvatar(
                                            radius: 28,
                                            backgroundImage: NetworkImage(community.logoUrl),
                                          )
                                        : CircleAvatar(
                                            radius: 28,
                                            backgroundColor: AppTheme.accentColor,
                                            child: Text(
                                              community.name.substring(0, 1).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            community.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (community.location.isNotEmpty) ...[  
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    community.location,
                                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (community.description.isNotEmpty) ...[  
                                            const SizedBox(height: 4),
                                            Text(
                                              community.description,
                                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 20),
          
          // Continue button
          PrimaryButton(
            text: 'Continue to Payment',
            onPressed: _selectedCommunityId != null ? _selectCommunity : null,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  // Build the payment view
  Widget _buildPaymentView(bool isLoading) {
    // Find selected community
    final selectedCommunity = _communities.firstWhere(
      (community) => community.id == _selectedCommunityId,
      orElse: () => Community.fromMap({
        'id': '',
        'name': 'Unknown',
        'description': 'No description available',
        'location': 'Unknown location',
        'createdAt': DateTime.now(),
      }),
    );
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _paymentFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected community card
            Card(
              color: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Community',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        selectedCommunity.logoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(selectedCommunity.logoUrl),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Text(
                                  selectedCommunity.name.substring(0, 1),
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCommunity.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              // Show location if not empty
                              if (selectedCommunity.location.isNotEmpty)
                                Text(
                                  selectedCommunity.location,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment information
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player Registration Fee',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A one-time registration fee of KSh 500 will be charged via M-Pesa.',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // M-Pesa payment section
            const Text(
              'M-Pesa Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Phone number option
            SwitchListTile(
              title: const Text(
                'Use registration phone number',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                widget.phoneNumber,
                style: const TextStyle(color: Colors.white70),
              ),
              value: _useSamePhone,
              onChanged: (value) {
                setState(() {
                  _useSamePhone = value;
                });
              },
              activeColor: AppTheme.accentColor,
            ),
            
            // Different phone number field
            if (!_useSamePhone) ...[  
              const SizedBox(height: 16),
              PhoneTextField(
                controller: _mpesaPhoneController,
                labelText: 'M-Pesa Phone Number',
                hintText: 'Enter M-Pesa phone number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter M-Pesa phone number';
                  }
                  // Basic Kenyan phone number validation
                  final phoneRegex = RegExp(r'^(0|\+254|254)(7|1)[0-9]{8}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Please enter a valid Kenyan phone number';
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Payment button
            PrimaryButton(
              text: 'Pay KSh 500 via M-Pesa',
              onPressed: _processPayment,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
