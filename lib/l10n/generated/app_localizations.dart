import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('tr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Fir File Manager'**
  String get appTitle;

  /// No description provided for @navLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get navLocal;

  /// No description provided for @navConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get navConnections;

  /// No description provided for @navServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get navServer;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @categoryImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryImages;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get categoryAudio;

  /// No description provided for @categoryVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get categoryVideo;

  /// No description provided for @categoryDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get categoryDownloads;

  /// No description provided for @categoryMainStorage.
  ///
  /// In en, this message translates to:
  /// **'Main Storage'**
  String get categoryMainStorage;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionNewFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get actionNewFolder;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @actionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get actionProperties;

  /// No description provided for @actionOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpenWith;

  /// No description provided for @actionRevealInFinder.
  ///
  /// In en, this message translates to:
  /// **'Reveal in Finder'**
  String get actionRevealInFinder;

  /// No description provided for @actionCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get actionCompress;

  /// No description provided for @actionCompressZip.
  ///
  /// In en, this message translates to:
  /// **'Compress to ZIP'**
  String get actionCompressZip;

  /// No description provided for @actionCompressTar.
  ///
  /// In en, this message translates to:
  /// **'Compress to TAR'**
  String get actionCompressTar;

  /// No description provided for @actionCompressTarGz.
  ///
  /// In en, this message translates to:
  /// **'Compress to TAR.GZ'**
  String get actionCompressTarGz;

  /// No description provided for @actionExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract Here'**
  String get actionExtract;

  /// No description provided for @actionExtractTo.
  ///
  /// In en, this message translates to:
  /// **'Extract to…'**
  String get actionExtractTo;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get actionConnect;

  /// No description provided for @actionDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get actionDisconnect;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Date Modified'**
  String get sortByDate;

  /// No description provided for @sortBySize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sortBySize;

  /// No description provided for @sortByType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get sortByType;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// No description provided for @panelLeft.
  ///
  /// In en, this message translates to:
  /// **'Left Panel'**
  String get panelLeft;

  /// No description provided for @panelRight.
  ///
  /// In en, this message translates to:
  /// **'Right Panel'**
  String get panelRight;

  /// No description provided for @panelActive.
  ///
  /// In en, this message translates to:
  /// **'Active Panel'**
  String get panelActive;

  /// No description provided for @operationCopying.
  ///
  /// In en, this message translates to:
  /// **'Copying {count} items…'**
  String operationCopying(int count);

  /// No description provided for @operationMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving {count} items…'**
  String operationMoving(int count);

  /// No description provided for @operationDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting {count} items…'**
  String operationDeleting(int count);

  /// No description provided for @operationComplete.
  ///
  /// In en, this message translates to:
  /// **'Operation complete'**
  String get operationComplete;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(String error);

  /// No description provided for @operationProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String operationProgress(int current, int total);

  /// No description provided for @connectionTypeSftp.
  ///
  /// In en, this message translates to:
  /// **'SFTP'**
  String get connectionTypeSftp;

  /// No description provided for @connectionTypeFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP'**
  String get connectionTypeFtp;

  /// No description provided for @connectionTypeWebdav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get connectionTypeWebdav;

  /// No description provided for @connectionTypeSmb.
  ///
  /// In en, this message translates to:
  /// **'SMB'**
  String get connectionTypeSmb;

  /// No description provided for @connectionTypeGdrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get connectionTypeGdrive;

  /// No description provided for @connectionTypeDropbox.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get connectionTypeDropbox;

  /// No description provided for @connectionHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get connectionHost;

  /// No description provided for @connectionPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get connectionPort;

  /// No description provided for @connectionUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get connectionUsername;

  /// No description provided for @connectionPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get connectionPassword;

  /// No description provided for @connectionName.
  ///
  /// In en, this message translates to:
  /// **'Connection Name'**
  String get connectionName;

  /// No description provided for @connectionAuthMethod.
  ///
  /// In en, this message translates to:
  /// **'Authentication Method'**
  String get connectionAuthMethod;

  /// No description provided for @connectionAuthPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get connectionAuthPassword;

  /// No description provided for @connectionAuthKey.
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get connectionAuthKey;

  /// No description provided for @connectionAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add New Connection'**
  String get connectionAddNew;

  /// No description provided for @connectionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Connection'**
  String get connectionEdit;

  /// No description provided for @connectionTest.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get connectionTest;

  /// No description provided for @connectionTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionTestSuccess;

  /// No description provided for @connectionTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String connectionTestFailed(String error);

  /// No description provided for @connectionDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get connectionDisconnected;

  /// No description provided for @connectionReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get connectionReconnecting;

  /// No description provided for @serverStart.
  ///
  /// In en, this message translates to:
  /// **'Start Server'**
  String get serverStart;

  /// No description provided for @serverStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Server'**
  String get serverStop;

  /// No description provided for @serverRunning.
  ///
  /// In en, this message translates to:
  /// **'Server is running'**
  String get serverRunning;

  /// No description provided for @serverStopped.
  ///
  /// In en, this message translates to:
  /// **'Server is stopped'**
  String get serverStopped;

  /// No description provided for @serverSharedFolder.
  ///
  /// In en, this message translates to:
  /// **'Shared Folder'**
  String get serverSharedFolder;

  /// No description provided for @serverPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get serverPort;

  /// No description provided for @serverUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get serverUsername;

  /// No description provided for @serverPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get serverPassword;

  /// No description provided for @serverActiveConnections.
  ///
  /// In en, this message translates to:
  /// **'Active Connections'**
  String get serverActiveConnections;

  /// No description provided for @serverNoConnections.
  ///
  /// In en, this message translates to:
  /// **'No active connections'**
  String get serverNoConnections;

  /// No description provided for @serverFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP Server'**
  String get serverFtp;

  /// No description provided for @serverWebdav.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Server'**
  String get serverWebdav;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @errorAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorAccessDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found: {path}'**
  String errorNotFound(String path);

  /// No description provided for @errorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Already exists: {path}'**
  String errorAlreadyExists(String path);

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String errorNetwork(String error);

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Operation timed out'**
  String get errorTimeout;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} item(s)?'**
  String confirmDeleteMessage(int count);

  /// No description provided for @confirmOverwriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get confirmOverwriteTitle;

  /// No description provided for @confirmOverwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} already exists. Overwrite?'**
  String confirmOverwriteMessage(String name);

  /// No description provided for @propertiesName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get propertiesName;

  /// No description provided for @propertiesPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get propertiesPath;

  /// No description provided for @propertiesSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get propertiesSize;

  /// No description provided for @propertiesType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get propertiesType;

  /// No description provided for @propertiesModified.
  ///
  /// In en, this message translates to:
  /// **'Date Modified'**
  String get propertiesModified;

  /// No description provided for @propertiesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get propertiesPermissions;

  /// No description provided for @propertiesFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get propertiesFolder;

  /// No description provided for @propertiesFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get propertiesFile;

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String itemsSelected(int count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolder;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
