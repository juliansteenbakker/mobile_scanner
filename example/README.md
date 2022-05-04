# Example for `mobile_scanner`

## Integration tests
This packages contains integration tests for Android. 

### Setup
To run these tests, you need insert an image to the virtual scene of the Android emulator. You can use these commands:
```sh
echo "" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "poster qr_code" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "size 2 2" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "position 0 0.3 -1.0" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "rotation 0 0 0" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
echo "default qr_code.jpg" >> ~/Library/Android/sdk/emulator/resources/Toren1BD.posters
mv integration_test/qr_code.jpg ~/Library/Android/sdk/emulator/resources/
```
Source: [Android emulator camera custom image](https://stackoverflow.com/a/64922184/8358501)

It's also important that you run start an Android Emulator with PlayStore services and the virtual scene as back camera. Additionally, you should be able to run command with `adb` from your terminal (it's required to grant the app permissions to the camera).

### Run
To run the integration tests, execute this command:
```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554
```

### Demo
Running the integration tests should look like this:
https://user-images.githubusercontent.com/24459435/166640395-b6cdf631-3c51-454d-8158-b9adc158871f.mov
