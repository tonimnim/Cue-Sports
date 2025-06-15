import 'package:flutter/material.dart';

class TournamentCard extends StatelessWidget {
  final String name;
  final String type;
  final String location;
  final String dateRange;
  final int players;
  final double? price;
  final bool isFeatured;
  final bool isRegistered;
  final bool isPast; // New parameter to identify past tournaments
  final VoidCallback onRegisterPressed;

  const TournamentCard({
    Key? key,
    required this.name,
    required this.type,
    required this.location,
    required this.dateRange,
    required this.players,
    this.price,
    this.isFeatured = false,
    this.isRegistered = false,
    this.isPast = false, // Default is not a past tournament
    required this.onRegisterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedCard(context);
    } else {
      return _buildRegularCard(context);
    }
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary, // Yellow background
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price != null ? '$type (\$${price.toStringAsFixed(2)})' : type,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary, // Yellow background
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateRange,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$players players',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
  
                    ElevatedButton(
                      // Disable button for past tournaments if not already registered
                      onPressed: isPast && !isRegistered ? null : onRegisterPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered 
                          ? Theme.of(context).colorScheme.primary // Green for registered
                          : isPast 
                              ? Colors.grey.shade400 // Grey for past tournaments
                              : Colors.grey.shade300, // Light grey for featured tournaments
                        foregroundColor: isRegistered 
                          ? Theme.of(context).colorScheme.onPrimary 
                          : isPast 
                              ? Colors.grey.shade700 // Dark grey text for past tournaments
                              : Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        // Add disabledBackgroundColor and disabledForegroundColor for past tournaments
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRegistered)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.check, 
                                  size: 14, 
                                  color: Theme.of(context).colorScheme.primary
                                ),
                              ),
                            ),
                          Text(
                            isRegistered 
                              ? 'Registered' 
                              : isPast 
                                  ? 'Past Event' 
                                  : 'Register'
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$players players',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ElevatedButton(
                  // Disable button for past tournaments if not already registered
                  onPressed: isPast && !isRegistered ? null : onRegisterPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRegistered 
                      ? Theme.of(context).colorScheme.primary // Green for registered
                      : isPast 
                          ? Colors.grey.shade400 // Grey for past tournaments
                          : Theme.of(context).colorScheme.secondary, // Yellow for regular tournaments
                    foregroundColor: isRegistered 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : isPast 
                          ? Colors.grey.shade700 // Dark grey text for past tournaments
                          : Theme.of(context).colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Add disabledBackgroundColor and disabledForegroundColor for past tournaments
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRegistered)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimary,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.check, 
                              size: 14, 
                              color: Theme.of(context).colorScheme.primary
                            ),
                          ),
                        ),
                      Text(
                        isRegistered 
                          ? 'Registered' 
                          : isPast 
                              ? 'Past Event' 
                              : 'Register'
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
