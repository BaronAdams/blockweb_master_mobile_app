// Direct port of types/index.ts. Plain Dart classes (no freezed/json_serializable
// codegen — build_runner isn't available in this environment to verify
// generated code, so everything here is hand-written and hand-verified).
// Every model carries toJson/fromJson for the store's SharedPreferences
// persistence (see lib/state/app_store.dart), mirroring Zustand's `persist`
// middleware in the RN app.

class BlockedApp {
  final String id;
  final String packageName;
  final String appName;
  final String? iconUrl;
  final bool isBlocked;
  final int addedAt;

  const BlockedApp({
    required this.id,
    required this.packageName,
    required this.appName,
    this.iconUrl,
    required this.isBlocked,
    required this.addedAt,
  });

  BlockedApp copyWith({bool? isBlocked}) => BlockedApp(
        id: id,
        packageName: packageName,
        appName: appName,
        iconUrl: iconUrl,
        isBlocked: isBlocked ?? this.isBlocked,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'appName': appName,
        'iconUrl': iconUrl,
        'isBlocked': isBlocked,
        'addedAt': addedAt,
      };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        iconUrl: json['iconUrl'] as String?,
        isBlocked: json['isBlocked'] as bool? ?? false,
        addedAt: json['addedAt'] as int,
      );
}

class BlockedKeyword {
  final String id;
  final String keyword;
  final int addedAt;

  const BlockedKeyword({required this.id, required this.keyword, required this.addedAt});

  Map<String, dynamic> toJson() => {'id': id, 'keyword': keyword, 'addedAt': addedAt};

  factory BlockedKeyword.fromJson(Map<String, dynamic> json) => BlockedKeyword(
        id: json['id'] as String,
        keyword: json['keyword'] as String,
        addedAt: json['addedAt'] as int,
      );
}

class BlockedWebsite {
  final String id;
  final String domain;
  final bool isBlocked;
  final int addedAt;

  const BlockedWebsite({
    required this.id,
    required this.domain,
    required this.isBlocked,
    required this.addedAt,
  });

  BlockedWebsite copyWith({bool? isBlocked}) => BlockedWebsite(
        id: id,
        domain: domain,
        isBlocked: isBlocked ?? this.isBlocked,
        addedAt: addedAt,
      );

  Map<String, dynamic> toJson() => {'id': id, 'domain': domain, 'isBlocked': isBlocked, 'addedAt': addedAt};

  factory BlockedWebsite.fromJson(Map<String, dynamic> json) => BlockedWebsite(
        id: json['id'] as String,
        domain: json['domain'] as String,
        isBlocked: json['isBlocked'] as bool? ?? false,
        addedAt: json['addedAt'] as int,
      );
}

class WhitelistedSite {
  final String id;
  final String domain;
  final int addedAt;

  const WhitelistedSite({required this.id, required this.domain, required this.addedAt});

  Map<String, dynamic> toJson() => {'id': id, 'domain': domain, 'addedAt': addedAt};

  factory WhitelistedSite.fromJson(Map<String, dynamic> json) => WhitelistedSite(
        id: json['id'] as String,
        domain: json['domain'] as String,
        addedAt: json['addedAt'] as int,
      );
}

enum DayOfWeek { mon, tue, wed, thu, fri, sat, sun }

class IntervalConfig {
  final String startTime;
  final String endTime;
  final List<DayOfWeek> days;

  const IntervalConfig({required this.startTime, required this.endTime, required this.days});

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'days': days.map((d) => d.name).toList(),
      };

  factory IntervalConfig.fromJson(Map<String, dynamic> json) => IntervalConfig(
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        days: (json['days'] as List).map((d) => DayOfWeek.values.byName(d as String)).toList(),
      );
}

/// 'daily' | 'hourly' | 'weekly' | 'interval' — see lib/models/profile_types.dart.
enum LimiterType { daily, hourly, weekly, interval }

class LimiterProfile {
  final String id;
  final String name;
  final LimiterType type;
  final List<String> apps;
  final List<String> websites;
  final List<String> keywords;
  final int? dailyLimitMinutes;
  final int? dailyUsedMinutes;
  final int? dailyResetAt;
  final int? hourlyLimitMinutes;
  final int? hourlyUsedMinutes;
  final int? weeklyLimitMinutes;
  final int? weeklyUsedMinutes;
  final int? weeklyResetAt;
  final IntervalConfig? intervalConfig;
  final bool isActive;
  final int createdAt;

  const LimiterProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.apps,
    required this.websites,
    required this.keywords,
    this.dailyLimitMinutes,
    this.dailyUsedMinutes,
    this.dailyResetAt,
    this.hourlyLimitMinutes,
    this.hourlyUsedMinutes,
    this.weeklyLimitMinutes,
    this.weeklyUsedMinutes,
    this.weeklyResetAt,
    this.intervalConfig,
    required this.isActive,
    required this.createdAt,
  });

  LimiterProfile copyWith({
    String? name,
    List<String>? apps,
    List<String>? websites,
    List<String>? keywords,
    bool? isActive,
  }) =>
      LimiterProfile(
        id: id,
        name: name ?? this.name,
        type: type,
        apps: apps ?? this.apps,
        websites: websites ?? this.websites,
        keywords: keywords ?? this.keywords,
        dailyLimitMinutes: dailyLimitMinutes,
        dailyUsedMinutes: dailyUsedMinutes,
        dailyResetAt: dailyResetAt,
        hourlyLimitMinutes: hourlyLimitMinutes,
        hourlyUsedMinutes: hourlyUsedMinutes,
        weeklyLimitMinutes: weeklyLimitMinutes,
        weeklyUsedMinutes: weeklyUsedMinutes,
        weeklyResetAt: weeklyResetAt,
        intervalConfig: intervalConfig,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'apps': apps,
        'websites': websites,
        'keywords': keywords,
        'dailyLimitMinutes': dailyLimitMinutes,
        'dailyUsedMinutes': dailyUsedMinutes,
        'dailyResetAt': dailyResetAt,
        'hourlyLimitMinutes': hourlyLimitMinutes,
        'hourlyUsedMinutes': hourlyUsedMinutes,
        'weeklyLimitMinutes': weeklyLimitMinutes,
        'weeklyUsedMinutes': weeklyUsedMinutes,
        'weeklyResetAt': weeklyResetAt,
        'intervalConfig': intervalConfig?.toJson(),
        'isActive': isActive,
        'createdAt': createdAt,
      };

  factory LimiterProfile.fromJson(Map<String, dynamic> json) => LimiterProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        type: LimiterType.values.byName(json['type'] as String),
        apps: List<String>.from(json['apps'] as List? ?? const []),
        // Defensive: profiles persisted before websites/keywords existed
        // won't have these keys — same guard the RN app needed (see
        // app/(tabs)/profiles.tsx's ProfileCard).
        websites: List<String>.from(json['websites'] as List? ?? const []),
        keywords: List<String>.from(json['keywords'] as List? ?? const []),
        dailyLimitMinutes: json['dailyLimitMinutes'] as int?,
        dailyUsedMinutes: json['dailyUsedMinutes'] as int?,
        dailyResetAt: json['dailyResetAt'] as int?,
        hourlyLimitMinutes: json['hourlyLimitMinutes'] as int?,
        hourlyUsedMinutes: json['hourlyUsedMinutes'] as int?,
        weeklyLimitMinutes: json['weeklyLimitMinutes'] as int?,
        weeklyUsedMinutes: json['weeklyUsedMinutes'] as int?,
        weeklyResetAt: json['weeklyResetAt'] as int?,
        intervalConfig: json['intervalConfig'] != null
            ? IntervalConfig.fromJson(json['intervalConfig'] as Map<String, dynamic>)
            : null,
        isActive: json['isActive'] as bool? ?? false,
        createdAt: json['createdAt'] as int,
      );
}

class DailyAnalytics {
  final String date;
  final Map<String, double> appUsage;
  final double totalMinutes;
  final int blockedAttempts;
  /// hour ("0".."23") -> packageName -> minutes.
  final Map<String, Map<String, double>>? hourlyUsage;

  const DailyAnalytics({
    required this.date,
    required this.appUsage,
    required this.totalMinutes,
    required this.blockedAttempts,
    this.hourlyUsage,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'appUsage': appUsage,
        'totalMinutes': totalMinutes,
        'blockedAttempts': blockedAttempts,
        'hourlyUsage': hourlyUsage,
      };

  factory DailyAnalytics.fromJson(Map<String, dynamic> json) => DailyAnalytics(
        date: json['date'] as String,
        appUsage: Map<String, double>.from(
          (json['appUsage'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        ),
        totalMinutes: (json['totalMinutes'] as num).toDouble(),
        blockedAttempts: json['blockedAttempts'] as int? ?? 0,
        hourlyUsage: json['hourlyUsage'] == null
            ? null
            : (json['hourlyUsage'] as Map).map((hour, packages) => MapEntry(
                  hour as String,
                  Map<String, double>.from(
                    (packages as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
                  ),
                )),
      );
}

class StrictModeState {
  final bool isActive;
  final int? activatedAt;
  final int? expiresAt;
  final int durationSeconds;

  const StrictModeState({
    required this.isActive,
    this.activatedAt,
    this.expiresAt,
    required this.durationSeconds,
  });

  static const initial = StrictModeState(isActive: false, durationSeconds: 86400);

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'activatedAt': activatedAt,
        'expiresAt': expiresAt,
        'durationSeconds': durationSeconds,
      };

  factory StrictModeState.fromJson(Map<String, dynamic> json) => StrictModeState(
        isActive: json['isActive'] as bool? ?? false,
        activatedAt: json['activatedAt'] as int?,
        expiresAt: json['expiresAt'] as int?,
        durationSeconds: json['durationSeconds'] as int? ?? 86400,
      );
}

enum UserPlan { free, monthly, yearly, lifetime }

class SubscriptionState {
  final UserPlan plan;
  final int? expiresAt;
  final bool isValid;

  const SubscriptionState({required this.plan, this.expiresAt, required this.isValid});

  static const initial = SubscriptionState(plan: UserPlan.free, expiresAt: null, isValid: true);

  Map<String, dynamic> toJson() => {'plan': plan.name, 'expiresAt': expiresAt, 'isValid': isValid};

  factory SubscriptionState.fromJson(Map<String, dynamic> json) => SubscriptionState(
        plan: UserPlan.values.byName(json['plan'] as String),
        expiresAt: json['expiresAt'] as int?,
        isValid: json['isValid'] as bool? ?? true,
      );
}

class AppUser {
  final String email;
  final String username;

  const AppUser({required this.email, required this.username});

  Map<String, dynamic> toJson() => {'email': email, 'username': username};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        email: json['email'] as String,
        username: json['username'] as String,
      );
}

/// 'device' (default) follows the phone's language; 'en' is an explicit
/// user override — see AppStoreState.setLanguagePreference.
enum LanguagePreference { device, en }
