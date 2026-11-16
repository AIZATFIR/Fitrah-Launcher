import 'dart:async';
import '../store/focus_store.dart';
import '../store/native_focus_store.dart';
import 'package:isar_community/isar.dart';

import '../../models/preset.dart';
import '../../core/theme.dart';

class PresetRepository {
  PresetRepository(Isar? isar)
    : this.store(isar == null ? null : NativeFocusStore(isar));
  PresetRepository.store(this._isar) {
    if (_isar == null) {
      for (final p in _defaultPresets()) {
        _memPresets[p.id] = p;
      }
    }
  }
  final FocusStore? _isar;

  final Map<int, Preset> _memPresets = {};
  int _memIdCounter = 100;
  final StreamController<void> _memController =
      StreamController<void>.broadcast();

  Stream<List<Preset>> watchAll() {
    if (_isar == null) {
      return _watchMemory();
    }
    return _isar.presets
        .select(
          compare: (a, b) {
            return a.createdAt.compareTo(b.createdAt);
          },
        )
        .watch(fireImmediately: true);
  }

  Stream<List<Preset>> _watchMemory() async* {
    List<Preset> query() {
      final list = _memPresets.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    yield query();
    await for (final _ in _memController.stream) {
      yield query();
    }
  }

  Future<int> upsert(Preset p) async {
    if (_isar == null) {
      if (p.id == Isar.autoIncrement || p.id <= 0) {
        p.id = _memIdCounter++;
      }
      _memPresets[p.id] = p;
      _memController.add(null);
      return p.id;
    }
    return _isar.writeTxn(() => _isar.presets.put(p));
  }

  Future<bool> delete(int id) async {
    if (_isar == null) {
      _memPresets.remove(id);
      _memController.add(null);
      return true;
    }
    return _isar.writeTxn(() => _isar.presets.delete(id));
  }

  Future<List<Preset>> getAll() async {
    if (_isar == null) {
      final list = _memPresets.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }
    return _isar.presets
        .select(
          compare: (a, b) {
            return a.createdAt.compareTo(b.createdAt);
          },
        )
        .findAll();
  }

  List<Preset> _defaultPresets() => [
    Preset()
      ..id = 1
      ..name = 'Deepwork'
      ..colorValue = presetColors[11]
      ..iconKey = 'computer'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 2
      ..name = 'Intentional Rest'
      ..colorValue = presetColors[15]
      ..iconKey = 'meditate'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 3
      ..name = 'Social activity'
      ..colorValue = presetColors[2]
      ..iconKey = 'meeting'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 4
      ..name = 'Hobbies'
      ..colorValue = presetColors[14]
      ..iconKey = 'art'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 5
      ..name = 'Exercise'
      ..colorValue = presetColors[7]
      ..iconKey = 'running'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 6
      ..name = 'Wind down'
      ..colorValue = presetColors[13]
      ..iconKey = 'relax'
      ..createdAt = DateTime.now(),
    Preset()
      ..id = 7
      ..name = 'Sleep'
      ..colorValue = presetColors[16]
      ..iconKey = 'sleep'
      ..createdAt = DateTime.now(),
  ];
}
