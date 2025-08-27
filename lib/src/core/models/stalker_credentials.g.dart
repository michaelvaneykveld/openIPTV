// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stalker_credentials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StalkerCredentialsAdapter extends TypeAdapter<StalkerCredentials> {
  @override
  final int typeId = 2;

  @override
  StalkerCredentials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StalkerCredentials(
      id: fields[0] as String,
      name: fields[1] as String,
      baseUrl: fields[2] as String,
      macAddress: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StalkerCredentials obj) {
    writer
      ..writeByte(4)
      ..writeByte(2)
      ..write(obj.baseUrl)
      ..writeByte(3)
      ..write(obj.macAddress)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StalkerCredentialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
