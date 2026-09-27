class AuthProvider {
  bool isAuthenticated = false;

  void signIn() {
    isAuthenticated = true;
  }

  void signOut() {
    isAuthenticated = false;
  }
}
