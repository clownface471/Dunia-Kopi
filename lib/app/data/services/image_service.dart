import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'dwloenjli', 
    'dunia-kopi-unsigned',
    cache: false,
  );

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image, folder: 'dunia_kopi_products'),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

