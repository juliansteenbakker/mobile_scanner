# #!/bin/bash

# List Flutter devices
flutter devices

# Navigate to example
cd example

echo "pwd"
pwd

echo "ls"
ls

# Insert QR Code image from "integration_test/qr_code.jpg" into the Android
# camera emulator.
echo "" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
echo "poster custom" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
echo "size 2 2" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
echo "position 0 0 -1.8" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
echo "rotation 0 0 0" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
echo "default qr_code.jpg" >> ~/Android/sdk/emulator/resources/Toren1BD.posters
mv integration_test/qr_code.jpg ~/Android/sdk/emulator/resources/qr_code.jpg

flutter run integration_test/app_test.dart -d emulator-5554