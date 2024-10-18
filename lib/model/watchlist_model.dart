

// Model class for Watchlist
class Watchlist {
  final String id;
  final String name;
  final String originalCreator;
  final String userEmail;

  Watchlist({
    required this.id,
    required this.name,
    required this.originalCreator,
    required this.userEmail,
  });

  // Factory method to create a Watchlist from JSON
  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      id: json['id'] as String,
      name: json['name'] as String,
      originalCreator: json['original_creator'] as String,
      userEmail: json['user_email'] as String,
    );
  }

  // Method to convert a Watchlist to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_creator': originalCreator,
      'user_email': userEmail,
    };
  }
}
