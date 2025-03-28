String chiffreEnLettre(int i) {
  if (i == 0) return "";
  const uniteSet = {
    1: 'un',
    2: 'deux',
    3: 'trois',
    4: 'quatre',
    5: 'cinq',
    6: 'six',
    7: 'sept',
    8: 'huit',
    9: 'neuf',
    10: 'dix',
    11: 'onze',
    12: 'douze',
    13: 'treize',
    14: 'quatorze',
    15: 'quinze',
    16: 'seize',
    17: 'dix-sept',
    18: 'dix-huit',
    19: 'dix-neuf'
  };

  const dizaineSet = {
    2: 'vingt',
    3: 'trente',
    4: 'quarante',
    5: 'cinquante',
    6: 'soixante',
    8: 'quatre-vingt'
  };

  List<int> tab = [];
  while (i > 0) {
    tab.add(i % 1000);
    i = (i / 1000).floor();
  }
  tab = tab.reversed.toList();
  if (tab.length <= 1) {
    int unite = tab[0] % 10;
    tab[0] = (tab[0] / 10).floor();
    int dizaine = tab[0] % 10;
    tab[0] = (tab[0] / 10).floor();
    int centaine = tab[0] % 10;
    String out = "";

    if (centaine != 0) {
      out +=
          "${(centaine > 1) ? ("${uniteSet[centaine]} ") : ""}cent${(centaine > 1) ? "s" : ""}";
    }

    if (dizaine >= 0) {
      if (dizaine == 9 || dizaine == 7 || dizaine == 1) {
        dizaine = dizaine - 1;
        unite += 10;
      }
      if (dizaine > 0) out += " ${dizaineSet[dizaine]}";
    }

    if (unite != 0) {
      out += " ${uniteSet[unite]}";
    }

    return out;
  }
  int temp = tab.removeAt(0);
  int reste = tab.reduce((value, element) => value * 1000 + element);
  const suffixe = {4: 'milliard', 3: 'million', 2: 'mille', 1: ''};
  if (temp == 0) return chiffreEnLettre(reste);
  return "${"${(!(temp == 1 && tab.length == 1)) ? "${chiffreEnLettre(temp)} " : ""}${suffixe[tab.length + 1]}${(temp > 1 && tab.length != 1) ? "s" : ""} "}${chiffreEnLettre(reste)}";
}

// void main() {
//   print(chiffreEnLettre(1001000).trim());
//   print(chiffreEnLettre(75000).trim());
// }
