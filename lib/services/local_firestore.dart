import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

/// Local, user-scoped document store with a Firestore-compatible API.
/// Firebase Auth remains the identity provider; application data never leaves
/// the device and is stored in Hive box local_db_<uid>.
class LocalFirestore {
  LocalFirestore._();
  static final LocalFirestore instance = LocalFirestore._();

  Future<Box<dynamic>> _box() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Se requiere un usuario autenticado para acceder a los datos locales.');
    }
    final name = 'local_db_${uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}';
    if (!Hive.isBoxOpen(name)) await Hive.openBox<dynamic>(name);
    return Hive.box<dynamic>(name);
  }

  CollectionReference collection(String path) => CollectionReference._(this, _clean(path));

  Future<List<Map<String, dynamic>>> _readCollection(String path) async {
    final box = await _box();
    final prefix = '${_clean(path)}/';
    return box.toMap().entries.where((entry) {
      final key = entry.key.toString();
      return key.startsWith(prefix) && !key.substring(prefix.length).contains('/');
    }).map((entry) {
      final value = _decode(entry.value);
      return {'id': entry.key.toString().substring(prefix.length), 'data': value};
    }).toList();
  }

  Future<Map<String, dynamic>?> _readDocument(String path) async {
    final box = await _box();
    final value = box.get(_clean(path));
    return value == null ? null : _decode(value);
  }

  Future<void> _writeDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    final box = await _box();
    final key = _clean(path);
    final existing = merge ? await _readDocument(key) : null;
    await box.put(key, _encode({...?existing, ..._resolve(data)}));
  }

  Future<void> _deleteDocument(String path) async => (await _box()).delete(_clean(path));

  static String _clean(String value) => value.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
  static Map<String, dynamic> _decode(dynamic value) {
    final source = value is Map ? value : <String, dynamic>{};
    return source.map((key, item) => MapEntry(key.toString(), _decodeValue(key.toString(), item)));
  }
  static dynamic _decodeValue(String key, dynamic value) {
    if (value is Map) return _decode(value);
    if (value is Iterable) return value.map((item) => _decodeValue(key, item)).toList();
    final isDateField = key.toLowerCase().contains('fecha') || key.toLowerCase().contains('timestamp') || key.toLowerCase().contains('createdat') || key.toLowerCase().contains('updatedat');
    if (isDateField && value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp._(parsed);
    }
    return value;
  }
  static dynamic _encode(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) return value.map((key, val) => MapEntry(key, _encode(val)));
    if (value is Iterable) return value.map(_encode).toList();
    return value;
  }
  static Map<String, dynamic> _resolve(Map<String, dynamic> data) => data.map((key, value) {
    if (value is FieldValue) return MapEntry(key, DateTime.now().toIso8601String());
    return MapEntry(key, _encode(value));
  });
}

class CollectionReference extends Query {
  CollectionReference._(LocalFirestore db, String path) : super._(db, path);
  DocumentReference doc([String? id]) => DocumentReference._(_db, '${_path}/${id ?? _newId()}');
  Future<DocumentReference> add(Map<String, dynamic> data) async { final ref = doc(); await ref.set(data); return ref; }
}

class DocumentReference {
  DocumentReference._(this._db, this.path);
  final LocalFirestore _db;
  final String path;
  String get id => path.split('/').last;
  CollectionReference collection(String name) => CollectionReference._(_db, '$path/$name');
  Future<DocumentSnapshot> get() async => DocumentSnapshot(this, await _db._readDocument(path));
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) => _db._writeDocument(path, data, merge: options?.merge ?? false);
  Future<void> update(Map<String, dynamic> data) => _db._writeDocument(path, data, merge: true);
  Future<void> delete() => _db._deleteDocument(path);
}

class Query {
  Query._(this._db, this._path);
  final LocalFirestore _db;
  final String _path;
  String? _whereField;
  dynamic _whereValue;
  String? _orderField;
  bool _descending = false;
  int? _limit;

  Query where(String field, {dynamic isEqualTo}) { final copy = _copy(); copy._whereField = field; copy._whereValue = isEqualTo; return copy; }
  Query orderBy(String field, {bool descending = false}) { final copy = _copy(); copy._orderField = field; copy._descending = descending; return copy; }
  Query limit(int value) { final copy = _copy(); copy._limit = value; return copy; }
  Query _copy() { final copy = Query._(_db, _path); copy._whereField = _whereField; copy._whereValue = _whereValue; copy._orderField = _orderField; copy._descending = _descending; copy._limit = _limit; return copy; }
  Future<QuerySnapshot> get() async {
    var rows = await _db._readCollection(_path);
    if (_whereField != null) rows = rows.where((row) => row['data'][_whereField] == _whereValue).toList();
    if (_orderField != null) rows.sort((a, b) => _compare(a['data'][_orderField], b['data'][_orderField]) * (_descending ? -1 : 1));
    if (_limit != null && rows.length > _limit!) rows = rows.sublist(0, _limit!);
    return QuerySnapshot(rows.map((row) => QueryDocumentSnapshot(DocumentReference._(_db, _path + '/' + row['id'].toString()), Map<String, dynamic>.from(row['data']))).toList());
  }
  Stream<QuerySnapshot> snapshots() async* {
    final box = await _db._box();
    yield await get();
    await for (final _ in box.watch()) { yield await get(); }
  }
}

String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
int _compare(dynamic a, dynamic b) => a.toString().compareTo(b.toString());
class QuerySnapshot { QuerySnapshot(this.docs); final List<QueryDocumentSnapshot> docs; }
class DocumentSnapshot { DocumentSnapshot(this.reference, this._data); final DocumentReference reference; final Map<String, dynamic>? _data; String get id => reference.id; bool get exists => _data != null; Map<String, dynamic> data() => _data ?? <String, dynamic>{}; }
class QueryDocumentSnapshot extends DocumentSnapshot { QueryDocumentSnapshot(DocumentReference reference, Map<String, dynamic> data) : super(reference, data); @override bool get exists => true; @override Map<String, dynamic> data() => super.data(); }
class Timestamp { Timestamp._(this._date); final DateTime _date; static Timestamp now() => Timestamp._(DateTime.now()); DateTime toDate() => _date; }
class FieldValue { const FieldValue._(); static FieldValue serverTimestamp() => const FieldValue._(); }
class SetOptions { const SetOptions({this.merge = false}); final bool merge; }
