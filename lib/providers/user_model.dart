class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String age;
  final String userType;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.age,
    required this.userType,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      age: data['age'] ?? '',
      userType: data['userType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'age': age,
      'userType': userType,
    };
  }
}
