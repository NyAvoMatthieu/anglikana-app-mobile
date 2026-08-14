import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class OfflineMapService {
  OfflineMapService._();

  static const String storeName = 'aca_map_store';
  static bool _initialised = false;

  static bool get isSupported => !kIsWeb;

  static Future<void> initialise() async {
    if (_initialised || !isSupported) return;
    await FMTCObjectBoxBackend().initialise();
    final store = FMTCStore(storeName);
    if (!await store.manage.ready) {
      await store.manage.create();
    }
    _initialised = true;
  }

  static TileProvider get tileProvider {
    if (!isSupported) return NetworkTileProvider();
    return FMTCTileProvider.allStores(
      allStoresStrategy: BrowseStoreStrategy.readUpdateCreate,
    );
  }
}
