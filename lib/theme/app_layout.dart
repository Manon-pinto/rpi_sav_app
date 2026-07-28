enum AppScreenClass { phone, tablet, desktop }

class AppLayout {
  static AppScreenClass classify(double width) {
    if (width < 560) return AppScreenClass.phone;
    if (width < 1100) return AppScreenClass.tablet;
    return AppScreenClass.desktop;
  }
}
