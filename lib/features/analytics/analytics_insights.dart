import 'package:flutter/material.dart';

class AnalyticsInsight {
  const AnalyticsInsight({
    required this.text,
    required this.accent,
    required this.icon,
    required this.priority,
    required this.gradients,
  });

  final String text;
  final Color accent;
  final IconData icon;
  final String priority;
  final List<Color> gradients;
}

class AnalyticsInsights {
  static List<AnalyticsInsight> build({
    required List<Map<String, dynamic>> trendData,
    required int totalScreened,
    required int totalReferred,
    required Map<String, int> ageGroups,
    required Map<String, int> referralStatuses,
    required List<Map<String, dynamic>> villages,
    required Map<String, int> conditionCounts,
    required Map<String, int> severityCounts,
  }) {
    final insights = <AnalyticsInsight>[];

    final trendBuckets = trendData
        .where((row) => row['label'] != '__total__')
        .toList();
    if (trendBuckets.length >= 2) {
      final passData = trendBuckets.map((row) {
        final passed = (row['pass_count'] as int).toDouble();
        final referred = (row['refer_count'] as int).toDouble();
        final total = passed + referred;
        return total > 0 ? passed / total * 100 : 0.0;
      }).toList();
      final current = passData.last;
      final previous = passData[passData.length - 2];
      final diff = current - previous;
      if (diff.abs() >= 1) {
        final up = diff > 0;
        insights.add(
          AnalyticsInsight(
            text:
                '${up ? 'Pass rate up' : 'Pass rate down'} ${diff.abs().toStringAsFixed(0)}% vs previous period. ${up ? 'Performance improving.' : 'Review recent screenings.'}',
            accent: up ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            priority: up ? 'Positive' : 'Warning',
            gradients: up
                ? [const Color(0xFF052E16), const Color(0xFF14532D)]
                : [const Color(0xFF2D0A0A), const Color(0xFF450A0A)],
          ),
        );
      }
    }

    if (totalScreened > 0) {
      final referRate = totalReferred / totalScreened * 100;
      if (referRate >= 30) {
        insights.add(
          AnalyticsInsight(
            text:
                'Referral rate is ${referRate.toStringAsFixed(0)}%. ${referRate >= 40 ? 'Critically high.' : 'Elevated.'} Consider targeted follow-up sessions.',
            accent: referRate >= 40
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B),
            icon: Icons.assignment_rounded,
            priority: referRate >= 40 ? 'Urgent' : 'Action',
            gradients: referRate >= 40
                ? [const Color(0xFF2D0A0A), const Color(0xFF450A0A)]
                : [const Color(0xFF2D1A00), const Color(0xFF3D2200)],
          ),
        );
      }
    }

    final allTotal = ageGroups.values.fold(0, (sum, value) => sum + value);
    final childTotal = ageGroups['0-17'] ?? 0;
    if (childTotal > 0 && allTotal > 0) {
      final childShare = childTotal / allTotal * 100;
      if (childShare >= 20) {
        insights.add(
          AnalyticsInsight(
            text:
                'Children (0-17) make up ${childShare.toStringAsFixed(0)}% of patients. Prioritise school and community outreach.',
            accent: const Color(0xFFF59E0B),
            icon: Icons.child_care_rounded,
            priority: 'Action',
            gradients: [const Color(0xFF2D1A00), const Color(0xFF3D2200)],
          ),
        );
      }
    }

    final overdue = referralStatuses['overdue'] ?? 0;
    if (overdue > 0) {
      insights.add(
        AnalyticsInsight(
          text:
              '$overdue referral${overdue == 1 ? '' : 's'} overdue. Follow up with ${overdue == 1 ? 'this patient' : 'these patients'} immediately.',
          accent: const Color(0xFFEF4444),
          icon: Icons.error_rounded,
          priority: 'Urgent',
          gradients: [const Color(0xFF2D0A0A), const Color(0xFF450A0A)],
        ),
      );
    }

    if (villages.length >= 2) {
      final topVillage = villages.first;
      final name = (topVillage['village'] as String?) ?? 'Unknown';
      final count = (topVillage['total'] as int?) ?? 0;
      insights.add(
        AnalyticsInsight(
          text:
              '$name leads with $count patients screened. Replicate this campaign model in lower-coverage locations.',
          accent: const Color(0xFF8B5CF6),
          icon: Icons.location_on_rounded,
          priority: 'Insight',
          gradients: [const Color(0xFF1A0533), const Color(0xFF240A45)],
        ),
      );
    }

    if (conditionCounts.isNotEmpty) {
      final top = conditionCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        AnalyticsInsight(
          text:
              '${top.key} is the most reported condition with ${top.value} cases. Ensure CHWs are trained to identify and document it.',
          accent: const Color(0xFF3B82F6),
          icon: Icons.health_and_safety_rounded,
          priority: 'Info',
          gradients: [const Color(0xFF0C1A2E), const Color(0xFF0F2744)],
        ),
      );
    }

    final elderlyTotal = ageGroups['60+'] ?? 0;
    if (elderlyTotal > 0 && allTotal > 0) {
      final elderlyShare = elderlyTotal / allTotal * 100;
      if (elderlyShare >= 15) {
        insights.add(
          AnalyticsInsight(
            text:
                'Elderly patients (60+) make up ${elderlyShare.toStringAsFixed(0)}% of screenings. Ensure referral pathways to specialist eye care are in place.',
            accent: const Color(0xFF8B5CF6),
            icon: Icons.elderly_rounded,
            priority: 'Action',
            gradients: [const Color(0xFF1A0533), const Color(0xFF240A45)],
          ),
        );
      }
    }

    final severeCount = severityCounts['Severe'] ?? 0;
    final criticalCount = severityCounts['Critical'] ?? 0;
    final severityTotal = severityCounts.values.fold(
      0,
      (sum, value) => sum + value,
    );
    if (severityTotal > 0 && (severeCount + criticalCount) > 0) {
      final severityShare = (severeCount + criticalCount) / severityTotal * 100;
      if (severityShare >= 10) {
        insights.add(
          AnalyticsInsight(
            text:
                '${severeCount + criticalCount} patient${(severeCount + criticalCount) == 1 ? '' : 's'} classified as Severe or Critical (${severityShare.toStringAsFixed(0)}%). Urgent referral follow-up required.',
            accent: const Color(0xFFEF4444),
            icon: Icons.warning_rounded,
            priority: 'Urgent',
            gradients: [const Color(0xFF2D0A0A), const Color(0xFF450A0A)],
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const AnalyticsInsight(
          text:
              'No screening data available for this period. Start a new screening session to generate insights.',
          accent: Color(0xFF8FA0B4),
          icon: Icons.info_outline_rounded,
          priority: 'Info',
          gradients: [Color(0xFF0C1A2E), Color(0xFF0F2744)],
        ),
      );
    }

    return insights;
  }
}
