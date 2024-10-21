class LogEntry {
  final String message;
  final int timestamp;

  LogEntry({required this.message, required this.timestamp});

  // Factory method to create a LogEntry from a Map
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      message: json['message'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  // Method to convert LogEntry to a Map
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp,
    };
  }
}
