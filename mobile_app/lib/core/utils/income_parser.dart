/// Utility class to parse and format Indian-style income strings.
class IncomeParser {
  /// Parses Indian-format income strings to integer rupees.
  /// 
  /// Examples:
  ///   "20 lakh"  -> 2000000
  ///   "20L"      -> 2000000
  ///   "5 hazar"  -> 5000
  ///   "5K"       -> 5000
  ///   "1.5 cr"   -> 15000000
  ///   "500000"   -> 500000
  static int? parse(String input) {
    final cleanInput = input.trim().toLowerCase().replaceAll(',', '');
    if (cleanInput.isEmpty) return null;

    // Regular expression to capture the numeric part and optional unit suffix
    final regex = RegExp(r'^(\d+(?:\.\d+)?)\s*(lakh|l|hazar|hazzar|hazaar|k|cr|crore)?$');
    final match = regex.firstMatch(cleanInput);
    if (match == null) return null;

    final numberStr = match.group(1);
    if (numberStr == null) return null;

    final number = double.tryParse(numberStr);
    if (number == null) return null;

    final unit = match.group(2) ?? '';

    switch (unit) {
      case 'lakh':
      case 'l':
        return (number * 100000).round();
      case 'hazar':
      case 'hazzar':
      case 'hazaar':
      case 'k':
        return (number * 1000).round();
      case 'cr':
      case 'crore':
        return (number * 10000000).round();
      default:
        return number.round();
    }
  }

  /// Formats an integer rupee value into a readable Indian-style string (e.g., Lakhs, Crores).
  /// 
  /// Examples:
  ///   2000000  -> "20 Lakh"
  ///   5000     -> "5 Hazar"
  ///   15500000 -> "1.55 Crore"
  ///   450000   -> "4.5 Lakh"
  ///   500      -> "500"
  static String format(int value, {bool useEnglishK = false}) {
    if (value <= 0) return '0';

    if (value >= 10000000) {
      final cr = value / 10000000;
      return '${_formatDouble(cr)} Crore';
    } else if (value >= 100000) {
      final lakh = value / 100000;
      return '${_formatDouble(lakh)} Lakh';
    } else if (value >= 1000) {
      final hazar = value / 1000;
      final suffix = useEnglishK ? 'K' : ' Hazar';
      return '${_formatDouble(hazar)}$suffix';
    } else {
      return value.toString();
    }
  }

  /// Helper to format double nicely (removes trailing .0 if integer)
  static String _formatDouble(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    // Limit to 2 decimal places and remove trailing zero if any
    String str = val.toStringAsFixed(2);
    if (str.endsWith('0')) {
      str = str.substring(0, str.length - 1);
    }
    if (str.endsWith('.0')) {
      str = str.substring(0, str.length - 2);
    }
    return str;
  }
}
