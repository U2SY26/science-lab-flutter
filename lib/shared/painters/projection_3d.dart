import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D → 2D 투영 유틸리티
/// Lorenz 어트랙터 패턴을 기반으로 한 재사용 가능한 3D 투영 클래스
class Projection3D {
  double rotX;
  double rotY;
  double scale;
  Offset center;

  Projection3D({
    this.rotX = 0.4,
    this.rotY = 0.6,
    this.scale = 60.0,
    this.center = Offset.zero,
  });

  /// 3D 좌표 → 2D 화면 좌표 투영 (원근감 포함)
  Offset project(double px, double py, double pz) {
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);

    // Y축 회전
    final x1 = px * cosY - pz * sinY;
    final z1 = px * sinY + pz * cosY;

    // X축 회전
    final y1 = py * cosX - z1 * sinX;
    final z2 = py * sinX + z1 * cosX;

    // 약한 원근 투영 (z 깊이)
    final perspective = 1.0 + z2 * 0.003;

    return Offset(
      center.dx + x1 * scale / perspective,
      center.dy - y1 * scale / perspective,
    );
  }

  /// 깊이값 반환 (뒤에서 앞 정렬용)
  double depth(double px, double py, double pz) {
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final z1 = px * sinY + pz * cosY;
    return py * sinX + z1 * cosX;
  }

  /// 와이어프레임 구 그리기
  static void drawWireframeSphere(
    Canvas canvas,
    Projection3D proj,
    double radius,
    Paint paint, {
    int latStep = 30,
    int lonStep = 5,
  }) {
    // 위도선
    for (double lat = -60; lat <= 60; lat += latStep) {
      final r = radius * math.cos(lat * math.pi / 180);
      final yy = radius * math.sin(lat * math.pi / 180);
      final path = Path();
      for (double lon = 0; lon <= 360; lon += lonStep.toDouble()) {
        final xx = r * math.cos(lon * math.pi / 180);
        final zz = r * math.sin(lon * math.pi / 180);
        final p = proj.project(xx, yy, zz);
        if (lon == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    // 경도선
    for (double lon = 0; lon < 360; lon += latStep.toDouble()) {
      final path = Path();
      for (double lat = -90; lat <= 90; lat += lonStep.toDouble()) {
        final r = radius * math.cos(lat * math.pi / 180);
        final yy = radius * math.sin(lat * math.pi / 180);
        final xx = r * math.cos(lon * math.pi / 180);
        final zz = r * math.sin(lon * math.pi / 180);
        final p = proj.project(xx, yy, zz);
        if (lat == -90) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  /// 3D 격자 평면 그리기 (XZ 평면)
  static void drawGridPlane(
    Canvas canvas,
    Projection3D proj,
    double size,
    Paint paint, {
    int divisions = 10,
  }) {
    final step = size / divisions;
    for (int i = 0; i <= divisions; i++) {
      final t = -size / 2 + i * step;
      // X 방향 선
      final p1 = proj.project(-size / 2, 0, t);
      final p2 = proj.project(size / 2, 0, t);
      canvas.drawLine(p1, p2, paint);
      // Z 방향 선
      final p3 = proj.project(t, 0, -size / 2);
      final p4 = proj.project(t, 0, size / 2);
      canvas.drawLine(p3, p4, paint);
    }
  }

  /// 원환체(torus) 그리기
  static void drawTorus(
    Canvas canvas,
    Projection3D proj,
    double majorRadius,
    double minorRadius,
    Paint paint, {
    int uSteps = 24,
    int vSteps = 12,
  }) {
    for (int ui = 0; ui < uSteps; ui++) {
      final u = ui * 2 * math.pi / uSteps;
      final path = Path();
      for (int vi = 0; vi <= vSteps; vi++) {
        final v = vi * 2 * math.pi / vSteps;
        final xx = (majorRadius + minorRadius * math.cos(v)) * math.cos(u);
        final yy = (majorRadius + minorRadius * math.cos(v)) * math.sin(u);
        final zz = minorRadius * math.sin(v);
        final p = proj.project(xx, yy, zz);
        if (vi == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    for (int vi = 0; vi < vSteps; vi++) {
      final v = vi * 2 * math.pi / vSteps;
      final path = Path();
      for (int ui = 0; ui <= uSteps; ui++) {
        final u = ui * 2 * math.pi / uSteps;
        final xx = (majorRadius + minorRadius * math.cos(v)) * math.cos(u);
        final yy = (majorRadius + minorRadius * math.cos(v)) * math.sin(u);
        final zz = minorRadius * math.sin(v);
        final p = proj.project(xx, yy, zz);
        if (ui == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
}

/// GestureDetector와 함께 사용할 3D 회전 컨트롤러 믹스인
mixin Rotation3DController {
  double rotX = 0.4;
  double rotY = 0.6;
  double scale3d = 60.0;
  Offset? lastPan;

  void handlePanStart(DragStartDetails d) {
    lastPan = d.globalPosition;
  }

  void handlePanUpdate(DragUpdateDetails d, void Function(void Function()) setState) {
    setState(() {
      rotY += (d.globalPosition.dx - (lastPan?.dx ?? d.globalPosition.dx)) * 0.01;
      rotX -= (d.globalPosition.dy - (lastPan?.dy ?? d.globalPosition.dy)) * 0.01;
      rotX = rotX.clamp(-math.pi / 2, math.pi / 2);
      lastPan = d.globalPosition;
    });
  }

  void handleScaleUpdate(ScaleUpdateDetails d, void Function(void Function()) setState) {
    if (d.scale != 1.0) {
      setState(() {
        scale3d = (scale3d * d.scale).clamp(20.0, 200.0);
      });
    }
  }

  Projection3D buildProjection(Offset center) => Projection3D(
        rotX: rotX,
        rotY: rotY,
        scale: scale3d,
        center: center,
      );
}
