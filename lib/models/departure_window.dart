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

  // The hour at which this window closes (24h). A window is expired on today
  // if the current time is at or past this hour.
  int get endHour {
    switch (this) {
      case DepartureWindow.morning:
        return 10;
      case DepartureWindow.midday:
        return 13;
      case DepartureWindow.afternoon:
        return 16;
    }
  }

  bool isExpiredForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    return isToday && now.hour >= endHour;
  }
}
