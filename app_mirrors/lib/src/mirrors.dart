// dart:mirrors is only on the VM in JIT mode (not in AOT nor in Flutter,
// where dart.library.io is also true).
export 'mirrors_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.mirrors) 'mirrors_stub_vm.dart';
