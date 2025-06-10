import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/community_transfer_request.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section.dart';
import '../widgets/community_info_card.dart';
import '../widgets/transfer_request_card.dart';

/// Community settings screen for players only
class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _reasonController = TextEditingController();
  String? _selectedCommunityId;
  String? _selectedCommunityName;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Community Settings',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state is CommunityTransferRequestCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
            _reasonController.clear();
            _selectedCommunityId = null;
            _selectedCommunityName = null;
          } else if (state is CommunityTransferRequestCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          // Get settings from current state
          UserSettings? settings;
          CommunityTransferRequest? transferRequest;

          if (state is SettingsLoaded) {
            settings = state.settings;
            transferRequest = state.transferRequest;
          } else if (state is SettingsUpdating) {
            settings = state.currentSettings;
          } else if (state is CommunityTransferRequesting) {
            settings = state.currentSettings;
          }

          if (settings == null) {
            return const Center(
              child: Text(
                'Settings not available',
                style: TextStyle(color: AppTheme.textColor),
              ),
            );
          }

          // Check if user is a player
          if (!settings.isPlayer) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_outlined,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Community Settings',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community settings are only available for players.',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildCommunitySettings(
              context, settings, transferRequest, state);
        },
      ),
    );
  }

  Widget _buildCommunitySettings(
    BuildContext context,
    UserSettings settings,
    CommunityTransferRequest? transferRequest,
    SettingsState state,
  ) {
    final isProcessing =
        state is CommunityTransferRequesting || state is SettingsUpdating;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Community Section
          SettingsSection(
            title: 'Current Community',
            children: [
              if (settings.currentCommunityId != null)
                CommunityInfoCard(
                  communityId: settings.currentCommunityId!,
                  communityName: settings.currentCommunityName!,
                  isCurrentCommunity: true,
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_off_outlined,
                        color: AppTheme.textSecondaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Community',
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You are not currently a member of any community',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Transfer Request Section
          if (transferRequest != null) ...[
            SettingsSection(
              title: 'Pending Transfer Request',
              children: [
                TransferRequestCard(
                  transferRequest: transferRequest,
                  onCancel: isProcessing
                      ? null
                      : () => _showCancelTransferDialog(
                          context, transferRequest.id),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Request Transfer Section (only if no pending request and user is in a community)
          if (settings.canRequestTransfer) ...[
            SettingsSection(
              title: 'Request Community Transfer',
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer to New Community',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Request to transfer from your current community to a new one. The request will be reviewed by the community admin.',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Community Selection
                      GestureDetector(
                        onTap: isProcessing
                            ? null
                            : () => _showCommunitySelectionDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.group_outlined,
                                color: AppTheme.textSecondaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedCommunityName ??
                                      'Select target community',
                                  style: TextStyle(
                                    color: _selectedCommunityName != null
                                        ? AppTheme.textColor
                                        : AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Reason TextField
                      TextField(
                        controller: _reasonController,
                        enabled: !isProcessing,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.textColor),
                        decoration: InputDecoration(
                          labelText: 'Reason for transfer',
                          labelStyle: const TextStyle(
                              color: AppTheme.textSecondaryColor),
                          hintText:
                              'Please explain why you want to transfer...',
                          hintStyle: const TextStyle(
                              color: AppTheme.textSecondaryColor),
                          border: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isProcessing ||
                                  _selectedCommunityId == null ||
                                  _reasonController.text.trim().isEmpty
                              ? null
                              : () => _submitTransferRequest(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Transfer Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (settings.hasTransferRequest) ...[
            // Info about existing transfer request
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transfer Request Pending',
                          style: TextStyle(
                            color: AppTheme.warningColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You can only have one transfer request at a time. Wait for your current request to be processed.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (settings.currentCommunityId == null) ...[
            // Info about needing to join a community first
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join a Community First',
                          style: TextStyle(
                            color: AppTheme.infoColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You need to be a member of a community before you can request a transfer.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showCommunitySelectionDialog(BuildContext context) {
    // Mock communities - in real app, this would come from a repository
    final communities = [
      {'id': 'comm1', 'name': 'Nairobi Billiards Club'},
      {'id': 'comm2', 'name': 'Mombasa Cue Masters'},
      {'id': 'comm3', 'name': 'Kisumu Pool Association'},
      {'id': 'comm4', 'name': 'Nakuru Snooker Club'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Select Community',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return ListTile(
                title: Text(
                  community['name']!,
                  style: const TextStyle(color: AppTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    _selectedCommunityId = community['id'];
                    _selectedCommunityName = community['name'];
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _submitTransferRequest(BuildContext context) {
    if (_selectedCommunityId == null || _reasonController.text.trim().isEmpty) {
      return;
    }

    context.read<SettingsBloc>().add(
          RequestCommunityTransfer(
            toCommunityId: _selectedCommunityId!,
            toCommunityName: _selectedCommunityName!,
            reason: _reasonController.text.trim(),
          ),
        );
  }

  void _showCancelTransferDialog(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Cancel Transfer Request',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: const Text(
          'Are you sure you want to cancel your transfer request? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Keep Request',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(
                    CancelCommunityTransferRequest(requestId: requestId),
                  );
            },
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
