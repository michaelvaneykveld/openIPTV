import 'package:openiptv/src/core/models/channel_override.dart';
import 'package:openiptv/src/core/models/recording.dart';
import 'package:openiptv/src/core/models/reminder.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:openiptv/utils/app_logger.dart'; // Added this import

class DatabaseHelper {
  static const _databaseName = "OpenIPTV.db";
  static const _databaseVersion = 4;

  static const columnPortalId = 'portal_id';

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

  // Channel Overrides Table
  static const tableChannelOverrides = 'channel_overrides';
  static const columnOverrideChannelId = 'channel_id';
  static const columnOverrideIsHidden = 'is_hidden';
  static const columnOverrideCustomName = 'custom_name';
  static const columnOverrideCustomGroup = 'custom_group';
  static const columnOverridePosition = 'position';

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
  static const columnChannelGroupTitle = 'group_title';
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

  // Series Table
  static const tableSeries = 'series';
  static const columnSeriesId = 'id';
  static const columnSeriesName = 'name';
  static const columnSeriesLogo = 'logo';
  static const columnSeriesDescription = 'description';
  static const columnSeriesYear = 'year';
  static const columnSeriesDirector = 'director';
  static const columnSeriesActors = 'actors';
  static const columnSeriesCmd = 'cmd';
  static const columnSeriesDuration = 'duration';
  static const columnSeriesCategoryId = 'category_id';

  // EPG Table
  static const tableEpg = 'epg';
  static const columnEpgId = 'id';
  static const columnEpgChannelId = 'channel_id';
  static const columnEpgStart = 'start';
  static const columnEpgStop = 'stop';
  static const columnEpgTitle = 'title';
  static const columnEpgDescription = 'description';

  // Recordings Table
  static const tableRecordings = 'recordings';
  static const columnRecordingId = 'id';
  static const columnRecordingChannelId = 'channel_id';
  static const columnRecordingTitle = 'title';
  static const columnRecordingStartTime = 'start_time';
  static const columnRecordingEndTime = 'end_time';
  static const columnRecordingStatus = 'status';
  static const columnRecordingFilePath = 'file_path';
  static const columnRecordingCreatedAt = 'created_at';

  // Reminders Table
  static const tableReminders = 'reminders';
  static const columnReminderId = 'id';
  static const columnReminderChannelId = 'channel_id';
  static const columnReminderProgramTitle = 'program_title';
  static const columnReminderStartTime = 'start_time';
  static const columnReminderNotificationId = 'notification_id';
  static const columnReminderCreatedAt = 'created_at';

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
      onUpgrade: _onUpgrade,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    appLogger.d('DatabaseHelper: Creating database tables...');
    await db.execute('''
          CREATE TABLE $tableGenres (
            $columnGenreId TEXT,
            $columnPortalId TEXT NOT NULL,
            $columnGenreTitle TEXT,
            $columnGenreAlias TEXT,
            $columnGenreCensored INTEGER,
            $columnGenreModified TEXT,
            $columnGenreNumber INTEGER,
            PRIMARY KEY ($columnGenreId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableGenres created.');
    await db.execute('''
          CREATE TABLE $tableVodCategories (
            $columnVodCategoryId TEXT,
            $columnPortalId TEXT NOT NULL,
            $columnVodCategoryTitle TEXT,
            $columnVodCategoryAlias TEXT,
            $columnVodCategoryCensored INTEGER,
            PRIMARY KEY ($columnVodCategoryId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableVodCategories created.');
    await db.execute('''
          CREATE TABLE $tableChannels (
            $columnChannelId TEXT,
            $columnPortalId TEXT NOT NULL,
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
            $columnChannelGroupTitle TEXT, 
            PRIMARY KEY ($columnChannelId, $columnPortalId),
            FOREIGN KEY ($columnChannelGenreId, $columnPortalId) REFERENCES $tableGenres ($columnGenreId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableChannels created.');
    await db.execute('''
          CREATE TABLE $tableChannelOverrides (
            $columnPortalId TEXT NOT NULL,
            $columnOverrideChannelId TEXT NOT NULL,
            $columnOverrideIsHidden INTEGER DEFAULT 0,
            $columnOverrideCustomName TEXT,
            $columnOverrideCustomGroup TEXT,
            $columnOverridePosition INTEGER,
            PRIMARY KEY ($columnPortalId, $columnOverrideChannelId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableChannelOverrides created.');
    await db.execute('''
          CREATE TABLE $tableChannelCmds (
            $columnCmdId TEXT,
            $columnPortalId TEXT NOT NULL,
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
            PRIMARY KEY ($columnCmdId, $columnPortalId),
            FOREIGN KEY ($columnCmdChannelId, $columnPortalId) REFERENCES $tableChannels ($columnChannelId, $columnPortalId) ON DELETE CASCADE
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableChannelCmds created.');
    await db.execute('''
          CREATE TABLE $tableVodContent (
            $columnVodContentId TEXT,
            $columnPortalId TEXT NOT NULL,
            $columnVodContentName TEXT,
            $columnVodContentCmd TEXT,
            $columnVodContentLogo TEXT,
            $columnVodContentDescription TEXT,
            $columnVodContentYear TEXT,
            $columnVodContentDirector TEXT,
            $columnVodContentActors TEXT,
            $columnVodContentDuration TEXT,
            $columnVodContentCategoryId TEXT,
            PRIMARY KEY ($columnVodContentId, $columnPortalId),
            FOREIGN KEY ($columnVodContentCategoryId, $columnPortalId) REFERENCES $tableVodCategories ($columnVodCategoryId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableVodContent created.');
    await db.execute('''
          CREATE TABLE $tableSeries (
            $columnSeriesId TEXT,
            $columnPortalId TEXT NOT NULL,
            $columnSeriesName TEXT,
            $columnSeriesLogo TEXT,
            $columnSeriesDescription TEXT,
            $columnSeriesYear TEXT,
            $columnSeriesDirector TEXT,
            $columnSeriesActors TEXT,
            $columnSeriesCmd TEXT,
            $columnSeriesDuration TEXT,
            $columnSeriesCategoryId TEXT,
            PRIMARY KEY ($columnSeriesId, $columnPortalId),
            FOREIGN KEY ($columnSeriesCategoryId, $columnPortalId) REFERENCES $tableVodCategories ($columnVodCategoryId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableSeries created.');
    await db.execute('''
          CREATE TABLE $tableEpg (
            $columnEpgId TEXT,
            $columnEpgChannelId TEXT,
            $columnEpgStart INTEGER,
            $columnEpgStop INTEGER,
            $columnEpgTitle TEXT,
            $columnEpgDescription TEXT,
            $columnPortalId TEXT NOT NULL,
            PRIMARY KEY ($columnEpgId, $columnPortalId)
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableEpg created.');
    await db.execute('''
          CREATE TABLE $tableRecordings (
            $columnRecordingId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPortalId TEXT NOT NULL,
            $columnRecordingChannelId TEXT NOT NULL,
            $columnRecordingTitle TEXT,
            $columnRecordingStartTime INTEGER NOT NULL,
            $columnRecordingEndTime INTEGER,
            $columnRecordingStatus INTEGER NOT NULL,
            $columnRecordingFilePath TEXT,
            $columnRecordingCreatedAt INTEGER NOT NULL
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableRecordings created.');
    await db.execute('''
          CREATE TABLE $tableReminders (
            $columnReminderId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPortalId TEXT NOT NULL,
            $columnReminderChannelId TEXT NOT NULL,
            $columnReminderProgramTitle TEXT,
            $columnReminderStartTime INTEGER NOT NULL,
            $columnReminderNotificationId INTEGER,
            $columnReminderCreatedAt INTEGER NOT NULL
          )
          ''');
    appLogger.d('DatabaseHelper: Table $tableReminders created.');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      appLogger.d('DatabaseHelper: Applying upgrade to version 2');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableChannelOverrides (
            $columnPortalId TEXT NOT NULL,
            $columnOverrideChannelId TEXT NOT NULL,
            $columnOverrideIsHidden INTEGER DEFAULT 0,
            $columnOverrideCustomName TEXT,
            $columnOverrideCustomGroup TEXT,
            $columnOverridePosition INTEGER,
            PRIMARY KEY ($columnPortalId, $columnOverrideChannelId)
          )
          ''');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableRecordings (
            $columnRecordingId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPortalId TEXT NOT NULL,
            $columnRecordingChannelId TEXT NOT NULL,
            $columnRecordingTitle TEXT,
            $columnRecordingStartTime INTEGER NOT NULL,
            $columnRecordingEndTime INTEGER,
            $columnRecordingStatus INTEGER NOT NULL,
            $columnRecordingFilePath TEXT,
            $columnRecordingCreatedAt INTEGER NOT NULL
          )
          ''');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableReminders (
            $columnReminderId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnPortalId TEXT NOT NULL,
            $columnReminderChannelId TEXT NOT NULL,
            $columnReminderProgramTitle TEXT,
            $columnReminderStartTime INTEGER NOT NULL,
            $columnReminderNotificationId INTEGER,
            $columnReminderCreatedAt INTEGER NOT NULL
          )
          ''');
    }
    if (oldVersion < 3) {
      appLogger.d('DatabaseHelper: Applying upgrade to version 3');
      await db.execute('DROP TABLE IF EXISTS $tableSeries');
      await db.execute('DROP TABLE IF EXISTS $tableEpg');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableSeries (
            $columnSeriesId TEXT,
            $columnPortalId TEXT NOT NULL,
            $columnSeriesName TEXT,
            $columnSeriesLogo TEXT,
            $columnSeriesDescription TEXT,
            $columnSeriesYear TEXT,
            $columnSeriesDirector TEXT,
            $columnSeriesActors TEXT,
            $columnSeriesCmd TEXT,
            $columnSeriesDuration TEXT,
            $columnSeriesCategoryId TEXT,
            PRIMARY KEY ($columnSeriesId, $columnPortalId),
            FOREIGN KEY ($columnSeriesCategoryId, $columnPortalId) REFERENCES $tableVodCategories ($columnVodCategoryId, $columnPortalId)
          )
          ''');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableEpg (
            $columnEpgId TEXT,
            $columnEpgChannelId TEXT,
            $columnEpgStart INTEGER,
            $columnEpgStop INTEGER,
            $columnEpgTitle TEXT,
            $columnEpgDescription TEXT,
            $columnPortalId TEXT NOT NULL,
            PRIMARY KEY ($columnEpgId, $columnPortalId)
          )
          ''');
    }
    if (oldVersion < 4) {
      appLogger.d('DatabaseHelper: Applying upgrade to version 4');
      await db.execute('DROP TABLE IF EXISTS $tableChannelCmds');
      await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableChannelCmds (
            $columnCmdId TEXT,
            $columnPortalId TEXT NOT NULL,
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
            PRIMARY KEY ($columnCmdId, $columnPortalId),
            FOREIGN KEY ($columnCmdChannelId, $columnPortalId) REFERENCES $tableChannels ($columnChannelId, $columnPortalId) ON DELETE CASCADE
          )
          ''');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSeries(String portalId) async {
    try {
      final db = await instance.database;
      return await db.query(
        tableSeries,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
    } catch (e) {
      appLogger.e('Error getting all series for portal $portalId', error: e);
      return [];
    }
  }

  Future<void> clearAllData(String portalId) async {
    appLogger.d('DatabaseHelper: Clearing data for portal: $portalId...');
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        tableChannelCmds,
        where:
            '$columnCmdChannelId IN (SELECT $columnChannelId FROM $tableChannels WHERE $columnPortalId = ?)',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableChannels,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableGenres,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableVodCategories,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableVodContent,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableSeries,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableEpg,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      ); // Added EPG table to clear
    });
    appLogger.d('DatabaseHelper: All data cleared for portal: $portalId.');
  }

  Future<void> clearChannelData(String portalId) async {
    appLogger.d(
      'DatabaseHelper: Clearing channel data for portal: $portalId...',
    );
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        tableChannelCmds,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      await txn.delete(
        tableChannels,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
    });
    appLogger.d('DatabaseHelper: Channel data cleared for portal: $portalId.');
  }

  // --- CRUD Operations for Genres ---
  Future<int> insertGenre(Map<String, dynamic> genre, String portalId) async {
    try {
      appLogger.d('Inserting genre: $genre for portal: $portalId');
      final db = await instance.database;
      final id = await db.insert(tableGenres, {
        ...genre,
        columnPortalId: portalId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted genre with id: $id for portal: $portalId');
      return id;
    } catch (e) {
      appLogger.e('Error inserting genre for portal $portalId', error: e);
      return -1; // Indicate error
    }
  }

  Future<List<Map<String, dynamic>>> getAllGenres(String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> genres = await db.query(
        tableGenres,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      appLogger.d('Retrieved ${genres.length} genres for portal: $portalId');
      if (genres.isNotEmpty) {
        appLogger.d('First genre: ${genres.first}');
      }
      return genres;
    } catch (e) {
      appLogger.e('Error getting all genres for portal $portalId', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGenre(String id, String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> genres = await db.query(
        tableGenres,
        where: '$columnGenreId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      if (genres.isNotEmpty) {
        appLogger.d('Retrieved genre with id: $id for portal: $portalId');
        return genres.first;
      }
      appLogger.d('Genre with id: $id for portal: $portalId not found.');
      return null;
    } catch (e) {
      appLogger.e(
        'Error getting genre with id $id for portal $portalId',
        error: e,
      );
      return null;
    }
  }

  Future<int> updateGenre(Map<String, dynamic> genre, String portalId) async {
    try {
      appLogger.d('Updating genre: $genre for portal: $portalId');
      final db = await instance.database;
      final id = genre[columnGenreId];
      final rowsAffected = await db.update(
        tableGenres,
        genre,
        where: '$columnGenreId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Updated $rowsAffected rows for genre with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error updating genre with id ${genre[columnGenreId]} for portal $portalId',
        error: e,
      );
      return 0; // Indicate no rows affected due to error
    }
  }

  Future<int> deleteGenre(String id, String portalId) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableGenres,
        where: '$columnGenreId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Deleted $rowsAffected rows for genre with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e('Error deleting genre with id $id for portal $portalId: $e');
      return 0;
    }
  }

  // --- CRUD Operations for VOD Categories ---
  Future<int> insertVodCategory(
    Map<String, dynamic> vodCategory,
    String portalId,
  ) async {
    try {
      appLogger.d('Inserting VOD category: $vodCategory for portal: $portalId');
      final db = await instance.database;
      final id = await db.insert(tableVodCategories, {
        ...vodCategory,
        columnPortalId: portalId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted VOD category with id: $id for portal: $portalId');
      return id;
    } catch (e) {
      appLogger.e('Error inserting VOD category for portal $portalId: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllVodCategories(
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodCategories = await db.query(
        tableVodCategories,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      appLogger.d(
        'Retrieved ${vodCategories.length} VOD categories for portal: $portalId',
      );
      if (vodCategories.isNotEmpty) {
        appLogger.d('First VOD category: ${vodCategories.first}');
      }
      return vodCategories;
    } catch (e) {
      appLogger.e('Error getting all VOD categories for portal $portalId: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVodCategory(
    String id,
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodCategories = await db.query(
        tableVodCategories,
        where: '$columnVodCategoryId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      if (vodCategories.isNotEmpty) {
        appLogger.d(
          'Retrieved VOD category with id: $id for portal: $portalId',
        );
        return vodCategories.first;
      }
      appLogger.d('VOD category with id: $id for portal: $portalId not found.');
      return null;
    } catch (e) {
      appLogger.e(
        'Error getting VOD category with id $id for portal $portalId: $e',
      );
      return null;
    }
  }

  Future<int> updateVodCategory(
    Map<String, dynamic> vodCategory,
    String portalId,
  ) async {
    try {
      appLogger.d('Updating VOD category: $vodCategory for portal: $portalId');
      final db = await instance.database;
      final id = vodCategory[columnVodCategoryId];
      final rowsAffected = await db.update(
        tableVodCategories,
        vodCategory,
        where: '$columnVodCategoryId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Updated $rowsAffected rows for VOD category with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error updating VOD category with id ${vodCategory[columnVodCategoryId]} for portal $portalId: $e',
      );
      return 0;
    }
  }

  Future<int> deleteVodCategory(String id, String portalId) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableVodCategories,
        where: '$columnVodCategoryId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Deleted $rowsAffected rows for VOD category with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error deleting VOD category with id $id for portal $portalId: $e',
      );
      return 0;
    }
  }

  // --- CRUD Operations for Channels ---
  Future<int> insertChannel(
    Map<String, dynamic> channel,
    String portalId,
  ) async {
    try {
      appLogger.d('Inserting channel: $channel for portal: $portalId');
      final db = await instance.database;
      final id = await db.insert(tableChannels, {
        ...channel,
        columnPortalId: portalId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted channel with id: $id for portal: $portalId');
      return id;
    } catch (e) {
      appLogger.e('Error inserting channel for portal $portalId: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllChannels(String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channels = await db.query(
        tableChannels,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      appLogger.d(
        'Retrieved ${channels.length} channels for portal: $portalId',
      );
      if (channels.isNotEmpty) {
        appLogger.d('First channel: ${channels.first}');
      }
      return channels;
    } catch (e) {
      appLogger.e('Error getting all channels for portal $portalId: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChannel(String id, String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channels = await db.query(
        tableChannels,
        where: '$columnChannelId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      if (channels.isNotEmpty) {
        appLogger.d('Retrieved channel with id: $id for portal: $portalId');
        return channels.first;
      }
      appLogger.d('Channel with id: $id for portal: $portalId not found.');
      return null;
    } catch (e) {
      appLogger.e('Error getting channel with id $id for portal $portalId: $e');
      return null;
    }
  }

  Future<int> updateChannel(
    Map<String, dynamic> channel,
    String portalId,
  ) async {
    try {
      appLogger.d('Updating channel: $channel for portal: $portalId');
      final db = await instance.database;
      final id = channel[columnChannelId];
      final rowsAffected = await db.update(
        tableChannels,
        channel,
        where: '$columnChannelId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Updated $rowsAffected rows for channel with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error updating channel with id ${channel[columnChannelId]} for portal $portalId: $e',
      );
      return 0;
    }
  }

  Future<int> deleteChannel(String id, String portalId) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableChannels,
        where: '$columnChannelId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Deleted $rowsAffected rows for channel with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error deleting channel with id $id for portal $portalId: $e',
      );
      return 0;
    }
  }

  // --- CRUD Operations for Channel CMDS ---
  Future<int> insertChannelCmd(
    Map<String, dynamic> channelCmd,
    String portalId,
  ) async {
    try {
      appLogger.d(
        'Inserting channel command: $channelCmd for portal: $portalId',
      );
      final db = await instance.database;
      final id = await db.insert(tableChannelCmds, {
        ...channelCmd,
        columnPortalId: portalId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d(
        'Inserted channel command with id: $id for portal: $portalId',
      );
      return id;
    } catch (e) {
      appLogger.e('Error inserting channel command for portal $portalId: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllChannelCmds(String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(
        tableChannelCmds,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      appLogger.d(
        'Retrieved ${channelCmds.length} channel commands for portal: $portalId',
      );
      if (channelCmds.isNotEmpty) {
        appLogger.d('First channel command: ${channelCmds.first}');
      }
      return channelCmds;
    } catch (e) {
      appLogger.e(
        'Error getting all channel commands for portal $portalId: $e',
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> getChannelCmd(
    String id,
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(
        tableChannelCmds,
        where: '$columnCmdId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      if (channelCmds.isNotEmpty) {
        appLogger.d(
          'Retrieved channel command with id: $id for portal: $portalId',
        );
        return channelCmds.first;
      }
      appLogger.d(
        'Channel command with id: $id for portal: $portalId not found.',
      );
      return null;
    } catch (e) {
      appLogger.e(
        'Error getting channel command with id $id for portal $portalId: $e',
      );
      return null;
    }
  }

  Future<int> updateChannelCmd(
    Map<String, dynamic> channelCmd,
    String portalId,
  ) async {
    try {
      appLogger.d(
        'Updating channel command: $channelCmd for portal: $portalId',
      );
      final db = await instance.database;
      final id = channelCmd[columnCmdId];
      final rowsAffected = await db.update(
        tableChannelCmds,
        channelCmd,
        where: '$columnCmdId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Updated $rowsAffected rows for channel command with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error updating channel command with id ${channelCmd[columnCmdId]} for portal $portalId: $e',
      );
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getChannelCmdsForChannel(
    String channelId,
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> channelCmds = await db.query(
        tableChannelCmds,
        where: '$columnCmdChannelId = ? AND $columnPortalId = ?',
        whereArgs: [channelId, portalId],
      );
      appLogger.d(
        'Retrieved ${channelCmds.length} channel commands for channel $channelId for portal: $portalId.',
      );
      if (channelCmds.isNotEmpty) {
        appLogger.d(
          'First channel command for channel $channelId: ${channelCmds.first}',
        );
      }
      return channelCmds;
    } catch (e) {
      appLogger.e(
        'Error getting channel commands for channel $channelId for portal $portalId: $e',
      );
      return [];
    }
  }

  // --- CRUD Operations for VOD Content ---
  Future<int> insertVodContent(
    Map<String, dynamic> vodContent,
    String portalId,
  ) async {
    try {
      appLogger.d('Inserting VOD content: $vodContent for portal: $portalId');
      final db = await instance.database;
      final id = await db.insert(tableVodContent, {
        ...vodContent,
        columnPortalId: portalId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      appLogger.d('Inserted VOD content with id: $id for portal: $portalId');
      return id;
    } catch (e) {
      appLogger.e('Error inserting VOD content for portal $portalId: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllVodContent(String portalId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(
        tableVodContent,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
      );
      appLogger.d(
        'Retrieved ${vodContent.length} VOD content items for portal: $portalId.',
      );
      if (vodContent.isNotEmpty) {
        appLogger.d('First VOD content: ${vodContent.first}');
      }
      return vodContent;
    } catch (e) {
      appLogger.e('Error getting all VOD content for portal $portalId: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getVodContentByCategoryId(
    String categoryId,
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(
        tableVodContent,
        where: '$columnVodContentCategoryId = ? AND $columnPortalId = ?',
        whereArgs: [categoryId, portalId],
      );
      appLogger.d(
        'Retrieved ${vodContent.length} VOD content items for category $categoryId for portal: $portalId.',
      );
      if (vodContent.isNotEmpty) {
        appLogger.d(
          'First VOD content for category $categoryId: ${vodContent.first}',
        );
      }
      return vodContent;
    } catch (e) {
      appLogger.e(
        'Error getting VOD content for category $categoryId for portal $portalId: $e',
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> getVodContent(
    String id,
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> vodContent = await db.query(
        tableVodContent,
        where: '$columnVodContentId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      if (vodContent.isNotEmpty) {
        appLogger.d('Retrieved VOD content with id: $id for portal: $portalId');
        return vodContent.first;
      }
      appLogger.d('VOD content with id: $id for portal: $portalId not found.');
      return null;
    } catch (e) {
      appLogger.e(
        'Error getting VOD content with id $id for portal $portalId: $e',
      );
      return null;
    }
  }

  Future<int> updateVodContent(
    Map<String, dynamic> vodContent,
    String portalId,
  ) async {
    try {
      appLogger.d('Updating VOD content: $vodContent for portal: $portalId');
      final db = await instance.database;
      final id = vodContent[columnVodContentId];
      final rowsAffected = await db.update(
        tableVodContent,
        vodContent,
        where: '$columnVodContentId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Updated $rowsAffected rows for VOD content with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error updating VOD content with id ${vodContent[columnVodContentId]} for portal $portalId: $e',
      );
      return 0;
    }
  }

  Future<int> deleteVodContent(String id, String portalId) async {
    try {
      final db = await instance.database;
      final rowsAffected = await db.delete(
        tableVodContent,
        where: '$columnVodContentId = ? AND $columnPortalId = ?',
        whereArgs: [id, portalId],
      );
      appLogger.d(
        'Deleted $rowsAffected rows for VOD content with id: $id for portal: $portalId',
      );
      return rowsAffected;
    } catch (e) {
      appLogger.e(
        'Error deleting VOD content with id $id for portal $portalId',
        error: e,
      );
      return 0;
    }
  }

  // --- CRUD Operations for Channel Overrides ---
  Future<List<Map<String, dynamic>>> getChannelOverrides(
    String portalId,
  ) async {
    try {
      final db = await instance.database;
      return await db.query(
        tableChannelOverrides,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
        orderBy:
            'CASE WHEN $columnOverridePosition IS NULL THEN 1 ELSE 0 END, $columnOverridePosition ASC, $columnOverrideCustomName ASC',
      );
    } catch (e) {
      appLogger.e('Error getting channel overrides for portal $portalId: $e');
      return [];
    }
  }

  Future<void> upsertChannelOverride(ChannelOverride override) async {
    try {
      final db = await instance.database;
      await db.insert(
        tableChannelOverrides,
        override.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      appLogger.e(
        'Error saving channel override for channel ${override.channelId} (${override.portalId}): $e',
      );
    }
  }

  Future<void> deleteChannelOverride(String portalId, String channelId) async {
    try {
      final db = await instance.database;
      await db.delete(
        tableChannelOverrides,
        where: '$columnPortalId = ? AND $columnOverrideChannelId = ?',
        whereArgs: [portalId, channelId],
      );
    } catch (e) {
      appLogger.e(
        'Error deleting channel override for channel $channelId ($portalId): $e',
      );
    }
  }

  Future<void> updateChannelOverridePositions(
    String portalId,
    List<ChannelOverride> orderedOverrides,
  ) async {
    try {
      final db = await instance.database;
      await db.transaction((txn) async {
        for (var i = 0; i < orderedOverrides.length; i++) {
          final override = orderedOverrides[i].copyWith(position: i);
          await txn.update(
            tableChannelOverrides,
            {columnOverridePosition: override.position},
            where: '$columnPortalId = ? AND $columnOverrideChannelId = ?',
            whereArgs: [portalId, override.channelId],
          );
        }
      });
    } catch (e) {
      appLogger.e('Error updating override positions for $portalId: $e');
    }
  }

  // --- CRUD Operations for Recordings ---
  Future<int> insertRecording(Recording recording) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableRecordings,
        recording.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      appLogger.e('Error inserting recording ${recording.title}: $e');
      return -1;
    }
  }

  Future<int> updateRecording(Recording recording) async {
    try {
      final db = await instance.database;
      return await db.update(
        tableRecordings,
        recording.toMap(),
        where: '$columnRecordingId = ?',
        whereArgs: [recording.id],
      );
    } catch (e) {
      appLogger.e('Error updating recording ${recording.id}: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllRecordings(String portalId) async {
    try {
      final db = await instance.database;
      return await db.query(
        tableRecordings,
        where: '$columnPortalId = ?',
        whereArgs: [portalId],
        orderBy: '$columnRecordingStartTime DESC',
      );
    } catch (e) {
      appLogger.e('Error fetching recordings for portal $portalId: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRecordings(DateTime now) async {
    try {
      final db = await instance.database;
      return await db.query(
        tableRecordings,
        where:
            '$columnRecordingStatus IN (?, ?) AND $columnRecordingStartTime <= ?',
        whereArgs: [
          RecordingStatus.scheduled.index,
          RecordingStatus.recording.index,
          now.millisecondsSinceEpoch,
        ],
        orderBy: '$columnRecordingStartTime ASC',
      );
    } catch (e) {
      appLogger.e('Error fetching pending recordings: $e');
      return [];
    }
  }

  Future<void> deleteRecording(int id) async {
    try {
      final db = await instance.database;
      await db.delete(
        tableRecordings,
        where: '$columnRecordingId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      appLogger.e('Error deleting recording $id: $e');
    }
  }

  // --- CRUD Operations for Reminders ---
  Future<int> insertReminder(Reminder reminder) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableReminders,
        reminder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      appLogger.e('Error inserting reminder ${reminder.programTitle}: $e');
      return -1;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      final db = await instance.database;
      await db.delete(
        tableReminders,
        where: '$columnReminderId = ?',
        whereArgs: [id],
      );
    } catch (e) {
      appLogger.e('Error deleting reminder $id: $e');
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      final db = await instance.database;
      await db.update(
        tableReminders,
        reminder.toMap(),
        where: '$columnReminderId = ?',
        whereArgs: [reminder.id],
      );
    } catch (e) {
      appLogger.e('Error updating reminder ${reminder.id}: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingReminders(DateTime now) async {
    try {
      final db = await instance.database;
      return await db.query(
        tableReminders,
        where: '$columnReminderStartTime >= ?',
        whereArgs: [now.millisecondsSinceEpoch],
        orderBy: '$columnReminderStartTime ASC',
      );
    } catch (e) {
      appLogger.e('Error fetching reminders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getReminderById(int id) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableReminders,
        where: '$columnReminderId = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first;
      }
    } catch (e) {
      appLogger.e('Error fetching reminder $id: $e');
    }
    return null;
  }

  // --- CRUD Operations for EPG ---
  Future<void> insertEpgProgrammes(
    List<Map<String, dynamic>> programmes, {
    required String portalId,
  }) async {
    final db = await instance.database;
    appLogger.d(
      'Inserting ${programmes.length} EPG programmes for portal: $portalId',
    );
    if (programmes.isNotEmpty) {
      appLogger.d('First EPG programme: ${programmes.first}');
    }
    await db.transaction((txn) async {
      for (final programme in programmes) {
        await txn.insert(tableEpg, {
          ...programme,
          columnPortalId: portalId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    appLogger.d(
      'Inserted ${programmes.length} EPG programmes for portal: $portalId',
    );
  }

  Future<List<Map<String, dynamic>>> getEpgForChannel(
    String channelId,
    String portalId,
  ) async {
    final db = await instance.database;
    final maps = await db.query(
      tableEpg,
      where: '$columnEpgChannelId = ? AND $columnPortalId = ?',
      whereArgs: [channelId, portalId],
      orderBy: '$columnEpgStart ASC',
    );
    appLogger.d(
      'Retrieved ${maps.length} EPG programmes for channel $channelId and portal: $portalId',
    );
    if (maps.isNotEmpty) {
      appLogger.d('First EPG programme for channel $channelId: ${maps.first}');
    }
    return maps;
  }

  // --- Debug Methods ---
  Future<List<String>> getTables() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> tables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
    );
    return tables.map((table) => table['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await instance.database;
    return await db.query(tableName);
  }
}
