import 'file_entry.dart';

/// A token that can be used to cancel an ongoing transfer operation.
///
/// Pass it to [StorageProvider.read], [StorageProvider.write], or
/// [StorageProvider.copy] and call [cancel] to abort the operation.
class CancelToken {
  CancelToken();

  bool _isCancelled = false;
  final List<void Function()> _callbacks = [];

  /// Whether cancellation has been requested
  bool get isCancelled => _isCancelled;

  /// Request cancellation of the associated operation
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final callback in _callbacks) {
      callback();
    }
  }

  /// Register a callback to be called when [cancel] is invoked
  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }

  /// Reset the token for reuse
  void reset() {
    _isCancelled = false;
    _callbacks.clear();
  }
}

/// Type of transfer operation
enum TransferOperation {
  copy,
  move,
  delete,
  read,
  write,
  zip,
  unzip,
  sync,
}

/// State of a transfer operation
enum TransferState {
  /// Operation is queued but not started
  pending,

  /// Operation is in progress
  inProgress,

  /// Operation completed successfully
  completed,

  /// Operation was cancelled by the user
  cancelled,

  /// Operation failed with an error
  failed,
}

/// Progress update for a file transfer operation.
///
/// Emitted as a [Stream] by [StorageProvider.read], [StorageProvider.write],
/// and [StorageProvider.copy]. The stream emits progress updates during the
/// operation and a final update with [state] set to [TransferState.completed]
/// or [TransferState.failed].
class TransferProgress {
  TransferProgress({
    required this.operation,
    required this.state,
    this.currentFile,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.filesTransferred = 0,
    this.totalFiles = 0,
    this.speed = 0,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Type of operation
  final TransferOperation operation;

  /// Current state
  final TransferState state;

  /// The file currently being transferred
  final FileEntry? currentFile;

  /// Bytes transferred so far for the current file
  final int bytesTransferred;

  /// Total bytes for the current file (0 if unknown)
  final int totalBytes;

  /// Number of files transferred so far (for batch operations)
  final int filesTransferred;

  /// Total number of files in the batch (0 if single file)
  final int totalFiles;

  /// Transfer speed in bytes/second
  final double speed;

  /// Error message if [state] is [TransferState.failed]
  final String? error;

  /// When this progress update was created
  final DateTime timestamp;

  /// Progress as a fraction (0.0 to 1.0), or null if total is unknown
  double? get fraction {
    if (totalBytes > 0) return bytesTransferred / totalBytes;
    if (totalFiles > 0) return filesTransferred / totalFiles;
    return null;
  }

  /// Progress as a percentage (0 to 100), or null if total is unknown
  int? get percent {
    final f = fraction;
    return f == null ? null : (f * 100).round();
  }

  /// Whether the operation is finished (completed, cancelled, or failed)
  bool get isFinished =>
      state == TransferState.completed ||
      state == TransferState.cancelled ||
      state == TransferState.failed;

  TransferProgress copyWith({
    TransferOperation? operation,
    TransferState? state,
    FileEntry? currentFile,
    int? bytesTransferred,
    int? totalBytes,
    int? filesTransferred,
    int? totalFiles,
    double? speed,
    String? error,
  }) {
    return TransferProgress(
      operation: operation ?? this.operation,
      state: state ?? this.state,
      currentFile: currentFile ?? this.currentFile,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      filesTransferred: filesTransferred ?? this.filesTransferred,
      totalFiles: totalFiles ?? this.totalFiles,
      speed: speed ?? this.speed,
      error: error ?? this.error,
    );
  }

  @override
  String toString() =>
      'TransferProgress(op: $operation, state: $state, $bytesTransferred/$totalBytes bytes, '
      '$filesTransferred/$totalFiles files, ${percent ?? '?'}%)';
}