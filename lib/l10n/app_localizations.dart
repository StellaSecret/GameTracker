import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// Application name in the app bar
  ///
  /// In en, this message translates to:
  /// **'GameTracker'**
  String get appTitle;

  /// Main screen app bar title
  ///
  /// In en, this message translates to:
  /// **'🎲 GameTracker'**
  String get appBarTitle;

  /// No description provided for @navTooltipStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navTooltipStats;

  /// No description provided for @navTooltipGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navTooltipGroups;

  /// No description provided for @navTooltipDrive.
  ///
  /// In en, this message translates to:
  /// **'Sync Drive'**
  String get navTooltipDrive;

  /// No description provided for @navTooltipPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get navTooltipPlayers;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a game…'**
  String get searchHint;

  /// No description provided for @emptyNoGame.
  ///
  /// In en, this message translates to:
  /// **'No game yet'**
  String get emptyNoGame;

  /// No description provided for @emptyNoGameSub.
  ///
  /// In en, this message translates to:
  /// **'Add your first game with the + button'**
  String get emptyNoGameSub;

  /// No description provided for @emptyNoResult.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get emptyNoResult;

  /// No description provided for @emptyNoResultSub.
  ///
  /// In en, this message translates to:
  /// **'Try a different term'**
  String get emptyNoResultSub;

  /// No description provided for @fabNewGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get fabNewGame;

  /// No description provided for @freeBannerCta.
  ///
  /// In en, this message translates to:
  /// **'Unlock groups & advanced stats'**
  String get freeBannerCta;

  /// No description provided for @freeBannerPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium →'**
  String get freeBannerPremium;

  /// No description provided for @adUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Try Advanced Stats'**
  String get adUnlockTitle;

  /// No description provided for @adUnlockBody.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to unlock stats for 5 minutes — or go Premium for permanent access with no ads.'**
  String get adUnlockBody;

  /// No description provided for @adUnlockWatchBtn.
  ///
  /// In en, this message translates to:
  /// **'Watch ad (5 min free)'**
  String get adUnlockWatchBtn;

  /// No description provided for @adUnlockPremiumBtn.
  ///
  /// In en, this message translates to:
  /// **'Go Premium — no ads'**
  String get adUnlockPremiumBtn;

  /// No description provided for @adUnlockLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get adUnlockLoading;

  /// No description provided for @adUnlockError.
  ///
  /// In en, this message translates to:
  /// **'Ad not available. Please try again later.'**
  String get adUnlockError;

  /// No description provided for @adUnlockWebUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ads aren\'t available on web — go Premium for unlimited stats access.'**
  String get adUnlockWebUnavailable;

  /// No description provided for @adUnlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stats unlocked for 5 minutes! 🎉'**
  String get adUnlockedSuccess;

  /// No description provided for @adUnlockTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Stats unlocked — {minutes}m {seconds}s remaining'**
  String adUnlockTimerLabel(int minutes, int seconds);

  /// No description provided for @driveSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get driveSheetTitle;

  /// No description provided for @driveSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual backup of your data (free & premium plan).'**
  String get driveSheetSubtitle;

  /// No description provided for @driveConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get driveConnected;

  /// No description provided for @driveSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get driveSignIn;

  /// No description provided for @driveBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get driveBackup;

  /// No description provided for @driveRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get driveRestore;

  /// No description provided for @driveSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get driveSignOut;

  /// No description provided for @driveWebWarning.
  ///
  /// In en, this message translates to:
  /// **'Issues signing in on Web?'**
  String get driveWebWarning;

  /// No description provided for @driveAdBlockerTip.
  ///
  /// In en, this message translates to:
  /// **'Try disabling your ad-blocker or Brave Shields. They often block Google\'s authentication scripts.'**
  String get driveAdBlockerTip;

  /// No description provided for @driveConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get driveConnecting;

  /// No description provided for @driveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Connection cancelled.'**
  String get driveCancelled;

  /// No description provided for @driveNoData.
  ///
  /// In en, this message translates to:
  /// **'⚠️ No local data to back up.'**
  String get driveNoData;

  /// No description provided for @driveUploadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up to Drive?'**
  String get driveUploadConfirmTitle;

  /// No description provided for @driveUploadConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace the data currently on Drive with your local data ({games, plural, =1{1 game} other{{games} games}}, {players, plural, =1{1 player} other{{players} players}}).'**
  String driveUploadConfirmBody(num games, num players);

  /// No description provided for @driveUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading to Drive…'**
  String get driveUploading;

  /// No description provided for @driveUploadOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Backed up to Drive.'**
  String get driveUploadOk;

  /// No description provided for @driveUploadError.
  ///
  /// In en, this message translates to:
  /// **'✗ Error while uploading.'**
  String get driveUploadError;

  /// No description provided for @driveDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading from Drive…'**
  String get driveDownloading;

  /// No description provided for @driveDownloadOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Data restored and merged.'**
  String get driveDownloadOk;

  /// No description provided for @driveDownloadError.
  ///
  /// In en, this message translates to:
  /// **'✗ No data or error.'**
  String get driveDownloadError;

  /// No description provided for @driveIdCopied.
  ///
  /// In en, this message translates to:
  /// **'ID copied to clipboard'**
  String get driveIdCopied;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} =1{1 session} other{{count} sessions}}'**
  String sessionCount(num count);

  /// No description provided for @addGameTitle.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get addGameTitle;

  /// No description provided for @editGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit game'**
  String get editGameTitle;

  /// No description provided for @sectionIcon.
  ///
  /// In en, this message translates to:
  /// **'ICON'**
  String get sectionIcon;

  /// No description provided for @sectionGameName.
  ///
  /// In en, this message translates to:
  /// **'GAME NAME'**
  String get sectionGameName;

  /// No description provided for @sectionDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION (optional)'**
  String get sectionDescription;

  /// No description provided for @sectionGameMode.
  ///
  /// In en, this message translates to:
  /// **'GAME MODE'**
  String get sectionGameMode;

  /// No description provided for @gameNameHint.
  ///
  /// In en, this message translates to:
  /// **'Game name'**
  String get gameNameHint;

  /// No description provided for @gameNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get gameNameRequired;

  /// No description provided for @gameDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'A few words about the game…'**
  String get gameDescriptionHint;

  /// No description provided for @lowestScoreWinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lowest score wins'**
  String get lowestScoreWinsLabel;

  /// No description provided for @lowestScoreWinsExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 6 qui prend, Hearts, Golf…'**
  String get lowestScoreWinsExample;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// No description provided for @btnCreateGame.
  ///
  /// In en, this message translates to:
  /// **'Create game'**
  String get btnCreateGame;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @btnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// No description provided for @btnInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get btnInvite;

  /// No description provided for @deleteGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this game?'**
  String get deleteGameTitle;

  /// No description provided for @deleteGameBody.
  ///
  /// In en, this message translates to:
  /// **'All sessions will be deleted. This action is irreversible.'**
  String get deleteGameBody;

  /// No description provided for @gameModePoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get gameModePoints;

  /// No description provided for @gameModePointsDesc.
  ///
  /// In en, this message translates to:
  /// **'Score ranking per session'**
  String get gameModePointsDesc;

  /// No description provided for @gameModeDuel.
  ///
  /// In en, this message translates to:
  /// **'Duel'**
  String get gameModeDuel;

  /// No description provided for @gameModeDuelDesc.
  ///
  /// In en, this message translates to:
  /// **'Win / Draw / Loss between two players'**
  String get gameModeDuelDesc;

  /// No description provided for @gameModeRanking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get gameModeRanking;

  /// No description provided for @gameModeRankingDesc.
  ///
  /// In en, this message translates to:
  /// **'Positional ranking for multiple players (1st, 2nd…)'**
  String get gameModeRankingDesc;

  /// No description provided for @playersScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Players'**
  String get playersScreenTitle;

  /// No description provided for @emptyNoPlayer.
  ///
  /// In en, this message translates to:
  /// **'No players'**
  String get emptyNoPlayer;

  /// No description provided for @emptyNoPlayerSub.
  ///
  /// In en, this message translates to:
  /// **'Add players to track their scores.'**
  String get emptyNoPlayerSub;

  /// No description provided for @btnAddPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add a player'**
  String get btnAddPlayer;

  /// No description provided for @fabNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get fabNewPlayer;

  /// No description provided for @playerGamesAndWins.
  ///
  /// In en, this message translates to:
  /// **'{games, plural, =1{1 game} other{{games} games}} · {wins, plural, =1{1 win} other{{wins} wins}}'**
  String playerGamesAndWins(num games, num wins);

  /// No description provided for @addPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get addPlayerTitle;

  /// No description provided for @editPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit player'**
  String get editPlayerTitle;

  /// No description provided for @playerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Player name'**
  String get playerNameLabel;

  /// No description provided for @playerNameHint.
  ///
  /// In en, this message translates to:
  /// **'First name or nickname'**
  String get playerNameHint;

  /// No description provided for @colorSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get colorSectionLabel;

  /// No description provided for @deletePlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this player?'**
  String get deletePlayerTitle;

  /// No description provided for @deletePlayerBody.
  ///
  /// In en, this message translates to:
  /// **'Their scores in existing sessions will be preserved.'**
  String get deletePlayerBody;

  /// No description provided for @gameDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY ({count})'**
  String gameDetailHistory(num count);

  /// No description provided for @gameDetailAddSession.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get gameDetailAddSession;

  /// No description provided for @leaderboardSection.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get leaderboardSection;

  /// No description provided for @noWinnerYet.
  ///
  /// In en, this message translates to:
  /// **'No winner yet.'**
  String get noWinnerYet;

  /// No description provided for @deletedPlayer.
  ///
  /// In en, this message translates to:
  /// **'Deleted player'**
  String get deletedPlayer;

  /// No description provided for @winCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 win} other{{count} wins}}'**
  String winCount(num count);

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record: {score}pts'**
  String recordLabel(num score);

  /// No description provided for @emptyNoSession.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get emptyNoSession;

  /// No description provided for @emptyNoSessionSub.
  ///
  /// In en, this message translates to:
  /// **'Record your first session!'**
  String get emptyNoSessionSub;

  /// No description provided for @fabNewSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get fabNewSession;

  /// No description provided for @btnAddSession.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get btnAddSession;

  /// No description provided for @tooltipEditSession.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltipEditSession;

  /// No description provided for @tooltipDeleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltipDeleteSession;

  /// No description provided for @deleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this session?'**
  String get deleteSessionTitle;

  /// No description provided for @deleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible.'**
  String get deleteSessionBody;

  /// No description provided for @duelWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get duelWin;

  /// No description provided for @duelDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get duelDraw;

  /// No description provided for @duelLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get duelLoss;

  /// No description provided for @ordinal1st.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get ordinal1st;

  /// No description provided for @ordinalNth.
  ///
  /// In en, this message translates to:
  /// **'{n}th'**
  String ordinalNth(num n);

  /// No description provided for @addSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session – {gameName}'**
  String addSessionTitle(String gameName);

  /// No description provided for @sectionPlayers.
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get sectionPlayers;

  /// No description provided for @sectionScores.
  ///
  /// In en, this message translates to:
  /// **'SCORES'**
  String get sectionScores;

  /// No description provided for @sectionNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES (optional)'**
  String get sectionNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Anecdotes, conditions…'**
  String get notesHint;

  /// No description provided for @noPlayersWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ No players created.'**
  String get noPlayersWarning;

  /// No description provided for @btnCreatePlayers.
  ///
  /// In en, this message translates to:
  /// **'Create players'**
  String get btnCreatePlayers;

  /// No description provided for @btnUpdateSession.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btnUpdateSession;

  /// No description provided for @btnSaveSession.
  ///
  /// In en, this message translates to:
  /// **'Save session'**
  String get btnSaveSession;

  /// No description provided for @roundsToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Round-by-round entry'**
  String get roundsToggleLabel;

  /// No description provided for @roundsToggleSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate total round by round'**
  String get roundsToggleSub;

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {n}'**
  String roundLabel(num n);

  /// No description provided for @btnAddRound.
  ///
  /// In en, this message translates to:
  /// **'+ Round'**
  String get btnAddRound;

  /// No description provided for @roundTotalsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round} other{{count} rounds}}'**
  String roundTotalsLabel(num count);

  /// No description provided for @pointsSuffix.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsSuffix;

  /// No description provided for @statsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'📊 Statistics'**
  String get statsScreenTitle;

  /// No description provided for @emptyNoStats.
  ///
  /// In en, this message translates to:
  /// **'No stats yet'**
  String get emptyNoStats;

  /// No description provided for @emptyNoStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Add games and play sessions to see your statistics.'**
  String get emptyNoStatsSub;

  /// No description provided for @tabPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get tabPlayers;

  /// No description provided for @tabGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get tabGames;

  /// No description provided for @tabGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get tabGlobal;

  /// No description provided for @emptyNoPlayerStats.
  ///
  /// In en, this message translates to:
  /// **'No players'**
  String get emptyNoPlayerStats;

  /// No description provided for @emptyNoPlayerStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Create players to see their statistics.'**
  String get emptyNoPlayerStatsSub;

  /// No description provided for @emptyNoGameStats.
  ///
  /// In en, this message translates to:
  /// **'No sessions played'**
  String get emptyNoGameStats;

  /// No description provided for @emptyNoGameStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Play sessions to see per-game stats.'**
  String get emptyNoGameStatsSub;

  /// No description provided for @emptyNoSessionStats.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get emptyNoSessionStats;

  /// No description provided for @emptyNoSessionStatsSub.
  ///
  /// In en, this message translates to:
  /// **'This player hasn\'t played yet.'**
  String get emptyNoSessionStatsSub;

  /// No description provided for @statSectionKeyMetrics.
  ///
  /// In en, this message translates to:
  /// **'KEY METRICS'**
  String get statSectionKeyMetrics;

  /// No description provided for @statSectionScores.
  ///
  /// In en, this message translates to:
  /// **'SCORES'**
  String get statSectionScores;

  /// No description provided for @statSectionStreaks.
  ///
  /// In en, this message translates to:
  /// **'WIN STREAKS'**
  String get statSectionStreaks;

  /// No description provided for @statSectionGames.
  ///
  /// In en, this message translates to:
  /// **'GAMES'**
  String get statSectionGames;

  /// No description provided for @statSectionNemesis.
  ///
  /// In en, this message translates to:
  /// **'NEMESIS'**
  String get statSectionNemesis;

  /// No description provided for @statSectionRival.
  ///
  /// In en, this message translates to:
  /// **'RIVAL'**
  String get statSectionRival;

  /// No description provided for @statSectionDominant.
  ///
  /// In en, this message translates to:
  /// **'DOMINANT PLAYER'**
  String get statSectionDominant;

  /// No description provided for @statSectionTightest.
  ///
  /// In en, this message translates to:
  /// **'TIGHTEST SESSION'**
  String get statSectionTightest;

  /// No description provided for @statSectionScoreHistory.
  ///
  /// In en, this message translates to:
  /// **'SCORE HISTORY'**
  String get statSectionScoreHistory;

  /// No description provided for @statSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get statSectionSummary;

  /// No description provided for @statSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get statSectionOverview;

  /// No description provided for @statSectionGlobalRanking.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL RANKING'**
  String get statSectionGlobalRanking;

  /// No description provided for @statSectionMostActive.
  ///
  /// In en, this message translates to:
  /// **'MOST ACTIVE'**
  String get statSectionMostActive;

  /// No description provided for @statSectionAbsoluteRecord.
  ///
  /// In en, this message translates to:
  /// **'ABSOLUTE RECORD'**
  String get statSectionAbsoluteRecord;

  /// No description provided for @statSectionRivalries.
  ///
  /// In en, this message translates to:
  /// **'RIVALRIES'**
  String get statSectionRivalries;

  /// No description provided for @statLabelSessions.
  ///
  /// In en, this message translates to:
  /// **'SESSIONS'**
  String get statLabelSessions;

  /// No description provided for @statLabelWins.
  ///
  /// In en, this message translates to:
  /// **'WINS'**
  String get statLabelWins;

  /// No description provided for @statLabelRate.
  ///
  /// In en, this message translates to:
  /// **'RATE'**
  String get statLabelRate;

  /// No description provided for @statLabelBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get statLabelBest;

  /// No description provided for @statLabelWorst.
  ///
  /// In en, this message translates to:
  /// **'WORST'**
  String get statLabelWorst;

  /// No description provided for @statLabelAvg.
  ///
  /// In en, this message translates to:
  /// **'AVG'**
  String get statLabelAvg;

  /// No description provided for @statLabelCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STREAK'**
  String get statLabelCurrentStreak;

  /// No description provided for @statLabelBestStreak.
  ///
  /// In en, this message translates to:
  /// **'BEST STREAK'**
  String get statLabelBestStreak;

  /// No description provided for @statLabelWins2.
  ///
  /// In en, this message translates to:
  /// **'wins'**
  String get statLabelWins2;

  /// No description provided for @statStreakOnFire.
  ///
  /// In en, this message translates to:
  /// **'🔥 on fire!'**
  String get statStreakOnFire;

  /// No description provided for @statFavoriteGame.
  ///
  /// In en, this message translates to:
  /// **'🏠 Favourite game'**
  String get statFavoriteGame;

  /// No description provided for @statFavoriteWins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 win} other{{count} wins}}'**
  String statFavoriteWins(num count);

  /// No description provided for @statFavoriteRate.
  ///
  /// In en, this message translates to:
  /// **'{pct}% success rate'**
  String statFavoriteRate(String pct);

  /// No description provided for @statNemesisLabel.
  ///
  /// In en, this message translates to:
  /// **'Nemesis'**
  String get statNemesisLabel;

  /// No description provided for @statNemesisLosses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 loss against them} other{{count} losses against them}}'**
  String statNemesisLosses(num count);

  /// No description provided for @statRivalLabel.
  ///
  /// In en, this message translates to:
  /// **'Rival'**
  String get statRivalLabel;

  /// No description provided for @statRivalGames.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session together} other{{count} sessions together}}'**
  String statRivalGames(num count);

  /// No description provided for @statDominatesGame.
  ///
  /// In en, this message translates to:
  /// **'Dominates this game'**
  String get statDominatesGame;

  /// No description provided for @statWinsPercent.
  ///
  /// In en, this message translates to:
  /// **'wins ({pct}%)'**
  String statWinsPercent(String pct);

  /// No description provided for @statGap.
  ///
  /// In en, this message translates to:
  /// **'Gap: {n, plural, =1{1 point} other{{n} points}}'**
  String statGap(num n);

  /// No description provided for @statLastScore.
  ///
  /// In en, this message translates to:
  /// **'{score} pts (last)'**
  String statLastScore(num score);

  /// No description provided for @statSummarySessionsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Sessions played'**
  String get statSummarySessionsPlayed;

  /// No description provided for @statSummaryUniquePlayers.
  ///
  /// In en, this message translates to:
  /// **'Unique players'**
  String get statSummaryUniquePlayers;

  /// No description provided for @statSummaryMaxScore.
  ///
  /// In en, this message translates to:
  /// **'All-time high score'**
  String get statSummaryMaxScore;

  /// No description provided for @statSummaryMaxScoreVal.
  ///
  /// In en, this message translates to:
  /// **'{score} pts'**
  String statSummaryMaxScoreVal(num score);

  /// No description provided for @statGlobalGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get statGlobalGames;

  /// No description provided for @statGlobalSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get statGlobalSessions;

  /// No description provided for @statGlobalPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get statGlobalPlayers;

  /// No description provided for @statMostActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session played} other{{count} sessions played}}'**
  String statMostActiveSessions(num count);

  /// No description provided for @statGlobalNemesisSection.
  ///
  /// In en, this message translates to:
  /// **'NEMESIS'**
  String get statGlobalNemesisSection;

  /// No description provided for @statGlobalNemesisSentence.
  ///
  /// In en, this message translates to:
  /// **'{playerA} dominates {playerB}'**
  String statGlobalNemesisSentence(String playerA, String playerB);

  /// No description provided for @statGlobalNemesisScore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 consecutive win} other{{count} consecutive wins}}'**
  String statGlobalNemesisScore(num count);

  /// No description provided for @statGlobalRivalsSection.
  ///
  /// In en, this message translates to:
  /// **'RIVALS'**
  String get statGlobalRivalsSection;

  /// No description provided for @statGlobalRivalsSentence.
  ///
  /// In en, this message translates to:
  /// **'{playerA} vs {playerB}'**
  String statGlobalRivalsSentence(String playerA, String playerB);

  /// No description provided for @statGlobalRivalsGames.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session together} other{{count} sessions together}}'**
  String statGlobalRivalsGames(num count);

  /// No description provided for @statGlobalRankingWins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 win} other{{count} wins}}'**
  String statGlobalRankingWins(num count);

  /// No description provided for @groupsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Groups'**
  String get groupsScreenTitle;

  /// No description provided for @groupsLeaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupsLeaveBtn;

  /// No description provided for @groupsLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the group?'**
  String get groupsLeaveTitle;

  /// No description provided for @groupsLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your local data will be kept.'**
  String get groupsLeaveBody;

  /// No description provided for @groupsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String groupsError(String error);

  /// No description provided for @groupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get groupsEmpty;

  /// No description provided for @groupsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Create a group to play in real time with your friends.'**
  String get groupsEmptySub;

  /// No description provided for @groupsBtnCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a group'**
  String get groupsBtnCreate;

  /// No description provided for @groupsBtnJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupsBtnJoin;

  /// No description provided for @groupsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get groupsActive;

  /// No description provided for @groupsMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String groupsMemberCount(num count);

  /// No description provided for @fabNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get fabNewGroup;

  /// No description provided for @groupsCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupsCreateTitle;

  /// No description provided for @groupsCreateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Game Night'**
  String get groupsCreateHint;

  /// No description provided for @groupsCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get groupsCreateBtn;

  /// No description provided for @groupsCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the group.'**
  String get groupsCreateError;

  /// No description provided for @groupsInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite a player'**
  String get groupsInviteTitle;

  /// No description provided for @groupsInviteGroupId.
  ///
  /// In en, this message translates to:
  /// **'Group ID: {id}'**
  String groupsInviteGroupId(String id);

  /// No description provided for @groupsInviteCopyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get groupsInviteCopyId;

  /// No description provided for @groupsInviteEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Player email'**
  String get groupsInviteEmailLabel;

  /// No description provided for @groupsInviteEmailHint.
  ///
  /// In en, this message translates to:
  /// **'friend@example.com'**
  String get groupsInviteEmailHint;

  /// No description provided for @groupsInviteOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Invitation sent to {email}'**
  String groupsInviteOk(String email);

  /// No description provided for @groupsInviteError.
  ///
  /// In en, this message translates to:
  /// **'✗ Error while sending invitation'**
  String get groupsInviteError;

  /// No description provided for @groupsActiveBanner.
  ///
  /// In en, this message translates to:
  /// **'Real-time sync active · Group {shortId}…'**
  String groupsActiveBanner(String shortId);

  /// No description provided for @groupsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get groupsSignInTitle;

  /// No description provided for @groupsSignInSub.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to access real-time groups.'**
  String get groupsSignInSub;

  /// No description provided for @groupsSignInBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get groupsSignInBtn;

  /// No description provided for @groupsTooltipInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupsTooltipInvite;

  /// No description provided for @paywallPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'🌟 GameTracker Premium'**
  String get paywallPremiumTitle;

  /// No description provided for @paywallGroupSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Real-time Groups'**
  String get paywallGroupSyncTitle;

  /// No description provided for @paywallPremiumHero.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get paywallPremiumHero;

  /// No description provided for @paywallGroupSyncHero.
  ///
  /// In en, this message translates to:
  /// **'Play Together'**
  String get paywallGroupSyncHero;

  /// No description provided for @paywallPremiumSub.
  ///
  /// In en, this message translates to:
  /// **'Advanced stats and CSV export\nwithout sacrificing anything on the free plan.'**
  String get paywallPremiumSub;

  /// No description provided for @paywallGroupSyncSub.
  ///
  /// In en, this message translates to:
  /// **'Sync your scores in real time\nacross all your devices.'**
  String get paywallGroupSyncSub;

  /// No description provided for @paywallTableFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get paywallTableFree;

  /// No description provided for @paywallTableThisPlan.
  ///
  /// In en, this message translates to:
  /// **'This plan'**
  String get paywallTableThisPlan;

  /// No description provided for @paywallLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load offers.\nCheck your connection.'**
  String get paywallLoadingError;

  /// No description provided for @paywallRestoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestoreBtn;

  /// No description provided for @paywallNoRestoreFound.
  ///
  /// In en, this message translates to:
  /// **'No purchases found to restore.'**
  String get paywallNoRestoreFound;

  /// No description provided for @paywallCrossSellPremium.
  ///
  /// In en, this message translates to:
  /// **'Looking for advanced stats? Discover Premium.'**
  String get paywallCrossSellPremium;

  /// No description provided for @paywallCrossSellGroupSync.
  ///
  /// In en, this message translates to:
  /// **'Want to play in a group? Discover real-time sync.'**
  String get paywallCrossSellGroupSync;

  /// No description provided for @paywallAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywallAnnual;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallAnnualBadge.
  ///
  /// In en, this message translates to:
  /// **'POPULAR'**
  String get paywallAnnualBadge;

  /// No description provided for @paywallAnnualBonus.
  ///
  /// In en, this message translates to:
  /// **'2 months free'**
  String get paywallAnnualBonus;

  /// No description provided for @paywallPerYear.
  ///
  /// In en, this message translates to:
  /// **'/yr'**
  String get paywallPerYear;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get paywallPerMonth;

  /// No description provided for @featureGamesAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Games & sessions'**
  String get featureGamesAndSessions;

  /// No description provided for @featureDriveBackup.
  ///
  /// In en, this message translates to:
  /// **'Drive backup'**
  String get featureDriveBackup;

  /// No description provided for @featureAdvancedStats.
  ///
  /// In en, this message translates to:
  /// **'Advanced stats'**
  String get featureAdvancedStats;

  /// No description provided for @featureCsvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV export'**
  String get featureCsvExport;

  /// No description provided for @featureGroupSync.
  ///
  /// In en, this message translates to:
  /// **'Real-time groups'**
  String get featureGroupSync;

  /// No description provided for @featureMultiDevice.
  ///
  /// In en, this message translates to:
  /// **'Multi-device'**
  String get featureMultiDevice;

  /// No description provided for @featureUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited ✓'**
  String get featureUnlimited;

  /// No description provided for @featureIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included ✓'**
  String get featureIncluded;

  /// No description provided for @featureNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get featureNotIncluded;

  /// No description provided for @featureSeparateSub.
  ///
  /// In en, this message translates to:
  /// **'Separate subscription'**
  String get featureSeparateSub;

  /// No description provided for @featureSeparatePremium.
  ///
  /// In en, this message translates to:
  /// **'Separate premium'**
  String get featureSeparatePremium;

  /// No description provided for @paywallLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Stats Locked'**
  String get paywallLockedTitle;

  /// No description provided for @paywallLockedSub.
  ///
  /// In en, this message translates to:
  /// **'Advanced statistics require a Premium subscription. You can unlock them temporarily by watching a short ad.'**
  String get paywallLockedSub;

  /// No description provided for @unlockWithAd.
  ///
  /// In en, this message translates to:
  /// **'Watch ad to unlock (5 min)'**
  String get unlockWithAd;

  /// No description provided for @adError.
  ///
  /// In en, this message translates to:
  /// **'Ad not available right now.'**
  String get adError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
