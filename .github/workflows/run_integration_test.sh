# #!/bin/bash

# Navigate to example
cd example

# We can't use the "flutter test" command, because it will not execute the adb
# command to access the camera (defined in the "test_driver/integration_test.jpg")
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554