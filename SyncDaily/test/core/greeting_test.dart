import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/utils/greeting.dart';

void main() {
  test('sapaan mengikuti batas jam', () {
    // malam: 18.00–03.59
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 3, 59)),
      AppStrings.greetingNight,
    );
    // pagi: 04.00–10.59
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 4, 0)),
      AppStrings.greetingMorning,
    );
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 10, 59)),
      AppStrings.greetingMorning,
    );
    // siang: 11.00–14.59
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 11, 0)),
      AppStrings.greetingAfternoon,
    );
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 14, 59)),
      AppStrings.greetingAfternoon,
    );
    // sore: 15.00–17.59
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 15, 0)),
      AppStrings.greetingEvening,
    );
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 17, 59)),
      AppStrings.greetingEvening,
    );
    // malam: 18.00–03.59
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 18, 0)),
      AppStrings.greetingNight,
    );
    expect(
      Greeting.forTime(DateTime(2026, 10, 14, 23, 59)),
      AppStrings.greetingNight,
    );
    expect(
      Greeting.forTime(DateTime(2026, 10, 14)),
      AppStrings.greetingNight,
    );
  });
}
