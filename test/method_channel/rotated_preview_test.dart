import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/method_channel/rotated_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // With sensorOrientationDegrees == 0 and facingSign == 1, the rotation
  // correction resolves to these quarter turns, which is what we assert on:
  //   portraitUp      -> 0
  //   landscapeRight  -> 2
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

    expect(quarterTurns(tester), 0);
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

    expect(quarterTurns(tester), 2);
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
      expect(quarterTurns(tester), 0);

      // Rebuild with the new stream. didUpdateWidget should resubscribe and
      // adopt the new initial orientation.
      await tester.pumpWidget(
        buildPreview(
          stream: newController.stream,
          initialOrientation: DeviceOrientation.landscapeRight,
        ),
      );
      expect(quarterTurns(tester), 2);

      // Events on the new stream are now followed.
      newController.add(DeviceOrientation.portraitUp);
      await tester.pumpAndSettle();
      expect(quarterTurns(tester), 0);

      // Events on the old stream are ignored: the old subscription was
      // cancelled, so this must not change the rotation.
      oldController.add(DeviceOrientation.landscapeRight);
      await tester.pumpAndSettle();
      expect(quarterTurns(tester), 0);
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

    expect(quarterTurns(tester), 2);
  });
}
