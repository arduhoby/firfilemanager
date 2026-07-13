// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fir File Manager';

  @override
  String get navLocal => 'Local';

  @override
  String get navConnections => 'Connections';

  @override
  String get navServer => 'Server';

  @override
  String get navSettings => 'Settings';

  @override
  String get categoryImages => 'Images';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryAudio => 'Audio';

  @override
  String get categoryVideo => 'Video';

  @override
  String get categoryDownloads => 'Downloads';

  @override
  String get categoryMainStorage => 'Main Storage';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionMove => 'Move';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionNewFolder => 'New Folder';

  @override
  String get actionPaste => 'Paste';

  @override
  String get actionSelectAll => 'Select All';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionProperties => 'Properties';

  @override
  String get actionOpenWith => 'Open';

  @override
  String get actionRevealInFinder => 'Reveal in Finder';

  @override
  String get actionCompress => 'Compress';

  @override
  String get actionCompressZip => 'Compress to ZIP';

  @override
  String get actionCompressTar => 'Compress to TAR';

  @override
  String get actionCompressTarGz => 'Compress to TAR.GZ';

  @override
  String get actionExtract => 'Extract Here';

  @override
  String get actionExtractTo => 'Extract to…';

  @override
  String get actionClose => 'Close';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConnect => 'Connect';

  @override
  String get actionDisconnect => 'Disconnect';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionRemove => 'Remove';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByDate => 'Date Modified';

  @override
  String get sortBySize => 'Size';

  @override
  String get sortByType => 'Type';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get panelLeft => 'Left Panel';

  @override
  String get panelRight => 'Right Panel';

  @override
  String get panelActive => 'Active Panel';

  @override
  String operationCopying(int count) {
    return 'Copying $count items…';
  }

  @override
  String operationMoving(int count) {
    return 'Moving $count items…';
  }

  @override
  String operationDeleting(int count) {
    return 'Deleting $count items…';
  }

  @override
  String get operationComplete => 'Operation complete';

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String operationProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get connectionTypeSftp => 'SFTP';

  @override
  String get connectionTypeFtp => 'FTP';

  @override
  String get connectionTypeWebdav => 'WebDAV';

  @override
  String get connectionTypeSmb => 'SMB';

  @override
  String get connectionTypeGdrive => 'Google Drive';

  @override
  String get connectionTypeDropbox => 'Dropbox';

  @override
  String get connectionHost => 'Host';

  @override
  String get connectionPort => 'Port';

  @override
  String get connectionUsername => 'Username';

  @override
  String get connectionPassword => 'Password';

  @override
  String get connectionName => 'Connection Name';

  @override
  String get connectionAuthMethod => 'Authentication Method';

  @override
  String get connectionAuthPassword => 'Password';

  @override
  String get connectionAuthKey => 'Private Key';

  @override
  String get connectionAddNew => 'Add New Connection';

  @override
  String get connectionEdit => 'Edit Connection';

  @override
  String get connectionTest => 'Test Connection';

  @override
  String get connectionTestSuccess => 'Connection successful';

  @override
  String connectionTestFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get connectionDisconnected => 'Disconnected';

  @override
  String get connectionReconnecting => 'Reconnecting…';

  @override
  String get serverStart => 'Start Server';

  @override
  String get serverStop => 'Stop Server';

  @override
  String get serverRunning => 'Server is running';

  @override
  String get serverStopped => 'Server is stopped';

  @override
  String get serverSharedFolder => 'Shared Folder';

  @override
  String get serverPort => 'Port';

  @override
  String get serverUsername => 'Username';

  @override
  String get serverPassword => 'Password';

  @override
  String get serverActiveConnections => 'Active Connections';

  @override
  String get serverNoConnections => 'No active connections';

  @override
  String get serverFtp => 'FTP Server';

  @override
  String get serverWebdav => 'WebDAV Server';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get errorAccessDenied => 'Access denied';

  @override
  String errorNotFound(String path) {
    return 'Not found: $path';
  }

  @override
  String errorAlreadyExists(String path) {
    return 'Already exists: $path';
  }

  @override
  String errorNetwork(String error) {
    return 'Network error: $error';
  }

  @override
  String get errorTimeout => 'Operation timed out';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get confirmDeleteTitle => 'Delete';

  @override
  String confirmDeleteMessage(int count) {
    return 'Are you sure you want to delete $count item(s)?';
  }

  @override
  String get confirmOverwriteTitle => 'Overwrite';

  @override
  String confirmOverwriteMessage(String name) {
    return '$name already exists. Overwrite?';
  }

  @override
  String get propertiesName => 'Name';

  @override
  String get propertiesPath => 'Path';

  @override
  String get propertiesSize => 'Size';

  @override
  String get propertiesType => 'Type';

  @override
  String get propertiesModified => 'Date Modified';

  @override
  String get propertiesPermissions => 'Permissions';

  @override
  String get propertiesFolder => 'Folder';

  @override
  String get propertiesFile => 'File';

  @override
  String itemsSelected(int count) {
    return '$count selected';
  }

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get emptyFolder => 'This folder is empty';
}
