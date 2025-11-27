// lib/screens/visitas_screen.dart
import 'package:flutter/material.dart';
import '../models/visita.dart';
import '../services/visitas_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class VisitasScreen extends StatefulWidget {
  const VisitasScreen({super.key});

  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  final VisitasService _visitasService = VisitasService();
  final ApiService _apiService = ApiService();
  List<Visita> _visitas = [];
  List<Visita> _visitasFiltradas = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _soloHoy = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cargarVisitas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarVisitas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final visitas = await _visitasService.obtenerVisitas();
      setState(() {
        _visitas = visitas;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar las visitas: $e';
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    List<Visita> resultado = _visitas;

    if (_soloHoy) {
      resultado = _visitasService.filtrarPorFecha(resultado, DateTime.now());
    }

    if (_query.isNotEmpty) {
      resultado = _visitasService.buscarPorNombre(resultado, _query);
    }

    _visitasFiltradas = resultado;
  }

  void _onBuscarChanged(String query) {
    setState(() {
      _query = query;
      _aplicarFiltros();
    });
  }

  Future<void> _cerrarSesion() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Visitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarVisitas,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro "Solo hoy"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.today),
                    SizedBox(width: 8),
                    Text('Solo mostrar visitas de hoy'),
                  ],
                ),
                Switch(
                  value: _soloHoy,
                  onChanged: (val) {
                    setState(() {
                      _soloHoy = val;
                      _aplicarFiltros();
                    });
                  },
                ),
              ],
            ),
          ),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onBuscarChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onBuscarChanged,
            ),
          ),
          // Contenido principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarVisitas,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _visitasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No hay visitas registradas'
                                      : 'No se encontraron resultados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarVisitas,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _visitasFiltradas.length,
                              itemBuilder: (context, index) {
                                final visita = _visitasFiltradas[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: Text(
                                        visita.nombre[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      visita.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('RUT: ${visita.rut}'),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Motivo: ${visita.motivoVisita}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              visita.fechaFormateada,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${visita.horaEntrada.substring(0, 5)} - ${visita.horaSalida.substring(0, 5)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Mostrar detalles de la visita
                                      _mostrarDetallesVisita(visita);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesVisita(Visita visita) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(visita.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetalle('RUT', visita.rut),
            _buildDetalle('Motivo', visita.motivoVisita),
            _buildDetalle('Fecha', visita.fechaFormateada),
            _buildDetalle('Hora Entrada', visita.horaEntrada.substring(0, 5)),
            _buildDetalle('Hora Salida', visita.horaSalida.substring(0, 5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}