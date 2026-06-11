import 'package:intl/intl.dart';

String formatearNumero(double value) => Formatters.currency(value);

class Formatters {
  Formatters._();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFormat = DateFormat('HH:mm');

  static String currency(double amount) => _currencyFormat.format(amount);

  static String date(DateTime date) => _dateFormat.format(date);

  static String dateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String time(DateTime dateTime) => _timeFormat.format(dateTime);

  static String dni(String dni) {
    if (dni.length == 8) {
      return '${dni.substring(0, 2)}.${dni.substring(2, 5)}.${dni.substring(5)}';
    }
    return dni;
  }

  static String phone(String number) {
    if (number.length == 9) {
      return '${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    if (number.length == 10) {
      return '(${number.substring(0, 3)}) ${number.substring(3, 6)} ${number.substring(6)}';
    }
    return number;
  }

  static String censoredDni(String dni) {
    if (dni.length == 8) {
      return '***${dni.substring(4)}';
    }
    if (dni.length >= 4) {
      return '***${dni.substring(dni.length - 4)}';
    }
    return dni;
  }

  static String percentage(double value) =>
      '${value.toStringAsFixed(1)}%';
}
