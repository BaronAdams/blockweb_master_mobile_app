import 'package:flutter/material.dart';
import 'app_models.dart';

/// Direct port of lib/profileTypes.ts. Exact colors from the Chrome
/// extension's TimerProfile pages: daily = amber-400, hourly = blue-400,
/// weekly = violet-400, interval = rose-400.
class ProfileTypeMeta {
  final String labelKey;
  final String createDescKey;
  final Color color;
  final IconData icon;

  const ProfileTypeMeta({
    required this.labelKey,
    required this.createDescKey,
    required this.color,
    required this.icon,
  });
}

const Map<LimiterType, ProfileTypeMeta> profileTypeMeta = {
  LimiterType.daily: ProfileTypeMeta(
    labelKey: 'daily',
    createDescKey: 'dailyCreateDesc',
    color: Color(0xFFFBBF24),
    icon: Icons.wb_sunny_outlined,
  ),
  LimiterType.hourly: ProfileTypeMeta(
    labelKey: 'hourly',
    createDescKey: 'hourlyCreateDesc',
    color: Color(0xFF60A5FA),
    icon: Icons.access_time_rounded,
  ),
  LimiterType.weekly: ProfileTypeMeta(
    labelKey: 'weekly',
    createDescKey: 'weeklyCreateDesc',
    color: Color(0xFFA78BFA),
    icon: Icons.calendar_month_outlined,
  ),
  LimiterType.interval: ProfileTypeMeta(
    labelKey: 'interval',
    createDescKey: 'intervalCreateDesc',
    color: Color(0xFFFB7185),
    icon: Icons.shield_outlined,
  ),
};

const List<LimiterType> profileTypeOrder = [
  LimiterType.daily,
  LimiterType.hourly,
  LimiterType.weekly,
  LimiterType.interval,
];
