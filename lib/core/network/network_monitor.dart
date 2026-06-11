import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  final _connectivity = Connectivity();

  Stream<bool> get connectivityStream =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
