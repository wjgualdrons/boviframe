import 'package:hive/hive.dart';

part 'evaluacion_model.g.dart';

@HiveType(typeId: 0)
class EvaluacionAnimal {
  @HiveField(0)
  final String idAnimal;

  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final DateTime fechaNac;

  @HiveField(3)
  final double pesoNac;

  @HiveField(4)
  final double pesoDestete;

  @HiveField(5)
  final double peso205;

  @HiveField(6)
  final String sexo;

  @HiveField(7)
  final String estado;

  @HiveField(8)
  final String padre;

  @HiveField(9)
  final String madre;

  @HiveField(10)
  final Map<String, double> epmuras;

  EvaluacionAnimal({
    required this.idAnimal,
    required this.nombre,
    required this.fechaNac,
    required this.pesoNac,
    required this.pesoDestete,
    required this.peso205,
    required this.sexo,
    required this.estado,
    required this.padre,
    required this.madre,
    required this.epmuras,
  });
}

Map<String, dynamic> evaluacionAnimalToMap(EvaluacionAnimal animal) {
  return {
    'idAnimal': animal.idAnimal,
    'nombre': animal.nombre,
    'fechaNac': animal.fechaNac.toIso8601String(),
    'pesoNac': animal.pesoNac,
    'pesoDestete': animal.pesoDestete,
    'peso205': animal.peso205,
    'sexo': animal.sexo,
    'estado': animal.estado,
    'padre': animal.padre,
    'madre': animal.madre,
    'epmuras': animal.epmuras,
  };
}

class Unidad {
  List<EvaluacionAnimal> evaluaciones;

  Unidad({required this.evaluaciones});
}

Unidad? _unidad;

void main() {
  // Ejemplo de uso
  _unidad = Unidad(
    evaluaciones: [
      EvaluacionAnimal(
        idAnimal: '1',
        nombre: 'Animal 1',
        fechaNac: DateTime.parse('2020-01-01'),
        pesoNac: 30.0,
        pesoDestete: 100.0,
        peso205: 200.0,
        sexo: 'M',
        estado: 'Sano',
        padre: 'Padre 1',
        madre: 'Madre 1',
        epmuras: {'EPM1': 1.5, 'EPM2': 2.5},
      ),
      EvaluacionAnimal(
        idAnimal: '2',
        nombre: 'Animal 2',
        fechaNac: DateTime.parse('2021-01-01'),
        pesoNac: 35.0,
        pesoDestete: 110.0,
        peso205: 210.0,
        sexo: 'F',
        estado: 'Sano',
        padre: 'Padre 2',
        madre: 'Madre 2',
        epmuras: {'EPM1': 1.8, 'EPM2': 2.8},
      ),
    ],
  );

  // Convertir a mapa
  Map<String, dynamic> unidadMap = {
    'evaluaciones': _unidad!.evaluaciones
        .map((animal) => evaluacionAnimalToMap(animal))
        .toList(),
  };

  print(unidadMap);
}

// Puedes eliminar la importaciÃ³n de flutter/material.dart si no se usa mÃ¡s aquÃ­.
// Pero si la mantienes, no causarÃ¡ problemas por sÃ­ misma una vez que hayas limpiado el cÃ³digo errÃ³neo.



