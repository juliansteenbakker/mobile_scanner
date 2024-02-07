/// Exception thrown when the auto-start feature of the scanner is disabled.
/// 
/// This exception is thrown when the scanner's auto-start feature is disabled and an attempt is made to start the scanner automatically.
/// The [message] parameter can be used to provide additional information about the exception.
class AutoStartDisabledException implements Exception {
  final String? message;

  AutoStartDisabledException(this.message);

  @override
  String toString() {
    return message ?? 'Scanner auto-start is disabled';
  }
}
