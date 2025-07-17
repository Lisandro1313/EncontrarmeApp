import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const EncontrarmeApp());
}

class EncontrarmeApp extends StatelessWidget {
  const EncontrarmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🐶 Encontrarme App',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
      ),
      home: const EncontrarmeHomePage(),
    );
  }
}

class Reporte {
  String tipo;
  String descripcion;
  String ubicacion;
  String? fotoPath;

  Reporte({
    required this.tipo,
    required this.descripcion,
    required this.ubicacion,
    this.fotoPath,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      ubicacion: json['ubicacion'],
      fotoPath: json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'foto': fotoPath,
    };
  }
}

class EncontrarmeHomePage extends StatefulWidget {
  const EncontrarmeHomePage({super.key});

  @override
  State<EncontrarmeHomePage> createState() => _EncontrarmeHomePageState();
}

class _EncontrarmeHomePageState extends State<EncontrarmeHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _tipo = 'Perdida';
  final _descController = TextEditingController();
  final _ubicController = TextEditingController();

  List<Reporte> _reportes = [];
  File? _fotoFile;
  final ImagePicker _picker = ImagePicker();

  late File _jsonFile;
  bool _fileExists = false;
  Directory? _dir;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _dir = await getApplicationDocumentsDirectory();
    _jsonFile = File('${_dir!.path}/reportes.json');
    _fileExists = await _jsonFile.exists();
    if (_fileExists) {
      String content = await _jsonFile.readAsString();
      List<dynamic> jsonData = json.decode(content);
      setState(() {
        _reportes = jsonData.map((e) => Reporte.fromJson(e)).toList();
      });
    }
  }

  Future<void> _guardarDatos() async {
    List<Map<String, dynamic>> jsonList = _reportes.map((r) => r.toJson()).toList();
    await _jsonFile.writeAsString(json.encode(jsonList));
  }

  Future<void> _seleccionarFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    if (image != null) {
      setState(() {
        _fotoFile = File(image.path);
      });
    }
  }

  void _guardarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    String? rutaFotoGuardada;
    if (_fotoFile != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final savedImage = await _fotoFile!.copy('${_dir!.path}/$fileName');
      rutaFotoGuardada = savedImage.path;
    }

    final nuevoReporte = Reporte(
      tipo: _tipo,
      descripcion: _descController.text,
      ubicacion: _ubicController.text,
      fotoPath: rutaFotoGuardada,
    );

    setState(() {
      _reportes.insert(0, nuevoReporte);
      _descController.clear();
      _ubicController.clear();
      _fotoFile = null;
    });

    await _guardarDatos();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Reporte publicado correctamente!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🐶 Encontrarme App')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text('📍 Reportar Mascota', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tipo:'),
                DropdownButton<String>(
                  value: _tipo,
                  items: const [
                    DropdownMenuItem(value: 'Perdida', child: Text('Perdida')),
                    DropdownMenuItem(value: 'Encontrada', child: Text('Encontrada')),
                  ],
                  onChanged: (val) => setState(() => _tipo = val ?? 'Perdida'),
                ),
                const SizedBox(height: 10),
                const Text('Descripción:'),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Descripción'),
                  validator: (val) => val == null || val.isEmpty ? 'Completá la descripción' : null,
                ),
                const SizedBox(height: 10),
                const Text('Ubicación:'),
                TextFormField(
                  controller: _ubicController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ubicación'),
                  validator: (val) => val == null || val.isEmpty ? 'Completá la ubicación' : null,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6DDCC)),
                  onPressed: _seleccionarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Seleccionar Foto'),
                ),
                if (_fotoFile != null)
                  Center(child: Image.file(_fotoFile!, width: 120, height: 120, fit: BoxFit.cover)),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAED6F1)),
                    onPressed: _guardarReporte,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text('✅ Publicar Reporte', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            Text('📋 Reportes Activos', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Color(0xFF117864))),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reportes.length,
              itemBuilder: (context, index) {
                final rep = _reportes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: rep.fotoPath != null ? Image.file(File(rep.fotoPath!), width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.pets),
                    title: Text('[${rep.tipo}] ${rep.descripcion}'),
                    subtitle: Text(rep.ubicacion),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
