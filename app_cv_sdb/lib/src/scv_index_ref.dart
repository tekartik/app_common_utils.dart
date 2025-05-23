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
}

/// Extension on index on 1 field.
extension ScvIndex1RefExt<
  K extends SdbKey,
  V extends ScvRecord<K>,
  I extends SdbIndexKey
>
    on ScvIndex1Ref<K, V, I> {
  /// Lower boundary
  SdbBoundary<I> lowerBoundary(I value, {bool? include = true}) =>
      rawRef1.lowerBoundary(value, include: include);

  /// Upper boundary
  SdbBoundary<I> upperBoundary(I value, {bool? include = false}) =>
      rawRef1.upperBoundary(value, include: include);
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
