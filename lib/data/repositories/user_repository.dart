import 'dart:convert';
import '../local/encrypted_storage.dart';

/// User settings model — persisted encrypted locally.
class UserSettings {
  final bool musicEnabled;
  final bool sfxEnabled;
  final bool hintsEnabled;
  final int themeIndex;
  final String language;
  final String activePieceSkinId;
  final String activeBoardSkinId;

  const UserSettings({
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.hintsEnabled = true,
    this.themeIndex = 0,
    this.language = 'en',
    this.activePieceSkinId = 'cyber_neon',
    this.activeBoardSkinId = 'deep_space',
  });

  UserSettings copyWith({
    bool? musicEnabled,
    bool? sfxEnabled,
    bool? hintsEnabled,
    int? themeIndex,
    String? language,
    String? activePieceSkinId,
    String? activeBoardSkinId,
  }) => UserSettings(
    musicEnabled: musicEnabled ?? this.musicEnabled,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    hintsEnabled: hintsEnabled ?? this.hintsEnabled,
    themeIndex: themeIndex ?? this.themeIndex,
    language: language ?? this.language,
    activePieceSkinId: activePieceSkinId ?? this.activePieceSkinId,
    activeBoardSkinId: activeBoardSkinId ?? this.activeBoardSkinId,
  );

  Map<String, dynamic> toMap() => {
    'musicEnabled': musicEnabled,
    'sfxEnabled': sfxEnabled,
    'hintsEnabled': hintsEnabled,
    'themeIndex': themeIndex,
    'language': language,
    'activePieceSkinId': activePieceSkinId,
    'activeBoardSkinId': activeBoardSkinId,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    musicEnabled: map['musicEnabled'] as bool? ?? true,
    sfxEnabled: map['sfxEnabled'] as bool? ?? true,
    hintsEnabled: map['hintsEnabled'] as bool? ?? true,
    themeIndex: map['themeIndex'] as int? ?? 0,
    language: map['language'] as String? ?? 'en',
    activePieceSkinId: map['activePieceSkinId'] as String? ?? 'cyber_neon',
    activeBoardSkinId: map['activeBoardSkinId'] as String? ?? 'deep_space',
  );
}

/// Repository for all user-related data.
/// Future: replace EncryptedStorage calls with API calls.
class UserRepository {
  static const _settingsKey = 'user_settings';
  static const _goldKey = 'user_gold';
  static const _ownedSkinsKey = 'owned_skins';

  // ── Settings ─────────────────────────────────────────────────────────────

  Future<UserSettings> getSettings() async {
    final map = await EncryptedStorage.loadMap(_settingsKey);
    if (map == null) return const UserSettings();
    return UserSettings.fromMap(map);
  }

  Future<void> saveSettings(UserSettings settings) async {
    await EncryptedStorage.saveMap(_settingsKey, settings.toMap());
  }

  // ── Gold ─────────────────────────────────────────────────────────────────

  Future<int> getGold() async {
    final raw = await EncryptedStorage.loadString(_goldKey);
    return int.tryParse(raw ?? '1250') ?? 1250;
  }

  Future<void> saveGold(int amount) async {
    await EncryptedStorage.saveString(_goldKey, amount.toString());
  }

  Future<bool> spendGold(int amount) async {
    final current = await getGold();
    if (current < amount) return false;
    await saveGold(current - amount);
    return true;
  }

  Future<void> addGold(int amount) async {
    final current = await getGold();
    await saveGold(current + amount);
  }

  // ── Skins ─────────────────────────────────────────────────────────────────

  Future<Set<String>> getOwnedSkins() async {
    final raw = await EncryptedStorage.loadString(_ownedSkinsKey);
    if (raw == null) return {'cyber_neon', 'deep_space'}; // default owned
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {'cyber_neon', 'deep_space'};
    }
  }

  Future<void> saveOwnedSkins(Set<String> skins) async {
    await EncryptedStorage.saveString(_ownedSkinsKey, jsonEncode(skins.toList()));
  }

  /// Purchase a skin. Returns true if success.
  Future<bool> purchaseSkin(String skinId, int price) async {
    final spent = await spendGold(price);
    if (!spent) return false;
    final owned = await getOwnedSkins();
    owned.add(skinId);
    await saveOwnedSkins(owned);
    return true;
  }
}
