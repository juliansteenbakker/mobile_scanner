# #!/bin/bash

# Navigate to example
cd example

# Insert QR Code image from "integration_test/qr_code.jpg" into the Android
# camera emulator.
echo "" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "poster qr_code" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "size 2 2" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "position 0 0 -1.8" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "rotation 0 0 0" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "default qr_code.jpg" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
mv integration_test/qr_code.jpg ~/Library/Android/sdk/emulator/resources/

flutter test integration_test/app_test.dart -d emulator-5554