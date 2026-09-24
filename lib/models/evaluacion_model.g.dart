// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluacion_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EvaluacionAnimalAdapter extends TypeAdapter<EvaluacionAnimal> {
  @override
  final int typeId = 0;

  @override
  EvaluacionAnimal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EvaluacionAnimal(
      idAnimal: fields[0] as String,
      nombre: fields[1] as String,
      fechaNac: fields[2] as DateTime,
      pesoNac: fields[3] as double,
      pesoDestete: fields[4] as double,
      peso205: fields[5] as double,
      sexo: fields[6] as String,
      estado: fields[7] as String,
      padre: fields[8] as String,
      madre: fields[9] as String,
      epmuras: (fields[10] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, EvaluacionAnimal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.idAnimal)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.fechaNac)
      ..writeByte(3)
      ..write(obj.pesoNac)
      ..writeByte(4)
      ..write(obj.pesoDestete)
      ..writeByte(5)
      ..write(obj.peso205)
      ..writeByte(6)
      ..write(obj.sexo)
      ..writeByte(7)
      ..write(obj.estado)
      ..writeByte(8)
      ..write(obj.padre)
      ..writeByte(9)
      ..write(obj.madre)
      ..writeByte(10)
      ..write(obj.epmuras);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluacionAnimalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}



