// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GameTracker';

  @override
  String get appBarTitle => '🎲 GameTracker';

  @override
  String get navTooltipStats => 'Statistics';

  @override
  String get navTooltipGroups => 'Groups';

  @override
  String get navTooltipDrive => 'Sync Drive';

  @override
  String get navTooltipPlayers => 'Players';

  @override
  String get searchHint => 'Search a game…';

  @override
  String get emptyNoGame => 'No game yet';

  @override
  String get emptyNoGameSub => 'Add your first game with the + button';

  @override
  String get emptyNoResult => 'No results';

  @override
  String get emptyNoResultSub => 'Try a different term';

  @override
  String get fabNewGame => 'New game';

  @override
  String get freeBannerCta => 'Unlock groups & advanced stats';

  @override
  String get freeBannerPremium => 'Premium →';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'Manual backup of your data (free & premium plan).';

  @override
  String get driveConnected => 'Connected';

  @override
  String get driveSignIn => 'Sign in with Google';

  @override
  String get driveBackup => 'Backup';

  @override
  String get driveRestore => 'Restore';

  @override
  String get driveSignOut => 'Sign out';

  @override
  String get driveWebWarning => 'Issues signing in on Web?';

  @override
  String get driveAdBlockerTip =>
      'Try disabling your ad-blocker or Brave Shields. They often block Google\'s authentication scripts.';

  @override
  String get driveConnecting => 'Connecting…';

  @override
  String get driveCancelled => 'Connection cancelled.';

  @override
  String get driveNoData => '⚠️ No local data to back up.';

  @override
  String get driveUploadConfirmTitle => 'Back up to Drive?';

  @override
  String driveUploadConfirmBody(num games, num players) {
    final intl.NumberFormat gamesNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String gamesString = gamesNumberFormat.format(games);
    final intl.NumberFormat playersNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String playersString = playersNumberFormat.format(players);

    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$gamesString games',
      one: '1 game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      players,
      locale: localeName,
      other: '$playersString players',
      one: '1 player',
    );
    return 'This will replace the data currently on Drive with your local data ($_temp0, $_temp1).';
  }

  @override
  String get driveUploading => 'Uploading to Drive…';

  @override
  String get driveUploadOk => '✓ Backed up to Drive.';

  @override
  String get driveUploadError => '✗ Error while uploading.';

  @override
  String get driveDownloading => 'Downloading from Drive…';

  @override
  String get driveDownloadOk => '✓ Data restored and merged.';

  @override
  String get driveDownloadError => '✗ No data or error.';

  @override
  String get driveIdCopied => 'ID copied to clipboard';

  @override
  String sessionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String get addGameTitle => 'New game';

  @override
  String get editGameTitle => 'Edit game';

  @override
  String get sectionIcon => 'ICON';

  @override
  String get sectionGameName => 'GAME NAME';

  @override
  String get sectionDescription => 'DESCRIPTION (optional)';

  @override
  String get sectionGameMode => 'GAME MODE';

  @override
  String get gameNameHint => 'Game name';

  @override
  String get gameNameRequired => 'Name required';

  @override
  String get gameDescriptionHint => 'A few words about the game…';

  @override
  String get lowestScoreWinsLabel => 'Lowest score wins';

  @override
  String get lowestScoreWinsExample => 'e.g. 6 qui prend, Hearts, Golf…';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCreateGame => 'Create game';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnAdd => 'Add';

  @override
  String get btnInvite => 'Invite';

  @override
  String get deleteGameTitle => 'Delete this game?';

  @override
  String get deleteGameBody =>
      'All sessions will be deleted. This action is irreversible.';

  @override
  String get gameModePoints => 'Points';

  @override
  String get gameModePointsDesc => 'Score ranking per session';

  @override
  String get gameModeDuel => 'Duel';

  @override
  String get gameModeDuelDesc => 'Win / Draw / Loss between two players';

  @override
  String get gameModeRanking => 'Ranking';

  @override
  String get gameModeRankingDesc =>
      'Positional ranking for multiple players (1st, 2nd…)';

  @override
  String get playersScreenTitle => '👥 Players';

  @override
  String get emptyNoPlayer => 'No players';

  @override
  String get emptyNoPlayerSub => 'Add players to track their scores.';

  @override
  String get btnAddPlayer => 'Add a player';

  @override
  String get fabNewPlayer => 'New player';

  @override
  String playerGamesAndWins(num games, num wins) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games games',
      one: '1 game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins wins',
      one: '1 win',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get addPlayerTitle => 'New player';

  @override
  String get editPlayerTitle => 'Edit player';

  @override
  String get playerNameLabel => 'Player name';

  @override
  String get playerNameHint => 'First name or nickname';

  @override
  String get colorSectionLabel => 'COLOR';

  @override
  String get deletePlayerTitle => 'Delete this player?';

  @override
  String get deletePlayerBody =>
      'Their scores in existing sessions will be preserved.';

  @override
  String gameDetailHistory(num count) {
    return 'HISTORY ($count)';
  }

  @override
  String get gameDetailAddSession => '+ Add';

  @override
  String get leaderboardSection => 'LEADERBOARD';

  @override
  String get noWinnerYet => 'No winner yet.';

  @override
  String get deletedPlayer => 'Deleted player';

  @override
  String winCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '1 win',
    );
    return '$_temp0';
  }

  @override
  String recordLabel(num score) {
    return 'Record: ${score}pts';
  }

  @override
  String get emptyNoSession => 'No sessions';

  @override
  String get emptyNoSessionSub => 'Record your first session!';

  @override
  String get fabNewSession => 'New session';

  @override
  String get btnAddSession => 'Add a session';

  @override
  String get tooltipEditSession => 'Edit';

  @override
  String get tooltipDeleteSession => 'Delete';

  @override
  String get deleteSessionTitle => 'Delete this session?';

  @override
  String get deleteSessionBody => 'This action is irreversible.';

  @override
  String get duelWin => 'Win';

  @override
  String get duelDraw => 'Draw';

  @override
  String get duelLoss => 'Loss';

  @override
  String get ordinal1st => '1st';

  @override
  String ordinalNth(num n) {
    return '${n}th';
  }

  @override
  String addSessionTitle(String gameName) {
    return 'Session – $gameName';
  }

  @override
  String get sectionPlayers => 'PLAYERS';

  @override
  String get sectionScores => 'SCORES';

  @override
  String get sectionNotes => 'NOTES (optional)';

  @override
  String get notesHint => 'Anecdotes, conditions…';

  @override
  String get noPlayersWarning => '⚠️ No players created.';

  @override
  String get btnCreatePlayers => 'Create players';

  @override
  String get btnUpdateSession => 'Update';

  @override
  String get btnSaveSession => 'Save session';

  @override
  String get roundsToggleLabel => 'Round-by-round entry';

  @override
  String get roundsToggleSub => 'Calculate total round by round';

  @override
  String roundLabel(num n) {
    return 'Round $n';
  }

  @override
  String get btnAddRound => '+ Round';

  @override
  String roundTotalsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '1 round',
    );
    return '$_temp0';
  }

  @override
  String get pointsSuffix => 'pts';

  @override
  String get statsScreenTitle => '📊 Statistics';

  @override
  String get emptyNoStats => 'No stats yet';

  @override
  String get emptyNoStatsSub =>
      'Add games and play sessions to see your statistics.';

  @override
  String get tabPlayers => 'Players';

  @override
  String get tabGames => 'Games';

  @override
  String get tabGlobal => 'Global';

  @override
  String get emptyNoPlayerStats => 'No players';

  @override
  String get emptyNoPlayerStatsSub => 'Create players to see their statistics.';

  @override
  String get emptyNoGameStats => 'No sessions played';

  @override
  String get emptyNoGameStatsSub => 'Play sessions to see per-game stats.';

  @override
  String get emptyNoSessionStats => 'No sessions';

  @override
  String get emptyNoSessionStatsSub => 'This player hasn\'t played yet.';

  @override
  String get statSectionKeyMetrics => 'KEY METRICS';

  @override
  String get statSectionScores => 'SCORES';

  @override
  String get statSectionStreaks => 'WIN STREAKS';

  @override
  String get statSectionGames => 'GAMES';

  @override
  String get statSectionNemesis => 'NEMESIS';

  @override
  String get statSectionRival => 'RIVAL';

  @override
  String get statSectionDominant => 'DOMINANT PLAYER';

  @override
  String get statSectionTightest => 'TIGHTEST SESSION';

  @override
  String get statSectionScoreHistory => 'SCORE HISTORY';

  @override
  String get statSectionSummary => 'SUMMARY';

  @override
  String get statSectionOverview => 'OVERVIEW';

  @override
  String get statSectionGlobalRanking => 'GLOBAL RANKING';

  @override
  String get statSectionMostActive => 'MOST ACTIVE';

  @override
  String get statSectionAbsoluteRecord => 'ABSOLUTE RECORD';

  @override
  String get statSectionRivalries => 'RIVALRIES';

  @override
  String get statLabelSessions => 'SESSIONS';

  @override
  String get statLabelWins => 'WINS';

  @override
  String get statLabelRate => 'RATE';

  @override
  String get statLabelBest => 'BEST';

  @override
  String get statLabelWorst => 'WORST';

  @override
  String get statLabelAvg => 'AVG';

  @override
  String get statLabelCurrentStreak => 'CURRENT STREAK';

  @override
  String get statLabelBestStreak => 'BEST STREAK';

  @override
  String get statLabelWins2 => 'wins';

  @override
  String get statStreakOnFire => '🔥 on fire!';

  @override
  String get statFavoriteGame => '🏠 Favourite game';

  @override
  String statFavoriteWins(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '1 win',
    );
    return '$_temp0';
  }

  @override
  String statFavoriteRate(String pct) {
    return '$pct% success rate';
  }

  @override
  String get statNemesisLabel => 'Nemesis';

  @override
  String statNemesisLosses(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count losses against them',
      one: '1 loss against them',
    );
    return '$_temp0';
  }

  @override
  String get statRivalLabel => 'Rival';

  @override
  String statRivalGames(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions together',
      one: '1 session together',
    );
    return '$_temp0';
  }

  @override
  String get statDominatesGame => 'Dominates this game';

  @override
  String statWinsPercent(String pct) {
    return 'wins ($pct%)';
  }

  @override
  String statGap(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points',
      one: '1 point',
    );
    return 'Gap: $_temp0';
  }

  @override
  String statLastScore(num score) {
    return '$score pts (last)';
  }

  @override
  String get statSummarySessionsPlayed => 'Sessions played';

  @override
  String get statSummaryUniquePlayers => 'Unique players';

  @override
  String get statSummaryMaxScore => 'All-time high score';

  @override
  String statSummaryMaxScoreVal(num score) {
    return '$score pts';
  }

  @override
  String get statGlobalGames => 'Games';

  @override
  String get statGlobalSessions => 'Sessions';

  @override
  String get statGlobalPlayers => 'Players';

  @override
  String statMostActiveSessions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions played',
      one: '1 session played',
    );
    return '$_temp0';
  }

  @override
  String get statGlobalNemesisSection => 'NEMESIS';

  @override
  String statGlobalNemesisSentence(String playerA, String playerB) {
    return '$playerA dominates $playerB';
  }

  @override
  String statGlobalNemesisScore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consecutive wins',
      one: '1 consecutive win',
    );
    return '$_temp0';
  }

  @override
  String get statGlobalRivalsSection => 'RIVALS';

  @override
  String statGlobalRivalsSentence(String playerA, String playerB) {
    return '$playerA vs $playerB';
  }

  @override
  String statGlobalRivalsGames(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions together',
      one: '1 session together',
    );
    return '$_temp0';
  }

  @override
  String statGlobalRankingWins(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '1 win',
    );
    return '$_temp0';
  }

  @override
  String get groupsScreenTitle => '👥 Groups';

  @override
  String get groupsLeaveBtn => 'Leave';

  @override
  String get groupsLeaveTitle => 'Leave the group?';

  @override
  String get groupsLeaveBody => 'Your local data will be kept.';

  @override
  String groupsError(String error) {
    return 'Error: $error';
  }

  @override
  String get groupsEmpty => 'No groups';

  @override
  String get groupsEmptySub =>
      'Create a group to play in real time with your friends.';

  @override
  String get groupsBtnCreate => 'Create a group';

  @override
  String get groupsBtnJoin => 'Join';

  @override
  String get groupsActive => 'Active';

  @override
  String groupsMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get fabNewGroup => 'New group';

  @override
  String get groupsCreateTitle => 'Group name';

  @override
  String get groupsCreateHint => 'e.g. Game Night';

  @override
  String get groupsCreateBtn => 'Create';

  @override
  String get groupsCreateError => 'Could not create the group.';

  @override
  String get groupsInviteTitle => 'Invite a player';

  @override
  String groupsInviteGroupId(String id) {
    return 'Group ID: $id';
  }

  @override
  String get groupsInviteCopyId => 'Copy ID';

  @override
  String get groupsInviteEmailLabel => 'Player email';

  @override
  String get groupsInviteEmailHint => 'friend@example.com';

  @override
  String groupsInviteOk(String email) {
    return '✓ Invitation sent to $email';
  }

  @override
  String get groupsInviteError => '✗ Error while sending invitation';

  @override
  String groupsActiveBanner(String shortId) {
    return 'Real-time sync active · Group $shortId…';
  }

  @override
  String get groupsSignInTitle => 'Sign in required';

  @override
  String get groupsSignInSub =>
      'Sign in with Google to access real-time groups.';

  @override
  String get groupsSignInBtn => 'Sign in with Google';

  @override
  String get groupsTooltipInvite => 'Invite';

  @override
  String get paywallPremiumTitle => '🌟 GameTracker Premium';

  @override
  String get paywallGroupSyncTitle => '👥 Real-time Groups';

  @override
  String get paywallPremiumHero => 'Go Premium';

  @override
  String get paywallGroupSyncHero => 'Play Together';

  @override
  String get paywallPremiumSub =>
      'Advanced stats and CSV export\nwithout sacrificing anything on the free plan.';

  @override
  String get paywallGroupSyncSub =>
      'Sync your scores in real time\nacross all your devices.';

  @override
  String get paywallTableFree => 'Free';

  @override
  String get paywallTableThisPlan => 'This plan';

  @override
  String get paywallLoadingError =>
      'Unable to load offers.\nCheck your connection.';

  @override
  String get paywallRestoreBtn => 'Restore purchases';

  @override
  String get paywallNoRestoreFound => 'No purchases found to restore.';

  @override
  String get paywallCrossSellPremium =>
      'Looking for advanced stats? Discover Premium.';

  @override
  String get paywallCrossSellGroupSync =>
      'Want to play in a group? Discover real-time sync.';

  @override
  String get paywallAnnual => 'Annual';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallAnnualBadge => 'POPULAR';

  @override
  String get paywallAnnualBonus => '2 months free';

  @override
  String get paywallPerYear => '/yr';

  @override
  String get paywallPerMonth => '/mo';

  @override
  String get featureGamesAndSessions => 'Games & sessions';

  @override
  String get featureDriveBackup => 'Drive backup';

  @override
  String get featureAdvancedStats => 'Advanced stats';

  @override
  String get featureCsvExport => 'CSV export';

  @override
  String get featureGroupSync => 'Real-time groups';

  @override
  String get featureMultiDevice => 'Multi-device';

  @override
  String get featureUnlimited => 'Unlimited ✓';

  @override
  String get featureIncluded => 'Included ✓';

  @override
  String get featureNotIncluded => '—';

  @override
  String get featureSeparateSub => 'Separate subscription';

  @override
  String get featureSeparatePremium => 'Separate premium';
}
