import 'package:idb_shim/idb_browser.dart';

import 'indexed_db_local_repository_backend.dart';
import 'local_repository_backend.dart';

LocalRepositoryBackend createLocalRepositoryBackend() =>
    IndexedDbLocalRepositoryBackend(factory: idbFactoryBrowser);
