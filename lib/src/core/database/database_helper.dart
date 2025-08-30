import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:openiptv/utils/app_logger.dart'; // Added this import

class DatabaseHelper {
  static const _databaseName = "OpenIPTV.db";
  static const _databaseVersion = 1;

  // Genres Table
  static const tableGenres = 'genres';
  static const columnGenreId = 'id';
  static const columnGenreTitle = 'title';
  static const columnGenreAlias = 'alias';
  static const columnGenreCensored = 'censored';
  static const columnGenreModified = 'modified';
  static const columnGenreNumber = 'number';

  // VOD Categories Table
  static const tableVodCategories = 'vod_categories';
  static const columnVodCategoryId = 'id';
  static const columnVodCategoryTitle = 'title';
  static const columnVodCategoryAlias = 'alias';
  static const columnVodCategoryCensored = 'censored';

  // Channels Table
  static const tableChannels = 'channels';
  static const columnChannelId = 'id';
  static const columnChannelName = 'name';
  static const columnChannelNumber = 'number';
  static const columnChannelLogo = 'logo';
  static const columnChannelGenreId = 'genre_id';
  static const columnChannelXmltvId = 'xmltv_id';
  static const columnChannelEpg = 'epg';
  static const columnChannelGenresStr = 'genres_str';
  static const columnChannelCurPlaying = 'cur_playing';
  static const columnChannelStatus = 'status';
  static const columnChannelHd = 'hd';
  static const columnChannelCensored = 'censored';
  static const columnChannelFav = 'fav';
  static const columnChannelLocked = 'locked';
  static const columnChannelArchive = 'archive';
  static const columnChannelPvr = 'pvr';
  static const columnChannelEnableTvArchive = 'enable_tv_archive';
  static const columnChannelTvArchiveDuration = 'tv_archive_duration';
  static const columnChannelAllowPvr = 'allow_pvr';
  static const columnChannelAllowLocalPvr = 'allow_local_pvr';
  static const columnChannelAllowRemotePvr = 'allow_remote_pvr';
  static const columnChannelAllowLocalTimeshift = 'allow_local_timeshift';
  static const columnChannelCmd = 'cmd';
  static const columnChannelCmd1 = 'cmd_1';
  static const columnChannelCmd2 = 'cmd_2';
  static const columnChannelCmd3 = 'cmd_3';
  static const columnChannelCost = 'cost';
  static const columnChannelCount = 'count';
  static const columnChannelBaseCh = 'base_ch';
  static const columnChannelServiceId = 'service_id';
  static const columnChannelBonusCh = 'bonus_ch';
  static const columnChannelVolumeCorrection = 'volume_correction';
  static const columnChannelMcCmd = 'mc_cmd';
  static const columnChannelWowzaTmpLink = 'wowza_tmp_link';
  static const columnChannelWowzaDvr = 'wowza_dvr';
  static const columnChannelUseHttpTmpLink = 'use_http_tmp_link';
  static const columnChannelMonitoringStatus = 'monitoring_status';
  static const columnChannelEnableMonitoring = 'enable_monitoring';
  static const columnChannelEnableWowzaLoadBalancing =
      'enable_wowza_load_balancing';
  static const columnChannelCorrectTime = 'correct_time';
  static const columnChannelNimbleDvr = 'nimble_dvr';
  static const columnChannelModified = 'modified';
  static const columnChannelNginxSecureLink = 'nginx_secure_link';
  static const columnChannelOpen = 'open';
  static const columnChannelUseLoadBalancing = 'use_load_balancing';

  // Channel CMDS Table
  static const tableChannelCmds = 'channel_cmds';
  static const columnCmdId = 'id';
  static const columnCmdChannelId = 'channel_id';
  static const columnCmdPriority = 'priority';
  static const columnCmdUrl = 'url';
  static const columnCmdStatus = 'status';
  static const columnCmdUseHttpTmpLink = 'use_http_tmp_link';
  static const columnCmdWowzaTmpLink = 'wowza_tmp_link';
  static const columnCmdUserAgentFilter = 'user_agent_filter';
  static const columnCmdUseLoadBalancing = 'use_load_balancing';
  static const columnCmdChanged = 'changed';
  static const columnCmdEnableMonitoring = 'enable_monitoring';
  static const columnCmdEnableBalancerMonitoring = 'enable_balancer_monitoring';
  static const columnCmdNginxSecureLink = 'nginx_secure_link';
  static const columnCmdFlussonicTmpLink = 'flussonic_tmp_link';

  // VOD Content Table
  static const tableVodContent = 'vod_content';
  static const columnVodContentId = 'id';
  static const columnVodContentName = 'name';
  static const columnVodContentCmd = 'cmd';
  static const columnVodContentLogo = 'logo';
  static const columnVodContentDescription = 'description';
  static const columnVodContentYear = 'year';
  static const columnVodContentDirector = 'director';
  static const columnVodContentActors = 'actors';
  static const columnVodContentDuration = 'duration';
  static const columnVodContentCategoryId = 'category_id';

  // make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    appLogger.d(
      'DatabaseHelper: Creating database tables...',
    );
    await db.execute('''
          CREATE TABLE $tableGenres (
            $columnGenreId TEXT PRIMARY KEY,
            $columnGenreTitle TEXT,
            $columnGenreAlias TEXT,
            $columnGenreCensored INTEGER,
            $columnGenreModified TEXT,
            $columnGenreNumber INTEGER
          )
          ''');
    appLogger.d(
      'DatabaseHelper: Table $tableGenres created.',
    );
    await db.execute('''
          CREATE TABLE $tableVodCategories (
            $columnVodCategoryId TEXT PRIMARY KEY,
            $columnVodCategoryTitle TEXT,
            $columnVodCategoryAlias TEXT,
            $columnVodCategoryCensored INTEGER
          )
          ''');
    appLogger.d(
      'DatabaseHelper: Table $tableVodCategories created.',
    );
    await db.execute('''
          CREATE TABLE $tableChannels (
            $columnChannelId TEXT PRIMARY KEY,
            $columnChannelName TEXT,
            $columnChannelNumber TEXT,
            $columnChannelLogo TEXT,
            $columnChannelGenreId TEXT,
            $columnChannelXmltvId TEXT,
            $columnChannelEpg TEXT,
            $columnChannelGenresStr TEXT,
            $columnChannelCurPlaying TEXT,
            $columnChannelStatus INTEGER,
            $columnChannelHd INTEGER,
            $columnChannelCensored INTEGER,
            $columnChannelFav INTEGER,
            $columnChannelLocked INTEGER,
            $columnChannelArchive INTEGER,
            $columnChannelPvr INTEGER,
            $columnChannelEnableTvArchive INTEGER,
            $columnChannelTvArchiveDuration INTEGER,
            $columnChannelAllowPvr INTEGER,
            $columnChannelAllowLocalPvr INTEGER,
            $columnChannelAllowRemotePvr INTEGER,
            $columnChannelAllowLocalTimeshift INTEGER,
            $columnChannelCmd TEXT,
            $columnChannelCmd1 TEXT,
            $columnChannelCmd2 TEXT,
            $columnChannelCmd3 TEXT,
            $columnChannelCost TEXT,
            $columnChannelCount TEXT,
            $columnChannelBaseCh TEXT,
            $columnChannelServiceId TEXT,
            $columnChannelBonusCh TEXT,
            $columnChannelVolumeCorrection TEXT,
            $columnChannelMcCmd TEXT,
            $columnChannelWowzaTmpLink TEXT,
            $columnChannelWowzaDvr TEXT,
            $columnChannelUseHttpTmpLink TEXT,
            $columnChannelMonitoringStatus TEXT,
            $columnChannelEnableMonitoring INTEGER,
            $columnChannelEnableWowzaLoadBalancing INTEGER,
            $columnChannelCorrectTime TEXT,
            $columnChannelNimbleDvr TEXT,
            $columnChannelModified TEXT,
            $columnChannelNginxSecureLink TEXT,
            $columnChannelOpen INTEGER,
            $columnChannelUseLoadBalancing INTEGER,
            FOREIGN KEY ($columnChannelGenreId) REFERENCES $tableGenres ($columnGenreId)
          )
          ''');
    appLogger.d(
      'DatabaseHelper: Table $tableChannels created.',
    );
    await db.execute('''
          CREATE TABLE $tableChannelCmds (
            $columnCmdId TEXT PRIMARY KEY,
            $columnCmdChannelId TEXT,
            $columnCmdPriority INTEGER,
            $columnCmdUrl TEXT,
            $columnCmdStatus INTEGER,
            $columnCmdUseHttpTmpLink INTEGER,
            $columnCmdWowzaTmpLink INTEGER,
            $columnCmdUserAgentFilter TEXT,
            $columnCmdUseLoadBalancing INTEGER,
            $columnCmdChanged TEXT,
            $columnCmdEnableMonitoring INTEGER,
            $columnCmdEnableBalancerMonitoring INTEGER,
            $columnCmdNginxSecureLink INTEGER,
            $columnCmdFlussonicTmpLink INTEGER,
            FOREIGN KEY ($columnCmdChannelId) REFERENCES $tableChannels ($columnChannelId) ON DELETE CASCADE
          )
          ''');
    appLogger.d(
      'DatabaseHelper: Table $tableChannelCmds created.',
    );
    await db.execute('''
          CREATE TABLE $tableVodContent (
            $columnVodContentId TEXT PRIMARY KEY,
            $columnVodContentName TEXT,
            $columnVodContentCmd TEXT,
            $columnVodContentLogo TEXT,
            $columnVodContentDescription TEXT,
            $columnVodContentYear TEXT,
            $columnVodContentDirector TEXT,
            $columnVodContentActors TEXT,
            $columnVodContentDuration TEXT,
            $columnVodContentCategoryId TEXT,
            FOREIGN KEY ($columnVodContentCategoryId) REFERENCES $tableVodCategories ($columnVodCategoryId) ON DELETE CASCADE
          )
          ''');
    appLogger.d(
      'DatabaseHelper: Table $tableVodContent created.',
    );
  }

  Future<void> clearAllData() async {
    appLogger.d(
      'DatabaseHelper: Clearing all data...',
    );
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(tableChannelCmds);
      await txn.delete(tableChannels);
      await txn.delete(tableGenres);
      await txn.delete(tableVodCategories);
    });
    appLogger.d('DatabaseHelper: All data cleared.');
  }

  // --- CRUD Operations for Genres ---
  Future<int> insertGenre(Map<String, dynamic> genre) async {
    try {
      final db = await instance.database;
      final id = await db.insert(tableGenres, genre, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted genre with id: $id');
      return id;
    } catch (e) {
      appLogger.e('Error inserting genre: $e');
      return -1; // Indicate error
    }
  }

  Future<List<Map<String, dynamic>>> getAllGenres() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> genres = await db.query(tableGenres);
      appLogger.d('Retrieved ${genres.length} genres.');
      return genres;
    } catch (e) {
      appLogger.e('Error getting all genres: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGenre(String id) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> genres = await db.query(
        tableGenres,
        where: '$columnGenreId = ?',
        whereArgs: [id],
      );
      if (genres.isNotEmpty) {
        appLogger.d('Retrieved genre with id: $id');
        return genres.first;
      }
      appLogger.d('Genre with id: $id not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting genre with id $id: $e');
      return null;
    }
  }

  Future<int> updateGenre(Map<String, dynamic> genre) async {
    try {
      final db = await instance.database;
      final id = genre[columnGenreId];
      final rowsAffected = await db.update(
        tableGenres,
        genre,
        where: '$columnGenreId = ?',
        whereArgs: [id],
      );
      appLogger.d('Updated $rowsAffected rows for genre with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error updating genre with id ${genre[columnGenreId]}: $e');
      return 0; // Indicate no rows affected due to error
    }
  }

  Future<int> deleteGenre(String id) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableGenres,
        where: '$columnGenreId = ?',
        whereArgs: [id],
      );
      appLogger.d('Deleted $rowsAffected rows for genre with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error deleting genre with id $id: $e');
      return 0;
    }
  }

  // --- CRUD Operations for VOD Categories ---
  Future<int> insertVodCategory(Map<String, dynamic> vodCategory) async {
    try {
      final db = await instance.database;
      final id = await db.insert(tableVodCategories, vodCategory, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted VOD category with id: $id');
      return id;
    } catch (e) {
      appLogger.e('Error inserting VOD category: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllVodCategories() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodCategories = await db.query(tableVodCategories);
      appLogger.d('Retrieved ${vodCategories.length} VOD categories.');
      return vodCategories;
    } catch (e) {
      appLogger.e('Error getting all VOD categories: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVodCategory(String id) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodCategories = await db.query(
        tableVodCategories,
        where: '$columnVodCategoryId = ?',
        whereArgs: [id],
      );
      if (vodCategories.isNotEmpty) {
        appLogger.d('Retrieved VOD category with id: $id');
        return vodCategories.first;
      }
      appLogger.d('VOD category with id: $id not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting VOD category with id $id: $e');
      return null;
    }
  }

  Future<int> updateVodCategory(Map<String, dynamic> vodCategory) async {
    try {
      final db = await instance.database;
      final id = vodCategory[columnVodCategoryId];
      final rowsAffected = await db.update(
        tableVodCategories,
        vodCategory,
        where: '$columnVodCategoryId = ?',
        whereArgs: [id],
      );
      appLogger.d('Updated $rowsAffected rows for VOD category with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error updating VOD category with id ${vodCategory[columnVodCategoryId]}: $e');
      return 0;
    }
  }

  Future<int> deleteVodCategory(String id) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableVodCategories,
        where: '$columnVodCategoryId = ?',
        whereArgs: [id],
      );
      appLogger.d('Deleted $rowsAffected rows for VOD category with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error deleting VOD category with id $id: $e');
      return 0;
    }
  }

  // --- CRUD Operations for Channels ---
  Future<int> insertChannel(Map<String, dynamic> channel) async {
    try {
      final db = await instance.database;
      final id = await db.insert(tableChannels, channel, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted channel with id: $id');
      return id;
    } catch (e) {
      appLogger.e('Error inserting channel: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllChannels() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channels = await db.query(tableChannels);
      appLogger.d('Retrieved ${channels.length} channels.');
      return channels;
    } catch (e) {
      appLogger.e('Error getting all channels: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChannel(String id) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channels = await db.query(
        tableChannels,
        where: '$columnChannelId = ?',
        whereArgs: [id],
      );
      if (channels.isNotEmpty) {
        appLogger.d('Retrieved channel with id: $id');
        return channels.first;
      }
      appLogger.d('Channel with id: $id not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting channel with id $id: $e');
      return null;
    }
  }

  Future<int> updateChannel(Map<String, dynamic> channel) async {
    try {
      final db = await instance.database;
      final id = channel[columnChannelId];
      final rowsAffected = await db.update(
        tableChannels,
        channel,
        where: '$columnChannelId = ?',
        whereArgs: [id],
      );
      appLogger.d('Updated $rowsAffected rows for channel with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error updating channel with id ${channel[columnChannelId]}: $e');
      return 0;
    }
  }

  Future<int> deleteChannel(String id) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableChannels,
        where: '$columnChannelId = ?',
        whereArgs: [id],
      );
      appLogger.d('Deleted $rowsAffected rows for channel with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error deleting channel with id $id: $e');
      return 0;
    }
  }

  // --- CRUD Operations for Channel CMDS ---
  Future<int> insertChannelCmd(Map<String, dynamic> channelCmd) async {
    try {
      final db = await instance.database;
      final id = await db.insert(tableChannelCmds, channelCmd, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted channel command with id: $id');
      return id;
    } catch (e) {
      appLogger.e('Error inserting channel command: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllChannelCmds() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(tableChannelCmds);
      appLogger.d('Retrieved ${channelCmds.length} channel commands.');
      return channelCmds;
    } catch (e) {
      appLogger.e('Error getting all channel commands: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChannelCmd(String id) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(
        tableChannelCmds,
        where: '$columnCmdId = ?',
        whereArgs: [id],
      );
      if (channelCmds.isNotEmpty) {
        appLogger.d('Retrieved channel command with id: $id');
        return channelCmds.first;
      }
      appLogger.d('Channel command with id: $id not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting channel command with id $id: $e');
      return null;
    }
  }

  Future<int> updateChannelCmd(Map<String, dynamic> channelCmd) async {
    try {
      final db = await instance.database;
      final id = channelCmd[columnCmdId];
      final rowsAffected = await db.update(
        tableChannelCmds,
        channelCmd,
        where: '$columnCmdId = ?',
        whereArgs: [id],
      );
      appLogger.d('Updated $rowsAffected rows for channel command with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error updating channel command with id ${channelCmd[columnCmdId]}: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getChannelCmdsForChannel(String channelId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(
        tableChannelCmds,
        where: '$columnCmdChannelId = ?',
        whereArgs: [channelId],
      );
      appLogger.d('Retrieved ${channelCmds.length} channel commands for channel $channelId.');
      return channelCmds;
    } catch (e) {
      appLogger.e('Error getting channel commands for channel $channelId: $e');
      return [];
    }
  }

  // --- CRUD Operations for VOD Content ---
  Future<int> insertVodContent(Map<String, dynamic> vodContent) async {
    try {
      final db = await instance.database;
      final id = await db.insert(tableVodContent, vodContent, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted VOD content with id: $id');
      return id;
    } catch (e) {
      appLogger.e('Error inserting VOD content: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllVodContent() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(tableVodContent);
      appLogger.d('Retrieved ${vodContent.length} VOD content items.');
      return vodContent;
    } catch (e) {
      appLogger.e('Error getting all VOD content: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVodContentByCategoryId(String categoryId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(
        tableVodContent,
        where: '$columnVodContentCategoryId = ?',
        whereArgs: [categoryId],
      );
      appLogger.d('Retrieved ${vodContent.length} VOD content items for category $categoryId.');
      return vodContent;
    } catch (e) {
      appLogger.e('Error getting VOD content for category $categoryId: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVodContent(String id) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(
        tableVodContent,
        where: '$columnVodContentId = ?',
        whereArgs: [id],
      );
      if (vodContent.isNotEmpty) {
        appLogger.d('Retrieved VOD content with id: $id');
        return vodContent.first;
      }
      appLogger.d('VOD content with id: $id not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting VOD content with id $id: $e');
      return null;
    }
  }

  Future<int> updateVodContent(Map<String, dynamic> vodContent) async {
    try {
      final db = await instance.database;
      final id = vodContent[columnVodContentId];
      final rowsAffected = await db.update(
        tableVodContent,
        vodContent,
        where: '$columnVodContentId = ?',
        whereArgs: [id],
      );
      appLogger.d('Updated $rowsAffected rows for VOD content with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error updating VOD content with id ${vodContent[columnVodContentId]}: $e');
      return 0;
    }
  }

  Future<int> deleteVodContent(String id) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableVodContent,
        where: '$columnVodContentId = ?',
        whereArgs: [id],
      );
      appLogger.d('Deleted $rowsAffected rows for VOD content with id: $id');
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error deleting VOD content with id $id: $e');
      return 0;
    }
  }
}