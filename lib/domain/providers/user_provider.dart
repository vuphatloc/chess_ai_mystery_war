import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/language_provider.dart';

final _userRepo = UserRepository();

// ── Gold Provider ─────────────────────────────────────────────────────────

final goldProvider = StateNotifierProvider<GoldNotifier, int>((ref) {
  return GoldNotifier();
});

class GoldNotifier extends StateNotifier<int> {
  GoldNotifier() : super(1250) { _load(); }

  Future<void> _load() async {
    state = await _userRepo.getGold();
  }

  Future<bool> spend(int amount) async {
    if (state < amount) return false;
    state -= amount;
    await _userRepo.saveGold(state);
    return true;
  }

  Future<void> add(int amount) async {
    state += amount;
    await _userRepo.saveGold(state);
  }
}

// ── Owned Skins Provider ──────────────────────────────────────────────────

final ownedSkinsProvider = StateNotifierProvider<OwnedSkinsNotifier, Set<String>>((ref) {
  return OwnedSkinsNotifier();
});

class OwnedSkinsNotifier extends StateNotifier<Set<String>> {
  OwnedSkinsNotifier() : super({'cyber_neon', 'deep_space'}) { _load(); }

  Future<void> _load() async {
    state = await _userRepo.getOwnedSkins();
  }

  bool owns(String skinId) => state.contains(skinId);

  Future<bool> purchase(String skinId, int price, GoldNotifier goldNotifier) async {
    if (!await goldNotifier.spend(price)) return false;
    state = {...state, skinId};
    await _userRepo.saveOwnedSkins(state);
    return true;
  }
}

// ── User Settings Provider ────────────────────────────────────────────────

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettings>((ref) {
  return UserSettingsNotifier(ref);
});

class UserSettingsNotifier extends StateNotifier<UserSettings> {
  final Ref _ref;
  UserSettingsNotifier(this._ref) : super(const UserSettings()) { _load(); }

  Future<void> _load() async {
    final settings = await _userRepo.getSettings();
    state = settings;
    // Sync language provider
    AppStrings.setLanguage(settings.language);
    _ref.read(languageProvider.notifier).setLanguage(settings.language);
  }

  Future<void> update(UserSettings newSettings) async {
    state = newSettings;
    await _userRepo.saveSettings(newSettings);
    // Sync language
    AppStrings.setLanguage(newSettings.language);
    await _ref.read(languageProvider.notifier).setLanguage(newSettings.language);
  }
}

// ── Active Skin Providers (computed from settings) ────────────────────────

final activePieceSkinProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).activePieceSkinId;
});

final activeBoardSkinProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).activeBoardSkinId;
});

final activeThemeIndexProvider = Provider<int>((ref) {
  return ref.watch(userSettingsProvider).themeIndex;
});
