// lib/services/visitas_service.dart
import '../models/visita.dart';
import 'api_service.dart';

class VisitasService {
  final ApiService _apiService = ApiService();

  // Obtener todas las visitas desde el ViewSet de DRF
  // Endpoint: GET /api/visitas/
  Future<List<Visita>> obtenerVisitas() async {
    try {
      final response = await _apiService.get('/visitas/');
      
      if (response['success']) {
        // El ViewSet de DRF devuelve una lista directamente
        List<dynamic> data = response['data'];
        return data.map((json) => Visita.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener visitas: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener una visita específica
  // Endpoint: GET /api/visitas/{id}/
  Future<Visita> obtenerVisita(int id) async {
    try {
      final response = await _apiService.get('/visitas/$id/');
      
      if (response['success']) {
        return Visita.fromJson(response['data']);
      } else {
        throw Exception('Error al obtener la visita: ${response['error']}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Método opcional para filtrar visitas por fecha localmente
  List<Visita> filtrarPorFecha(List<Visita> visitas, DateTime fecha) {
    return visitas.where((visita) {
      return visita.fechaVisita.year == fecha.year &&
             visita.fechaVisita.month == fecha.month &&
             visita.fechaVisita.day == fecha.day;
    }).toList();
  }

  // Método opcional para buscar por nombre
  List<Visita> buscarPorNombre(List<Visita> visitas, String nombre) {
    return visitas.where((visita) {
      return visita.nombre.toLowerCase().contains(nombre.toLowerCase());
    }).toList();
  }
}