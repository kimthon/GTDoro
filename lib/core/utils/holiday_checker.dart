/// Utility class for checking holidays and weekends
class HolidayChecker {
  /// Check if a date is a weekend (Saturday or Sunday)
  static bool isWeekend(DateTime date) {
    final weekday = date.weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Check if a date is a holiday
  /// Currently checks for weekends and can be extended for custom holidays
  static bool isHoliday(DateTime date) {
    return isWeekend(date);
  }

  /// Get the next business day (skip weekends and holidays)
  static DateTime getNextBusinessDay(DateTime date) {
    var nextDate = date;
    int maxAttempts = 14; // Prevent infinite loop
    
    while (isHoliday(nextDate) && maxAttempts > 0) {
      nextDate = nextDate.add(const Duration(days: 1));
      maxAttempts--;
    }
    
    return nextDate;
  }

  /// Get the previous business day (skip weekends and holidays)
  static DateTime getPreviousBusinessDay(DateTime date) {
    var prevDate = date;
    int maxAttempts = 14; // Prevent infinite loop
    
    while (isHoliday(prevDate) && maxAttempts > 0) {
      prevDate = prevDate.subtract(const Duration(days: 1));
      maxAttempts--;
    }
    
    return prevDate;
  }

  /// Check if a date should be skipped based on holiday settings
  /// Returns the adjusted date if holiday should be skipped, or original date if not
  static DateTime adjustDateForHoliday(DateTime date, bool skipHolidays) {
    if (!skipHolidays) {
      return date;
    }
    
    if (isHoliday(date)) {
      return getNextBusinessDay(date);
    }
    
    return date;
  }
}
