import 'package:sync_daily/core/strings/app_strings.dart';

/// Sapaan Beranda mengikuti waktu perangkat.
///
/// - pagi: 04.00–10.59
/// - siang: 11.00–14.59
/// - sore: 15.00–17.59
/// - malam: 18.00–03.59
class Greeting {
  const Greeting._();

  static String forTime(DateTime time) {
    final hour = time.hour;
    if (hour >= 4 && hour < 11) {
      return AppStrings.greetingMorning;
    }
    if (hour >= 11 && hour < 15) {
      return AppStrings.greetingAfternoon;
    }
    if (hour >= 15 && hour < 18) {
      return AppStrings.greetingEvening;
    }
    return AppStrings.greetingNight;
  }
}
