// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm3u_credentials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class M3uCredentialsAdapter extends TypeAdapter<M3uCredentials> {
  @override
  final int typeId = 1;

  @override
  M3uCredentials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return M3uCredentials(
      id: fields[0] as String,
      name: fields[1] as String,
      m3uUrl: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, M3uCredentials obj) {
    writer
      ..writeByte(3)
      ..writeByte(2)
      ..write(obj.m3uUrl)
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
      other is M3uCredentialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
