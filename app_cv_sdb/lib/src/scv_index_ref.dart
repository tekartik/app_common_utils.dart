import 'package:tekartik_app_cv_sdb/app_cv_sdb.dart';

import 'scv_index_record_ref.dart';

/// Index reference.
abstract interface class ScvIndexRef<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
> {
  /// Store reference.
  ScvStoreRef<K, V> get store;

  /// Raw reference.
  SdbIndexRef<K, SdbModel, I> get rawRef;

  /// Index name.
  String get name;
}

/// Index on 1 field
abstract class ScvIndex1Ref<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvIndexRef<K, V, I> {
  /// Store reference.
  @override
  ScvStoreRef<K, V> get store;

  /// Index name.
  @override
  String get name;
}

/// Index on 2 field
abstract class ScvIndex2Ref<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I1 extends SdbIndexKey,
  I2 extends SdbIndexKey
>
    implements ScvIndexRef<K, V, (I1, I2)> {
  /// Store reference.
  @override
  ScvStoreRef<K, V> get store;

  /// Index name.
  @override
  String get name;
}

/// Index on 1 field.
class ScvIndex1RefImpl<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    extends ScvIndexRefImpl<K, V, I>
    implements ScvIndex1Ref<K, V, I> {
  /// Index on 1 field.
  ScvIndex1RefImpl(super.store, super.rawRef);
}

/// Index on 2 field.
class ScvIndex2RefImpl<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I1 extends SdbIndexKey,
  I2 extends SdbIndexKey
>
    extends ScvIndexRefImpl<K, V, (I1, I2)>
    implements ScvIndex2Ref<K, V, I1, I2> {
  /// Index on 1 field.
  ScvIndex2RefImpl(super.store, super.rawRef);
}

/// Index extension.
extension ScvIndexRefExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRef<K, V, I> {
  /// Record reference.
  ScvIndexRecordRef<K, V, I> record(I indexKey) =>
      ScvIndexRecordRefImpl<K, V, I>(impl, impl.rawRef.record(indexKey));

  /*
  /// Schema
  SdbIndexSchema schema({required Object keyPath, bool? unique}) {
    return rawRef.schema(keyPath: keyPath, unique: unique);
  }*/
}

/// Extension on index on 1 field.
extension ScvIndex1RefExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndex1Ref<K, V, I> {
  /// Record reference.
  ScvIndexRecordRef<K, V, I> record(I indexKey) =>
      ScvIndexRecordRefImpl<K, V, I>(impl, impl.rawRef.record(indexKey));

  /// Lower boundary
  SdbBoundary<I> lowerBoundary(I value, {bool? include = true}) =>
      rawRef1.lowerBoundary(value, include: include);

  /// Upper boundary
  SdbBoundary<I> upperBoundary(I value, {bool? include = false}) =>
      rawRef1.upperBoundary(value, include: include);

  /// Schema
  SdbIndexSchema schema({required String keyPath, bool? unique}) {
    return rawRef.schema(keyPath: keyPath, unique: unique);
  }
}

/// Extension on index on 1 field.
extension ScvIndex2RefExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I1 extends SdbIndexKey,
  I2 extends SdbIndexKey
>
    on ScvIndex2Ref<K, V, I1, I2> {
  /// Record reference.
  ScvIndexRecordRef<K, V, (I1, I2)> record(I1 indexKey1, I2 indexKey2) =>
      ScvIndexRecordRefImpl<K, V, (I1, I2)>(
        impl,
        impl.rawRef.record((indexKey1, indexKey2)),
      );

  /// Lower boundary
  SdbBoundary<(I1, I2)> lowerBoundary(
    I1 value1,
    I2 value2, {
    bool? include = true,
  }) => rawRef1.lowerBoundary((value1, value2), include: include);

  /// Upper boundary
  SdbBoundary<(I1, I2)> upperBoundary(
    I1 value1,
    I2 value2, {
    bool? include = false,
  }) => rawRef1.upperBoundary((value1, value2), include: include);

  /// Schema
  SdbIndexSchema schema({required List<String> keyPath, bool? unique}) {
    return rawRef.schema(keyPath: keyPath, unique: unique);
  }
}

/// Index private extension.
extension ScvIndexRefExtPrv<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndexRef<K, V, I> {
  /// Private implementation.
  ScvIndexRefImpl<K, V, I> get impl => this as ScvIndexRefImpl<K, V, I>;

  /// Cast as raw ref1
  SdbIndex1Ref<K, SdbModel, I> get rawRef1 =>
      rawRef as SdbIndex1Ref<K, SdbModel, I>;

  /// Cast as raw ref1
}

/// Index private extension.
extension ScvIndexRef2ExtPrv<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I1 extends SdbIndexKey,
  I2 extends SdbIndexKey
>
    on ScvIndex2Ref<K, V, I1, I2> {
  /// Private implementation.
  ScvIndex2RefImpl<K, V, I1, I2> get impl =>
      this as ScvIndex2RefImpl<K, V, I1, I2>;

  /// Cast as raw ref1
  SdbIndex2Ref<K, SdbModel, I1, I2> get rawRef2 =>
      rawRef as SdbIndex2Ref<K, SdbModel, I1, I2>;

  /// Cast as raw ref1
}

/// Index reference extension.
class ScvIndexRefImpl<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    implements ScvIndexRef<K, V, I> {
  @override
  final ScvStoreRef<K, V> store;
  @override
  final SdbIndexRef<K, SdbModel, I> rawRef;

  @override
  String get name => rawRef.name;

  /// Constructor (private)
  ScvIndexRefImpl(this.store, this.rawRef);
}

/*
/// Index reference extension.
class ScvIndex2RefImpl<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I1 extends SdbIndexKey,
  I2 extends SdbIndexKey
>
    implements ScvIndex2Ref<K, V, I1, I2> {
  @override
  final ScvStoreRef<K, V> store;
  @override
  final SdbIndex2Ref<K, SdbModel, I1, I2> rawRef;

  @override
  String get name => rawRef.name;

  /// Constructor (private)
  ScvIndex2RefImpl(this.store, this.rawRef);
}
*/
