import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Read the original image
  final file = File('assets/images/logo.png');
  final image = img.decodeImage(file.readAsBytesSync());

  if (image != null) {
    // Determine the max dimension
    int maxDim = image.width > image.height ? image.width : image.height;
    
    // We want the original logo to occupy about 60% of the final canvas to avoid cropping.
    // So the new canvas should be roughly maxDim / 0.6
    int canvasSize = (maxDim / 0.6).round();
    
    // Create a new blank canvas (transparent)
    var padded = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
    
    // Fill with transparent or white. For adaptive icons, transparent is better if we define a background color.
    // Let's just keep it transparent.
    img.fill(padded, color: img.ColorRgba8(0, 0, 0, 0));
    
    // Draw the original image onto the center of the canvas
    int dstX = (canvasSize - image.width) ~/ 2;
    int dstY = (canvasSize - image.height) ~/ 2;
    
    img.compositeImage(padded, image, dstX: dstX, dstY: dstY);

    // Save it as a new file
    final outFile = File('assets/images/logo_padded.png');
    outFile.writeAsBytesSync(img.encodePng(padded));
    
    print('Padded image saved to ${outFile.path}');
  } else {
    print('Failed to decode image.');
  }
}
