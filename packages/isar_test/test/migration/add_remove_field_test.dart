import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'add_remove_field_test.g.dart';

@Collection()
@Name('Col')
class Col1 {
  Col1(this.id, this.value);
  int? id;

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col1 && id == other.id && value == other.value;
}

@Collection()
@Name('Col')
class Col2 {
  Col2(this.id, this.value, this.newValues);
  int? id;

  String? value;

  List<String>? newValues;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col2 &&
      id == other.id &&
      value == other.value &&
      listEquals(newValues, other.newValues);
}

void main() {
  isarTest('Add field', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    await isar1.tWriteTxn(() {
      return isar1.col1s.tPutAll([Col1(1, 'value1'), Col1(2, 'value2')]);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isar1.name);
    await qEqual(isar2.col2s.where().tFindAll(), [
      Col2(1, 'value1', null),
      Col2(2, 'value2', null),
    ]);
    await isar2.tWriteTxn(() {
      return isar2.col2s.tPutAll([
        Col2(1, 'value3', ['hi']),
        Col2(3, 'value4', [])
      ]);
    });
    await qEqual(isar2.col2s.where().tFindAll(), [
      Col2(1, 'value3', ['hi']),
      Col2(2, 'value2', null),
      Col2(3, 'value4', []),
    ]);
    expect(await isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isar1.name);
    await qEqual(isar3.col1s.where().tFindAll(), [
      Col1(1, 'value3'),
      Col1(2, 'value2'),
      Col1(3, 'value4'),
    ]);
    expect(await isar3.close(), true);
  });

  isarTest('Remove field', () async {
    final isar1 = await openTempIsar([Col2Schema]);
    await isar1.writeTxn(() {
      return isar1.col2s.putAll([
        Col2(1, 'value1', ['hi']),
        Col2(2, 'value2', ['val2', 'val22']),
      ]);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col1Schema], name: isar1.name);
    await qEqual(isar2.col1s.where().findAll(), [
      Col1(1, 'value1'),
      Col1(2, 'value2'),
    ]);
    await isar2.writeTxn(() {
      return isar2.col1s.put(Col1(1, 'value3'));
    });
    await qEqual(isar2.col1s.where().findAll(), [
      Col1(1, 'value3'),
      Col1(2, 'value2'),
    ]);
    expect(await isar2.close(), true);
  });
}
