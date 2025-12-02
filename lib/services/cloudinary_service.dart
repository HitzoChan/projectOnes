import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  final ImagePicker _picker = ImagePicker();

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy to a temporary file to avoid content-uri/read issues on some OEMs
        final bytes = await image.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final ext = image.name.contains('.') ? image.name.split('.').last : 'jpg';
        final tempFile = File('${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tempFile.writeAsBytes(bytes, flush: true);
        return tempFile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to Cloudinary
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Upload with user ID as public_id for easy replacement
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'attendance_app/profiles',
          publicId: userId, // This allows replacing old images
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL
      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(String publicId, {
    int width = 400,
    int height = 400,
  }) {
    return CloudinaryConfig.getImageUrl(
      publicId,
      width: width,
      height: height,
      crop: 'fill',
      quality: 'auto',
      format: 'auto',
    );
  }

  /// Delete image from Cloudinary (requires backend implementation)
  /// Note: Client-side deletion requires API Secret, which should not be in the app
  /// Implement this on your backend/Firebase Functions if needed
  Future<void> deleteImage(String publicId) async {
    // This would require backend implementation with API Secret
    throw UnimplementedError(
      'Image deletion requires backend implementation for security',
    );
  }
}
