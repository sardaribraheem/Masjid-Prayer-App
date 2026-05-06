import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../l10n/app_localization.dart';

/// Enhanced Event Card Widget for Community Page
/// Shows comprehensive event information with better design
class EnhancedEventCard extends StatelessWidget {
  final Event event;

  const EnhancedEventCard({Key? key, required this.event}) : super(key: key);

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  IconData _getCategoryIcon() {
    switch (event.category?.toLowerCase()) {
      case 'taleem':
        return Icons.school;
      case 'dars':
        return Icons.book;
      case 'tablighi jamaat':
        return Icons.group;
      case 'gasht':
        return Icons.directions_walk;
      default:
        return Icons.event;
    }
  }

  Color _getCategoryColor() {
    switch (event.category?.toLowerCase()) {
      case 'taleem':
        return const Color(0xFF2196F3); // Blue
      case 'dars':
        return const Color(0xFF9C27B0); // Purple
      case 'tablighi jamaat':
        return const Color(0xFF4CAF50); // Green
      case 'gasht':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF1B5E47); // Deep Emerald
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color deepEmerald = Color(0xFF1B5E47);
    const Color brushGold = Color(0xFFD4A574);

    final categoryColor = _getCategoryColor();
    final translations = appLocalization.translations;

    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 12, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: deepEmerald.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Masjid name and Category Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.masjidName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF999999),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deepEmerald,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category Badge
                  if (event.category != null && event.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(),
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.category!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Date and Time Info Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: brushGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(event.eventDate),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: deepEmerald,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: brushGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.startTime} - ${event.endTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: deepEmerald,
                      ),
                    ),
                  ],
                ),
              ),

              // Location info if available
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
