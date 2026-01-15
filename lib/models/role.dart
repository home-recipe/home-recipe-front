enum Role {
  ADMIN,
  USER;

  static Role fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN':
        return Role.ADMIN;
      case 'USER':
        return Role.USER;
      default:
        return Role.USER;
    }
  }

  String toJson() {
    return name;
  }
}
