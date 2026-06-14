// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'GameTracker';

  @override
  String get appBarTitle => '🎲 GameTracker';

  @override
  String get navTooltipStats => 'Statistiques';

  @override
  String get navTooltipGroups => 'Groupes';

  @override
  String get navTooltipDrive => 'Sync Drive';

  @override
  String get navTooltipPlayers => 'Joueurs';

  @override
  String get searchHint => 'Rechercher un jeu…';

  @override
  String get emptyNoGame => 'Aucun jeu encore';

  @override
  String get emptyNoGameSub => 'Ajoutez votre premier jeu avec le bouton +';

  @override
  String get emptyNoResult => 'Aucun résultat';

  @override
  String get emptyNoResultSub => 'Essayez un autre terme';

  @override
  String get fabNewGame => 'Nouveau jeu';

  @override
  String get freeBannerCta => 'Débloquer les groupes & stats avancées';

  @override
  String get freeBannerPremium => 'Premium →';

  @override
  String get driveSheetTitle => 'Google Drive';

  @override
  String get driveSheetSubtitle =>
      'Sauvegarde manuelle de vos données (plan gratuit & premium).';

  @override
  String get driveConnected => 'Connecté';

  @override
  String get driveSignIn => 'Se connecter avec Google';

  @override
  String get driveBackup => 'Sauvegarder';

  @override
  String get driveRestore => 'Restaurer';

  @override
  String get driveSignOut => 'Se déconnecter';

  @override
  String get driveWebWarning => 'Problèmes de connexion sur le Web ?';

  @override
  String get driveAdBlockerTip =>
      'Désactivez votre bloqueur de pub ou Brave Shields. Ils bloquent souvent les scripts Google.';

  @override
  String get driveConnecting => 'Connexion…';

  @override
  String get driveCancelled => 'Connexion annulée.';

  @override
  String get driveNoData => '⚠️ Aucune donnée locale à sauvegarder.';

  @override
  String get driveUploadConfirmTitle => 'Sauvegarder sur Drive ?';

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
      other: '$gamesString jeux',
      one: '1 jeu',
    );
    String _temp1 = intl.Intl.pluralLogic(
      players,
      locale: localeName,
      other: '$playersString joueurs',
      one: '1 joueur',
    );
    return 'Cela remplacera les données actuellement sur Drive par vos données locales ($_temp0, $_temp1).';
  }

  @override
  String get driveUploading => 'Envoi vers Drive…';

  @override
  String get driveUploadOk => '✓ Sauvegardé sur Drive.';

  @override
  String get driveUploadError => '✗ Erreur lors de l\'envoi.';

  @override
  String get driveDownloading => 'Téléchargement depuis Drive…';

  @override
  String get driveDownloadOk => '✓ Données restaurées et fusionnées.';

  @override
  String get driveDownloadError => '✗ Aucune donnée ou erreur.';

  @override
  String get driveIdCopied => 'ID copié dans le presse-papier';

  @override
  String sessionCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties',
      one: '1 partie',
      zero: 'Aucune partie',
    );
    return '$_temp0';
  }

  @override
  String get addGameTitle => 'Nouveau jeu';

  @override
  String get editGameTitle => 'Modifier le jeu';

  @override
  String get sectionIcon => 'ICÔNE';

  @override
  String get sectionGameName => 'NOM DU JEU';

  @override
  String get sectionDescription => 'DESCRIPTION (optionnel)';

  @override
  String get sectionGameMode => 'MODE DE JEU';

  @override
  String get gameNameHint => 'Nom du jeu';

  @override
  String get gameNameRequired => 'Nom requis';

  @override
  String get gameDescriptionHint => 'Quelques mots sur le jeu…';

  @override
  String get lowestScoreWinsLabel => 'Le moins de points gagne';

  @override
  String get lowestScoreWinsExample => 'Ex : 6 qui prend, Hearts, Golf…';

  @override
  String get btnSave => 'Enregistrer';

  @override
  String get btnCreateGame => 'Créer le jeu';

  @override
  String get btnCancel => 'Annuler';

  @override
  String get btnDelete => 'Supprimer';

  @override
  String get btnAdd => 'Ajouter';

  @override
  String get btnInvite => 'Inviter';

  @override
  String get deleteGameTitle => 'Supprimer ce jeu ?';

  @override
  String get deleteGameBody =>
      'Toutes les parties seront supprimées. Cette action est irréversible.';

  @override
  String get gameModePoints => 'Points';

  @override
  String get gameModePointsDesc => 'Classement par nombre de points par partie';

  @override
  String get gameModeDuel => 'Duel';

  @override
  String get gameModeDuelDesc =>
      'Victoire / Match nul / Défaite entre deux joueurs';

  @override
  String get gameModeRanking => 'Classement';

  @override
  String get gameModeRankingDesc =>
      'Classement positionnel multi-joueurs (1er, 2ème…)';

  @override
  String get playersScreenTitle => '👥 Joueurs';

  @override
  String get emptyNoPlayer => 'Aucun joueur';

  @override
  String get emptyNoPlayerSub =>
      'Ajoutez des joueurs pour suivre leurs scores.';

  @override
  String get btnAddPlayer => 'Ajouter un joueur';

  @override
  String get fabNewPlayer => 'Nouveau joueur';

  @override
  String playerGamesAndWins(num games, num wins) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games jeux',
      one: '1 jeu',
    );
    String _temp1 = intl.Intl.pluralLogic(
      wins,
      locale: localeName,
      other: '$wins victoires',
      one: '1 victoire',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get addPlayerTitle => 'Nouveau joueur';

  @override
  String get editPlayerTitle => 'Modifier le joueur';

  @override
  String get playerNameLabel => 'Nom du joueur';

  @override
  String get playerNameHint => 'Prénom ou pseudo';

  @override
  String get colorSectionLabel => 'COULEUR';

  @override
  String get deletePlayerTitle => 'Supprimer ce joueur ?';

  @override
  String get deletePlayerBody =>
      'Ses scores dans les parties existantes seront conservés.';

  @override
  String gameDetailHistory(num count) {
    return 'HISTORIQUE ($count)';
  }

  @override
  String get gameDetailAddSession => '+ Ajouter';

  @override
  String get leaderboardSection => 'CLASSEMENT';

  @override
  String get noWinnerYet => 'Pas encore de vainqueur.';

  @override
  String get deletedPlayer => 'Joueur supprimé';

  @override
  String winCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires',
      one: '1 victoire',
    );
    return '$_temp0';
  }

  @override
  String recordLabel(num score) {
    return 'Record : ${score}pts';
  }

  @override
  String get emptyNoSession => 'Aucune partie';

  @override
  String get emptyNoSessionSub => 'Enregistrez votre première partie !';

  @override
  String get fabNewSession => 'Nouvelle partie';

  @override
  String get btnAddSession => 'Ajouter une partie';

  @override
  String get tooltipEditSession => 'Modifier';

  @override
  String get tooltipDeleteSession => 'Supprimer';

  @override
  String get deleteSessionTitle => 'Supprimer cette partie ?';

  @override
  String get deleteSessionBody => 'Cette action est irréversible.';

  @override
  String get duelWin => 'Victoire';

  @override
  String get duelDraw => 'Match nul';

  @override
  String get duelLoss => 'Défaite';

  @override
  String get ordinal1st => '1er';

  @override
  String ordinalNth(num n) {
    return '$nème';
  }

  @override
  String addSessionTitle(String gameName) {
    return 'Partie – $gameName';
  }

  @override
  String get sectionPlayers => 'JOUEURS';

  @override
  String get sectionScores => 'SCORES';

  @override
  String get sectionNotes => 'NOTES (optionnel)';

  @override
  String get notesHint => 'Anecdotes, conditions de jeu…';

  @override
  String get noPlayersWarning => '⚠️ Aucun joueur créé.';

  @override
  String get btnCreatePlayers => 'Créer des joueurs';

  @override
  String get btnUpdateSession => 'Mettre à jour';

  @override
  String get btnSaveSession => 'Enregistrer la partie';

  @override
  String get roundsToggleLabel => 'Saisie par manches';

  @override
  String get roundsToggleSub => 'Calculer le total manche par manche';

  @override
  String roundLabel(num n) {
    return 'Manche $n';
  }

  @override
  String get btnAddRound => '+ Manche';

  @override
  String roundTotalsLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count manches',
      one: '1 manche',
    );
    return '$_temp0';
  }

  @override
  String get pointsSuffix => 'pts';

  @override
  String get statsScreenTitle => '📊 Statistiques';

  @override
  String get emptyNoStats => 'Pas encore de stats';

  @override
  String get emptyNoStatsSub =>
      'Ajoutez des jeux et jouez des parties pour voir vos statistiques.';

  @override
  String get tabPlayers => 'Joueurs';

  @override
  String get tabGames => 'Jeux';

  @override
  String get tabGlobal => 'Global';

  @override
  String get emptyNoPlayerStats => 'Aucun joueur';

  @override
  String get emptyNoPlayerStatsSub =>
      'Créez des joueurs pour voir leurs statistiques.';

  @override
  String get emptyNoGameStats => 'Aucune partie jouée';

  @override
  String get emptyNoGameStatsSub =>
      'Jouez des parties pour voir les stats par jeu.';

  @override
  String get emptyNoSessionStats => 'Aucune partie';

  @override
  String get emptyNoSessionStatsSub => 'Ce joueur n\'a pas encore joué.';

  @override
  String get statSectionKeyMetrics => 'CHIFFRES CLÉS';

  @override
  String get statSectionScores => 'SCORES';

  @override
  String get statSectionStreaks => 'SÉRIES DE VICTOIRES';

  @override
  String get statSectionGames => 'JEUX';

  @override
  String get statSectionNemesis => 'NÉMÉSIS';

  @override
  String get statSectionRival => 'RIVAL';

  @override
  String get statSectionDominant => 'JOUEUR DOMINANT';

  @override
  String get statSectionTightest => 'PARTIE LA PLUS SERRÉE';

  @override
  String get statSectionScoreHistory => 'ÉVOLUTION DES SCORES';

  @override
  String get statSectionSummary => 'RÉSUMÉ';

  @override
  String get statSectionOverview => 'VUE D\'ENSEMBLE';

  @override
  String get statSectionGlobalRanking => 'CLASSEMENT GÉNÉRAL';

  @override
  String get statSectionMostActive => 'LE PLUS ACTIF';

  @override
  String get statSectionAbsoluteRecord => 'RECORD ABSOLU';

  @override
  String get statSectionRivalries => 'RIVALITÉS';

  @override
  String get statLabelSessions => 'PARTIES';

  @override
  String get statLabelWins => 'VICTOIRES';

  @override
  String get statLabelRate => 'TAUX';

  @override
  String get statLabelBest => 'MEILLEUR';

  @override
  String get statLabelWorst => 'PIRE';

  @override
  String get statLabelAvg => 'MOYENNE';

  @override
  String get statLabelCurrentStreak => 'SÉRIE EN COURS';

  @override
  String get statLabelBestStreak => 'MEILLEURE SÉRIE';

  @override
  String get statLabelWins2 => 'victoires';

  @override
  String get statStreakOnFire => '🔥 en feu !';

  @override
  String get statFavoriteGame => '🏠 Jeu favori';

  @override
  String statFavoriteWins(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires',
      one: '1 victoire',
    );
    return '$_temp0';
  }

  @override
  String statFavoriteRate(String pct) {
    return '$pct% de réussite';
  }

  @override
  String get statNemesisLabel => 'Némésis';

  @override
  String statNemesisLosses(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count défaites contre lui',
      one: '1 défaite contre lui',
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
      other: '$count parties ensemble',
      one: '1 partie ensemble',
    );
    return '$_temp0';
  }

  @override
  String get statDominatesGame => 'Domine ce jeu';

  @override
  String statWinsPercent(String pct) {
    return 'victoires ($pct%)';
  }

  @override
  String statGap(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points',
      one: '1 point',
    );
    return 'Écart : $_temp0';
  }

  @override
  String statLastScore(num score) {
    return '$score pts (dernier)';
  }

  @override
  String get statSummarySessionsPlayed => 'Parties jouées';

  @override
  String get statSummaryUniquePlayers => 'Joueurs uniques';

  @override
  String get statSummaryMaxScore => 'Score max all-time';

  @override
  String statSummaryMaxScoreVal(num score) {
    return '$score pts';
  }

  @override
  String get statGlobalGames => 'Jeux';

  @override
  String get statGlobalSessions => 'Parties';

  @override
  String get statGlobalPlayers => 'Joueurs';

  @override
  String statMostActiveSessions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties jouées',
      one: '1 partie jouée',
    );
    return '$_temp0';
  }

  @override
  String get statGlobalNemesisSection => 'NÉMÉSIS';

  @override
  String statGlobalNemesisSentence(String playerA, String playerB) {
    return '$playerA domine $playerB';
  }

  @override
  String statGlobalNemesisScore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires d\'affilée',
      one: '1 victoire d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String get statGlobalRivalsSection => 'RIVAUX';

  @override
  String statGlobalRivalsSentence(String playerA, String playerB) {
    return '$playerA vs $playerB';
  }

  @override
  String statGlobalRivalsGames(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties ensemble',
      one: '1 partie ensemble',
    );
    return '$_temp0';
  }

  @override
  String statGlobalRankingWins(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires',
      one: '1 victoire',
    );
    return '$_temp0';
  }

  @override
  String get groupsScreenTitle => '👥 Groupes';

  @override
  String get groupsLeaveBtn => 'Quitter';

  @override
  String get groupsLeaveTitle => 'Quitter le groupe ?';

  @override
  String get groupsLeaveBody => 'Vos données locales seront conservées.';

  @override
  String groupsError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get groupsEmpty => 'Aucun groupe';

  @override
  String get groupsEmptySub =>
      'Créez un groupe pour jouer en temps réel avec vos amis.';

  @override
  String get groupsBtnCreate => 'Créer un groupe';

  @override
  String get groupsBtnJoin => 'Rejoindre';

  @override
  String get groupsActive => 'Actif';

  @override
  String groupsMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get fabNewGroup => 'Nouveau groupe';

  @override
  String get groupsCreateTitle => 'Nom du groupe';

  @override
  String get groupsCreateHint => 'ex : Soirée jeux';

  @override
  String get groupsCreateBtn => 'Créer';

  @override
  String get groupsCreateError => 'Impossible de créer le groupe.';

  @override
  String get groupsInviteTitle => 'Inviter un joueur';

  @override
  String groupsInviteGroupId(String id) {
    return 'ID du groupe : $id';
  }

  @override
  String get groupsInviteCopyId => 'Copier l\'ID';

  @override
  String get groupsInviteEmailLabel => 'Email du joueur';

  @override
  String get groupsInviteEmailHint => 'ami@exemple.com';

  @override
  String groupsInviteOk(String email) {
    return '✓ Invitation envoyée à $email';
  }

  @override
  String get groupsInviteError => '✗ Erreur lors de l\'invitation';

  @override
  String groupsActiveBanner(String shortId) {
    return 'Sync temps réel actif · Groupe $shortId…';
  }

  @override
  String get groupsSignInTitle => 'Connexion requise';

  @override
  String get groupsSignInSub =>
      'Connectez-vous avec Google pour accéder aux groupes temps réel.';

  @override
  String get groupsSignInBtn => 'Se connecter avec Google';

  @override
  String get groupsTooltipInvite => 'Inviter';

  @override
  String get paywallPremiumTitle => '🌟 GameTracker Premium';

  @override
  String get paywallGroupSyncTitle => '👥 Groupes temps réel';

  @override
  String get paywallPremiumHero => 'Passez à Premium';

  @override
  String get paywallGroupSyncHero => 'Jouez ensemble';

  @override
  String get paywallPremiumSub =>
      'Stats avancées et export CSV\nsans rien sacrifier sur le plan gratuit.';

  @override
  String get paywallGroupSyncSub =>
      'Synchronisez vos scores en temps réel\nentre tous vos appareils.';

  @override
  String get paywallTableFree => 'Gratuit';

  @override
  String get paywallTableThisPlan => 'Ce plan';

  @override
  String get paywallLoadingError =>
      'Impossible de charger les offres.\nVérifiez votre connexion.';

  @override
  String get paywallRestoreBtn => 'Restaurer les achats';

  @override
  String get paywallNoRestoreFound => 'Aucun achat trouvé à restaurer.';

  @override
  String get paywallCrossSellPremium =>
      'Vous cherchez les stats avancées ? Découvrez Premium.';

  @override
  String get paywallCrossSellGroupSync =>
      'Vous voulez jouer en groupe ? Découvrez le sync temps réel.';

  @override
  String get paywallAnnual => 'Annuel';

  @override
  String get paywallMonthly => 'Mensuel';

  @override
  String get paywallAnnualBadge => 'POPULAIRE';

  @override
  String get paywallAnnualBonus => '2 mois offerts';

  @override
  String get paywallPerYear => '/an';

  @override
  String get paywallPerMonth => '/mois';

  @override
  String get featureGamesAndSessions => 'Jeux & parties';

  @override
  String get featureDriveBackup => 'Backup Drive';

  @override
  String get featureAdvancedStats => 'Stats avancées';

  @override
  String get featureCsvExport => 'Export CSV';

  @override
  String get featureGroupSync => 'Groupes temps réel';

  @override
  String get featureMultiDevice => 'Multi-appareils';

  @override
  String get featureUnlimited => 'Illimités ✓';

  @override
  String get featureIncluded => 'Inclus ✓';

  @override
  String get featureNotIncluded => '—';

  @override
  String get featureSeparateSub => 'Abonnement séparé';

  @override
  String get featureSeparatePremium => 'Premium séparé';
}
