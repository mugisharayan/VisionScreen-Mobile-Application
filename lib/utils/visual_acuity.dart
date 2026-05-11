import 'dart:math' as math;

class VisualAcuity {
  VisualAcuity._();

  static const List<int> _snellenDenominators = <int>[
    6,
    9,
    12,
    18,
    24,
    36,
    48,
    60,
    120,
  ];

  static const Map<String, String> _snellenToLogmarMap = <String, String>{
    '6/6': '0.0',
    '6/9': '0.2',
    '6/12': '0.3',
    '6/18': '0.5',
    '6/24': '0.6',
    '6/36': '0.8',
    '6/48': '0.9',
    '6/60': '1.0',
    '6/120': '1.3',
  };

  static String toSnellen(String logmar, {String? invalidValue}) {
    final value = double.tryParse(logmar);
    if (value == null) {
      return invalidValue ?? logmar;
    }

    final denominator = (6 * math.pow(10, value)).round();
    final snapped = _snellenDenominators.reduce(
      (left, right) =>
          (left - denominator).abs() < (right - denominator).abs()
              ? left
              : right,
    );
    return '6/$snapped';
  }

  static String toLogmar(String snellen, {String invalidValue = '0.5'}) {
    return _snellenToLogmarMap[snellen] ?? invalidValue;
  }

  static String classification(String logmar, {String? invalidValue}) {
    final value = double.tryParse(logmar);
    if (value == null) {
      return invalidValue ?? logmar;
    }
    if (value <= 0.0) {
      return 'Normal';
    }
    if (value <= 0.3) {
      return 'Near Normal';
    }
    if (value <= 0.5) {
      return 'Moderate Visual Impairment';
    }
    if (value <= 1.0) {
      return 'Severe Visual Impairment';
    }
    return 'Blind';
  }
}
