import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer' as developer;

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
  static const columnChannelEnableWowzaLoadBalancing = 'enable_wowza_load_balancing';
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
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    developer.log('DatabaseHelper: Creating database tables...', name: 'DatabaseHelper');
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
    developer.log('DatabaseHelper: Table $tableGenres created.', name: 'DatabaseHelper');
    await db.execute('''
          CREATE TABLE $tableVodCategories (
            $columnVodCategoryId TEXT PRIMARY KEY,
            $columnVodCategoryTitle TEXT,
            $columnVodCategoryAlias TEXT,
            $columnVodCategoryCensored INTEGER
          )
          ''');
    developer.log('DatabaseHelper: Table $tableVodCategories created.', name: 'DatabaseHelper');
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
    developer.log('DatabaseHelper: Table $tableChannels created.', name: 'DatabaseHelper');
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
    developer.log('DatabaseHelper: Table $tableChannelCmds created.', name: 'DatabaseHelper');
  }

  Future<void> clearAllData() async {
    developer.log('DatabaseHelper: Clearing all data...', name: 'DatabaseHelper');
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(tableChannelCmds);
      await txn.delete(tableChannels);
      await txn.delete(tableGenres);
      await txn.delete(tableVodCategories);
    });
    developer.log('DatabaseHelper: All data cleared.', name: 'DatabaseHelper');
  }
}