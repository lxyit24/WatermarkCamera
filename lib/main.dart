import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(WatermarkCameraApp(prefs: prefs));
}

class WatermarkCameraApp extends StatelessWidget {
  final SharedPreferences prefs;
  const WatermarkCameraApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watermark Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  
  // Watermark settings
  bool _showDate = true;
  bool _showTime = true;
  bool _showLocation = false;
  String _customText = '';
  
  Position? _currentPosition;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initCamera();
  }

  Future<void> _loadSettings() async {
    _showDate = prefs.getBool('showDate') ?? true;
    _showTime = prefs.getBool('showTime') ?? true;
    _showLocation = prefs.getBool('showLocation') ?? false;
    _customText = prefs.getString('customText') ?? '';
    _textController.text = _customText;
    setState(() {});
  }

  Future<void> _saveSettings() async {
    await prefs.setBool('showDate', _showDate);
    await prefs.setBool('showTime', _showTime);
    await prefs.setBool('showLocation', _showLocation);
    await prefs.setString('customText', _customText);
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(_cameras[0], ResolutionPreset.high);
        await _controller!.initialize();
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
      } catch (e) {
        // Location unavailable
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    
    setState(() => _isCapturing = true);
    
    try {
      if (_showLocation) await _getCurrentLocation();
      
      final XFile image = await _controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/IMG_$timestamp.jpg';
      
      // Copy file
      await File(image.path).copy(filePath);
      
      // Save to gallery
      await ImageGallerySaverPlus.saveFile(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Watermark Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SwitchListTile(title: const Text('Show Date'), value: _showDate, 
                onChanged: (v) { setModalState(() => _showDate = v); setState(() {}); }),
              SwitchListTile(title: const Text('Show Time'), value: _showTime, 
                onChanged: (v) { setModalState(() => _showTime = v); setState(() {}); }),
              SwitchListTile(title: const Text('Show Location'), value: _showLocation, 
                onChanged: (v) { setModalState(() => _showLocation = v); setState(() {}); }),
              const SizedBox(height: 10),
              TextField(controller: _textController, decoration: const InputDecoration(
                labelText: 'Custom Text', border: OutlineInputBorder()),
                onChanged: (v) => _customText = v),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () { _saveSettings(); Navigator.pop(context); },
                child: const Text('Save'))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watermark Camera'), actions: [
        IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsSheet),
      ]),
      body: _isInitialized && _controller != null
          ? Stack(
              children: [
                Center(child: CameraPreview(_controller!)),
                _buildWatermark(),
                Positioned(
                  bottom: 30, left: 0, right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capturePhoto,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                        child: _isCapturing 
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildWatermark() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);
    String locStr = '';
    if (_showLocation && _currentPosition != null) {
      locStr = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
    }
    
    final parts = <String>[];
    if (_showDate) parts.add(dateStr);
    if (_showTime) parts.add(timeStr);
    if (_showLocation) parts.add(locStr);
    if (_customText.isNotEmpty) parts.add(_customText);
    
    if (parts.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 130, left: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Text(parts.join(' | '), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textController.dispose();
    super.dispose();
  }
}