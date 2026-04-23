/// Stub API service — future server integration point.
/// Currently all methods delegate to local repository.
/// To connect a real server: replace the body of each method with Dio calls.
///
/// Example:
///   Future<int> getGold() async {
///     final response = await _dio.get('/api/user/gold',
///         options: Options(headers: {'Authorization': 'Bearer $token'}));
///     return response.data['gold'] as int;
///   }
class ApiService {
  // Future: inject Dio here
  // final Dio _dio;
  // final String baseUrl = 'https://api.chessaimysterywar.com';

  ApiService();

  /// Health check — will ping real server in future
  Future<bool> isOnline() async => false; // local-only for now

  // Auth stubs
  Future<String?> login(String userId) async => null;
  Future<void> logout() async {}

  // Gold stubs — will sync with server
  Future<int?> syncGold(int localGold) async => null;

  // Skin purchase validation — will call server to validate
  Future<bool> validatePurchase(String skinId, int price) async => true;
}
