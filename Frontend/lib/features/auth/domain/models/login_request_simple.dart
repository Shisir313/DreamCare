/// Login request payload - simple Dart class
class LoginRequest {
  const LoginRequest({
    required this.phone,
    required this.password,
  });

  final String phone;
  final String password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginRequest &&
          runtimeType == other.runtimeType &&
          phone == other.phone &&
          password == other.password;

  @override
  int get hashCode => Object.hash(phone, password);

  @override
  String toString() => 'LoginRequest(phone: $phone)';
}

/// Register request payload - simple Dart class
class RegisterRequest {
  const RegisterRequest({
    required this.phone,
    required this.name,
    required this.password,
    this.email,
  });

  final String phone;
  final String name;
  final String password;
  final String? email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterRequest &&
          runtimeType == other.runtimeType &&
          phone == other.phone &&
          name == other.name &&
          password == other.password &&
          email == other.email;

  @override
  int get hashCode => Object.hash(phone, name, password, email);

  @override
  String toString() => 'RegisterRequest(phone: $phone, name: $name)';
}
