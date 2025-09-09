import 'package:flutter/material.dart';
import '../models/attendee_profile.dart';

class AttendeeProfileCard extends StatelessWidget {
  final AttendeeProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onConnect;
  final bool showRecommendationReason;
  final String? recommendationReason;
  final double? recommendationScore;

  const AttendeeProfileCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onMessage,
    this.onConnect,
    this.showRecommendationReason = false,
    this.recommendationReason,
    this.recommendationScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile.profileImage != null
                        ? NetworkImage(profile.profileImage!)
                        : null,
                    child: profile.profileImage == null
                        ? Text(
                            profile.firstName.substring(0, 1) +
                                profile.lastName.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (profile.jobTitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            profile.jobTitle!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (profile.company != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.company!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (recommendationScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(recommendationScore!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(recommendationScore! * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (showRecommendationReason && recommendationReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recommendationReason!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (profile.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: profile.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (profile.city != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.city!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  if (profile.industry != null) ...[
                    if (profile.city != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(
                      Icons.work_outline,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.industry!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      if (onMessage != null && profile.allowMessages)
                        IconButton(
                          onPressed: onMessage,
                          icon: const Icon(Icons.message_outlined),
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (onConnect != null)
                        IconButton(
                          onPressed: onConnect,
                          icon: const Icon(Icons.person_add_outlined),
                          iconSize: 20,
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_ios),
                        iconSize: 16,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.blue;
    return Colors.grey;
  }
}