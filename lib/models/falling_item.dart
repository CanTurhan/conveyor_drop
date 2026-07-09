import 'drop_color_type.dart';

class FallingItem {
  FallingItem({
    required this.x,
    required this.y,
    required this.colorType,
    required this.radius,
  });

  double x;
  double y;
  final DropColorType colorType;
  final double radius;
}
