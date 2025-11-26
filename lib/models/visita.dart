// lib/models/visita.dart
class Visita {
  final int? id;
  final String rut;
  final String nombre;
  final String motivoVisita;
  final DateTime fechaVisita;
  final String horaEntrada; // TimeField de Django se maneja como String en formato "HH:MM:SS"
  final String horaSalida;

  Visita({
    this.id,
    required this.rut,
    required this.nombre,
    required this.motivoVisita,
    required this.fechaVisita,
    required this.horaEntrada,
    required this.horaSalida,
  });

  // Convertir JSON del backend a objeto Visita
  factory Visita.fromJson(Map<String, dynamic> json) {
    return Visita(
      id: json['id'],
      rut: json['rut'],
      nombre: json['nombre'],
      motivoVisita: json['motivo_visita'],
      fechaVisita: DateTime.parse(json['fecha_visita']),
      horaEntrada: json['hora_entrada'],
      horaSalida: json['hora_salida'],
    );
  }

  // Convertir objeto Visita a JSON (por si en el futuro necesitas POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      'rut': rut,
      'nombre': nombre,
      'motivo_visita': motivoVisita,
      'fecha_visita': '${fechaVisita.year}-${fechaVisita.month.toString().padLeft(2, '0')}-${fechaVisita.day.toString().padLeft(2, '0')}',
      'hora_entrada': horaEntrada,
      'hora_salida': horaSalida,
    };
  }

  // Método helper para formatear la fecha de forma legible
  String get fechaFormateada {
    return '${fechaVisita.day.toString().padLeft(2, '0')}/${fechaVisita.month.toString().padLeft(2, '0')}/${fechaVisita.year}';
  }
}