String formatNumber(num number) {
  String numStr = number.toStringAsFixed(number is double ? 2 : 0);
  List<String> parts = numStr.split('.');

  parts[0] = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]} ',
  );

  return parts.length > 1 ? '${parts[0]}.${parts[1]}' : parts[0];
}
