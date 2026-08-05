import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/method_channel/rotated_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // RotatedPreview does not rotate by the device orientation itself: it
  // applies the correction that remains after CameraPreview has already
  // rotated the preview by the device orientation. So the expected quarter
  // turns below are that leftover correction, not the orientation.
  //
  // For sensorOrientationDegrees == 0 and facingSign == 1, per
  // _computeRotationDegrees: ((sensor - device + 360) % 360) - device
  //   portraitUp:     ((0 -  0 + 360) % 360) -  0 =   0 ->  0 turns
  //   landscapeRight: ((0 - 90 + 360) % 360) - 90 = 180 ->  2 turns
  //
  // These two are used throughout because they are unambiguous: with a zero
  // sensor orientation, portraitUp and portraitDown both resolve to 0 turns.
  const portraitUpTurns = 0;
  const landscapeRightTurns = 2;

  const childKey = Key('rotated-child');

  Widget buildPreview({
    required Stream<DeviceOrientation> stream,
    required DeviceOrientation initialOrientation,
  }) {
    return RotatedPreview(
      deviceOrientationStream: stream,
      facingSign: 1,
      initialDeviceOrientation: initialOrientation,
      sensorOrientationDegrees: 0,
      child: const SizedBox(key: childKey),
    );
  }

  int quarterTurns(WidgetTester tester) {
    return tester
        .widget<RotatedBox>(
          find.ancestor(
            of: find.byKey(childKey),
            matching: find.byType(RotatedBox),
          ),
        )
        .quarterTurns;
  }

  testWidgets('applies the initial device orientation', (tester) async {
    final controller = StreamController<DeviceOrientation>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      buildPreview(
        stream: controller.stream,
        initialOrientation: DeviceOrientation.portraitUp,
      ),
    );

    expect(quarterTurns(tester), portraitUpTurns);
  });

  testWidgets('rotates when the orientation stream emits', (tester) async {
    final controller = StreamController<DeviceOrientation>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      buildPreview(
        stream: controller.stream,
        initialOrientation: DeviceOrientation.portraitUp,
      ),
    );

    controller.add(DeviceOrientation.landscapeRight);
    await tester.pumpAndSettle();

    expect(quarterTurns(tester), landscapeRightTurns);
  });

  testWidgets(
    'resubscribes to a new stream and stops following the old one when the '
    'stream instance changes',
    (tester) async {
      // Emulates a camera restart (e.g. switchCamera), where the platform
      // recreates the device orientation stream and the widget is rebuilt
      // with a new stream instance and a new initial orientation.
      final oldController = StreamController<DeviceOrientation>.broadcast();
      final newController = StreamController<DeviceOrientation>.broadcast();
      addTearDown(oldController.close);
      addTearDown(newController.close);

      await tester.pumpWidget(
        buildPreview(
          stream: oldController.stream,
          initialOrientation: DeviceOrientation.portraitUp,
        ),
      );
      expect(quarterTurns(tester), portraitUpTurns);

      // Rebuild with the new stream. didUpdateWidget should resubscribe and
      // adopt the new initial orientation.
      await tester.pumpWidget(
        buildPreview(
          stream: newController.stream,
          initialOrientation: DeviceOrientation.landscapeRight,
        ),
      );
      expect(quarterTurns(tester), landscapeRightTurns);

      // Events on the new stream are now followed.
      newController.add(DeviceOrientation.portraitUp);
      await tester.pumpAndSettle();
      expect(quarterTurns(tester), portraitUpTurns);

      // Events on the old stream are ignored: the old subscription was
      // cancelled, so this must not change the rotation.
      oldController.add(DeviceOrientation.landscapeRight);
      await tester.pumpAndSettle();
      expect(quarterTurns(tester), portraitUpTurns);
    },
  );

  testWidgets('keeps following the same stream instance across rebuilds', (
    tester,
  ) async {
    final controller = StreamController<DeviceOrientation>.broadcast();
    addTearDown(controller.close);

    await tester.pumpWidget(
      buildPreview(
        stream: controller.stream,
        initialOrientation: DeviceOrientation.portraitUp,
      ),
    );

    // Rebuild with the same stream instance; the subscription must stay live.
    await tester.pumpWidget(
      buildPreview(
        stream: controller.stream,
        initialOrientation: DeviceOrientation.portraitUp,
      ),
    );

    controller.add(DeviceOrientation.landscapeRight);
    await tester.pumpAndSettle();

    expect(quarterTurns(tester), landscapeRightTurns);
  });
}
