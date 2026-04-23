/// App-wide localization strings.
/// Supports: English (en), Vietnamese (vi)
class AppStrings {
  static String _lang = 'en';

  static void setLanguage(String langCode) => _lang = langCode;
  static String get currentLang => _lang;

  static String get(String key) =>
      (_translations[_lang] ?? _translations['en']!)[key] ?? key;

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Main screen
      'app_subtitle': 'MYSTERY WAR',
      'start_game': 'START GAME',
      'store': 'STORE',
      'config': 'CONFIG',
      'start_desc': 'Normal • Mystery • Champion',
      'store_desc': 'Skins & Gold',
      'config_desc': 'Audio • Hints',
      'version': 'v1.0.0 • AI-Powered Chess Engine',

      // Mode selector
      'select_mode': 'SELECT MODE',
      'choose_battle': 'Choose Your Battle',
      'mode_normal': 'NORMAL',
      'mode_mystery': 'MYSTERY',
      'mode_champion': 'CHAMPION',
      'normal_subtitle': 'Classic Chess',
      'mystery_subtitle': 'Hidden & Surprise',
      'champion_subtitle': 'Boss Battle',
      'normal_desc': 'Standard rules. Configure players and difficulty.',
      'mystery_desc': 'Choose a mystery variant. Every move is a surprise.',
      'champion_desc': 'Face AI Champions. Progress is saved between sessions.',
      'featured': 'FEATURED',
      'begin_match': 'NEXT: SETUP',

      // Game Setup screen
      'game_setup': 'GAME SETUP',
      'configure_match': 'Configure Your Match',
      'players': 'PLAYERS',
      'one_player': '1 Player',
      'two_players': '2 Players',
      'vs_ai': 'vs AI Bot',
      'vs_friend': 'vs Friend',

      // Bot difficulty
      'bot_difficulty': 'BOT DIFFICULTY',
      'bot_elo': 'Elo Rating',
      'diff_beginner': 'Beginner',
      'diff_novice': 'Novice',
      'diff_intermediate': 'Intermediate',
      'diff_advanced': 'Advanced',
      'diff_expert': 'Expert',
      'diff_master': 'Master',
      'diff_grandmaster': 'Grandmaster',

      // Time control
      'time_control': 'TIME CONTROL',
      'unlimited': 'Unlimited',
      'unlimited_desc': 'No time pressure',
      'blitz': 'Blitz',
      'min': 'min',
      'increment': 'sec/move',

      // Mystery sub-types
      'mystery_type': 'MYSTERY TYPE',
      'hidden_identity': 'Hidden Identity (Cờ Úp)',
      'hidden_identity_desc': 'All pieces are face-down. Identity is revealed when a piece moves.',
      'fog_of_war': 'Fog of War (Dark Chess)',
      'fog_of_war_desc': 'You only see squares your pieces control. Enemy positions are hidden.',
      'blindfold': 'Blindfold Chess',
      'blindfold_desc': 'Pieces are hidden after the first 5 moves. Test your memory!',
      'double_blind': 'Double Blind',
      'double_blind_desc': 'Face-down pieces AND fog of war. The ultimate challenge.',

      // Champion
      'champion_session': 'CHAMPION SESSION',
      'champion_only_1p': 'Champion mode is single-player only.',
      'new_campaign': 'New Campaign',
      'continue_campaign': 'Continue Campaign',
      'no_save_found': 'No saved campaign found.',
      'champion_type': 'CHAMPION TYPE',
      'champion_normal': 'Champion Normal',
      'champion_normal_desc': 'Classic rules against powerful AI Champions.',
      'champion_mystery': 'Champion Mystery',
      'champion_mystery_desc': 'Hidden Identity rules against AI Champions.',

      // Start button
      'start_battle': 'START BATTLE',

      // Game screen
      'turn_white': 'WHITE',
      'turn_black': 'BLACK',
      'check_alert': 'CHECK!',
      'checkmate': 'CHECKMATE!',
      'stalemate': 'STALEMATE',
      'wins': 'WINS',
      'draw': 'DRAW',
      'play_again': 'Play Again',
      'menu': 'Menu',
      'new_game': 'New Game',
      'quit_menu': 'Quit to Menu',
      'moves': 'moves',
      'time_expired': 'Time Expired',

      // Store
      'marketplace': 'MARKETPLACE',
      'pieces_tab': 'PIECES',
      'boards_tab': 'BOARDS',
      'earn_tab': 'EARN GOLD',
      'owned': 'OWNED',
      'watch_ad': 'WATCH AD (+100 Gold)',
      'watch_ad_desc': 'Watch a short video and earn 100 Gold instantly.',
      'win_a_game': 'Win a Game',
      'win_a_game_desc': 'Earn 50 Gold per victory in any mode.',
      'daily_login': 'Daily Login',
      'daily_login_desc': 'Log in every day to receive bonus Gold.',
      'win_streak': 'Win Streak (5x)',
      'win_streak_desc': 'Win 5 games in a row for a huge reward.',

      // Settings
      'settings': 'SETTINGS',
      'configuration': 'CONFIGURATION',
      'audio': 'AUDIO',
      'bg_music': 'Background Music',
      'bg_music_desc': 'Atmospheric game soundtrack',
      'sfx': 'Sound Effects',
      'sfx_desc': 'Piece moves, captures, check alerts',
      'gameplay': 'GAMEPLAY',
      'move_hints': 'Move Hints',
      'move_hints_desc': 'Highlight best moves to help beginners',
      'app_theme': 'APP THEME',
      'language': 'LANGUAGE',
      'select_language': 'Select Language',
      'tutorial_section': 'TUTORIAL',
      'chess_beginners': 'Chess for Beginners',
      'chess_beginners_desc': 'Learn piece movement, strategy & Mystery Mode rules.',

      // Tutorial
      'tutorial': 'TUTORIAL',
      'the_board': 'The Board',
      'the_pieces': 'The Pieces',
      'check_checkmate': 'Check & Checkmate',
      'opening_strategy': 'Opening Strategy',
      'mystery_rules': 'Mystery Mode',
      'finish': 'FINISH',
      'next': 'NEXT',
      'previous': 'Previous',

      // Settings extras
      'auto_saved': 'AUTO-SAVED',
      'theme_desc': 'Applies to board and UI accent colors',
      'board_preview': 'Board colors',

      // Store extras
      'store_label': 'STORE',
      'confirm_purchase': 'Confirm Purchase',
      'confirm_buy_msg': 'Do you want to purchase',
      'for': 'for',
      'gold': 'Gold',
      'after_purchase': 'Gold remaining after purchase',
      'insufficient_gold': 'Insufficient Gold',
      'insufficient_gold_msg': 'You need more Gold to buy this item.',
      'confirm': 'CONFIRM',
      'cancel': 'Cancel',
      'equip': 'EQUIP',
      'equipped': 'EQUIPPED',
      'buy': 'BUY',
      'cannot_afford': 'Need more Gold',

      // Inventory
      'my_items': 'MY ITEMS',
      'my_items_desc': 'Owned Skins',
      'inventory': 'INVENTORY',
      'my_collection': 'My Collection',
      'no_items': 'No items yet. Visit the Store!',
      'piece_skins': 'PIECE SKINS',
      'board_skins': 'BOARD SKINS',
    },

    'vi': {
      // Main screen
      'app_subtitle': 'CHIẾN TRANH BÍ ẨN',
      'start_game': 'BẮT ĐẦU CHƠI',
      'store': 'CỬA HÀNG',
      'config': 'CÀI ĐẶT',
      'start_desc': 'Bình Thường • Bí Ẩn • Vô Địch',
      'store_desc': 'Skin & Vàng',
      'config_desc': 'Âm Thanh • Gợi Ý',
      'version': 'v1.0.0 • Cờ Vua AI',

      // Mode selector
      'select_mode': 'CHỌN CHẾ ĐỘ',
      'choose_battle': 'Chọn Trận Đấu',
      'mode_normal': 'BÌNH THƯỜNG',
      'mode_mystery': 'BÍ ẨN',
      'mode_champion': 'VÔ ĐỊCH',
      'normal_subtitle': 'Cờ Vua Cổ Điển',
      'mystery_subtitle': 'Ẩn & Bất Ngờ',
      'champion_subtitle': 'Đấu Boss',
      'normal_desc': 'Luật chuẩn. Cấu hình người chơi và độ khó.',
      'mystery_desc': 'Chọn biến thể bí ẩn. Mỗi nước đi là một bất ngờ.',
      'champion_desc': 'Đối đầu AI Vô Địch. Tiến trình được lưu giữa các phiên.',
      'featured': 'NỔI BẬT',
      'begin_match': 'TIẾP: CÀI ĐẶT',

      // Game Setup screen
      'game_setup': 'CÀI ĐẶT VÁN ĐẤU',
      'configure_match': 'Cấu Hình Trận Đấu',
      'players': 'NGƯỜI CHƠI',
      'one_player': '1 Người Chơi',
      'two_players': '2 Người Chơi',
      'vs_ai': 'vs Bot AI',
      'vs_friend': 'vs Bạn Bè',

      // Bot difficulty
      'bot_difficulty': 'ĐỘ KHÓ BOT',
      'bot_elo': 'Điểm Elo',
      'diff_beginner': 'Mới Bắt Đầu',
      'diff_novice': 'Tập Sự',
      'diff_intermediate': 'Trung Cấp',
      'diff_advanced': 'Nâng Cao',
      'diff_expert': 'Chuyên Gia',
      'diff_master': 'Cao Thủ',
      'diff_grandmaster': 'Đại Kiện Tướng',

      // Time control
      'time_control': 'KIỂM SOÁT THỜI GIAN',
      'unlimited': 'Không giới hạn',
      'unlimited_desc': 'Không áp lực thời gian',
      'blitz': 'Cờ Chớp',
      'min': 'phút',
      'increment': 'giây/nước',

      // Mystery sub-types
      'mystery_type': 'LOẠI BÍ ẨN',
      'hidden_identity': 'Cờ Úp (Ẩn Danh Tính)',
      'hidden_identity_desc': 'Toàn bộ quân úp mặt. Danh tính lộ khi quân di chuyển.',
      'fog_of_war': 'Cờ Sương Mù (Dark Chess)',
      'fog_of_war_desc': 'Chỉ thấy ô quân bạn kiểm soát. Vị trí địch bị ẩn.',
      'blindfold': 'Cờ Mù',
      'blindfold_desc': 'Quân bị ẩn sau 5 nước đi đầu. Thử thách trí nhớ!',
      'double_blind': 'Mù Tuyệt Đối',
      'double_blind_desc': 'Cờ úp KẾT HỢP sương mù. Thử thách tối thượng.',

      // Champion
      'champion_session': 'PHIÊN VÔ ĐỊCH',
      'champion_only_1p': 'Chế độ Vô Địch chỉ dành cho 1 người chơi.',
      'new_campaign': 'Chiến Dịch Mới',
      'continue_campaign': 'Tiếp Tục Chiến Dịch',
      'no_save_found': 'Không tìm thấy tiến trình đã lưu.',
      'champion_type': 'LOẠI VÔ ĐỊCH',
      'champion_normal': 'Vô Địch Bình Thường',
      'champion_normal_desc': 'Luật chuẩn đấu với AI Vô Địch mạnh.',
      'champion_mystery': 'Vô Địch Bí Ẩn',
      'champion_mystery_desc': 'Luật Cờ Úp đấu với AI Vô Địch.',

      // Start button
      'start_battle': 'BẮT ĐẦU TRẬN',

      // Game screen
      'turn_white': 'TRẮNG',
      'turn_black': 'ĐEN',
      'check_alert': 'CHIẾU!',
      'checkmate': 'CHIẾU HẾT!',
      'stalemate': 'HÒA CỜ',
      'wins': 'THẮNG',
      'draw': 'HÒA',
      'play_again': 'Chơi Lại',
      'menu': 'Menu',
      'new_game': 'Ván Mới',
      'quit_menu': 'Quay về Menu',
      'moves': 'nước',
      'time_expired': 'Hết Giờ',

      // Store
      'marketplace': 'CHỢ',
      'pieces_tab': 'QUÂN CỜ',
      'boards_tab': 'BÀN CỜ',
      'earn_tab': 'KIẾM VÀNG',
      'owned': 'ĐÃ SỞ HỮU',
      'watch_ad': 'XEM QUẢNG CÁO (+100 Vàng)',
      'watch_ad_desc': 'Xem video ngắn và nhận ngay 100 Vàng.',
      'win_a_game': 'Thắng Ván Đấu',
      'win_a_game_desc': 'Nhận 50 Vàng mỗi chiến thắng ở bất kỳ chế độ nào.',
      'daily_login': 'Đăng Nhập Hàng Ngày',
      'daily_login_desc': 'Đăng nhập mỗi ngày để nhận thưởng Vàng.',
      'win_streak': 'Chuỗi Thắng (5x)',
      'win_streak_desc': 'Thắng 5 ván liên tiếp để nhận thưởng lớn.',

      // Settings
      'settings': 'CÀI ĐẶT',
      'configuration': 'CẤU HÌNH',
      'audio': 'ÂM THANH',
      'bg_music': 'Nhạc Nền',
      'bg_music_desc': 'Nhạc nền không khí trận đấu',
      'sfx': 'Hiệu Ứng Âm Thanh',
      'sfx_desc': 'Di chuyển quân, bắt quân, cảnh báo chiếu',
      'gameplay': 'GAMEPLAY',
      'move_hints': 'Gợi Ý Nước Đi',
      'move_hints_desc': 'Đánh dấu nước đi tốt nhất cho người mới',
      'app_theme': 'GIAO DIỆN',
      'language': 'NGÔN NGỮ',
      'select_language': 'Chọn Ngôn Ngữ',
      'tutorial_section': 'HƯỚNG DẪN',
      'chess_beginners': 'Cờ Vua Cho Người Mới',
      'chess_beginners_desc': 'Học cách di chuyển quân, chiến thuật & luật Bí Ẩn.',

      // Tutorial
      'tutorial': 'HƯỚNG DẪN',
      'the_board': 'Bàn Cờ',
      'the_pieces': 'Các Quân Cờ',
      'check_checkmate': 'Chiếu & Chiếu Hết',
      'opening_strategy': 'Chiến Lược Khai Cục',
      'mystery_rules': 'Chế Độ Bí Ẩn',
      'finish': 'HOÀN THÀNH',
      'next': 'TIẾP',
      'previous': 'Trước',

      // Settings extras
      'auto_saved': 'TỰ ĐỘNG LƯU',
      'theme_desc': 'Áp dụng cho bàn cờ và màu sắc giao diện',
      'board_preview': 'Màu bàn cờ',

      // Store extras
      'store_label': 'CỬA HÀNG',
      'confirm_purchase': 'Xác Nhận Mua',
      'confirm_buy_msg': 'Bạn có muốn mua',
      'for': 'với giá',
      'gold': 'Vàng',
      'after_purchase': 'Vàng còn lại sau khi mua',
      'insufficient_gold': 'Không Đủ Vàng',
      'insufficient_gold_msg': 'Bạn cần thêm Vàng để mua vật phẩm này.',
      'confirm': 'XÁC NHẬN',
      'cancel': 'Hủy',
      'equip': 'TRANG BỊ',
      'equipped': 'ĐANG DÙNG',
      'buy': 'MUA',
      'cannot_afford': 'Không đủ Vàng',

      // Inventory
      'my_items': 'VẬT PHẨM',
      'my_items_desc': 'Skin Đã Sở Hữu',
      'inventory': 'KHO VẬT PHẨM',
      'my_collection': 'Bộ Sưu Tập',
      'no_items': 'Chưa có vật phẩm. Ghé Cửa Hàng nhé!',
      'piece_skins': 'SKIN QUÂN CỜ',
      'board_skins': 'SKIN BÀN CỜ',
    },
  };

  static List<Map<String, String>> get availableLanguages => [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
  ];
}
