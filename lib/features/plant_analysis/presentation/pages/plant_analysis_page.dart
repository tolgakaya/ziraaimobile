import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class PlantAnalysisPage extends StatefulWidget {
  const PlantAnalysisPage({super.key});

  @override
  State<PlantAnalysisPage> createState() => _PlantAnalysisPageState();
}

class _PlantAnalysisPageState extends State<PlantAnalysisPage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  String _statusMessage = '';
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectFromCamera() async {
    print('🎯 Camera selection started');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _statusMessage = 'Fotoğraf seçildi, analiz için hazır';
        });
        print('✅ Image selected from camera: ${image.path}');
      } else {
        print('❌ No image selected from camera');
      }
    } catch (e) {
      print('❌ Camera error: $e');
      setState(() {
        _statusMessage = 'Kamera hatası: $e';
      });
    }
  }

  Future<void> _selectFromGallery() async {
    print('🎯 Gallery selection started');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _statusMessage = 'Fotoğraf seçildi, analiz için hazır';
        });
        print('✅ Image selected from gallery: ${image.path}');
      } else {
        print('❌ No image selected from gallery');
      }
    } catch (e) {
      print('❌ Gallery error: $e');
      setState(() {
        _statusMessage = 'Galeri hatası: $e';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      setState(() {
        _statusMessage = 'Lütfen önce bir fotoğraf seçin';
      });
      return;
    }

    print('🚀 Plant analysis started');
    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Bitki analiz ediliyor...';
      _analysisResult = null;
    });

    try {
      // TODO: Token'ı secure storage'dan al
      final String token = 'Bearer_token_will_be_here';

      final dio = Dio();

      // Multipart form data hazırla
      String fileName = _selectedImage!.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: fileName,
        ),
      });

      print('📤 Sending analysis request...');

      final response = await dio.post(
        'https://ziraai-api-sit.up.railway.app/api/v1/plantanalyses/analyze',
        data: formData,
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['success'] == true) {
          setState(() {
            _analysisResult = responseData['data'];
            _statusMessage = 'Analiz tamamlandı!';
            _isAnalyzing = false;
          });
          print('✅ Analysis completed successfully');
        } else {
          setState(() {
            _statusMessage = responseData['message'] ?? 'Analiz başarısız';
            _isAnalyzing = false;
          });
          print('❌ Analysis failed: ${responseData['message']}');
        }
      } else {
        setState(() {
          _statusMessage = 'Geçersiz response';
          _isAnalyzing = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _isAnalyzing = false;
        if (e.response != null) {
          final errorData = e.response!.data;
          _statusMessage = errorData['message'] ?? 'API hatası: ${e.response!.statusCode}';
        } else {
          _statusMessage = 'Bağlantı hatası: ${e.message}';
        }
      });
      print('❌ Analysis error: $e');
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _statusMessage = 'Bilinmeyen hata: $e';
      });
      print('❌ Unexpected error: $e');
    }
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 64,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 16),
                Text(
                  'Fotoğraf Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kamera veya galeri kullanarak\nbitki fotoğrafı ekleyin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _selectFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAnalyzing ? null : _selectFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isAnalyzing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Analiz Ediliyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'Bitki Analizi Başlat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analiz Sonucu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          // Analiz sonuçlarını burada göster
          Text(
            'Bitki Türü: ${_analysisResult!['plantType'] ?? 'Bilinmiyor'}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sağlık Durumu: ${_analysisResult!['healthStatus'] ?? 'Analiz edilmedi'}',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          if (_analysisResult!['diseases'] != null)
            Text(
              'Tespit Edilen Hastalıklar: ${_analysisResult!['diseases'].join(', ')}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFDC2626),
              ),
            ),
          const SizedBox(height: 8),
          if (_analysisResult!['recommendations'] != null)
            Text(
              'Öneriler: ${_analysisResult!['recommendations']}',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF059669),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Bitki Analizi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf Seçme Alanı
            _buildImageSection(),

            const SizedBox(height: 24),

            // Buton Grubu
            _buildActionButtons(),

            const SizedBox(height: 16),

            // Analiz Butonu
            _buildAnalyzeButton(),

            const SizedBox(height: 16),

            // Durum Mesajı
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('hata') || _statusMessage.contains('başarısız')
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: _statusMessage.contains('hata') || _statusMessage.contains('başarısız')
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF059669),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Analiz Sonucu
            _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }
}