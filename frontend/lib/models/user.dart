class User {
  final String username;
  final String name;
  
  User({required this.username, required this.name});

  factory User.Json(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      name: json['name'],
    );
  }
}