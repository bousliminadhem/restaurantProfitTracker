// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DishAdapter extends TypeAdapter<Dish> {
  @override
  final int typeId = 0;

  @override
  Dish read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dish(
      id: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      type: fields[3] == null ? 'Vollailes' : fields[3] as String,
      hasVariant: fields[4] == null ? false : fields[4] as bool,
      variant: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Dish obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.hasVariant)
      ..writeByte(5)
      ..write(obj.variant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
