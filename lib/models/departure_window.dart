enum DepartureWindow {
  morning,
  midday,
  afternoon,
}

extension DepartureWindowX on DepartureWindow {
  String get label {
    switch (this) {
      case DepartureWindow.morning:
        return '08:00 – 10:00';
      case DepartureWindow.midday:
        return '11:00 – 13:00';
      case DepartureWindow.afternoon:
        return '14:00 – 16:00';
    }
  }

  String get apiValue {
    switch (this) {
      case DepartureWindow.morning:
        return '08-10';
      case DepartureWindow.midday:
        return '11-13';
      case DepartureWindow.afternoon:
        return '14-16';
    }
  }
}
