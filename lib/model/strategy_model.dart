class Strategy {
  final String id;
  final String name;
  final String displayName;

  Strategy({required this.id, required this.name, required this.displayName});

  // Factory constructor to create an instance of Strategy from JSON
  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'],
    );
  }
}
