// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FacturesTable extends Factures with TableInfo<$FacturesTable, Facture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FacturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idFactureMeta = const VerificationMeta(
    'idFacture',
  );
  @override
  late final GeneratedColumn<String> idFacture = GeneratedColumn<String>(
    'id_facture',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientMeta = const VerificationMeta('client');
  @override
  late final GeneratedColumn<String> client = GeneratedColumn<String>(
    'client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateFactureMeta = const VerificationMeta(
    'dateFacture',
  );
  @override
  late final GeneratedColumn<DateTime> dateFacture = GeneratedColumn<DateTime>(
    'date_facture',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [idFacture, client, dateFacture];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'factures';
  @override
  VerificationContext validateIntegrity(
    Insertable<Facture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_facture')) {
      context.handle(
        _idFactureMeta,
        idFacture.isAcceptableOrUnknown(data['id_facture']!, _idFactureMeta),
      );
    } else if (isInserting) {
      context.missing(_idFactureMeta);
    }
    if (data.containsKey('client')) {
      context.handle(
        _clientMeta,
        client.isAcceptableOrUnknown(data['client']!, _clientMeta),
      );
    } else if (isInserting) {
      context.missing(_clientMeta);
    }
    if (data.containsKey('date_facture')) {
      context.handle(
        _dateFactureMeta,
        dateFacture.isAcceptableOrUnknown(
          data['date_facture']!,
          _dateFactureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateFactureMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Facture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Facture(
      idFacture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_facture'],
      )!,
      client: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client'],
      )!,
      dateFacture: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_facture'],
      )!,
    );
  }

  @override
  $FacturesTable createAlias(String alias) {
    return $FacturesTable(attachedDatabase, alias);
  }
}

class Facture extends DataClass implements Insertable<Facture> {
  final String idFacture;
  final String client;
  final DateTime dateFacture;
  const Facture({
    required this.idFacture,
    required this.client,
    required this.dateFacture,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_facture'] = Variable<String>(idFacture);
    map['client'] = Variable<String>(client);
    map['date_facture'] = Variable<DateTime>(dateFacture);
    return map;
  }

  FacturesCompanion toCompanion(bool nullToAbsent) {
    return FacturesCompanion(
      idFacture: Value(idFacture),
      client: Value(client),
      dateFacture: Value(dateFacture),
    );
  }

  factory Facture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Facture(
      idFacture: serializer.fromJson<String>(json['idFacture']),
      client: serializer.fromJson<String>(json['client']),
      dateFacture: serializer.fromJson<DateTime>(json['dateFacture']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idFacture': serializer.toJson<String>(idFacture),
      'client': serializer.toJson<String>(client),
      'dateFacture': serializer.toJson<DateTime>(dateFacture),
    };
  }

  Facture copyWith({
    String? idFacture,
    String? client,
    DateTime? dateFacture,
  }) => Facture(
    idFacture: idFacture ?? this.idFacture,
    client: client ?? this.client,
    dateFacture: dateFacture ?? this.dateFacture,
  );
  Facture copyWithCompanion(FacturesCompanion data) {
    return Facture(
      idFacture: data.idFacture.present ? data.idFacture.value : this.idFacture,
      client: data.client.present ? data.client.value : this.client,
      dateFacture: data.dateFacture.present
          ? data.dateFacture.value
          : this.dateFacture,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Facture(')
          ..write('idFacture: $idFacture, ')
          ..write('client: $client, ')
          ..write('dateFacture: $dateFacture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idFacture, client, dateFacture);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Facture &&
          other.idFacture == this.idFacture &&
          other.client == this.client &&
          other.dateFacture == this.dateFacture);
}

class FacturesCompanion extends UpdateCompanion<Facture> {
  final Value<String> idFacture;
  final Value<String> client;
  final Value<DateTime> dateFacture;
  final Value<int> rowid;
  const FacturesCompanion({
    this.idFacture = const Value.absent(),
    this.client = const Value.absent(),
    this.dateFacture = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FacturesCompanion.insert({
    required String idFacture,
    required String client,
    required DateTime dateFacture,
    this.rowid = const Value.absent(),
  }) : idFacture = Value(idFacture),
       client = Value(client),
       dateFacture = Value(dateFacture);
  static Insertable<Facture> custom({
    Expression<String>? idFacture,
    Expression<String>? client,
    Expression<DateTime>? dateFacture,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idFacture != null) 'id_facture': idFacture,
      if (client != null) 'client': client,
      if (dateFacture != null) 'date_facture': dateFacture,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FacturesCompanion copyWith({
    Value<String>? idFacture,
    Value<String>? client,
    Value<DateTime>? dateFacture,
    Value<int>? rowid,
  }) {
    return FacturesCompanion(
      idFacture: idFacture ?? this.idFacture,
      client: client ?? this.client,
      dateFacture: dateFacture ?? this.dateFacture,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idFacture.present) {
      map['id_facture'] = Variable<String>(idFacture.value);
    }
    if (client.present) {
      map['client'] = Variable<String>(client.value);
    }
    if (dateFacture.present) {
      map['date_facture'] = Variable<DateTime>(dateFacture.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FacturesCompanion(')
          ..write('idFacture: $idFacture, ')
          ..write('client: $client, ')
          ..write('dateFacture: $dateFacture, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationsTable extends Operations
    with TableInfo<$OperationsTable, Operation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idOperationMeta = const VerificationMeta(
    'idOperation',
  );
  @override
  late final GeneratedColumn<String> idOperation = GeneratedColumn<String>(
    'id_operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomOperationMeta = const VerificationMeta(
    'nomOperation',
  );
  @override
  late final GeneratedColumn<String> nomOperation = GeneratedColumn<String>(
    'nom_operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prixOperationMeta = const VerificationMeta(
    'prixOperation',
  );
  @override
  late final GeneratedColumn<int> prixOperation = GeneratedColumn<int>(
    'prix_operation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantiteOperationMeta = const VerificationMeta(
    'quantiteOperation',
  );
  @override
  late final GeneratedColumn<int> quantiteOperation = GeneratedColumn<int>(
    'quantite_operation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factureMeta = const VerificationMeta(
    'facture',
  );
  @override
  late final GeneratedColumn<String> facture = GeneratedColumn<String>(
    'facture',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES factures (id_facture)',
    ),
  );
  static const VerificationMeta _dateOperationMeta = const VerificationMeta(
    'dateOperation',
  );
  @override
  late final GeneratedColumn<DateTime> dateOperation =
      GeneratedColumn<DateTime>(
        'date_operation',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    idOperation,
    nomOperation,
    prixOperation,
    quantiteOperation,
    facture,
    dateOperation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Operation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_operation')) {
      context.handle(
        _idOperationMeta,
        idOperation.isAcceptableOrUnknown(
          data['id_operation']!,
          _idOperationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idOperationMeta);
    }
    if (data.containsKey('nom_operation')) {
      context.handle(
        _nomOperationMeta,
        nomOperation.isAcceptableOrUnknown(
          data['nom_operation']!,
          _nomOperationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nomOperationMeta);
    }
    if (data.containsKey('prix_operation')) {
      context.handle(
        _prixOperationMeta,
        prixOperation.isAcceptableOrUnknown(
          data['prix_operation']!,
          _prixOperationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prixOperationMeta);
    }
    if (data.containsKey('quantite_operation')) {
      context.handle(
        _quantiteOperationMeta,
        quantiteOperation.isAcceptableOrUnknown(
          data['quantite_operation']!,
          _quantiteOperationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantiteOperationMeta);
    }
    if (data.containsKey('facture')) {
      context.handle(
        _factureMeta,
        facture.isAcceptableOrUnknown(data['facture']!, _factureMeta),
      );
    }
    if (data.containsKey('date_operation')) {
      context.handle(
        _dateOperationMeta,
        dateOperation.isAcceptableOrUnknown(
          data['date_operation']!,
          _dateOperationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateOperationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Operation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Operation(
      idOperation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_operation'],
      )!,
      nomOperation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom_operation'],
      )!,
      prixOperation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prix_operation'],
      )!,
      quantiteOperation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantite_operation'],
      )!,
      facture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facture'],
      ),
      dateOperation: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_operation'],
      )!,
    );
  }

  @override
  $OperationsTable createAlias(String alias) {
    return $OperationsTable(attachedDatabase, alias);
  }
}

class Operation extends DataClass implements Insertable<Operation> {
  final String idOperation;
  final String nomOperation;
  final int prixOperation;
  final int quantiteOperation;
  final String? facture;
  final DateTime dateOperation;
  const Operation({
    required this.idOperation,
    required this.nomOperation,
    required this.prixOperation,
    required this.quantiteOperation,
    this.facture,
    required this.dateOperation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_operation'] = Variable<String>(idOperation);
    map['nom_operation'] = Variable<String>(nomOperation);
    map['prix_operation'] = Variable<int>(prixOperation);
    map['quantite_operation'] = Variable<int>(quantiteOperation);
    if (!nullToAbsent || facture != null) {
      map['facture'] = Variable<String>(facture);
    }
    map['date_operation'] = Variable<DateTime>(dateOperation);
    return map;
  }

  OperationsCompanion toCompanion(bool nullToAbsent) {
    return OperationsCompanion(
      idOperation: Value(idOperation),
      nomOperation: Value(nomOperation),
      prixOperation: Value(prixOperation),
      quantiteOperation: Value(quantiteOperation),
      facture: facture == null && nullToAbsent
          ? const Value.absent()
          : Value(facture),
      dateOperation: Value(dateOperation),
    );
  }

  factory Operation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Operation(
      idOperation: serializer.fromJson<String>(json['idOperation']),
      nomOperation: serializer.fromJson<String>(json['nomOperation']),
      prixOperation: serializer.fromJson<int>(json['prixOperation']),
      quantiteOperation: serializer.fromJson<int>(json['quantiteOperation']),
      facture: serializer.fromJson<String?>(json['facture']),
      dateOperation: serializer.fromJson<DateTime>(json['dateOperation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idOperation': serializer.toJson<String>(idOperation),
      'nomOperation': serializer.toJson<String>(nomOperation),
      'prixOperation': serializer.toJson<int>(prixOperation),
      'quantiteOperation': serializer.toJson<int>(quantiteOperation),
      'facture': serializer.toJson<String?>(facture),
      'dateOperation': serializer.toJson<DateTime>(dateOperation),
    };
  }

  Operation copyWith({
    String? idOperation,
    String? nomOperation,
    int? prixOperation,
    int? quantiteOperation,
    Value<String?> facture = const Value.absent(),
    DateTime? dateOperation,
  }) => Operation(
    idOperation: idOperation ?? this.idOperation,
    nomOperation: nomOperation ?? this.nomOperation,
    prixOperation: prixOperation ?? this.prixOperation,
    quantiteOperation: quantiteOperation ?? this.quantiteOperation,
    facture: facture.present ? facture.value : this.facture,
    dateOperation: dateOperation ?? this.dateOperation,
  );
  Operation copyWithCompanion(OperationsCompanion data) {
    return Operation(
      idOperation: data.idOperation.present
          ? data.idOperation.value
          : this.idOperation,
      nomOperation: data.nomOperation.present
          ? data.nomOperation.value
          : this.nomOperation,
      prixOperation: data.prixOperation.present
          ? data.prixOperation.value
          : this.prixOperation,
      quantiteOperation: data.quantiteOperation.present
          ? data.quantiteOperation.value
          : this.quantiteOperation,
      facture: data.facture.present ? data.facture.value : this.facture,
      dateOperation: data.dateOperation.present
          ? data.dateOperation.value
          : this.dateOperation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Operation(')
          ..write('idOperation: $idOperation, ')
          ..write('nomOperation: $nomOperation, ')
          ..write('prixOperation: $prixOperation, ')
          ..write('quantiteOperation: $quantiteOperation, ')
          ..write('facture: $facture, ')
          ..write('dateOperation: $dateOperation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idOperation,
    nomOperation,
    prixOperation,
    quantiteOperation,
    facture,
    dateOperation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Operation &&
          other.idOperation == this.idOperation &&
          other.nomOperation == this.nomOperation &&
          other.prixOperation == this.prixOperation &&
          other.quantiteOperation == this.quantiteOperation &&
          other.facture == this.facture &&
          other.dateOperation == this.dateOperation);
}

class OperationsCompanion extends UpdateCompanion<Operation> {
  final Value<String> idOperation;
  final Value<String> nomOperation;
  final Value<int> prixOperation;
  final Value<int> quantiteOperation;
  final Value<String?> facture;
  final Value<DateTime> dateOperation;
  final Value<int> rowid;
  const OperationsCompanion({
    this.idOperation = const Value.absent(),
    this.nomOperation = const Value.absent(),
    this.prixOperation = const Value.absent(),
    this.quantiteOperation = const Value.absent(),
    this.facture = const Value.absent(),
    this.dateOperation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationsCompanion.insert({
    required String idOperation,
    required String nomOperation,
    required int prixOperation,
    required int quantiteOperation,
    this.facture = const Value.absent(),
    required DateTime dateOperation,
    this.rowid = const Value.absent(),
  }) : idOperation = Value(idOperation),
       nomOperation = Value(nomOperation),
       prixOperation = Value(prixOperation),
       quantiteOperation = Value(quantiteOperation),
       dateOperation = Value(dateOperation);
  static Insertable<Operation> custom({
    Expression<String>? idOperation,
    Expression<String>? nomOperation,
    Expression<int>? prixOperation,
    Expression<int>? quantiteOperation,
    Expression<String>? facture,
    Expression<DateTime>? dateOperation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idOperation != null) 'id_operation': idOperation,
      if (nomOperation != null) 'nom_operation': nomOperation,
      if (prixOperation != null) 'prix_operation': prixOperation,
      if (quantiteOperation != null) 'quantite_operation': quantiteOperation,
      if (facture != null) 'facture': facture,
      if (dateOperation != null) 'date_operation': dateOperation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationsCompanion copyWith({
    Value<String>? idOperation,
    Value<String>? nomOperation,
    Value<int>? prixOperation,
    Value<int>? quantiteOperation,
    Value<String?>? facture,
    Value<DateTime>? dateOperation,
    Value<int>? rowid,
  }) {
    return OperationsCompanion(
      idOperation: idOperation ?? this.idOperation,
      nomOperation: nomOperation ?? this.nomOperation,
      prixOperation: prixOperation ?? this.prixOperation,
      quantiteOperation: quantiteOperation ?? this.quantiteOperation,
      facture: facture ?? this.facture,
      dateOperation: dateOperation ?? this.dateOperation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idOperation.present) {
      map['id_operation'] = Variable<String>(idOperation.value);
    }
    if (nomOperation.present) {
      map['nom_operation'] = Variable<String>(nomOperation.value);
    }
    if (prixOperation.present) {
      map['prix_operation'] = Variable<int>(prixOperation.value);
    }
    if (quantiteOperation.present) {
      map['quantite_operation'] = Variable<int>(quantiteOperation.value);
    }
    if (facture.present) {
      map['facture'] = Variable<String>(facture.value);
    }
    if (dateOperation.present) {
      map['date_operation'] = Variable<DateTime>(dateOperation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationsCompanion(')
          ..write('idOperation: $idOperation, ')
          ..write('nomOperation: $nomOperation, ')
          ..write('prixOperation: $prixOperation, ')
          ..write('quantiteOperation: $quantiteOperation, ')
          ..write('facture: $facture, ')
          ..write('dateOperation: $dateOperation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DepensesTable extends Depenses with TableInfo<$DepensesTable, Depense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idDepenseMeta = const VerificationMeta(
    'idDepense',
  );
  @override
  late final GeneratedColumn<String> idDepense = GeneratedColumn<String>(
    'id_depense',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libelleMeta = const VerificationMeta(
    'libelle',
  );
  @override
  late final GeneratedColumn<String> libelle = GeneratedColumn<String>(
    'libelle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantMeta = const VerificationMeta(
    'montant',
  );
  @override
  late final GeneratedColumn<int> montant = GeneratedColumn<int>(
    'montant',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateDepenseMeta = const VerificationMeta(
    'dateDepense',
  );
  @override
  late final GeneratedColumn<DateTime> dateDepense = GeneratedColumn<DateTime>(
    'date_depense',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idDepense,
    libelle,
    montant,
    dateDepense,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'depenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Depense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_depense')) {
      context.handle(
        _idDepenseMeta,
        idDepense.isAcceptableOrUnknown(data['id_depense']!, _idDepenseMeta),
      );
    } else if (isInserting) {
      context.missing(_idDepenseMeta);
    }
    if (data.containsKey('libelle')) {
      context.handle(
        _libelleMeta,
        libelle.isAcceptableOrUnknown(data['libelle']!, _libelleMeta),
      );
    } else if (isInserting) {
      context.missing(_libelleMeta);
    }
    if (data.containsKey('montant')) {
      context.handle(
        _montantMeta,
        montant.isAcceptableOrUnknown(data['montant']!, _montantMeta),
      );
    } else if (isInserting) {
      context.missing(_montantMeta);
    }
    if (data.containsKey('date_depense')) {
      context.handle(
        _dateDepenseMeta,
        dateDepense.isAcceptableOrUnknown(
          data['date_depense']!,
          _dateDepenseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateDepenseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Depense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Depense(
      idDepense: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_depense'],
      )!,
      libelle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}libelle'],
      )!,
      montant: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant'],
      )!,
      dateDepense: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_depense'],
      )!,
    );
  }

  @override
  $DepensesTable createAlias(String alias) {
    return $DepensesTable(attachedDatabase, alias);
  }
}

class Depense extends DataClass implements Insertable<Depense> {
  final String idDepense;
  final String libelle;
  final int montant;
  final DateTime dateDepense;
  const Depense({
    required this.idDepense,
    required this.libelle,
    required this.montant,
    required this.dateDepense,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_depense'] = Variable<String>(idDepense);
    map['libelle'] = Variable<String>(libelle);
    map['montant'] = Variable<int>(montant);
    map['date_depense'] = Variable<DateTime>(dateDepense);
    return map;
  }

  DepensesCompanion toCompanion(bool nullToAbsent) {
    return DepensesCompanion(
      idDepense: Value(idDepense),
      libelle: Value(libelle),
      montant: Value(montant),
      dateDepense: Value(dateDepense),
    );
  }

  factory Depense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Depense(
      idDepense: serializer.fromJson<String>(json['idDepense']),
      libelle: serializer.fromJson<String>(json['libelle']),
      montant: serializer.fromJson<int>(json['montant']),
      dateDepense: serializer.fromJson<DateTime>(json['dateDepense']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idDepense': serializer.toJson<String>(idDepense),
      'libelle': serializer.toJson<String>(libelle),
      'montant': serializer.toJson<int>(montant),
      'dateDepense': serializer.toJson<DateTime>(dateDepense),
    };
  }

  Depense copyWith({
    String? idDepense,
    String? libelle,
    int? montant,
    DateTime? dateDepense,
  }) => Depense(
    idDepense: idDepense ?? this.idDepense,
    libelle: libelle ?? this.libelle,
    montant: montant ?? this.montant,
    dateDepense: dateDepense ?? this.dateDepense,
  );
  Depense copyWithCompanion(DepensesCompanion data) {
    return Depense(
      idDepense: data.idDepense.present ? data.idDepense.value : this.idDepense,
      libelle: data.libelle.present ? data.libelle.value : this.libelle,
      montant: data.montant.present ? data.montant.value : this.montant,
      dateDepense: data.dateDepense.present
          ? data.dateDepense.value
          : this.dateDepense,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Depense(')
          ..write('idDepense: $idDepense, ')
          ..write('libelle: $libelle, ')
          ..write('montant: $montant, ')
          ..write('dateDepense: $dateDepense')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idDepense, libelle, montant, dateDepense);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Depense &&
          other.idDepense == this.idDepense &&
          other.libelle == this.libelle &&
          other.montant == this.montant &&
          other.dateDepense == this.dateDepense);
}

class DepensesCompanion extends UpdateCompanion<Depense> {
  final Value<String> idDepense;
  final Value<String> libelle;
  final Value<int> montant;
  final Value<DateTime> dateDepense;
  final Value<int> rowid;
  const DepensesCompanion({
    this.idDepense = const Value.absent(),
    this.libelle = const Value.absent(),
    this.montant = const Value.absent(),
    this.dateDepense = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DepensesCompanion.insert({
    required String idDepense,
    required String libelle,
    required int montant,
    required DateTime dateDepense,
    this.rowid = const Value.absent(),
  }) : idDepense = Value(idDepense),
       libelle = Value(libelle),
       montant = Value(montant),
       dateDepense = Value(dateDepense);
  static Insertable<Depense> custom({
    Expression<String>? idDepense,
    Expression<String>? libelle,
    Expression<int>? montant,
    Expression<DateTime>? dateDepense,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idDepense != null) 'id_depense': idDepense,
      if (libelle != null) 'libelle': libelle,
      if (montant != null) 'montant': montant,
      if (dateDepense != null) 'date_depense': dateDepense,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DepensesCompanion copyWith({
    Value<String>? idDepense,
    Value<String>? libelle,
    Value<int>? montant,
    Value<DateTime>? dateDepense,
    Value<int>? rowid,
  }) {
    return DepensesCompanion(
      idDepense: idDepense ?? this.idDepense,
      libelle: libelle ?? this.libelle,
      montant: montant ?? this.montant,
      dateDepense: dateDepense ?? this.dateDepense,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idDepense.present) {
      map['id_depense'] = Variable<String>(idDepense.value);
    }
    if (libelle.present) {
      map['libelle'] = Variable<String>(libelle.value);
    }
    if (montant.present) {
      map['montant'] = Variable<int>(montant.value);
    }
    if (dateDepense.present) {
      map['date_depense'] = Variable<DateTime>(dateDepense.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepensesCompanion(')
          ..write('idDepense: $idDepense, ')
          ..write('libelle: $libelle, ')
          ..write('montant: $montant, ')
          ..write('dateDepense: $dateDepense, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrelevementsTable extends Prelevements
    with TableInfo<$PrelevementsTable, Prelevement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrelevementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idPrelevementMeta = const VerificationMeta(
    'idPrelevement',
  );
  @override
  late final GeneratedColumn<String> idPrelevement = GeneratedColumn<String>(
    'id_prelevement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantMeta = const VerificationMeta(
    'montant',
  );
  @override
  late final GeneratedColumn<int> montant = GeneratedColumn<int>(
    'montant',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datePrelevementMeta = const VerificationMeta(
    'datePrelevement',
  );
  @override
  late final GeneratedColumn<DateTime> datePrelevement =
      GeneratedColumn<DateTime>(
        'date_prelevement',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    idPrelevement,
    montant,
    datePrelevement,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prelevements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Prelevement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_prelevement')) {
      context.handle(
        _idPrelevementMeta,
        idPrelevement.isAcceptableOrUnknown(
          data['id_prelevement']!,
          _idPrelevementMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idPrelevementMeta);
    }
    if (data.containsKey('montant')) {
      context.handle(
        _montantMeta,
        montant.isAcceptableOrUnknown(data['montant']!, _montantMeta),
      );
    } else if (isInserting) {
      context.missing(_montantMeta);
    }
    if (data.containsKey('date_prelevement')) {
      context.handle(
        _datePrelevementMeta,
        datePrelevement.isAcceptableOrUnknown(
          data['date_prelevement']!,
          _datePrelevementMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_datePrelevementMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Prelevement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prelevement(
      idPrelevement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_prelevement'],
      )!,
      montant: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant'],
      )!,
      datePrelevement: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_prelevement'],
      )!,
    );
  }

  @override
  $PrelevementsTable createAlias(String alias) {
    return $PrelevementsTable(attachedDatabase, alias);
  }
}

class Prelevement extends DataClass implements Insertable<Prelevement> {
  final String idPrelevement;
  final int montant;
  final DateTime datePrelevement;
  const Prelevement({
    required this.idPrelevement,
    required this.montant,
    required this.datePrelevement,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_prelevement'] = Variable<String>(idPrelevement);
    map['montant'] = Variable<int>(montant);
    map['date_prelevement'] = Variable<DateTime>(datePrelevement);
    return map;
  }

  PrelevementsCompanion toCompanion(bool nullToAbsent) {
    return PrelevementsCompanion(
      idPrelevement: Value(idPrelevement),
      montant: Value(montant),
      datePrelevement: Value(datePrelevement),
    );
  }

  factory Prelevement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prelevement(
      idPrelevement: serializer.fromJson<String>(json['idPrelevement']),
      montant: serializer.fromJson<int>(json['montant']),
      datePrelevement: serializer.fromJson<DateTime>(json['datePrelevement']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idPrelevement': serializer.toJson<String>(idPrelevement),
      'montant': serializer.toJson<int>(montant),
      'datePrelevement': serializer.toJson<DateTime>(datePrelevement),
    };
  }

  Prelevement copyWith({
    String? idPrelevement,
    int? montant,
    DateTime? datePrelevement,
  }) => Prelevement(
    idPrelevement: idPrelevement ?? this.idPrelevement,
    montant: montant ?? this.montant,
    datePrelevement: datePrelevement ?? this.datePrelevement,
  );
  Prelevement copyWithCompanion(PrelevementsCompanion data) {
    return Prelevement(
      idPrelevement: data.idPrelevement.present
          ? data.idPrelevement.value
          : this.idPrelevement,
      montant: data.montant.present ? data.montant.value : this.montant,
      datePrelevement: data.datePrelevement.present
          ? data.datePrelevement.value
          : this.datePrelevement,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prelevement(')
          ..write('idPrelevement: $idPrelevement, ')
          ..write('montant: $montant, ')
          ..write('datePrelevement: $datePrelevement')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idPrelevement, montant, datePrelevement);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prelevement &&
          other.idPrelevement == this.idPrelevement &&
          other.montant == this.montant &&
          other.datePrelevement == this.datePrelevement);
}

class PrelevementsCompanion extends UpdateCompanion<Prelevement> {
  final Value<String> idPrelevement;
  final Value<int> montant;
  final Value<DateTime> datePrelevement;
  final Value<int> rowid;
  const PrelevementsCompanion({
    this.idPrelevement = const Value.absent(),
    this.montant = const Value.absent(),
    this.datePrelevement = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrelevementsCompanion.insert({
    required String idPrelevement,
    required int montant,
    required DateTime datePrelevement,
    this.rowid = const Value.absent(),
  }) : idPrelevement = Value(idPrelevement),
       montant = Value(montant),
       datePrelevement = Value(datePrelevement);
  static Insertable<Prelevement> custom({
    Expression<String>? idPrelevement,
    Expression<int>? montant,
    Expression<DateTime>? datePrelevement,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idPrelevement != null) 'id_prelevement': idPrelevement,
      if (montant != null) 'montant': montant,
      if (datePrelevement != null) 'date_prelevement': datePrelevement,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrelevementsCompanion copyWith({
    Value<String>? idPrelevement,
    Value<int>? montant,
    Value<DateTime>? datePrelevement,
    Value<int>? rowid,
  }) {
    return PrelevementsCompanion(
      idPrelevement: idPrelevement ?? this.idPrelevement,
      montant: montant ?? this.montant,
      datePrelevement: datePrelevement ?? this.datePrelevement,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idPrelevement.present) {
      map['id_prelevement'] = Variable<String>(idPrelevement.value);
    }
    if (montant.present) {
      map['montant'] = Variable<int>(montant.value);
    }
    if (datePrelevement.present) {
      map['date_prelevement'] = Variable<DateTime>(datePrelevement.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrelevementsCompanion(')
          ..write('idPrelevement: $idPrelevement, ')
          ..write('montant: $montant, ')
          ..write('datePrelevement: $datePrelevement, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelevesTable extends Releves with TableInfo<$RelevesTable, Releve> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelevesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idReleveMeta = const VerificationMeta(
    'idReleve',
  );
  @override
  late final GeneratedColumn<String> idReleve = GeneratedColumn<String>(
    'id_releve',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compteurMeta = const VerificationMeta(
    'compteur',
  );
  @override
  late final GeneratedColumn<double> compteur = GeneratedColumn<double>(
    'compteur',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sousCompteurMeta = const VerificationMeta(
    'sousCompteur',
  );
  @override
  late final GeneratedColumn<double> sousCompteur = GeneratedColumn<double>(
    'sous_compteur',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateReleveMeta = const VerificationMeta(
    'dateReleve',
  );
  @override
  late final GeneratedColumn<DateTime> dateReleve = GeneratedColumn<DateTime>(
    'date_releve',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idReleve,
    compteur,
    sousCompteur,
    dateReleve,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'releves';
  @override
  VerificationContext validateIntegrity(
    Insertable<Releve> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_releve')) {
      context.handle(
        _idReleveMeta,
        idReleve.isAcceptableOrUnknown(data['id_releve']!, _idReleveMeta),
      );
    } else if (isInserting) {
      context.missing(_idReleveMeta);
    }
    if (data.containsKey('compteur')) {
      context.handle(
        _compteurMeta,
        compteur.isAcceptableOrUnknown(data['compteur']!, _compteurMeta),
      );
    } else if (isInserting) {
      context.missing(_compteurMeta);
    }
    if (data.containsKey('sous_compteur')) {
      context.handle(
        _sousCompteurMeta,
        sousCompteur.isAcceptableOrUnknown(
          data['sous_compteur']!,
          _sousCompteurMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sousCompteurMeta);
    }
    if (data.containsKey('date_releve')) {
      context.handle(
        _dateReleveMeta,
        dateReleve.isAcceptableOrUnknown(data['date_releve']!, _dateReleveMeta),
      );
    } else if (isInserting) {
      context.missing(_dateReleveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Releve map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Releve(
      idReleve: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_releve'],
      )!,
      compteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}compteur'],
      )!,
      sousCompteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sous_compteur'],
      )!,
      dateReleve: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_releve'],
      )!,
    );
  }

  @override
  $RelevesTable createAlias(String alias) {
    return $RelevesTable(attachedDatabase, alias);
  }
}

class Releve extends DataClass implements Insertable<Releve> {
  final String idReleve;
  final double compteur;
  final double sousCompteur;
  final DateTime dateReleve;
  const Releve({
    required this.idReleve,
    required this.compteur,
    required this.sousCompteur,
    required this.dateReleve,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_releve'] = Variable<String>(idReleve);
    map['compteur'] = Variable<double>(compteur);
    map['sous_compteur'] = Variable<double>(sousCompteur);
    map['date_releve'] = Variable<DateTime>(dateReleve);
    return map;
  }

  RelevesCompanion toCompanion(bool nullToAbsent) {
    return RelevesCompanion(
      idReleve: Value(idReleve),
      compteur: Value(compteur),
      sousCompteur: Value(sousCompteur),
      dateReleve: Value(dateReleve),
    );
  }

  factory Releve.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Releve(
      idReleve: serializer.fromJson<String>(json['idReleve']),
      compteur: serializer.fromJson<double>(json['compteur']),
      sousCompteur: serializer.fromJson<double>(json['sousCompteur']),
      dateReleve: serializer.fromJson<DateTime>(json['dateReleve']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idReleve': serializer.toJson<String>(idReleve),
      'compteur': serializer.toJson<double>(compteur),
      'sousCompteur': serializer.toJson<double>(sousCompteur),
      'dateReleve': serializer.toJson<DateTime>(dateReleve),
    };
  }

  Releve copyWith({
    String? idReleve,
    double? compteur,
    double? sousCompteur,
    DateTime? dateReleve,
  }) => Releve(
    idReleve: idReleve ?? this.idReleve,
    compteur: compteur ?? this.compteur,
    sousCompteur: sousCompteur ?? this.sousCompteur,
    dateReleve: dateReleve ?? this.dateReleve,
  );
  Releve copyWithCompanion(RelevesCompanion data) {
    return Releve(
      idReleve: data.idReleve.present ? data.idReleve.value : this.idReleve,
      compteur: data.compteur.present ? data.compteur.value : this.compteur,
      sousCompteur: data.sousCompteur.present
          ? data.sousCompteur.value
          : this.sousCompteur,
      dateReleve: data.dateReleve.present
          ? data.dateReleve.value
          : this.dateReleve,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Releve(')
          ..write('idReleve: $idReleve, ')
          ..write('compteur: $compteur, ')
          ..write('sousCompteur: $sousCompteur, ')
          ..write('dateReleve: $dateReleve')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idReleve, compteur, sousCompteur, dateReleve);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Releve &&
          other.idReleve == this.idReleve &&
          other.compteur == this.compteur &&
          other.sousCompteur == this.sousCompteur &&
          other.dateReleve == this.dateReleve);
}

class RelevesCompanion extends UpdateCompanion<Releve> {
  final Value<String> idReleve;
  final Value<double> compteur;
  final Value<double> sousCompteur;
  final Value<DateTime> dateReleve;
  final Value<int> rowid;
  const RelevesCompanion({
    this.idReleve = const Value.absent(),
    this.compteur = const Value.absent(),
    this.sousCompteur = const Value.absent(),
    this.dateReleve = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelevesCompanion.insert({
    required String idReleve,
    required double compteur,
    required double sousCompteur,
    required DateTime dateReleve,
    this.rowid = const Value.absent(),
  }) : idReleve = Value(idReleve),
       compteur = Value(compteur),
       sousCompteur = Value(sousCompteur),
       dateReleve = Value(dateReleve);
  static Insertable<Releve> custom({
    Expression<String>? idReleve,
    Expression<double>? compteur,
    Expression<double>? sousCompteur,
    Expression<DateTime>? dateReleve,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idReleve != null) 'id_releve': idReleve,
      if (compteur != null) 'compteur': compteur,
      if (sousCompteur != null) 'sous_compteur': sousCompteur,
      if (dateReleve != null) 'date_releve': dateReleve,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelevesCompanion copyWith({
    Value<String>? idReleve,
    Value<double>? compteur,
    Value<double>? sousCompteur,
    Value<DateTime>? dateReleve,
    Value<int>? rowid,
  }) {
    return RelevesCompanion(
      idReleve: idReleve ?? this.idReleve,
      compteur: compteur ?? this.compteur,
      sousCompteur: sousCompteur ?? this.sousCompteur,
      dateReleve: dateReleve ?? this.dateReleve,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idReleve.present) {
      map['id_releve'] = Variable<String>(idReleve.value);
    }
    if (compteur.present) {
      map['compteur'] = Variable<double>(compteur.value);
    }
    if (sousCompteur.present) {
      map['sous_compteur'] = Variable<double>(sousCompteur.value);
    }
    if (dateReleve.present) {
      map['date_releve'] = Variable<DateTime>(dateReleve.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelevesCompanion(')
          ..write('idReleve: $idReleve, ')
          ..write('compteur: $compteur, ')
          ..write('sousCompteur: $sousCompteur, ')
          ..write('dateReleve: $dateReleve, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FacturesJiroTable extends FacturesJiro
    with TableInfo<$FacturesJiroTable, FacturesJiroData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FacturesJiroTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idFactureJiroMeta = const VerificationMeta(
    'idFactureJiro',
  );
  @override
  late final GeneratedColumn<String> idFactureJiro = GeneratedColumn<String>(
    'id_facture_jiro',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moisMeta = const VerificationMeta('mois');
  @override
  late final GeneratedColumn<String> mois = GeneratedColumn<String>(
    'mois',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateAncienIndexMeta = const VerificationMeta(
    'dateAncienIndex',
  );
  @override
  late final GeneratedColumn<DateTime> dateAncienIndex =
      GeneratedColumn<DateTime>(
        'date_ancien_index',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dateNouvelIndexMeta = const VerificationMeta(
    'dateNouvelIndex',
  );
  @override
  late final GeneratedColumn<DateTime> dateNouvelIndex =
      GeneratedColumn<DateTime>(
        'date_nouvel_index',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _ancienIndexCompteurMeta =
      const VerificationMeta('ancienIndexCompteur');
  @override
  late final GeneratedColumn<double> ancienIndexCompteur =
      GeneratedColumn<double>(
        'ancien_index_compteur',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nouvelIndexCompteurMeta =
      const VerificationMeta('nouvelIndexCompteur');
  @override
  late final GeneratedColumn<double> nouvelIndexCompteur =
      GeneratedColumn<double>(
        'nouvel_index_compteur',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _ancienIndexSousCompteurMeta =
      const VerificationMeta('ancienIndexSousCompteur');
  @override
  late final GeneratedColumn<double> ancienIndexSousCompteur =
      GeneratedColumn<double>(
        'ancien_index_sous_compteur',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nouvelIndexSousCompteurMeta =
      const VerificationMeta('nouvelIndexSousCompteur');
  @override
  late final GeneratedColumn<double> nouvelIndexSousCompteur =
      GeneratedColumn<double>(
        'nouvel_index_sous_compteur',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _prixUnitaireKwhMeta = const VerificationMeta(
    'prixUnitaireKwh',
  );
  @override
  late final GeneratedColumn<double> prixUnitaireKwh = GeneratedColumn<double>(
    'prix_unitaire_kwh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _redevanceJiramaMeta = const VerificationMeta(
    'redevanceJirama',
  );
  @override
  late final GeneratedColumn<double> redevanceJirama = GeneratedColumn<double>(
    'redevance_jirama',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primeFixeJiramaMeta = const VerificationMeta(
    'primeFixeJirama',
  );
  @override
  late final GeneratedColumn<double> primeFixeJirama = GeneratedColumn<double>(
    'prime_fixe_jirama',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxesRedevancesMeta = const VerificationMeta(
    'taxesRedevances',
  );
  @override
  late final GeneratedColumn<double> taxesRedevances = GeneratedColumn<double>(
    'taxes_redevances',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tvaMeta = const VerificationMeta('tva');
  @override
  late final GeneratedColumn<double> tva = GeneratedColumn<double>(
    'tva',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateFactureMeta = const VerificationMeta(
    'dateFacture',
  );
  @override
  late final GeneratedColumn<DateTime> dateFacture = GeneratedColumn<DateTime>(
    'date_facture',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idFactureJiro,
    mois,
    dateAncienIndex,
    dateNouvelIndex,
    ancienIndexCompteur,
    nouvelIndexCompteur,
    ancienIndexSousCompteur,
    nouvelIndexSousCompteur,
    prixUnitaireKwh,
    redevanceJirama,
    primeFixeJirama,
    taxesRedevances,
    tva,
    dateFacture,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'factures_jiro';
  @override
  VerificationContext validateIntegrity(
    Insertable<FacturesJiroData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_facture_jiro')) {
      context.handle(
        _idFactureJiroMeta,
        idFactureJiro.isAcceptableOrUnknown(
          data['id_facture_jiro']!,
          _idFactureJiroMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idFactureJiroMeta);
    }
    if (data.containsKey('mois')) {
      context.handle(
        _moisMeta,
        mois.isAcceptableOrUnknown(data['mois']!, _moisMeta),
      );
    } else if (isInserting) {
      context.missing(_moisMeta);
    }
    if (data.containsKey('date_ancien_index')) {
      context.handle(
        _dateAncienIndexMeta,
        dateAncienIndex.isAcceptableOrUnknown(
          data['date_ancien_index']!,
          _dateAncienIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateAncienIndexMeta);
    }
    if (data.containsKey('date_nouvel_index')) {
      context.handle(
        _dateNouvelIndexMeta,
        dateNouvelIndex.isAcceptableOrUnknown(
          data['date_nouvel_index']!,
          _dateNouvelIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateNouvelIndexMeta);
    }
    if (data.containsKey('ancien_index_compteur')) {
      context.handle(
        _ancienIndexCompteurMeta,
        ancienIndexCompteur.isAcceptableOrUnknown(
          data['ancien_index_compteur']!,
          _ancienIndexCompteurMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ancienIndexCompteurMeta);
    }
    if (data.containsKey('nouvel_index_compteur')) {
      context.handle(
        _nouvelIndexCompteurMeta,
        nouvelIndexCompteur.isAcceptableOrUnknown(
          data['nouvel_index_compteur']!,
          _nouvelIndexCompteurMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nouvelIndexCompteurMeta);
    }
    if (data.containsKey('ancien_index_sous_compteur')) {
      context.handle(
        _ancienIndexSousCompteurMeta,
        ancienIndexSousCompteur.isAcceptableOrUnknown(
          data['ancien_index_sous_compteur']!,
          _ancienIndexSousCompteurMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ancienIndexSousCompteurMeta);
    }
    if (data.containsKey('nouvel_index_sous_compteur')) {
      context.handle(
        _nouvelIndexSousCompteurMeta,
        nouvelIndexSousCompteur.isAcceptableOrUnknown(
          data['nouvel_index_sous_compteur']!,
          _nouvelIndexSousCompteurMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nouvelIndexSousCompteurMeta);
    }
    if (data.containsKey('prix_unitaire_kwh')) {
      context.handle(
        _prixUnitaireKwhMeta,
        prixUnitaireKwh.isAcceptableOrUnknown(
          data['prix_unitaire_kwh']!,
          _prixUnitaireKwhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prixUnitaireKwhMeta);
    }
    if (data.containsKey('redevance_jirama')) {
      context.handle(
        _redevanceJiramaMeta,
        redevanceJirama.isAcceptableOrUnknown(
          data['redevance_jirama']!,
          _redevanceJiramaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_redevanceJiramaMeta);
    }
    if (data.containsKey('prime_fixe_jirama')) {
      context.handle(
        _primeFixeJiramaMeta,
        primeFixeJirama.isAcceptableOrUnknown(
          data['prime_fixe_jirama']!,
          _primeFixeJiramaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primeFixeJiramaMeta);
    }
    if (data.containsKey('taxes_redevances')) {
      context.handle(
        _taxesRedevancesMeta,
        taxesRedevances.isAcceptableOrUnknown(
          data['taxes_redevances']!,
          _taxesRedevancesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxesRedevancesMeta);
    }
    if (data.containsKey('tva')) {
      context.handle(
        _tvaMeta,
        tva.isAcceptableOrUnknown(data['tva']!, _tvaMeta),
      );
    } else if (isInserting) {
      context.missing(_tvaMeta);
    }
    if (data.containsKey('date_facture')) {
      context.handle(
        _dateFactureMeta,
        dateFacture.isAcceptableOrUnknown(
          data['date_facture']!,
          _dateFactureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateFactureMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  FacturesJiroData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FacturesJiroData(
      idFactureJiro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_facture_jiro'],
      )!,
      mois: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mois'],
      )!,
      dateAncienIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_ancien_index'],
      )!,
      dateNouvelIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_nouvel_index'],
      )!,
      ancienIndexCompteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ancien_index_compteur'],
      )!,
      nouvelIndexCompteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nouvel_index_compteur'],
      )!,
      ancienIndexSousCompteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ancien_index_sous_compteur'],
      )!,
      nouvelIndexSousCompteur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}nouvel_index_sous_compteur'],
      )!,
      prixUnitaireKwh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prix_unitaire_kwh'],
      )!,
      redevanceJirama: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}redevance_jirama'],
      )!,
      primeFixeJirama: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prime_fixe_jirama'],
      )!,
      taxesRedevances: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}taxes_redevances'],
      )!,
      tva: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tva'],
      )!,
      dateFacture: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_facture'],
      )!,
    );
  }

  @override
  $FacturesJiroTable createAlias(String alias) {
    return $FacturesJiroTable(attachedDatabase, alias);
  }
}

class FacturesJiroData extends DataClass
    implements Insertable<FacturesJiroData> {
  final String idFactureJiro;
  final String mois;
  final DateTime dateAncienIndex;
  final DateTime dateNouvelIndex;
  final double ancienIndexCompteur;
  final double nouvelIndexCompteur;
  final double ancienIndexSousCompteur;
  final double nouvelIndexSousCompteur;
  final double prixUnitaireKwh;
  final double redevanceJirama;
  final double primeFixeJirama;
  final double taxesRedevances;
  final double tva;
  final DateTime dateFacture;
  const FacturesJiroData({
    required this.idFactureJiro,
    required this.mois,
    required this.dateAncienIndex,
    required this.dateNouvelIndex,
    required this.ancienIndexCompteur,
    required this.nouvelIndexCompteur,
    required this.ancienIndexSousCompteur,
    required this.nouvelIndexSousCompteur,
    required this.prixUnitaireKwh,
    required this.redevanceJirama,
    required this.primeFixeJirama,
    required this.taxesRedevances,
    required this.tva,
    required this.dateFacture,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_facture_jiro'] = Variable<String>(idFactureJiro);
    map['mois'] = Variable<String>(mois);
    map['date_ancien_index'] = Variable<DateTime>(dateAncienIndex);
    map['date_nouvel_index'] = Variable<DateTime>(dateNouvelIndex);
    map['ancien_index_compteur'] = Variable<double>(ancienIndexCompteur);
    map['nouvel_index_compteur'] = Variable<double>(nouvelIndexCompteur);
    map['ancien_index_sous_compteur'] = Variable<double>(
      ancienIndexSousCompteur,
    );
    map['nouvel_index_sous_compteur'] = Variable<double>(
      nouvelIndexSousCompteur,
    );
    map['prix_unitaire_kwh'] = Variable<double>(prixUnitaireKwh);
    map['redevance_jirama'] = Variable<double>(redevanceJirama);
    map['prime_fixe_jirama'] = Variable<double>(primeFixeJirama);
    map['taxes_redevances'] = Variable<double>(taxesRedevances);
    map['tva'] = Variable<double>(tva);
    map['date_facture'] = Variable<DateTime>(dateFacture);
    return map;
  }

  FacturesJiroCompanion toCompanion(bool nullToAbsent) {
    return FacturesJiroCompanion(
      idFactureJiro: Value(idFactureJiro),
      mois: Value(mois),
      dateAncienIndex: Value(dateAncienIndex),
      dateNouvelIndex: Value(dateNouvelIndex),
      ancienIndexCompteur: Value(ancienIndexCompteur),
      nouvelIndexCompteur: Value(nouvelIndexCompteur),
      ancienIndexSousCompteur: Value(ancienIndexSousCompteur),
      nouvelIndexSousCompteur: Value(nouvelIndexSousCompteur),
      prixUnitaireKwh: Value(prixUnitaireKwh),
      redevanceJirama: Value(redevanceJirama),
      primeFixeJirama: Value(primeFixeJirama),
      taxesRedevances: Value(taxesRedevances),
      tva: Value(tva),
      dateFacture: Value(dateFacture),
    );
  }

  factory FacturesJiroData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FacturesJiroData(
      idFactureJiro: serializer.fromJson<String>(json['idFactureJiro']),
      mois: serializer.fromJson<String>(json['mois']),
      dateAncienIndex: serializer.fromJson<DateTime>(json['dateAncienIndex']),
      dateNouvelIndex: serializer.fromJson<DateTime>(json['dateNouvelIndex']),
      ancienIndexCompteur: serializer.fromJson<double>(
        json['ancienIndexCompteur'],
      ),
      nouvelIndexCompteur: serializer.fromJson<double>(
        json['nouvelIndexCompteur'],
      ),
      ancienIndexSousCompteur: serializer.fromJson<double>(
        json['ancienIndexSousCompteur'],
      ),
      nouvelIndexSousCompteur: serializer.fromJson<double>(
        json['nouvelIndexSousCompteur'],
      ),
      prixUnitaireKwh: serializer.fromJson<double>(json['prixUnitaireKwh']),
      redevanceJirama: serializer.fromJson<double>(json['redevanceJirama']),
      primeFixeJirama: serializer.fromJson<double>(json['primeFixeJirama']),
      taxesRedevances: serializer.fromJson<double>(json['taxesRedevances']),
      tva: serializer.fromJson<double>(json['tva']),
      dateFacture: serializer.fromJson<DateTime>(json['dateFacture']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idFactureJiro': serializer.toJson<String>(idFactureJiro),
      'mois': serializer.toJson<String>(mois),
      'dateAncienIndex': serializer.toJson<DateTime>(dateAncienIndex),
      'dateNouvelIndex': serializer.toJson<DateTime>(dateNouvelIndex),
      'ancienIndexCompteur': serializer.toJson<double>(ancienIndexCompteur),
      'nouvelIndexCompteur': serializer.toJson<double>(nouvelIndexCompteur),
      'ancienIndexSousCompteur': serializer.toJson<double>(
        ancienIndexSousCompteur,
      ),
      'nouvelIndexSousCompteur': serializer.toJson<double>(
        nouvelIndexSousCompteur,
      ),
      'prixUnitaireKwh': serializer.toJson<double>(prixUnitaireKwh),
      'redevanceJirama': serializer.toJson<double>(redevanceJirama),
      'primeFixeJirama': serializer.toJson<double>(primeFixeJirama),
      'taxesRedevances': serializer.toJson<double>(taxesRedevances),
      'tva': serializer.toJson<double>(tva),
      'dateFacture': serializer.toJson<DateTime>(dateFacture),
    };
  }

  FacturesJiroData copyWith({
    String? idFactureJiro,
    String? mois,
    DateTime? dateAncienIndex,
    DateTime? dateNouvelIndex,
    double? ancienIndexCompteur,
    double? nouvelIndexCompteur,
    double? ancienIndexSousCompteur,
    double? nouvelIndexSousCompteur,
    double? prixUnitaireKwh,
    double? redevanceJirama,
    double? primeFixeJirama,
    double? taxesRedevances,
    double? tva,
    DateTime? dateFacture,
  }) => FacturesJiroData(
    idFactureJiro: idFactureJiro ?? this.idFactureJiro,
    mois: mois ?? this.mois,
    dateAncienIndex: dateAncienIndex ?? this.dateAncienIndex,
    dateNouvelIndex: dateNouvelIndex ?? this.dateNouvelIndex,
    ancienIndexCompteur: ancienIndexCompteur ?? this.ancienIndexCompteur,
    nouvelIndexCompteur: nouvelIndexCompteur ?? this.nouvelIndexCompteur,
    ancienIndexSousCompteur:
        ancienIndexSousCompteur ?? this.ancienIndexSousCompteur,
    nouvelIndexSousCompteur:
        nouvelIndexSousCompteur ?? this.nouvelIndexSousCompteur,
    prixUnitaireKwh: prixUnitaireKwh ?? this.prixUnitaireKwh,
    redevanceJirama: redevanceJirama ?? this.redevanceJirama,
    primeFixeJirama: primeFixeJirama ?? this.primeFixeJirama,
    taxesRedevances: taxesRedevances ?? this.taxesRedevances,
    tva: tva ?? this.tva,
    dateFacture: dateFacture ?? this.dateFacture,
  );
  FacturesJiroData copyWithCompanion(FacturesJiroCompanion data) {
    return FacturesJiroData(
      idFactureJiro: data.idFactureJiro.present
          ? data.idFactureJiro.value
          : this.idFactureJiro,
      mois: data.mois.present ? data.mois.value : this.mois,
      dateAncienIndex: data.dateAncienIndex.present
          ? data.dateAncienIndex.value
          : this.dateAncienIndex,
      dateNouvelIndex: data.dateNouvelIndex.present
          ? data.dateNouvelIndex.value
          : this.dateNouvelIndex,
      ancienIndexCompteur: data.ancienIndexCompteur.present
          ? data.ancienIndexCompteur.value
          : this.ancienIndexCompteur,
      nouvelIndexCompteur: data.nouvelIndexCompteur.present
          ? data.nouvelIndexCompteur.value
          : this.nouvelIndexCompteur,
      ancienIndexSousCompteur: data.ancienIndexSousCompteur.present
          ? data.ancienIndexSousCompteur.value
          : this.ancienIndexSousCompteur,
      nouvelIndexSousCompteur: data.nouvelIndexSousCompteur.present
          ? data.nouvelIndexSousCompteur.value
          : this.nouvelIndexSousCompteur,
      prixUnitaireKwh: data.prixUnitaireKwh.present
          ? data.prixUnitaireKwh.value
          : this.prixUnitaireKwh,
      redevanceJirama: data.redevanceJirama.present
          ? data.redevanceJirama.value
          : this.redevanceJirama,
      primeFixeJirama: data.primeFixeJirama.present
          ? data.primeFixeJirama.value
          : this.primeFixeJirama,
      taxesRedevances: data.taxesRedevances.present
          ? data.taxesRedevances.value
          : this.taxesRedevances,
      tva: data.tva.present ? data.tva.value : this.tva,
      dateFacture: data.dateFacture.present
          ? data.dateFacture.value
          : this.dateFacture,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FacturesJiroData(')
          ..write('idFactureJiro: $idFactureJiro, ')
          ..write('mois: $mois, ')
          ..write('dateAncienIndex: $dateAncienIndex, ')
          ..write('dateNouvelIndex: $dateNouvelIndex, ')
          ..write('ancienIndexCompteur: $ancienIndexCompteur, ')
          ..write('nouvelIndexCompteur: $nouvelIndexCompteur, ')
          ..write('ancienIndexSousCompteur: $ancienIndexSousCompteur, ')
          ..write('nouvelIndexSousCompteur: $nouvelIndexSousCompteur, ')
          ..write('prixUnitaireKwh: $prixUnitaireKwh, ')
          ..write('redevanceJirama: $redevanceJirama, ')
          ..write('primeFixeJirama: $primeFixeJirama, ')
          ..write('taxesRedevances: $taxesRedevances, ')
          ..write('tva: $tva, ')
          ..write('dateFacture: $dateFacture')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idFactureJiro,
    mois,
    dateAncienIndex,
    dateNouvelIndex,
    ancienIndexCompteur,
    nouvelIndexCompteur,
    ancienIndexSousCompteur,
    nouvelIndexSousCompteur,
    prixUnitaireKwh,
    redevanceJirama,
    primeFixeJirama,
    taxesRedevances,
    tva,
    dateFacture,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FacturesJiroData &&
          other.idFactureJiro == this.idFactureJiro &&
          other.mois == this.mois &&
          other.dateAncienIndex == this.dateAncienIndex &&
          other.dateNouvelIndex == this.dateNouvelIndex &&
          other.ancienIndexCompteur == this.ancienIndexCompteur &&
          other.nouvelIndexCompteur == this.nouvelIndexCompteur &&
          other.ancienIndexSousCompteur == this.ancienIndexSousCompteur &&
          other.nouvelIndexSousCompteur == this.nouvelIndexSousCompteur &&
          other.prixUnitaireKwh == this.prixUnitaireKwh &&
          other.redevanceJirama == this.redevanceJirama &&
          other.primeFixeJirama == this.primeFixeJirama &&
          other.taxesRedevances == this.taxesRedevances &&
          other.tva == this.tva &&
          other.dateFacture == this.dateFacture);
}

class FacturesJiroCompanion extends UpdateCompanion<FacturesJiroData> {
  final Value<String> idFactureJiro;
  final Value<String> mois;
  final Value<DateTime> dateAncienIndex;
  final Value<DateTime> dateNouvelIndex;
  final Value<double> ancienIndexCompteur;
  final Value<double> nouvelIndexCompteur;
  final Value<double> ancienIndexSousCompteur;
  final Value<double> nouvelIndexSousCompteur;
  final Value<double> prixUnitaireKwh;
  final Value<double> redevanceJirama;
  final Value<double> primeFixeJirama;
  final Value<double> taxesRedevances;
  final Value<double> tva;
  final Value<DateTime> dateFacture;
  final Value<int> rowid;
  const FacturesJiroCompanion({
    this.idFactureJiro = const Value.absent(),
    this.mois = const Value.absent(),
    this.dateAncienIndex = const Value.absent(),
    this.dateNouvelIndex = const Value.absent(),
    this.ancienIndexCompteur = const Value.absent(),
    this.nouvelIndexCompteur = const Value.absent(),
    this.ancienIndexSousCompteur = const Value.absent(),
    this.nouvelIndexSousCompteur = const Value.absent(),
    this.prixUnitaireKwh = const Value.absent(),
    this.redevanceJirama = const Value.absent(),
    this.primeFixeJirama = const Value.absent(),
    this.taxesRedevances = const Value.absent(),
    this.tva = const Value.absent(),
    this.dateFacture = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FacturesJiroCompanion.insert({
    required String idFactureJiro,
    required String mois,
    required DateTime dateAncienIndex,
    required DateTime dateNouvelIndex,
    required double ancienIndexCompteur,
    required double nouvelIndexCompteur,
    required double ancienIndexSousCompteur,
    required double nouvelIndexSousCompteur,
    required double prixUnitaireKwh,
    required double redevanceJirama,
    required double primeFixeJirama,
    required double taxesRedevances,
    required double tva,
    required DateTime dateFacture,
    this.rowid = const Value.absent(),
  }) : idFactureJiro = Value(idFactureJiro),
       mois = Value(mois),
       dateAncienIndex = Value(dateAncienIndex),
       dateNouvelIndex = Value(dateNouvelIndex),
       ancienIndexCompteur = Value(ancienIndexCompteur),
       nouvelIndexCompteur = Value(nouvelIndexCompteur),
       ancienIndexSousCompteur = Value(ancienIndexSousCompteur),
       nouvelIndexSousCompteur = Value(nouvelIndexSousCompteur),
       prixUnitaireKwh = Value(prixUnitaireKwh),
       redevanceJirama = Value(redevanceJirama),
       primeFixeJirama = Value(primeFixeJirama),
       taxesRedevances = Value(taxesRedevances),
       tva = Value(tva),
       dateFacture = Value(dateFacture);
  static Insertable<FacturesJiroData> custom({
    Expression<String>? idFactureJiro,
    Expression<String>? mois,
    Expression<DateTime>? dateAncienIndex,
    Expression<DateTime>? dateNouvelIndex,
    Expression<double>? ancienIndexCompteur,
    Expression<double>? nouvelIndexCompteur,
    Expression<double>? ancienIndexSousCompteur,
    Expression<double>? nouvelIndexSousCompteur,
    Expression<double>? prixUnitaireKwh,
    Expression<double>? redevanceJirama,
    Expression<double>? primeFixeJirama,
    Expression<double>? taxesRedevances,
    Expression<double>? tva,
    Expression<DateTime>? dateFacture,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idFactureJiro != null) 'id_facture_jiro': idFactureJiro,
      if (mois != null) 'mois': mois,
      if (dateAncienIndex != null) 'date_ancien_index': dateAncienIndex,
      if (dateNouvelIndex != null) 'date_nouvel_index': dateNouvelIndex,
      if (ancienIndexCompteur != null)
        'ancien_index_compteur': ancienIndexCompteur,
      if (nouvelIndexCompteur != null)
        'nouvel_index_compteur': nouvelIndexCompteur,
      if (ancienIndexSousCompteur != null)
        'ancien_index_sous_compteur': ancienIndexSousCompteur,
      if (nouvelIndexSousCompteur != null)
        'nouvel_index_sous_compteur': nouvelIndexSousCompteur,
      if (prixUnitaireKwh != null) 'prix_unitaire_kwh': prixUnitaireKwh,
      if (redevanceJirama != null) 'redevance_jirama': redevanceJirama,
      if (primeFixeJirama != null) 'prime_fixe_jirama': primeFixeJirama,
      if (taxesRedevances != null) 'taxes_redevances': taxesRedevances,
      if (tva != null) 'tva': tva,
      if (dateFacture != null) 'date_facture': dateFacture,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FacturesJiroCompanion copyWith({
    Value<String>? idFactureJiro,
    Value<String>? mois,
    Value<DateTime>? dateAncienIndex,
    Value<DateTime>? dateNouvelIndex,
    Value<double>? ancienIndexCompteur,
    Value<double>? nouvelIndexCompteur,
    Value<double>? ancienIndexSousCompteur,
    Value<double>? nouvelIndexSousCompteur,
    Value<double>? prixUnitaireKwh,
    Value<double>? redevanceJirama,
    Value<double>? primeFixeJirama,
    Value<double>? taxesRedevances,
    Value<double>? tva,
    Value<DateTime>? dateFacture,
    Value<int>? rowid,
  }) {
    return FacturesJiroCompanion(
      idFactureJiro: idFactureJiro ?? this.idFactureJiro,
      mois: mois ?? this.mois,
      dateAncienIndex: dateAncienIndex ?? this.dateAncienIndex,
      dateNouvelIndex: dateNouvelIndex ?? this.dateNouvelIndex,
      ancienIndexCompteur: ancienIndexCompteur ?? this.ancienIndexCompteur,
      nouvelIndexCompteur: nouvelIndexCompteur ?? this.nouvelIndexCompteur,
      ancienIndexSousCompteur:
          ancienIndexSousCompteur ?? this.ancienIndexSousCompteur,
      nouvelIndexSousCompteur:
          nouvelIndexSousCompteur ?? this.nouvelIndexSousCompteur,
      prixUnitaireKwh: prixUnitaireKwh ?? this.prixUnitaireKwh,
      redevanceJirama: redevanceJirama ?? this.redevanceJirama,
      primeFixeJirama: primeFixeJirama ?? this.primeFixeJirama,
      taxesRedevances: taxesRedevances ?? this.taxesRedevances,
      tva: tva ?? this.tva,
      dateFacture: dateFacture ?? this.dateFacture,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idFactureJiro.present) {
      map['id_facture_jiro'] = Variable<String>(idFactureJiro.value);
    }
    if (mois.present) {
      map['mois'] = Variable<String>(mois.value);
    }
    if (dateAncienIndex.present) {
      map['date_ancien_index'] = Variable<DateTime>(dateAncienIndex.value);
    }
    if (dateNouvelIndex.present) {
      map['date_nouvel_index'] = Variable<DateTime>(dateNouvelIndex.value);
    }
    if (ancienIndexCompteur.present) {
      map['ancien_index_compteur'] = Variable<double>(
        ancienIndexCompteur.value,
      );
    }
    if (nouvelIndexCompteur.present) {
      map['nouvel_index_compteur'] = Variable<double>(
        nouvelIndexCompteur.value,
      );
    }
    if (ancienIndexSousCompteur.present) {
      map['ancien_index_sous_compteur'] = Variable<double>(
        ancienIndexSousCompteur.value,
      );
    }
    if (nouvelIndexSousCompteur.present) {
      map['nouvel_index_sous_compteur'] = Variable<double>(
        nouvelIndexSousCompteur.value,
      );
    }
    if (prixUnitaireKwh.present) {
      map['prix_unitaire_kwh'] = Variable<double>(prixUnitaireKwh.value);
    }
    if (redevanceJirama.present) {
      map['redevance_jirama'] = Variable<double>(redevanceJirama.value);
    }
    if (primeFixeJirama.present) {
      map['prime_fixe_jirama'] = Variable<double>(primeFixeJirama.value);
    }
    if (taxesRedevances.present) {
      map['taxes_redevances'] = Variable<double>(taxesRedevances.value);
    }
    if (tva.present) {
      map['tva'] = Variable<double>(tva.value);
    }
    if (dateFacture.present) {
      map['date_facture'] = Variable<DateTime>(dateFacture.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FacturesJiroCompanion(')
          ..write('idFactureJiro: $idFactureJiro, ')
          ..write('mois: $mois, ')
          ..write('dateAncienIndex: $dateAncienIndex, ')
          ..write('dateNouvelIndex: $dateNouvelIndex, ')
          ..write('ancienIndexCompteur: $ancienIndexCompteur, ')
          ..write('nouvelIndexCompteur: $nouvelIndexCompteur, ')
          ..write('ancienIndexSousCompteur: $ancienIndexSousCompteur, ')
          ..write('nouvelIndexSousCompteur: $nouvelIndexSousCompteur, ')
          ..write('prixUnitaireKwh: $prixUnitaireKwh, ')
          ..write('redevanceJirama: $redevanceJirama, ')
          ..write('primeFixeJirama: $primeFixeJirama, ')
          ..write('taxesRedevances: $taxesRedevances, ')
          ..write('tva: $tva, ')
          ..write('dateFacture: $dateFacture, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FacturesTable factures = $FacturesTable(this);
  late final $OperationsTable operations = $OperationsTable(this);
  late final $DepensesTable depenses = $DepensesTable(this);
  late final $PrelevementsTable prelevements = $PrelevementsTable(this);
  late final $RelevesTable releves = $RelevesTable(this);
  late final $FacturesJiroTable facturesJiro = $FacturesJiroTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    factures,
    operations,
    depenses,
    prelevements,
    releves,
    facturesJiro,
  ];
}

typedef $$FacturesTableCreateCompanionBuilder =
    FacturesCompanion Function({
      required String idFacture,
      required String client,
      required DateTime dateFacture,
      Value<int> rowid,
    });
typedef $$FacturesTableUpdateCompanionBuilder =
    FacturesCompanion Function({
      Value<String> idFacture,
      Value<String> client,
      Value<DateTime> dateFacture,
      Value<int> rowid,
    });

final class $$FacturesTableReferences
    extends BaseReferences<_$AppDatabase, $FacturesTable, Facture> {
  $$FacturesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OperationsTable, List<Operation>>
  _operationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.operations,
    aliasName: $_aliasNameGenerator(
      db.factures.idFacture,
      db.operations.facture,
    ),
  );

  $$OperationsTableProcessedTableManager get operationsRefs {
    final manager = $$OperationsTableTableManager($_db, $_db.operations).filter(
      (f) => f.facture.idFacture.sqlEquals($_itemColumn<String>('id_facture')!),
    );

    final cache = $_typedResult.readTableOrNull(_operationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FacturesTableFilterComposer
    extends Composer<_$AppDatabase, $FacturesTable> {
  $$FacturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idFacture => $composableBuilder(
    column: $table.idFacture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get client => $composableBuilder(
    column: $table.client,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> operationsRefs(
    Expression<bool> Function($$OperationsTableFilterComposer f) f,
  ) {
    final $$OperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idFacture,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.facture,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableFilterComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FacturesTableOrderingComposer
    extends Composer<_$AppDatabase, $FacturesTable> {
  $$FacturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idFacture => $composableBuilder(
    column: $table.idFacture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get client => $composableBuilder(
    column: $table.client,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FacturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FacturesTable> {
  $$FacturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idFacture =>
      $composableBuilder(column: $table.idFacture, builder: (column) => column);

  GeneratedColumn<String> get client =>
      $composableBuilder(column: $table.client, builder: (column) => column);

  GeneratedColumn<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => column,
  );

  Expression<T> operationsRefs<T extends Object>(
    Expression<T> Function($$OperationsTableAnnotationComposer a) f,
  ) {
    final $$OperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idFacture,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.facture,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FacturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FacturesTable,
          Facture,
          $$FacturesTableFilterComposer,
          $$FacturesTableOrderingComposer,
          $$FacturesTableAnnotationComposer,
          $$FacturesTableCreateCompanionBuilder,
          $$FacturesTableUpdateCompanionBuilder,
          (Facture, $$FacturesTableReferences),
          Facture,
          PrefetchHooks Function({bool operationsRefs})
        > {
  $$FacturesTableTableManager(_$AppDatabase db, $FacturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FacturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FacturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FacturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idFacture = const Value.absent(),
                Value<String> client = const Value.absent(),
                Value<DateTime> dateFacture = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FacturesCompanion(
                idFacture: idFacture,
                client: client,
                dateFacture: dateFacture,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idFacture,
                required String client,
                required DateTime dateFacture,
                Value<int> rowid = const Value.absent(),
              }) => FacturesCompanion.insert(
                idFacture: idFacture,
                client: client,
                dateFacture: dateFacture,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FacturesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({operationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (operationsRefs) db.operations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (operationsRefs)
                    await $_getPrefetchedData<
                      Facture,
                      $FacturesTable,
                      Operation
                    >(
                      currentTable: table,
                      referencedTable: $$FacturesTableReferences
                          ._operationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FacturesTableReferences(
                        db,
                        table,
                        p0,
                      ).operationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.facture == item.idFacture,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FacturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FacturesTable,
      Facture,
      $$FacturesTableFilterComposer,
      $$FacturesTableOrderingComposer,
      $$FacturesTableAnnotationComposer,
      $$FacturesTableCreateCompanionBuilder,
      $$FacturesTableUpdateCompanionBuilder,
      (Facture, $$FacturesTableReferences),
      Facture,
      PrefetchHooks Function({bool operationsRefs})
    >;
typedef $$OperationsTableCreateCompanionBuilder =
    OperationsCompanion Function({
      required String idOperation,
      required String nomOperation,
      required int prixOperation,
      required int quantiteOperation,
      Value<String?> facture,
      required DateTime dateOperation,
      Value<int> rowid,
    });
typedef $$OperationsTableUpdateCompanionBuilder =
    OperationsCompanion Function({
      Value<String> idOperation,
      Value<String> nomOperation,
      Value<int> prixOperation,
      Value<int> quantiteOperation,
      Value<String?> facture,
      Value<DateTime> dateOperation,
      Value<int> rowid,
    });

final class $$OperationsTableReferences
    extends BaseReferences<_$AppDatabase, $OperationsTable, Operation> {
  $$OperationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FacturesTable _factureTable(_$AppDatabase db) =>
      db.factures.createAlias(
        $_aliasNameGenerator(db.operations.facture, db.factures.idFacture),
      );

  $$FacturesTableProcessedTableManager? get facture {
    final $_column = $_itemColumn<String>('facture');
    if ($_column == null) return null;
    final manager = $$FacturesTableTableManager(
      $_db,
      $_db.factures,
    ).filter((f) => f.idFacture.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_factureTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idOperation => $composableBuilder(
    column: $table.idOperation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomOperation => $composableBuilder(
    column: $table.nomOperation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prixOperation => $composableBuilder(
    column: $table.prixOperation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantiteOperation => $composableBuilder(
    column: $table.quantiteOperation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateOperation => $composableBuilder(
    column: $table.dateOperation,
    builder: (column) => ColumnFilters(column),
  );

  $$FacturesTableFilterComposer get facture {
    final $$FacturesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facture,
      referencedTable: $db.factures,
      getReferencedColumn: (t) => t.idFacture,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacturesTableFilterComposer(
            $db: $db,
            $table: $db.factures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idOperation => $composableBuilder(
    column: $table.idOperation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomOperation => $composableBuilder(
    column: $table.nomOperation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prixOperation => $composableBuilder(
    column: $table.prixOperation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantiteOperation => $composableBuilder(
    column: $table.quantiteOperation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateOperation => $composableBuilder(
    column: $table.dateOperation,
    builder: (column) => ColumnOrderings(column),
  );

  $$FacturesTableOrderingComposer get facture {
    final $$FacturesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facture,
      referencedTable: $db.factures,
      getReferencedColumn: (t) => t.idFacture,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacturesTableOrderingComposer(
            $db: $db,
            $table: $db.factures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idOperation => $composableBuilder(
    column: $table.idOperation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nomOperation => $composableBuilder(
    column: $table.nomOperation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prixOperation => $composableBuilder(
    column: $table.prixOperation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantiteOperation => $composableBuilder(
    column: $table.quantiteOperation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateOperation => $composableBuilder(
    column: $table.dateOperation,
    builder: (column) => column,
  );

  $$FacturesTableAnnotationComposer get facture {
    final $$FacturesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.facture,
      referencedTable: $db.factures,
      getReferencedColumn: (t) => t.idFacture,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FacturesTableAnnotationComposer(
            $db: $db,
            $table: $db.factures,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationsTable,
          Operation,
          $$OperationsTableFilterComposer,
          $$OperationsTableOrderingComposer,
          $$OperationsTableAnnotationComposer,
          $$OperationsTableCreateCompanionBuilder,
          $$OperationsTableUpdateCompanionBuilder,
          (Operation, $$OperationsTableReferences),
          Operation,
          PrefetchHooks Function({bool facture})
        > {
  $$OperationsTableTableManager(_$AppDatabase db, $OperationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idOperation = const Value.absent(),
                Value<String> nomOperation = const Value.absent(),
                Value<int> prixOperation = const Value.absent(),
                Value<int> quantiteOperation = const Value.absent(),
                Value<String?> facture = const Value.absent(),
                Value<DateTime> dateOperation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion(
                idOperation: idOperation,
                nomOperation: nomOperation,
                prixOperation: prixOperation,
                quantiteOperation: quantiteOperation,
                facture: facture,
                dateOperation: dateOperation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idOperation,
                required String nomOperation,
                required int prixOperation,
                required int quantiteOperation,
                Value<String?> facture = const Value.absent(),
                required DateTime dateOperation,
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion.insert(
                idOperation: idOperation,
                nomOperation: nomOperation,
                prixOperation: prixOperation,
                quantiteOperation: quantiteOperation,
                facture: facture,
                dateOperation: dateOperation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OperationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({facture = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (facture) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.facture,
                                referencedTable: $$OperationsTableReferences
                                    ._factureTable(db),
                                referencedColumn: $$OperationsTableReferences
                                    ._factureTable(db)
                                    .idFacture,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationsTable,
      Operation,
      $$OperationsTableFilterComposer,
      $$OperationsTableOrderingComposer,
      $$OperationsTableAnnotationComposer,
      $$OperationsTableCreateCompanionBuilder,
      $$OperationsTableUpdateCompanionBuilder,
      (Operation, $$OperationsTableReferences),
      Operation,
      PrefetchHooks Function({bool facture})
    >;
typedef $$DepensesTableCreateCompanionBuilder =
    DepensesCompanion Function({
      required String idDepense,
      required String libelle,
      required int montant,
      required DateTime dateDepense,
      Value<int> rowid,
    });
typedef $$DepensesTableUpdateCompanionBuilder =
    DepensesCompanion Function({
      Value<String> idDepense,
      Value<String> libelle,
      Value<int> montant,
      Value<DateTime> dateDepense,
      Value<int> rowid,
    });

class $$DepensesTableFilterComposer
    extends Composer<_$AppDatabase, $DepensesTable> {
  $$DepensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idDepense => $composableBuilder(
    column: $table.idDepense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateDepense => $composableBuilder(
    column: $table.dateDepense,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DepensesTableOrderingComposer
    extends Composer<_$AppDatabase, $DepensesTable> {
  $$DepensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idDepense => $composableBuilder(
    column: $table.idDepense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateDepense => $composableBuilder(
    column: $table.dateDepense,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DepensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DepensesTable> {
  $$DepensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idDepense =>
      $composableBuilder(column: $table.idDepense, builder: (column) => column);

  GeneratedColumn<String> get libelle =>
      $composableBuilder(column: $table.libelle, builder: (column) => column);

  GeneratedColumn<int> get montant =>
      $composableBuilder(column: $table.montant, builder: (column) => column);

  GeneratedColumn<DateTime> get dateDepense => $composableBuilder(
    column: $table.dateDepense,
    builder: (column) => column,
  );
}

class $$DepensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DepensesTable,
          Depense,
          $$DepensesTableFilterComposer,
          $$DepensesTableOrderingComposer,
          $$DepensesTableAnnotationComposer,
          $$DepensesTableCreateCompanionBuilder,
          $$DepensesTableUpdateCompanionBuilder,
          (Depense, BaseReferences<_$AppDatabase, $DepensesTable, Depense>),
          Depense,
          PrefetchHooks Function()
        > {
  $$DepensesTableTableManager(_$AppDatabase db, $DepensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idDepense = const Value.absent(),
                Value<String> libelle = const Value.absent(),
                Value<int> montant = const Value.absent(),
                Value<DateTime> dateDepense = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DepensesCompanion(
                idDepense: idDepense,
                libelle: libelle,
                montant: montant,
                dateDepense: dateDepense,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idDepense,
                required String libelle,
                required int montant,
                required DateTime dateDepense,
                Value<int> rowid = const Value.absent(),
              }) => DepensesCompanion.insert(
                idDepense: idDepense,
                libelle: libelle,
                montant: montant,
                dateDepense: dateDepense,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DepensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DepensesTable,
      Depense,
      $$DepensesTableFilterComposer,
      $$DepensesTableOrderingComposer,
      $$DepensesTableAnnotationComposer,
      $$DepensesTableCreateCompanionBuilder,
      $$DepensesTableUpdateCompanionBuilder,
      (Depense, BaseReferences<_$AppDatabase, $DepensesTable, Depense>),
      Depense,
      PrefetchHooks Function()
    >;
typedef $$PrelevementsTableCreateCompanionBuilder =
    PrelevementsCompanion Function({
      required String idPrelevement,
      required int montant,
      required DateTime datePrelevement,
      Value<int> rowid,
    });
typedef $$PrelevementsTableUpdateCompanionBuilder =
    PrelevementsCompanion Function({
      Value<String> idPrelevement,
      Value<int> montant,
      Value<DateTime> datePrelevement,
      Value<int> rowid,
    });

class $$PrelevementsTableFilterComposer
    extends Composer<_$AppDatabase, $PrelevementsTable> {
  $$PrelevementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idPrelevement => $composableBuilder(
    column: $table.idPrelevement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get datePrelevement => $composableBuilder(
    column: $table.datePrelevement,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrelevementsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrelevementsTable> {
  $$PrelevementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idPrelevement => $composableBuilder(
    column: $table.idPrelevement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get datePrelevement => $composableBuilder(
    column: $table.datePrelevement,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrelevementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrelevementsTable> {
  $$PrelevementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idPrelevement => $composableBuilder(
    column: $table.idPrelevement,
    builder: (column) => column,
  );

  GeneratedColumn<int> get montant =>
      $composableBuilder(column: $table.montant, builder: (column) => column);

  GeneratedColumn<DateTime> get datePrelevement => $composableBuilder(
    column: $table.datePrelevement,
    builder: (column) => column,
  );
}

class $$PrelevementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrelevementsTable,
          Prelevement,
          $$PrelevementsTableFilterComposer,
          $$PrelevementsTableOrderingComposer,
          $$PrelevementsTableAnnotationComposer,
          $$PrelevementsTableCreateCompanionBuilder,
          $$PrelevementsTableUpdateCompanionBuilder,
          (
            Prelevement,
            BaseReferences<_$AppDatabase, $PrelevementsTable, Prelevement>,
          ),
          Prelevement,
          PrefetchHooks Function()
        > {
  $$PrelevementsTableTableManager(_$AppDatabase db, $PrelevementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrelevementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrelevementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrelevementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idPrelevement = const Value.absent(),
                Value<int> montant = const Value.absent(),
                Value<DateTime> datePrelevement = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrelevementsCompanion(
                idPrelevement: idPrelevement,
                montant: montant,
                datePrelevement: datePrelevement,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idPrelevement,
                required int montant,
                required DateTime datePrelevement,
                Value<int> rowid = const Value.absent(),
              }) => PrelevementsCompanion.insert(
                idPrelevement: idPrelevement,
                montant: montant,
                datePrelevement: datePrelevement,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrelevementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrelevementsTable,
      Prelevement,
      $$PrelevementsTableFilterComposer,
      $$PrelevementsTableOrderingComposer,
      $$PrelevementsTableAnnotationComposer,
      $$PrelevementsTableCreateCompanionBuilder,
      $$PrelevementsTableUpdateCompanionBuilder,
      (
        Prelevement,
        BaseReferences<_$AppDatabase, $PrelevementsTable, Prelevement>,
      ),
      Prelevement,
      PrefetchHooks Function()
    >;
typedef $$RelevesTableCreateCompanionBuilder =
    RelevesCompanion Function({
      required String idReleve,
      required double compteur,
      required double sousCompteur,
      required DateTime dateReleve,
      Value<int> rowid,
    });
typedef $$RelevesTableUpdateCompanionBuilder =
    RelevesCompanion Function({
      Value<String> idReleve,
      Value<double> compteur,
      Value<double> sousCompteur,
      Value<DateTime> dateReleve,
      Value<int> rowid,
    });

class $$RelevesTableFilterComposer
    extends Composer<_$AppDatabase, $RelevesTable> {
  $$RelevesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idReleve => $composableBuilder(
    column: $table.idReleve,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get compteur => $composableBuilder(
    column: $table.compteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sousCompteur => $composableBuilder(
    column: $table.sousCompteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateReleve => $composableBuilder(
    column: $table.dateReleve,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelevesTableOrderingComposer
    extends Composer<_$AppDatabase, $RelevesTable> {
  $$RelevesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idReleve => $composableBuilder(
    column: $table.idReleve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get compteur => $composableBuilder(
    column: $table.compteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sousCompteur => $composableBuilder(
    column: $table.sousCompteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateReleve => $composableBuilder(
    column: $table.dateReleve,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelevesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelevesTable> {
  $$RelevesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idReleve =>
      $composableBuilder(column: $table.idReleve, builder: (column) => column);

  GeneratedColumn<double> get compteur =>
      $composableBuilder(column: $table.compteur, builder: (column) => column);

  GeneratedColumn<double> get sousCompteur => $composableBuilder(
    column: $table.sousCompteur,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateReleve => $composableBuilder(
    column: $table.dateReleve,
    builder: (column) => column,
  );
}

class $$RelevesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RelevesTable,
          Releve,
          $$RelevesTableFilterComposer,
          $$RelevesTableOrderingComposer,
          $$RelevesTableAnnotationComposer,
          $$RelevesTableCreateCompanionBuilder,
          $$RelevesTableUpdateCompanionBuilder,
          (Releve, BaseReferences<_$AppDatabase, $RelevesTable, Releve>),
          Releve,
          PrefetchHooks Function()
        > {
  $$RelevesTableTableManager(_$AppDatabase db, $RelevesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelevesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelevesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelevesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idReleve = const Value.absent(),
                Value<double> compteur = const Value.absent(),
                Value<double> sousCompteur = const Value.absent(),
                Value<DateTime> dateReleve = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelevesCompanion(
                idReleve: idReleve,
                compteur: compteur,
                sousCompteur: sousCompteur,
                dateReleve: dateReleve,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idReleve,
                required double compteur,
                required double sousCompteur,
                required DateTime dateReleve,
                Value<int> rowid = const Value.absent(),
              }) => RelevesCompanion.insert(
                idReleve: idReleve,
                compteur: compteur,
                sousCompteur: sousCompteur,
                dateReleve: dateReleve,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelevesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RelevesTable,
      Releve,
      $$RelevesTableFilterComposer,
      $$RelevesTableOrderingComposer,
      $$RelevesTableAnnotationComposer,
      $$RelevesTableCreateCompanionBuilder,
      $$RelevesTableUpdateCompanionBuilder,
      (Releve, BaseReferences<_$AppDatabase, $RelevesTable, Releve>),
      Releve,
      PrefetchHooks Function()
    >;
typedef $$FacturesJiroTableCreateCompanionBuilder =
    FacturesJiroCompanion Function({
      required String idFactureJiro,
      required String mois,
      required DateTime dateAncienIndex,
      required DateTime dateNouvelIndex,
      required double ancienIndexCompteur,
      required double nouvelIndexCompteur,
      required double ancienIndexSousCompteur,
      required double nouvelIndexSousCompteur,
      required double prixUnitaireKwh,
      required double redevanceJirama,
      required double primeFixeJirama,
      required double taxesRedevances,
      required double tva,
      required DateTime dateFacture,
      Value<int> rowid,
    });
typedef $$FacturesJiroTableUpdateCompanionBuilder =
    FacturesJiroCompanion Function({
      Value<String> idFactureJiro,
      Value<String> mois,
      Value<DateTime> dateAncienIndex,
      Value<DateTime> dateNouvelIndex,
      Value<double> ancienIndexCompteur,
      Value<double> nouvelIndexCompteur,
      Value<double> ancienIndexSousCompteur,
      Value<double> nouvelIndexSousCompteur,
      Value<double> prixUnitaireKwh,
      Value<double> redevanceJirama,
      Value<double> primeFixeJirama,
      Value<double> taxesRedevances,
      Value<double> tva,
      Value<DateTime> dateFacture,
      Value<int> rowid,
    });

class $$FacturesJiroTableFilterComposer
    extends Composer<_$AppDatabase, $FacturesJiroTable> {
  $$FacturesJiroTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idFactureJiro => $composableBuilder(
    column: $table.idFactureJiro,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mois => $composableBuilder(
    column: $table.mois,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAncienIndex => $composableBuilder(
    column: $table.dateAncienIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateNouvelIndex => $composableBuilder(
    column: $table.dateNouvelIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ancienIndexCompteur => $composableBuilder(
    column: $table.ancienIndexCompteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nouvelIndexCompteur => $composableBuilder(
    column: $table.nouvelIndexCompteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ancienIndexSousCompteur => $composableBuilder(
    column: $table.ancienIndexSousCompteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get nouvelIndexSousCompteur => $composableBuilder(
    column: $table.nouvelIndexSousCompteur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prixUnitaireKwh => $composableBuilder(
    column: $table.prixUnitaireKwh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get redevanceJirama => $composableBuilder(
    column: $table.redevanceJirama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get primeFixeJirama => $composableBuilder(
    column: $table.primeFixeJirama,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxesRedevances => $composableBuilder(
    column: $table.taxesRedevances,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tva => $composableBuilder(
    column: $table.tva,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FacturesJiroTableOrderingComposer
    extends Composer<_$AppDatabase, $FacturesJiroTable> {
  $$FacturesJiroTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idFactureJiro => $composableBuilder(
    column: $table.idFactureJiro,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mois => $composableBuilder(
    column: $table.mois,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAncienIndex => $composableBuilder(
    column: $table.dateAncienIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateNouvelIndex => $composableBuilder(
    column: $table.dateNouvelIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ancienIndexCompteur => $composableBuilder(
    column: $table.ancienIndexCompteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nouvelIndexCompteur => $composableBuilder(
    column: $table.nouvelIndexCompteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ancienIndexSousCompteur => $composableBuilder(
    column: $table.ancienIndexSousCompteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get nouvelIndexSousCompteur => $composableBuilder(
    column: $table.nouvelIndexSousCompteur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prixUnitaireKwh => $composableBuilder(
    column: $table.prixUnitaireKwh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get redevanceJirama => $composableBuilder(
    column: $table.redevanceJirama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get primeFixeJirama => $composableBuilder(
    column: $table.primeFixeJirama,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxesRedevances => $composableBuilder(
    column: $table.taxesRedevances,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tva => $composableBuilder(
    column: $table.tva,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FacturesJiroTableAnnotationComposer
    extends Composer<_$AppDatabase, $FacturesJiroTable> {
  $$FacturesJiroTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idFactureJiro => $composableBuilder(
    column: $table.idFactureJiro,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mois =>
      $composableBuilder(column: $table.mois, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAncienIndex => $composableBuilder(
    column: $table.dateAncienIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateNouvelIndex => $composableBuilder(
    column: $table.dateNouvelIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ancienIndexCompteur => $composableBuilder(
    column: $table.ancienIndexCompteur,
    builder: (column) => column,
  );

  GeneratedColumn<double> get nouvelIndexCompteur => $composableBuilder(
    column: $table.nouvelIndexCompteur,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ancienIndexSousCompteur => $composableBuilder(
    column: $table.ancienIndexSousCompteur,
    builder: (column) => column,
  );

  GeneratedColumn<double> get nouvelIndexSousCompteur => $composableBuilder(
    column: $table.nouvelIndexSousCompteur,
    builder: (column) => column,
  );

  GeneratedColumn<double> get prixUnitaireKwh => $composableBuilder(
    column: $table.prixUnitaireKwh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get redevanceJirama => $composableBuilder(
    column: $table.redevanceJirama,
    builder: (column) => column,
  );

  GeneratedColumn<double> get primeFixeJirama => $composableBuilder(
    column: $table.primeFixeJirama,
    builder: (column) => column,
  );

  GeneratedColumn<double> get taxesRedevances => $composableBuilder(
    column: $table.taxesRedevances,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tva =>
      $composableBuilder(column: $table.tva, builder: (column) => column);

  GeneratedColumn<DateTime> get dateFacture => $composableBuilder(
    column: $table.dateFacture,
    builder: (column) => column,
  );
}

class $$FacturesJiroTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FacturesJiroTable,
          FacturesJiroData,
          $$FacturesJiroTableFilterComposer,
          $$FacturesJiroTableOrderingComposer,
          $$FacturesJiroTableAnnotationComposer,
          $$FacturesJiroTableCreateCompanionBuilder,
          $$FacturesJiroTableUpdateCompanionBuilder,
          (
            FacturesJiroData,
            BaseReferences<_$AppDatabase, $FacturesJiroTable, FacturesJiroData>,
          ),
          FacturesJiroData,
          PrefetchHooks Function()
        > {
  $$FacturesJiroTableTableManager(_$AppDatabase db, $FacturesJiroTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FacturesJiroTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FacturesJiroTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FacturesJiroTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idFactureJiro = const Value.absent(),
                Value<String> mois = const Value.absent(),
                Value<DateTime> dateAncienIndex = const Value.absent(),
                Value<DateTime> dateNouvelIndex = const Value.absent(),
                Value<double> ancienIndexCompteur = const Value.absent(),
                Value<double> nouvelIndexCompteur = const Value.absent(),
                Value<double> ancienIndexSousCompteur = const Value.absent(),
                Value<double> nouvelIndexSousCompteur = const Value.absent(),
                Value<double> prixUnitaireKwh = const Value.absent(),
                Value<double> redevanceJirama = const Value.absent(),
                Value<double> primeFixeJirama = const Value.absent(),
                Value<double> taxesRedevances = const Value.absent(),
                Value<double> tva = const Value.absent(),
                Value<DateTime> dateFacture = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FacturesJiroCompanion(
                idFactureJiro: idFactureJiro,
                mois: mois,
                dateAncienIndex: dateAncienIndex,
                dateNouvelIndex: dateNouvelIndex,
                ancienIndexCompteur: ancienIndexCompteur,
                nouvelIndexCompteur: nouvelIndexCompteur,
                ancienIndexSousCompteur: ancienIndexSousCompteur,
                nouvelIndexSousCompteur: nouvelIndexSousCompteur,
                prixUnitaireKwh: prixUnitaireKwh,
                redevanceJirama: redevanceJirama,
                primeFixeJirama: primeFixeJirama,
                taxesRedevances: taxesRedevances,
                tva: tva,
                dateFacture: dateFacture,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idFactureJiro,
                required String mois,
                required DateTime dateAncienIndex,
                required DateTime dateNouvelIndex,
                required double ancienIndexCompteur,
                required double nouvelIndexCompteur,
                required double ancienIndexSousCompteur,
                required double nouvelIndexSousCompteur,
                required double prixUnitaireKwh,
                required double redevanceJirama,
                required double primeFixeJirama,
                required double taxesRedevances,
                required double tva,
                required DateTime dateFacture,
                Value<int> rowid = const Value.absent(),
              }) => FacturesJiroCompanion.insert(
                idFactureJiro: idFactureJiro,
                mois: mois,
                dateAncienIndex: dateAncienIndex,
                dateNouvelIndex: dateNouvelIndex,
                ancienIndexCompteur: ancienIndexCompteur,
                nouvelIndexCompteur: nouvelIndexCompteur,
                ancienIndexSousCompteur: ancienIndexSousCompteur,
                nouvelIndexSousCompteur: nouvelIndexSousCompteur,
                prixUnitaireKwh: prixUnitaireKwh,
                redevanceJirama: redevanceJirama,
                primeFixeJirama: primeFixeJirama,
                taxesRedevances: taxesRedevances,
                tva: tva,
                dateFacture: dateFacture,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FacturesJiroTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FacturesJiroTable,
      FacturesJiroData,
      $$FacturesJiroTableFilterComposer,
      $$FacturesJiroTableOrderingComposer,
      $$FacturesJiroTableAnnotationComposer,
      $$FacturesJiroTableCreateCompanionBuilder,
      $$FacturesJiroTableUpdateCompanionBuilder,
      (
        FacturesJiroData,
        BaseReferences<_$AppDatabase, $FacturesJiroTable, FacturesJiroData>,
      ),
      FacturesJiroData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FacturesTableTableManager get factures =>
      $$FacturesTableTableManager(_db, _db.factures);
  $$OperationsTableTableManager get operations =>
      $$OperationsTableTableManager(_db, _db.operations);
  $$DepensesTableTableManager get depenses =>
      $$DepensesTableTableManager(_db, _db.depenses);
  $$PrelevementsTableTableManager get prelevements =>
      $$PrelevementsTableTableManager(_db, _db.prelevements);
  $$RelevesTableTableManager get releves =>
      $$RelevesTableTableManager(_db, _db.releves);
  $$FacturesJiroTableTableManager get facturesJiro =>
      $$FacturesJiroTableTableManager(_db, _db.facturesJiro);
}
