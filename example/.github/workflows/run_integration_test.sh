# #!/bin/bash

# List Flutter devices
flutter devices

# Grant camera permissions
adb shell pm grant dev.steenbakker.mobile_scanner.example android.permission.CAMERA

echo "pwd"
pwd

echo "ls"
ls

# Insert QR Code image from "integration_test/qr_code.jpg" into the Android
# camera emulator.
echo "" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
echo "poster custom" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
echo "size 2 2" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
echo "position 0 0 -1.8" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
echo "rotation 0 0 0" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
echo "default qr_code.jpg" >> ~/Android/Sdk/emulator/resources/Toren1BD.posters
mv integration_test/qr_code.jpg ~/Android/Sdk/emulator/resources/Toren1BD.posters

flutter run integration_test/app_test.dart -d emulator-5556