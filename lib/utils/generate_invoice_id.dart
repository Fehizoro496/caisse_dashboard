String generateInvoiceId({required String client, required DateTime date}) {
  // Étape 1 : Générer un hash du client
  int clientHash = client.hashCode;

  // Étape 2 : Obtenir l'horodatage précis en millisecondes
  int timestamp = date.millisecondsSinceEpoch;

  // Étape 3 : Combiner les deux valeurs en utilisant l'opérateur XOR
  int combinedValue = clientHash ^ timestamp;

  // Étape 4 : Convertir en hexadécimal et s'assurer d'avoir 8 caractères
  String hexString = combinedValue.toRadixString(16).toUpperCase();
  String uniqueReference = hexString.length > 9
      ? hexString.substring(0, 9)
      : hexString.padLeft(9, '0');

  return uniqueReference;
}
