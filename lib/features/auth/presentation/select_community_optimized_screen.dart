import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/theme.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/logger_service.dart';
import '../domain/entities/community.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import '../../../widget/buttons/primary_button.dart';
import '../../../widget/display/loading_indicator.dart';
import 'pages/sms_verification_screen.dart';

/// Optimized community selection screen for the new registration flow
/// This screen handles community selection BEFORE email verification
class SelectCommunityOptimizedScreen extends StatefulWidget {
  static const String routeName = '/select-community-optimized';

  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const SelectCommunityOptimizedScreen({
    Key? key,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  }) : super(key: key);

  @override
  State<SelectCommunityOptimizedScreen> createState() =>
      _SelectCommunityOptimizedScreenState();
}

class _SelectCommunityOptimizedScreenState
    extends State<SelectCommunityOptimizedScreen> {
  String? _selectedCommunityId;
  String _searchQuery = '';
  List<Community> _communities = [];
  List<Community> _filteredCommunities = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load communities immediately
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load communities from the database
  void _loadCommunities() {
    try {
      context.read<AuthBloc>().add(FetchCommunitiesEvent());
    } catch (e) {
      final logger = sl<LoggerService>();
      logger.e('Error loading communities: $e');
      _showErrorSnackBar('Failed to load communities: $e');
    }
  }

  // Optimized search with debouncing for better performance
  void _filterCommunities(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCommunities = List.from(_communities);
      } else {
        _filteredCommunities = _communities
            .where((community) =>
                community.name.toLowerCase().contains(_searchQuery) ||
                community.location.toLowerCase().contains(_searchQuery) ||
                (community.description?.toLowerCase().contains(_searchQuery) ??
                    false))
            .toList();
      }
    });
  }

  // Continue with registration after community selection
  void _continueWithRegistration() {
    if (_selectedCommunityId == null) {
      _showErrorSnackBar('Please select a community first');
      return;
    }

    // Generate payment ID for the player
    final paymentId =
        'PB${DateTime.now().millisecondsSinceEpoch}${_selectedCommunityId!.substring(0, 3).toUpperCase()}';

    // Create pending registration with community selection
    context.read<AuthBloc>().add(
          CreatePendingRegistrationEvent(
            fullName: widget.fullName,
            email: widget.email,
            phoneNumber: widget.phoneNumber,
            password: widget.password,
            userType: 'player',
            communityId: _selectedCommunityId!,
            paymentId: paymentId,
          ),
        );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Your Community'),
            const SizedBox(width: 8),
            const Icon(
              Icons.groups,
              size: 24,
              color: Colors.amber,
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            _showErrorSnackBar(state.message);
          } else if (state is PendingRegistrationCreated) {
            // SMS verification code sent, navigate to SMS verification screen
            _showSuccessSnackBar(
                'SMS verification code sent! Check your messages.');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SmsVerificationScreen(
                  phoneNumber: widget.phoneNumber,
                  fullName: widget.fullName,
                ),
              ),
            );
          } else if (state is CommunitiesLoaded) {
            setState(() {
              _communities = state.communities;
              _filteredCommunities = List.from(_communities);
              _isLoading = false;
            });
          } else if (state is CommunitiesLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is CommunitySelected) {
            // Community selected, now start player registration
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
          final isLoading = state is AuthLoading || _isLoading;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Search Bar at top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildSearchBar(),
                ),

                const SizedBox(height: 20),

                // Communities List (Expanded to take available space)
                Expanded(
                  child: isLoading
                      ? const Center(child: LoadingIndicator())
                      : _communities.isEmpty
                          ? _buildEmptyState()
                          : _buildOptimizedCommunitiesList(),
                ),

                // Bottom Section with Continue Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContinueButton(isLoading),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      controller: _searchController,
      onChanged: _filterCommunities,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Search communities by name or location...',
        hintStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.black54),
                onPressed: () {
                  _searchController.clear();
                  _filterCommunities('');
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFB7C5B6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildOptimizedCommunitiesList() {
    if (_filteredCommunities.isEmpty) {
      return _buildNoResultsState();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredCommunities.length,
        itemBuilder: (context, index) {
          final community = _filteredCommunities[index];
          return _buildOptimizedCommunityCard(community);
        },
      ),
    );
  }

  Widget _buildOptimizedCommunityCard(Community community) {
    final isSelected = _selectedCommunityId == community.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      color: isSelected
          ? AppTheme.primaryColor.withOpacity(0.8)
          : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.amber : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: () {
          // Provide haptic feedback for better UX
          HapticFeedback.selectionClick();

          setState(() {
            _selectedCommunityId = community.id;
          });
        },
        leading: CircleAvatar(
          backgroundColor:
              isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
          radius: 18,
          child: Icon(
            Icons.location_city,
            color: isSelected ? Colors.black : Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          community.name,
          style: TextStyle(
            color: isSelected ? Colors.amber : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          community.location,
          style: TextStyle(
            color: isSelected ? Colors.amber.shade200 : Colors.white70,
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.amber, size: 24)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildContinueButton(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isLoading || _selectedCommunityId == null
              ? null
              : _continueWithRegistration,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.registerButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : const Text(
                  'Continue to Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (_selectedCommunityId == null) ...[
          const SizedBox(height: 8),
          Text(
            'Please select a community to continue',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No communities found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
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
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No communities available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please try again later or contact support.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Retry',
              onPressed: _loadCommunities,
            ),
          ],
        ),
      ),
    );
  }
}
