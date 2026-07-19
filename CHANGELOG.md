# Changelog

## [7.4.0](https://github.com/juliansteenbakker/mobile_scanner/compare/v7.3.1...v7.4.0) (2026-07-19)


### Features

* add error message if controller is used before attached to a mobile scanner widget ([a263c6f](https://github.com/juliansteenbakker/mobile_scanner/commit/a263c6f23486a39e0792bd45a9f011d130289dcd))
* add focus point func, initial zoom position and use of ultra wide camera on Ios ([0e02e66](https://github.com/juliansteenbakker/mobile_scanner/commit/0e02e66cedfee839c541021993002b7453b8e99f))
* add focus point functionality and initial zoom settings for mobile scanner, along with optional use of ultraWideAngle camera on ios ([fb4f0ea](https://github.com/juliansteenbakker/mobile_scanner/commit/fb4f0eaf0e56ebe06b9f5e77c36adf9b36f3585c))
* Add getSupportedLenses() stub and lensType controller parameter ([cc5c42b](https://github.com/juliansteenbakker/mobile_scanner/commit/cc5c42b50ee19ceab6259cce553eca102c66392a))
* add iOS barcodeType detection ([004d488](https://github.com/juliansteenbakker/mobile_scanner/commit/004d4886c661c78338ae406b0af83bb747b316df))
* add iOS barcodeType detection ([6c61481](https://github.com/juliansteenbakker/mobile_scanner/commit/6c61481e7f3ebf4fbf6f172c677632e3035604a2))
* add support for ITF 2 of 5 ([c7f2c12](https://github.com/juliansteenbakker/mobile_scanner/commit/c7f2c1239f342c58e35c8eac36b2a79c478f19f1))
* Added lens enum types ([e366955](https://github.com/juliansteenbakker/mobile_scanner/commit/e366955221e7b5266935e58e806d47ea08b4c18d))
* Added method names as constants in `mobile_scanner_method_channel.dart` ([c0acf6c](https://github.com/juliansteenbakker/mobile_scanner/commit/c0acf6cb6d1a73b07a94dcee7ba38a87340aee54))
* Android implementation for querying camera lenses ([29a1e3a](https://github.com/juliansteenbakker/mobile_scanner/commit/29a1e3a419e7963577644dcf25e67a7c24fa5215))
* **android:** use OrientationEventListener for orientation ([b10087c](https://github.com/juliansteenbakker/mobile_scanner/commit/b10087c8f2f9e3eba46e08431d8e6ba14f435a5d))
* Apple implementation for querying camera lenses ([b61cbe3](https://github.com/juliansteenbakker/mobile_scanner/commit/b61cbe343058be37656887124254936dd4bf0127))
* Flutter view barcode corners ([f666714](https://github.com/juliansteenbakker/mobile_scanner/commit/f6667149bc2379219b1d2efd569bb0df66de5167))
* Implement example for lens switching ([c3a6c93](https://github.com/juliansteenbakker/mobile_scanner/commit/c3a6c9335e8ebcee1c4f17e6e6c9e5a935a861c7))
* Implemented lens selection on web ([d999dc0](https://github.com/juliansteenbakker/mobile_scanner/commit/d999dc05e3fe3d92aaaf0b39e27daf0cb4783ac0))
* release of v7.0.0 ([3c5a9ac](https://github.com/juliansteenbakker/mobile_scanner/commit/3c5a9ac34200436a1ff18611f20847e70f721abc))
* tap to focus, initial zoom and more lenses ([0ae802a](https://github.com/juliansteenbakker/mobile_scanner/commit/0ae802a0e3fb8406dca8dd31863ec53b859c3128))
* update screenshots to represent the latest example app ([a09039a](https://github.com/juliansteenbakker/mobile_scanner/commit/a09039a591c22b78427f8325a6d14cef8ea6ae25))


### Bug Fixes

* [Android] reset isPaused flag in start() called ([cc66756](https://github.com/juliansteenbakker/mobile_scanner/commit/cc66756cad7a35d1b7c6679c58edaa4083392d55))
* [Android] reset isPaused flag on start() called ([721f225](https://github.com/juliansteenbakker/mobile_scanner/commit/721f2253b9400bbf92018a0ba3f03f8c083c5131))
* add barcode payload parser ([343fac0](https://github.com/juliansteenbakker/mobile_scanner/commit/343fac0a167be3028d344c1d42429e6850f53bb2))
* add exclusion for macos ([b86610f](https://github.com/juliansteenbakker/mobile_scanner/commit/b86610f0a4cf1b4e4fcc69d746b613abeaf2c254))
* add exclusion for macos ([2a54ea6](https://github.com/juliansteenbakker/mobile_scanner/commit/2a54ea67dcfe1fcc647acffaf3ff88d2ecec1124))
* add ignore pointer to other widgets in stack to fix tapToFocus ([1f33cdf](https://github.com/juliansteenbakker/mobile_scanner/commit/1f33cdf9c02d8f73e8693391c929d3205c23141f))
* add isStarting to state in order to track if initialization is currently in progress ([a761e45](https://github.com/juliansteenbakker/mobile_scanner/commit/a761e45a6a8bf1f1e7434c661970ccd187d4844b))
* add isStarting to state in order to track if initialization is currently in progress ([8344d5d](https://github.com/juliansteenbakker/mobile_scanner/commit/8344d5d166e57fa11ac042ad455f8c2ab04776fa))
* add missing deviceOrientation parameter to BarcodePainter tests ([ebb3b4d](https://github.com/juliansteenbakker/mobile_scanner/commit/ebb3b4d6497d64a4d9562a8307794d7778cda209))
* add toString for jvmTarget ([a3d68dc](https://github.com/juliansteenbakker/mobile_scanner/commit/a3d68dc0e57ea8eb6e8dccb385e232c32a050f7e))
* add upperbound for meta dependency ([715c50f](https://github.com/juliansteenbakker/mobile_scanner/commit/715c50f2ebaefd57bda24edcfa388e35c6481899))
* all device orientations on ios ([60ba123](https://github.com/juliansteenbakker/mobile_scanner/commit/60ba12364ff61aaeec6c188a180fc95ec58c7c97))
* apply latest lint changes ([910604d](https://github.com/juliansteenbakker/mobile_scanner/commit/910604dd8e5cbd0725aae7c6e0f309d25f2b8977))
* apply latest lint changes for example app ([2be82c3](https://github.com/juliansteenbakker/mobile_scanner/commit/2be82c312ef657208d6658057aff2b119bb25daf))
* arrow to block notation ([689d7b4](https://github.com/juliansteenbakker/mobile_scanner/commit/689d7b4227a34992f42449c1aa70e7a37fa07534))
* Assign event channel streams to null on stop() ([1a5fc53](https://github.com/juliansteenbakker/mobile_scanner/commit/1a5fc53ac3c38055d130cd8871c8aedbf31f8aa8))
* await setFocusPoint ([1eac3ac](https://github.com/juliansteenbakker/mobile_scanner/commit/1eac3acb041bcdad2eda5d457b396f4d79617850))
* barcode corners for web overlay ([0147320](https://github.com/juliansteenbakker/mobile_scanner/commit/0147320797f6131a55c0ec482836e3312df2c1f7))
* black screen after multiple initialization ([18c05e6](https://github.com/juliansteenbakker/mobile_scanner/commit/18c05e67f70c84e68718b18f6e139caf6df28dbd))
* build for macos ([068c73b](https://github.com/juliansteenbakker/mobile_scanner/commit/068c73bde325ad03aa65a2eba9e9f1b2e50cc8ec))
* camera orientation on macos, reinitialization of controller in example, ([5ba0009](https://github.com/juliansteenbakker/mobile_scanner/commit/5ba0009f70ace68a4ddf0a875d01e375ee135735))
* camera view placeholder for test ([da730d4](https://github.com/juliansteenbakker/mobile_scanner/commit/da730d4f6f06e3103ebb8d60396d7146ef6c3ef9))
* change dispose check to same as init check ([7861d90](https://github.com/juliansteenbakker/mobile_scanner/commit/7861d906e2a1f13abbd1a6e157cdfcb07c97c655))
* change old surface producer API usage ([f55617d](https://github.com/juliansteenbakker/mobile_scanner/commit/f55617df866d5da66ff22c5ada208c7c5f0e05ab))
* change screenshot order ([6c5c5b0](https://github.com/juliansteenbakker/mobile_scanner/commit/6c5c5b068815f6e581725004633f097b52faa098))
* check for same rotation on older code path ([cb7c361](https://github.com/juliansteenbakker/mobile_scanner/commit/cb7c36100c40bd904568601288c064adfdb33c21))
* cleanup changelog ([e74c984](https://github.com/juliansteenbakker/mobile_scanner/commit/e74c984c702236e72792dc9e78726cc32ce1e81c))
* core style ([6cd552a](https://github.com/juliansteenbakker/mobile_scanner/commit/6cd552a20c77ca9b6d789cda24290d47898dca15))
* correct texture size on orientation change ([4a60da0](https://github.com/juliansteenbakker/mobile_scanner/commit/4a60da0088e83ea359e2a3691160ccc393542641))
* dependency update ([e0f9f5a](https://github.com/juliansteenbakker/mobile_scanner/commit/e0f9f5a7dd7f056395edb340091060465297c75b))
* device orientation checked on older and newest sdk ([aafc07a](https://github.com/juliansteenbakker/mobile_scanner/commit/aafc07aa977c8f878954cd5f76d3f983828455bf))
* device orientation checked on older and newest sdk ([4b0e7a2](https://github.com/juliansteenbakker/mobile_scanner/commit/4b0e7a211a5d4c1e708b158c30d9c379fab74749))
* Device orientation handling not respecting auto-rotate settings (Android) ([2e45fc8](https://github.com/juliansteenbakker/mobile_scanner/commit/2e45fc89f19a77f34fa8f703f84e08c107c9d5ff))
* device orientation lock on android by listening to display orientation rather than device sensor orientation ([af2541a](https://github.com/juliansteenbakker/mobile_scanner/commit/af2541abf91c9a31dd033aac364f752257917592))
* doc ([4eadb43](https://github.com/juliansteenbakker/mobile_scanner/commit/4eadb43f04c71f96e8230127f4f3fff177e40771))
* don't rotate when device orientation has been locked from flutter side ([ceea083](https://github.com/juliansteenbakker/mobile_scanner/commit/ceea0830a15088f6329541fad5d2559fcab9486b))
* filter out null values ([8254a8d](https://github.com/juliansteenbakker/mobile_scanner/commit/8254a8d369d4c4634a56685b136815da7e7b1ffd))
* fix on detect not working when controller is provided ([58f2df7](https://github.com/juliansteenbakker/mobile_scanner/commit/58f2df7398512cf20d15ab7e43b778f8604dd0e8))
* format according to dart 3.7 ([74a686d](https://github.com/juliansteenbakker/mobile_scanner/commit/74a686d2c3b01610df36f2c3bfa4e2879bd64d23))
* groovy syntax ([4bd2a94](https://github.com/juliansteenbakker/mobile_scanner/commit/4bd2a9406b4a0321460807dc99af3b8e3dd68811))
* handle errors from cvcreatepixelbuffer ([3d8565f](https://github.com/juliansteenbakker/mobile_scanner/commit/3d8565fe7310678cd23ce0f7f286942572302b82))
* hot reload ([460a6d8](https://github.com/juliansteenbakker/mobile_scanner/commit/460a6d8cd7380c962cc29ca05e7d6a62ef514278))
* hot-restart by adding force parameter ([f5cfe45](https://github.com/juliansteenbakker/mobile_scanner/commit/f5cfe4553eb74cfa60d5565b1b75a386889a4c16))
* improve attached code handling for end users ([061a2fc](https://github.com/juliansteenbakker/mobile_scanner/commit/061a2fc1faa04f4f46fea1f9dcc13aa16db806ca))
* improve pixel format selection for video output on iPhone 17 ([82f8b25](https://github.com/juliansteenbakker/mobile_scanner/commit/82f8b25b346bb83fb04daac54d4d73de3d5d1f23))
* improve pixel format selection for video output on iPhone 17 ([51055a5](https://github.com/juliansteenbakker/mobile_scanner/commit/51055a52365ddcefd4b34acb6d5fca030bc7c1b8))
* improve pixel format selection for video output on iPhone 17 ([3dc0823](https://github.com/juliansteenbakker/mobile_scanner/commit/3dc08239692ae702abbc7364abbe75c5ee156259))
* increase minSdkVersion from 21 to 23 ([9667f6d](https://github.com/juliansteenbakker/mobile_scanner/commit/9667f6df70190996292d59933960a958e3b6a362))
* ios overlay orientation ([5f8636c](https://github.com/juliansteenbakker/mobile_scanner/commit/5f8636c0da9e2b6f673de3ed1b0fe94511b321af))
* **ios:** use device orientation for video orientation ([4a3008a](https://github.com/juliansteenbakker/mobile_scanner/commit/4a3008aec729c4c208c524df897e62236e7a3595))
* kotlin error during build ([4487371](https://github.com/juliansteenbakker/mobile_scanner/commit/44873713b00fc4e4a06b1f56c2500985556fc135))
* latest linter style by very_good_analysis ([54b983d](https://github.com/juliansteenbakker/mobile_scanner/commit/54b983defa18b9cba126cf6643f406c0e4e25398))
* **lint:** wrap long lines in barcode_painter.dart to comply with 80-char limit ([1bbfcd4](https://github.com/juliansteenbakker/mobile_scanner/commit/1bbfcd455626a28d2f1831297fc72cb30c4f4eba))
* macos overlay text ([1fa5863](https://github.com/juliansteenbakker/mobile_scanner/commit/1fa586344ad789426c6425dca92824656c5bbf47))
* **macos:** wrap deprecated devices(for:) in #if os(iOS) ([2c51a37](https://github.com/juliansteenbakker/mobile_scanner/commit/2c51a3709e84c126088250a05f7a04006bb083fa))
* **macos:** wrap deprecated devices(for:) in #if os(iOS) ([bd4d4a7](https://github.com/juliansteenbakker/mobile_scanner/commit/bd4d4a7f2979bea0272a7d8d82b1630380987396)), closes [#1558](https://github.com/juliansteenbakker/mobile_scanner/issues/1558)
* make async initialization and dispose calls in separate async function ([5276188](https://github.com/juliansteenbakker/mobile_scanner/commit/5276188ef8736a55bf8fd0157d57a7886147f0d0))
* merge conflict ([1cb6979](https://github.com/juliansteenbakker/mobile_scanner/commit/1cb69791a1bbcb9f9698803c007f574eb157864a))
* merge conflicts ([7b5b2bc](https://github.com/juliansteenbakker/mobile_scanner/commit/7b5b2bc9607090de150128d82fb460ca999e5876))
* merge issues ([f856972](https://github.com/juliansteenbakker/mobile_scanner/commit/f856972d018e86a716122ad31fa40541c437c779))
* merge orientation listeners into one ([9f42e26](https://github.com/juliansteenbakker/mobile_scanner/commit/9f42e26a4d5191ca40f8a11451e2323e6b786b49))
* migrate deprecated assignment to new syntax ([2339c7c](https://github.com/juliansteenbakker/mobile_scanner/commit/2339c7cbfef9f2e4afbe365c21c52d577a5879d8))
* migrate rawBytes to byte array from payloadStringValue. ([b859b99](https://github.com/juliansteenbakker/mobile_scanner/commit/b859b9948ce1870d5097ff89e0fea29096936358))
* migrate rawBytes to byte array from payloadStringValue. migrate payloadData to rawPayloadData ([efefbf6](https://github.com/juliansteenbakker/mobile_scanner/commit/efefbf683fad76e750e8d022544d29b835456867))
* migrate to new nv21 output, remove deprecated renderscript api ([715717f](https://github.com/juliansteenbakker/mobile_scanner/commit/715717f553e6835abd81bae8a6989d8270f1ac40))
* move subscription.cancel to async dispose, move removeObserver ([7f45793](https://github.com/juliansteenbakker/mobile_scanner/commit/7f457936e6232257f5c50e6abdcd6af8ad420c7d))
* move widget test to example app, where widget resides ([3e8c842](https://github.com/juliansteenbakker/mobile_scanner/commit/3e8c842f6f533377181064935f4d1ad6ca072785))
* not attached error message ([5d71d4b](https://github.com/juliansteenbakker/mobile_scanner/commit/5d71d4bf61ff8a8fc94a1df87a58afb36d0fd576))
* not attached error message ([5fc60b0](https://github.com/juliansteenbakker/mobile_scanner/commit/5fc60b09ddd39379669a07dfc0e59aa9835ce62a))
* nv21 update ([250bea4](https://github.com/juliansteenbakker/mobile_scanner/commit/250bea49fb42a36ba273047579274eb6b0629ca3))
* optional value ([3af169d](https://github.com/juliansteenbakker/mobile_scanner/commit/3af169d24583847d634b92b5a98de996e34ebdf9))
* optional value ([079726f](https://github.com/juliansteenbakker/mobile_scanner/commit/079726f451448573d00d7165b3532c6be839fb6a))
* **orientation:** refactor orientation detection and fix related issues ([61b2f8a](https://github.com/juliansteenbakker/mobile_scanner/commit/61b2f8ac3a63edef6d72bc178e2ee55063940945))
* overlay position on landscape ([a9752bc](https://github.com/juliansteenbakker/mobile_scanner/commit/a9752bc29934b1a72476b3f612dc68abd9063a5b))
* **overlay:** correct barcode overlay alignment on orientation change ([6ca108d](https://github.com/juliansteenbakker/mobile_scanner/commit/6ca108d1ba407a6f02d2e8dc85455455cefd848a))
* position of variable ([7459d69](https://github.com/juliansteenbakker/mobile_scanner/commit/7459d69dfbd87983c5b7a4596baa542430d714cd))
* prevent half-stopped camera state causing false ALREADY_STARTED_ERROR. ([ebfe58d](https://github.com/juliansteenbakker/mobile_scanner/commit/ebfe58d4d2a6eaa9740b151681ba2e4a6b919d05))
* prevent half-stopped camera state causing false ALREADY_STARTED. ([7ef6118](https://github.com/juliansteenbakker/mobile_scanner/commit/7ef61181672b755ebb90f8f2c0ef23f51e29fd49))
* reinstate dependabot, ([404cda2](https://github.com/juliansteenbakker/mobile_scanner/commit/404cda2b914cfca16d4864a0a61f6ff437d091e0))
* remove depreacted package assignment ([c9efc60](https://github.com/juliansteenbakker/mobile_scanner/commit/c9efc6073b64a3cc6e55900929501c414f8d6fb9))
* remove old code ([e0381d7](https://github.com/juliansteenbakker/mobile_scanner/commit/e0381d7a6b98edbc79c0815294262e80ac645d04))
* remove overlay on orientation change due to wrong position ([c3aa13d](https://github.com/juliansteenbakker/mobile_scanner/commit/c3aa13db07b28e7d3064625f930a54f61dc6ad74))
* remove print ([2b45cb2](https://github.com/juliansteenbakker/mobile_scanner/commit/2b45cb2b79212e48503b9b2f3f4e72d44de5a2b9))
* remove redundant initializer ([1a8ed1c](https://github.com/juliansteenbakker/mobile_scanner/commit/1a8ed1c00e593f301363b9f7b6bc10164421814c))
* remove redundant null checks, upgrade macos files for latest flutter ([0c5283d](https://github.com/juliansteenbakker/mobile_scanner/commit/0c5283d3d634362dbacddb632c2a3f3a3792b6f8))
* remove team ([1c3a21e](https://github.com/juliansteenbakker/mobile_scanner/commit/1c3a21e90e07666a7e9f9c95262b65eccb8cdc13))
* remove unnecessary stream pause on inactive, only use observer when no controller is passed ([594b583](https://github.com/juliansteenbakker/mobile_scanner/commit/594b58379feaedde96bc845139427a3b7969581c))
* replace deprecated Radio API with RadioGroup ([0bd6d6f](https://github.com/juliansteenbakker/mobile_scanner/commit/0bd6d6f4de0ce59c314962870d33b69469bb77da))
* replace deprecated Radio API with RadioGroup ([4809505](https://github.com/juliansteenbakker/mobile_scanner/commit/480950517c1574bbeb9566bbc2994b32a5464c21))
* replaced dead analysisBuilder with correct target rotation ([e20e475](https://github.com/juliansteenbakker/mobile_scanner/commit/e20e4751660b988c12af780f2326e260ed6d7165))
* replaced dead analysisBuilder with correct target rotation ([9311b85](https://github.com/juliansteenbakker/mobile_scanner/commit/9311b853995d75da8e0891a6ec6e3257385a5618))
* revert kotlin library for compatibility ([a158e95](https://github.com/juliansteenbakker/mobile_scanner/commit/a158e95459493dc388e35de902c09eea1bf27779))
* revert safe return ([e44b335](https://github.com/juliansteenbakker/mobile_scanner/commit/e44b335388a000c3a3d0a7e6dc96da93ac304f7c))
* revert the required initial zoom ([e1ad348](https://github.com/juliansteenbakker/mobile_scanner/commit/e1ad348a4d1324d475c11804bf1e4cb19126a5fb))
* rotation when no restriction is set ([a6c7af1](https://github.com/juliansteenbakker/mobile_scanner/commit/a6c7af16deb168b88ae4a03726ab6470a7e58253))
* rotation while locked for android ([06c0dbf](https://github.com/juliansteenbakker/mobile_scanner/commit/06c0dbf74be65b36c35c30449db43e636fd58d26))
* rotation while locked for apple ([3b62d9f](https://github.com/juliansteenbakker/mobile_scanner/commit/3b62d9f135ee477a91aede910d35032ddd6fa195))
* set _isAttached to false on dispose ([0a1007c](https://github.com/juliansteenbakker/mobile_scanner/commit/0a1007c32bc08b63021967b94732ab6f0a300d41))
* set best camera quality on darwin ([56f3a2b](https://github.com/juliansteenbakker/mobile_scanner/commit/56f3a2b965221a9fa97fd60be97390c365a9a9ff))
* set to null at stop ([7991bbe](https://github.com/juliansteenbakker/mobile_scanner/commit/7991bbe660ed646bc098a2dca97b62bf5194a81f))
* skip deprecated enum ([2f3d8ca](https://github.com/juliansteenbakker/mobile_scanner/commit/2f3d8ca8e3f743e41b31681bed0a9782f16cdce5))
* specify platforms ([0169e0e](https://github.com/juliansteenbakker/mobile_scanner/commit/0169e0e5986bdd1ed9ba5ebc269ec2ecf2ff5501))
* state never initialized when controller is already running ([854a15d](https://github.com/juliansteenbakker/mobile_scanner/commit/854a15d72eb1befa94160c85f947e44b761b3393))
* test correctness ([ae6af50](https://github.com/juliansteenbakker/mobile_scanner/commit/ae6af508ce1775a1eb348277e24e41b756b9e3e1))
* text overlay being upside down ([66339ed](https://github.com/juliansteenbakker/mobile_scanner/commit/66339edc06a4a04787d807416e439e5aea501ac4))
* update corner processing of BarcodeCorners for web ([df49a05](https://github.com/juliansteenbakker/mobile_scanner/commit/df49a05943c8b9e63cd4669edb755dc2f9580436))
* update gradle JVM args ([b3d33e3](https://github.com/juliansteenbakker/mobile_scanner/commit/b3d33e3bb0784b1bbf676c0cbd08a950612376de))

## 7.3.1

**Bug Fixes**

* Bumped the minimum required version of the `web` package to `1.0.0`.

## 7.3.0

**New features**

* [Web] Added support for multiple barcode detection backends, selectable via `MobileScannerPlatform.instance.setWebBarcodeReader(WebBarcodeReader reader)`:
  * `WebBarcodeReader.auto` (default), uses the native `BarcodeDetector` API when available, and falls back to `zxing-wasm` otherwise.
  * `WebBarcodeReader.barcodeDetector`, uses the W3C Shape Detection API (Chrome 83+, Edge 83+, Safari 17+). No external library is loaded.
  * `WebBarcodeReader.zxingWasm`, uses zxing-wasm (ZXing C++ compiled to WebAssembly), which works in all modern browsers including Firefox.
  * `WebBarcodeReader.zxingJs`, the legacy ZXing JavaScript backend, retained for backward compatibility.
* [Web] Added `MobileScannerPlatform.instance.activeWebReader` to query which backend is currently active.
* Added `BarcodeFormat.maxiCode` and `BarcodeFormat.microQrCode`, supported by the `WebBarcodeReader.zxingJs` and `WebBarcodeReader.zxingWasm` backends.
* Added `BarcodeFormat.dataBar`, `BarcodeFormat.dataBarExpanded` and `BarcodeFormat.dataBarLimited` (GS1 DataBar / RSS-14), supported by the `WebBarcodeReader.zxingJs` and `WebBarcodeReader.zxingWasm` backends (DataBar and DataBar Expanded only for `zxingJs`), and by Apple Vision on iOS 15+ / macOS 12+.

**Improvements**

* [Web] Bumped `@zxing/library` (the `WebBarcodeReader.zxingJs` backend) from 0.21.3 to 0.23.0.

**Bug Fixes**

* Fixed disposing a `MobileScannerController` also disposing the platform resources of a different controller. Disposing a controller that does not hold the active camera session no longer tears down the camera of the controller that does. ([#1631](https://github.com/juliansteenbakker/mobile_scanner/issues/1631))
* Fixed a subscription leak where a controller that was disposed without being stopped kept its internal event stream subscriptions alive.
* Fixed an issue when running the plugin using AGP 9.

## 7.2.1

**Improvements**

* [Web] The preferred camera device ID is now persisted in localStorage and reused on the next start.
* [Web] Focus, exposure, and white-balance constraints are now applied automatically when supported by the browser (Image Capture API).
* [Web] The camera now uses `StartOptions.cameraResolution` as the ideal resolution, falling back to 1920×1080.
* [Web] The barcode overlay is now mirrored when the video preview is mirrored (e.g. front camera).
* [Web] The scan window is now supported. Barcodes detected outside the scan window are ignored.
* [Android] Laid groundwork for Android Gradle Plugin (AGP) 9 compatibility by conditionally applying the `kotlin-android` plugin only on AGP versions below 9, while remaining compatible with older AGP versions.

**Bug Fixes**

* [Apple] Fixed a race condition in `captureOutput` where `latestBuffer` was read on a background thread after being deallocated on the main thread, causing a crash in `VTCreateCGImageFromCVPixelBuffer`.
* [Apple] Fixed an issue where `captureOutput` was being processed on the main thread, causing overheating issues on device.
* [Android] Fixed `start()` not resuming the camera after `pause()`, caused by the `isPaused` flag being reset before the paused-state check.
* [Android] Fixed ProGuard/R8 full mode (default since AGP 8.0) stripping or obfuscating MLKit classes by widening the keep rule to `com.google.mlkit.**`.

## 7.2.0

**Highlights**

* Added support for switching between lens types (normal, wide, zoom) using the `switchCamera()` method with `ToggleLensType` or `SelectCamera` options.
* Added `rawDecodedBytes` field to `Barcode` which replaces `Barcode.rawBytes`. On Apple platforms, this returns a `DecodedVisionBarcodeBytes` containing `bytes` (decoded payload, without header/padding) and `rawBytes` (full raw payload, available on iOS 17.0+ / macOS 14.0+). On Android and web, this returns a `DecodedBarcodeBytes` containing `bytes`.

**Improvements**

* [Android] Migrated barcode bounding box from `boundingBox` to `cornerPoints` for more accurate scan window detection.
* Added support for `ITF-Two-of-Five`.
* Added constants for testing the method channel methods in `MobileScannerMethods` and `MobileScannerEvents`.
* The global method `calculateBoxFitRatio()` is now deprecated.

**Bug Fixes**

* [Android] Fixed incorrect texture size on orientation change.
* [Android] Fixed a bug where the `isPaused` flag was not reset when `start()` was called.
* [Android] Fixed `imageAnalysis` not being unbound on dispose.
* [Android] Fixed an issue where the app orientation handling was not respecting auto-rotate settings
* [Apple] Fixed `rawBytes` returning incorrect data for barcodes containing non-ASCII characters (e.g. `ø`). For QR codes, bytes are now extracted directly from the error-corrected bit stream via `CIQRCodeDescriptor`, bypassing the Vision string API entirely. For Aztec, DataMatrix, PDF417 and linear formats, the ISO-Latin-1 round-trip is used to recover the original bytes from `payloadStringValue`.
* [Apple] Fixed `displayValue` returning a garbled Latin-1 string (e.g. `hellÃ¸`) for barcodes with non-ASCII UTF-8 content. It is now correctly decoded to UTF-8 (e.g. `hellø`).
* [Apple] Fixed a bug where the barcode type results did not have a value.
* [Apple] Fixed camera rotating, even when rotation is locked.
* [macOS] Fixed barcode overlay text displaying upside down.
* Fixed barcode overlay rendering at wrong position after orientation change.
* Fixed a bug where taps were ignored on the scanner widget.
* Fixed a bug where a controller that was only disposed would throw an incorrect error code.

### 7.1.4

* [Apple] Fixed crash on iPhone 17 when starting MobileScanner by checking available pixel formats before setting video output settings. ([#1578](https://github.com/juliansteenbakker/mobile_scanner/issues/1578))

### 7.1.3

* Overlay: Updated `BarcodePainter` to receive `deviceOrientation` and dynamically adjust `cameraPreviewSize`, fixing barcode overlay misalignment during device rotation changes [](https://github.com/juliansteenbakker/mobile_scanner/issues/1462).

* [Android] Refactored orientation detection to use `OrientationEventListener` instead of `BroadcastReceiver` for `ACTION_CONFIGURATION_CHANGED`, ensuring physical device orientation is captured correctly and preventing unwanted screen rotations on `MobileScanner` initialization [](https://github.com/juliansteenbakker/mobile_scanner/issues/1486).
* [Android] Changed minSDK from 21 to 23 in line with Flutter requirements.
* [Android] Removed deprecated renderscript api's, improved performance for analysis.
* [Apple] Prevent half-stopped camera state causing false ALREADY_STARTED.
* [Apple] Fixed a bug where invalid images would cause crashes when processing them with CoreVideo.

## 7.1.2

* Fixed an issue with the `initialZoom` parameter.

## 7.1.1

* Fixed missing import of 'package:meta/meta.dart' on older Flutter sdk's

## 7.1.0

**Highlights**

* [Apple & Android] Added tap to focus functionality. You can enable it in the `MobileScanner` widget.
* [Apple & Android] You can now set the initial zoom factor using the `initialZoom` parameter in the `startOptions`.

**Bug Fixes and Improvements**

* [iOS] Increased minimum os level to 13 due to Flutter requirements.
* [macOS] Increased minimum os level to 10.15 due to Flutter requirements.
* [Android] Update to Java 17, and update other dependencies.
* [Apple] Improved fallback for when camera is not found.
* Added a `Barcode.scaleCorners()` method.

## 7.0.1

* Added error handling for when `MobileScannerController.start` is called without an active `MobileScanner` widget.

## 7.0.0

This version finalizes all changes from the beta and release candidate cycles and introduces major improvements, bug fixes, and breaking changes.

**BREAKING CHANGES**

* Requires Flutter 3.29.0 or higher.
* The initial camera facing direction in `MobileScannerState` is now `CameraFacing.unknown`.
* Removed the deprecated `EncryptionType.none`. Use `EncryptionType.unknown` instead.
* The `errorBuilder` and `placeholderBuilder` no longer have a Widget argument.
* Removed the `MobileScannerErrorBuilder` typedef.

**Highlights**

* [iOS/macOS] Migrated to the Vision API with a unified Apple codebase.
* [iOS] Minimum iOS version changed from 15 to 12.
* [Android] Removed dependency on `kotlin-bom` and updated CameraX and camera-camera2 dependencies.
* Support for pause/resume functionality across platforms.
* `MobileScannerErrorCode` now includes readable error messages in debug mode.
* Hot-restart during development now works correctly.
* Added overlay widgets for barcode and scan window visualization.
* Exposed new API parameters like `autoZoom`, `invertImage`, and lifecycle handling.

**Bug Fixes and Improvements**

* [Apple]
  * Fixed rotation, orientation, and zoom behavior.
  * Resolved incorrect barcode overlay dimensions and corner coordinates.
  * Fixed a crash when stopping the camera with a nil device.
  * Fixed build issues including optional chaining on non-optional values.
* [Android]
  * Fixed rotation and orientation issues.
  * Resolved timing issues in `SurfaceProducer` with Kotlin 1.8+.
  * Fixed resource leaks and improved image analysis compatibility.
  * Improved logging behavior (CameraX logs only errors).
* [macOS]
  * Fixed mirrored images and build issues.
* [Web]
  * Fixed barcode overlay not displaying due to incorrect corner point data.

## 7.0.0-rc.2

Bugs fixed:
* [Apple] Fixed build issues "Cannot use optional chaining on non-optional value".

## 7.0.0-rc.1

After six months of development, Version 7.0.0 is finally moving out of beta with this release candidate!
A stable release is scheduled for next week.

Improvements:
* [Android] Remove the dependency on `org.jetbrains.kotlin:kotlin-bom`.
* [Android] Updated camerax dependencies.
* Hot-restart for development purposes is now working correctly
* Added message to `MobileScannerErrorCode`, which will be shown if kDebugMode is true. Otherwise, a generic error message will appear.
* Fixed issues regarding initialization of the `MobileScannerController`, which could result in a black screen without error message.

Bugs fixed:
* [Android] Fixed rotation & orientation issues.
* [Apple] Fixed rotation & orientation issues.
* [Apple] Fixed a crash when stopping the camera when the camera device is nil.
* [macOS] Fixed image not being mirrored.
* [Web] Fixed barcode corners not being passed correctly resulting in no overlay being drawn.

## 7.0.0-beta.9

**BREAKING CHANGES:**

* This release requires Flutter 3.29.0 or higher.

Bugs fixed:
* [Android] Fixed a timing issue for the SurfaceProducer implementation, by switching to the `onSurfaceCleanup` callback. 

## 7.0.0-beta.8

Improvements:
* Updated examples in example app.
* Added [useAppLifecycleState] parameter to enable or disable handling of lifecycle state when no controller is passed.
* Dispose function of [MobileScanner] is now async.
* The [BarcodeOverlay] now correctly disposes the text painter.

Bugs fixed:
* [Apple] Fixed barcode corners representation for barcode overlay.
* [Apple] Fixed zoom callback not working.
* [Apple] Updated zoom scale factor to match Android implementation.
* Fixed build issues on older kotlin versions.

## 7.0.0-beta.7

**BREAKING CHANGES:**

* The initial state of the `MobileScannerState` camera facing direction is changed to `CameraFacing.unknown`.

Improvements:
* [Android] Turn off logging for CameraX, except for the `Log.ERROR` logging level.
* Added `CameraFacing.external` and `CameraFacing.unknown` enum values.

Bugs fixed:
* [Android] Fixed an issue when compiling with Kotlin 1.8.0 or higher.

## 7.0.0-beta.6

**BREAKING CHANGES:**

* This release requires Flutter 3.27.0 or higher.

Improvements:
* [Android] Added support for Impeller.
* [Apple] Added support for `rawBytes` from the Vision API observations.
* Export the `MobileScannerViewAttributes` and `StartOptions` types, to allow them in tests.

Bugs fixed:
* [Apple] Fixed a bug that caused a crash when the capture session could not add the video input.

## 7.0.0-beta.5

Improvements:
* [Android] Added `autoZoom` parameter to auto zoom if the detected code is to far from the camera.
* [Android] Added `invertImage` parameter to invert image colors for analyzer to support white-on-black barcodes, which are not supported by MLKit.
* [Android] Updated camera-camera2 dependencies.
* Added pause functionality to all platforms.

Bugs fixed:
* [Android] Fixed resources not being closed.

## 7.0.0-beta.4

**BREAKING CHANGES:**

* The `updateScanWindow` method is now private. Instead, update the scan window in the `MobileScanner` widget directly.
* The deprecated `EncryptionType.none` constant has been removed. Use `EncryptionType.unknown` instead.
* The `errorBuilder` and `placeholderBuilder` of the `MobileScanner` widget no longer take a Widget argument, as it was unused.
* The `MobileScannerErrorBuilder` typedef has been removed.

Bugs fixed:
* [Apple] Fixed an issue which caused the scanWindow to always be present, even when reset to no value.
* [Apple] Fixed an issue that caused the barcode size to report the wrong height.
* [Apple] Fixed a bug that caused the corner points to not be returned in clockwise orientation.
* [Apple] Fixed an issue where `analyzeImage` would not throw an error if no valid image is provided as argument.
* [Apple] Fixed an issue where `analyzeImage` would not return if no barcodes are found in the image.
* [Apple] Fixed an issue where the iOS Simulator did not report that analyzing images from a file is unsupported. 
* [Android] Fixed an issue where `analyzeImage` would not return if no valid image is provided as argument.

Improvements:
* Added a basic barcode overlay widget, for use with the camera preview.
* Added a basic scan window overlay widget, for use with the camera preview.
* Update the bundled MLKit model for Android to version `17.3.0`.
* Added documentation in places where it was missing.
* Added `color` and `style` properties to the `BarcodePainter` widget.
* Enabled Swift Package Manager for the example app.

## 7.0.0-beta.3

* Fixed a build issue on macOS.

## 7.0.0-beta.2

Bugs fixed:
* [Apple] Fixed an issue with the zoom slider being non-functional.
* [Apple] Fixed an issue where the flash would briefly show when the camera is turned on.
* [Apple] Fixed an issue that prevented the scan window from working.
* [Apple] Fixed an issue that caused the barcode overlay to use the wrong dimensions.

Improvements:
* [iOS] Adds support for Swift Package Manager.

Known issues:
* BoxFit.cover & BoxFit.fitHeight produce the wrong width in the barcode overlay.

## 7.0.0-beta.1

Improvements:
* [iOS] Migrate to the Vision API.
* [iOS] Updated the minimum iOS version back down to 12.0.
* [Apple] Merged the iOS and MacOS sources.

Known issues:
* [Apple] The zoom slider does not work correctly.
* [Apple] The scan window does not work correctly.
* [Apple] The camera flash briefly shows when the camera is started.

## 6.0.11
* [Android] Update camerax dependencies to support 16KB pages sizes.

## 6.0.10
* [Apple] Fixed a crash when stopping the camera when the camera device is nil.

## 6.0.9
Fixed onDetect not working when a `MobileScannerController` is provided.

## 6.0.8
Improvements:
* [Android] Remove the dependency on `org.jetbrains.kotlin:kotlin-bom`.
* Hot-restart for development purposes is now working correctly
* Added message to `MobileScannerErrorCode`, which will be shown if kDebugMode is true. Otherwise, a generic error message will appear.
* Fixed issues regarding initialization of the `MobileScannerController`, which could result in a black screen without error message.

## 6.0.7
Improvements:
* [Android] Updated bundled barcode scanning library to v17.3.0

## 6.0.6
Bugs fixed:
* [web] Fixed a bug that prevented color inverted barcodes from being scanned.

Improvements:
* [web] Bump ZXingJS from version 0.19.1 to 0.21.3.

## 6.0.5
Bugs fixed:
* [Android] Fixed crash due to imageProxy being closed too early.

## 6.0.4
Bugs fixed:
* [Android] Fixed UI stutter when `returnImage` is true.

## 6.0.3
New features:
* Adds pause function to pause the camera but keep textures in place.

## 6.0.2
Bugs fixed:
* Fixed a bug that prevented `analyzeImage` from actually accepting the configured formats.

Improvements:
* [iOS] Excluded the `arm64` architecture for Simulators, which is unsupported by MLKit 7.0.0.

## 6.0.1
Bugs fixed:
* Fixed a bug that would cause onDetect to not handle errors.

Improvements:
* [iOS] Excluded the `armv7` architecture, which is unsupported by MLKit 7.0.0.
* Added a new `onDetectError` error handler to the `MobileScanner` widget, for use with `onDetect`.

## 6.0.0

**BREAKING CHANGES:**

* [iOS] iOS 15.5.0 is now the minimum supported iOS version.
* [iOS] Updates MLKit to version 7.0.0.
* [iOS] Updates the minimum supported XCode version to 15.3.0.

Improvements:
* [MacOS] Added the corners and size information to barcode results.
* [MacOS] Added support for `analyzeImage`.
* [MacOS] Added a Privacy Manifest.
* [web] Added the size information to barcode results.
* [web] Added the video output size information to barcode capture.
* Added support for barcode formats to image analysis.
* Updated the scanner to report any scanning errors that were encountered during processing.
* Introduced a new getter `hasCameraPermission` for the `MobileScannerState`.
* Fixed a bug in the lifecycle handling sample. Now instead of checking `isInitialized`,
the sample recommends using `hasCameraPermission`, which also guards against camera permission errors.
* Updated the behavior of `returnImage` to only determine if the camera output bytes should be sent.
* Updated the behavior of `BarcodeCapture.size` to always be provided when available, regardless of `returnImage`.

Bugs fixed:
* Fixed a bug that would cause the scanner to emit an error when it was already started. Now it ignores any calls to start while it is starting.
* [MacOS] Fixed a bug that prevented the `anaylzeImage()` sample from working properly.

## 5.2.3

Deprecations:
* The `EncryptionType.none` constant has been deprecated, as its name was misleading. Use `EncryptionType.unknown` instead.

Bugs fixed:
* Fixed `EncryptionType` throwing on invalid `SAE` encryption type.
* [web] Removed the `controls` attribute on the video preview.

Improvements:
* All enum types for barcode data (i.e. Wifi type or email type) now return `unknown` for unrecognized values.

## 5.2.2

Improvements:
* [MacOS] Adds Swift Package Manager support.
* [MacOS] Adds support for `returnImage`.
* Added a new `size` property to `Barcode`, that denotes the bounding box of the barcode.

Bugs fixed:
* Fixed some documentation errors for the `size` and `image` of `BarcodeCapture`.
* [iOS] Fixed a bug with `returnImage`.
* [Android/iOS] Adjusted the raw barcode scan value to pass the raw event data, like on MacOS.

## 5.2.1

* Updates the `package:web` dependency to use a version range.

## 5.2.0

This release requires Flutter 3.22.0 and Dart 3.4.

* [Android] Fixed a leak of the barcode scanner.
* [Android] Fixed a crash when encountering invalid numbers for the scan window.
* [Web] Migrates `package:web` to 1.0.0.

## 5.1.1
* This release fixes an issue with automatic starts in the examples.

## 5.1.0
This updates reverts a few breaking changes made in v5.0.0 in order to keep things simple.

* The `onDetect` method has been reinstated in the `MobileScanner` widget, but is nullable. You can
still listen to `MobileScannerController.barcodes` directly by passing null to this parameter.
* The `autoStart` attribute has been reinstated in the `MobileScannerController` and defaults to true. However, if you want
to control which camera is used on start, or you want to manage the lifecycle yourself, you should set
autoStart to false and manually call `MobileScannerController.start({CameraFacing? cameraDirection})`.
* The `controller` is no longer required in the `MobileScanner` widget. However if provided, the user should take care 
of disposing it.
* [Android] Revert Gradle 8 back to Gradle 7, to be inline with most Flutter plugins and prevent build issues.
* [Android] Revert Kotlin back from 1.9 to 1.7 to be inline with most Flutter plugins. Special 1.9 functionality
has been refactored to be compatible with 1.7.


## 5.0.2
Bugs fixed:
* Fixed a crash when the controller is disposed while it is still starting. [#1036](https://github.com/juliansteenbakker/mobile_scanner/pull/1036) (thanks @EArminjon !)
* Fixed an issue that causes the initial torch state to be out of sync.

Improvements:
* Updated the lifeycle code sample to handle not-initialized controllers.

## 5.0.1
Improvements:
* Adjusted the platform checks to use the defaultTargetPlatform API, so that tests can use the correct platform overrides.

## 5.0.0
This major release contains all the changes from the 5.0.0 beta releases, along with the following changes:

Improvements:
* [Android] Remove the Kotlin Standard Library from the dependencies, as it is automatically included in Kotlin 1.4+

## 5.0.0-beta.3
**BREAKING CHANGES:**

* Flutter 3.19.0 is now required.
* [iOS] iOS 12.0 is now the minimum supported iOS version.
* [iOS] Adds a Privacy Manifest.

Bugs fixed:
* Fixed an issue where the camera preview and barcode scanner did not work the second time on web.

Improvements:
* [web] Migrates to extension types. (thanks @koji-1009 !)

## 5.0.0-beta.2
Bugs fixed:
* Fixed an issue where the scan window was not updated when its size was changed. (thanks @navaronbracke !)

## 5.0.0-beta.1
**BREAKING CHANGES:**

* The `width` and `height` of `BarcodeCapture` have been removed, in favor of `size`.
* The `raw` attribute is now `Object?` instead of `dynamic`, so that it participates in type promotion.
* The `MobileScannerArguments` class has been removed from the public API, as it is an internal type.
* The `cameraFacingOverride` named argument for the `start()` method has been renamed to `cameraDirection`.
* The `analyzeImage` function now correctly returns a `BarcodeCapture?` instead of a boolean.
* The `formats` attribute of the `MobileScannerController` is now non-null.
* The `MobileScannerState` enum has been renamed to `MobileScannerAuthorizationState`.
* The various `ValueNotifier`s for the camera state have been removed. Use the `value` of the `MobileScannerController` instead.
* The `hasTorch` getter has been removed. Instead, use the torch state of the controller's value.
  The `TorchState` enum now provides a new value for unavailable flashlights.
* The `autoStart` attribute has been removed from the `MobileScannerController`. The controller should be manually started on-demand.  
* A controller is now required for the `MobileScanner` widget.
* The  `onPermissionSet`, `onStart` and `onScannerStarted` methods have been removed from the `MobileScanner` widget. Instead, await `MobileScannerController.start()`.
* The `startDelay` has been removed from the `MobileScanner` widget. Instead, use a delay between manual starts of one or more controllers.
* The `onDetect` method has been removed from the `MobileScanner` widget. Instead, listen to `MobileScannerController.barcodes` directly.
* The `overlay` widget of the `MobileScanner` has been replaced by a new property, `overlayBuilder`, which provides the constraints for the overlay.
* The torch can no longer be toggled on the web, as this is only available for image tracks and not video tracks. As a result the torch state for the web will always be `TorchState.unavailable`.
* The zoom scale can no longer be modified on the web, as this is only available for image tracks and not video tracks. As a result, the zoom scale will always be `1.0`.

Improvements:
* The `MobileScannerController` is now a ChangeNotifier, with `MobileScannerState` as its model.
* The web implementation now supports alternate URLs for loading the barcode library.

## 4.0.1
Bugs fixed:
* [iOS] Fixed a crash with a nil capture session when starting the camera. (thanks @navaronbracke !)

## 4.0.0
**BREAKING CHANGES:**

* [Android] compileSdk has been upgraded to version 34.
* [Android] Java version has been upgraded to version 17.

## 3.5.7
Improvements:
* Updated js dependency together with other dependencies.
* Reverted compileSdk version to 33 on Android. This update will be released under version 4.0.0.

## 3.5.6
Bugs fixed:
* [web] Fixed a crash with the ZXing barcode format (thanks @hazzo!)
* [web] Fixed stream controller not being closed on web.
* [iOS] Fixed a crash with unsupported torch modes. (thanks @navaronbracke !)
* [iOS] Fixed a crash with the camera discovery session. (thanks @navaronbracke !)

Improvements:
* Upgrade camera dependencies on Android.
* Upgrade compileSdk version to 34 on Android.
* Add numberOfCameras parameter in MobileScannerArguments callback, which shows how many cameras there are available on Android. 
* [Android] Migrated to ResolutionSelector with ResolutionStrategy. You can opt in into the new selector by setting [useNewCameraSelector] in the [MobileScannerController] to true.

## 3.5.5
Bugs fixed:
* Fixed a bug where the scanner would get stuck after denying permissions on Android. (thanks @navaronbracke !)

## 3.5.4
Bugs fixed:
* Fixed a bug with an implicit conversion to integer for the scan timeout for iOS. (thanks @EArminjon !)

## 3.5.2
Improvements:
* Updated to `play-services-mlkit-barcode-scanning` version 18.3.0

Bugs fixed:
* Fixed the `updateScanWindow()` function not completing on Android and MacOS. (thanks @navaronbracke !)
* Fixed some camera access issues, when the camera could have been null on Android. (thanks @navaronbracke !)
* Fixed a crash on Android when there is no camera. (thanks @navaronbracke !)
* Fixed a bug with the `noDuplicates` detection speed. (thanks @pgeof !)
* Fixed a synchronization issue for the torch state. (thanks @navaronbracke !)

## 3.5.1
Improvements:
* The `type` of an `Address` is now non-null.
* The `type` of an `Email` is now non-null.
* The `phoneNumber` of an `SMS` is now non-null.
* The `latitude` and `longitude` of a `GeoPoint` are now non-null.
* The `phones` and `urls` of `ContactInfo` are now non-null.
* The `url` of a `UrlBookmark` is now non-null.
* The `type` of `Phone` is now non-null.
* The `width` and `height` of `BarcodeCapture` are now non-null.
* The `BarcodeCapture` class now exposes a `size`.
* The list of `corners` of a `Barcode` is now non-null.

Bugs fixed:
* Fixed the default values for the `format` and `type` arguments of the Barcode constructor.
  These now use `BarcodeFormat.unknown` and `BarcodeType.unknown`, rather than `BarcodeFormat.ean13` and `BarcodeType.text`.
  (thanks @navaronbracke !)
* Fixed messages not being sent on the main thread for Android, iOS and MacOS. (thanks @navaronbracke !)

## 3.5.0

**NOTE: From this version onwards, `mobile_scanner` requires Android projects to have a `compileSdk` of 34 (Android 14) or higher**

New Features:
* Added the option to switch between bundled and unbundled MLKit for Android. (thanks @woolfred !)
* Added the option to specify the camera resolution for Android. (thanks @EArminjon !)
* Added a sample with a scanner overlay. (thanks @Spyy004 !)

Bugs fixed:
* Fixed the scan window calculation taking into account the widget coordinates, instead of the screen coordinates. (thanks @jlin5 !)
* Fixed the scan window calculation returning wrong results. (thanks @MBulli !)
* Fixed the BarcodeCapture format on MacOS. (thanks @ryanduffyne !)
* Fixed the timeout for scanning on MacOS. (thanks @ryanduffyne !)
* Fixed Android builds failing by downgrading from Kotlin 1.9.10 to 1.7.22. (thanks @vbuberen !)
* Fixed images on iOS being rotated, resulting in bad detection rates. (thanks @EArminjon !)
* Fixed scan timeout not working on iOS. (thanks @navaronbracke !)
* Fixed a crash on iOS when the device is nil. (thanks @navaronbracke !)
* Fixed a case of an unhandled exception when starting the scanner. (thanks @navaronbracke !)

Improvements:
* Improved MacOS memory footprint by using a background queue. (thanks @ryanduffyne !)

## 3.4.1
* Changed MediaQuery.sizeOf(context) to of(context).size for compatibility with older Flutter versions.

## 3.4.0
New Features:
* This PR adds an option to add an overlay to the scanner which is only visible when the scanner has started. (thanks @svenopdehipt !)

Improvements:
* fix a bug in the static interop binding of PhotoCapabilities (thanks @navaronbracke !)
* [Web] add the corners from the ZXing result to the barcode on web (thanks @navaronbracke !)
* update the example app web entrypoint to the latest template by running flutter create . --platforms=web (thanks @navaronbracke !)
* add better handling for the case where scanning barcodes is unsupported (for example a desktop running the browser sample) (thanks @navaronbracke !)
* [Web] fix the permission denied handling on the web, by using the NotAllowedError error message as defined by MDN (thanks @navaronbracke !)
* add app bars with back buttons to the example app (so that you can go back easily) (thanks @navaronbracke !)

* [iOS] Implements a fix from issue iOS After first QR Code Scan, When Scanning again, First Image stays on Camera buffer (thanks @FlockiiX !)

* By dynamically adjusting the positioning and scaling of the scan window relative to the texture, the package ensures optimal coverage and alignment for scanning targets. (thanks @sdkysfzai !)
* In the original package, If there are multiple barcode/qrcodes in the screen, the scan would randomly pick up any barcode/qrcode that shows in the screen, This upgrade fixes it and picks on the qrcode/barcode that is in the center of the camera. (thanks @sdkysfzai !)
* In the original package if you changed the camera size, it would still pick scans even if the barcode are not shown in the screen, This issue is also fixed in the upgraded packaged. (thanks @sdkysfzai !)

* [iOS] This removes a threading warning (and potentially jank). (thanks @ened !)
* [Android] fix(ScanImage): fix android image result is not correct format and orientation (thanks @phanbaohuy96 !)

* [iOS] Respect detectionTimeout on iOS devices, instead of arbitrarily waiting 10 frames (thanks @jorgenpt !)
* [iOS] Don't start a second scan until the first one is done, to keep memory usage more fixed if the device is slow (thanks @jorgenpt !)
* [Android] This PR ensure that the camera is not stopped in the callback. (thanks @g123k !)
* [macOS] Fix some macOS build errors (thanks @svenopdehipt !)

* [Android] Fixed an issue which caused the App Lifecycle States to not work correctly on Android. (thanks @androi7 !)

## 3.3.0
Bugs fixed:
* Fixed bug where onDetect method was being called multiple times
* [Android] Fix Gradle 8 compatibility by adding the `namespace` attribute to the build.gradle.

Improvements:
* [Android] Upgraded camera2 dependency
* Added zoomScale value notifier in MobileScannerController for the application to know the zoom scale value set actually.
  The value is notified from the native SDK(CameraX/AVFoundation).
* Added resetZoomScale() in MobileScannerController to reset zoom ratio with 1x.
  Both Android and iOS, if the device have ultra-wide camera, calling setZoomScale with small value causes to use ultra-wide camera and may be diffcult to detect barcodes.
  resetZoomScale() is useful to use standard camera with zoom 1x.
  setZoomScale() with the specific value can realize same effect, but added resetZoomScale for avoiding floating point errors.
  The application can know what zoom scale value is selected actually by subscribing zoomScale above after calling resetZoomScale.
* [iOS] Call resetZoomScale while starting scan.
  Android camera is initialized with a zoom of 1x, whereas iOS is initialized with the minimum zoom value, which causes to select the ultra-wide camera unintentionally ([iOS] Impossible to focus and scan the QR code due to picking the wide back camera #554).
  Fixed this issue by calling resetZoomScale
* [iOS] Remove zoom animation with ramp function to match Android behavior.

## 3.2.0
Improvements:
* [iOS] Updated GoogleMLKit/BarcodeScanning to 4.0.0 
* [Android] Updated com.google.mlkit:barcode-scanning from 17.0.3 to 17.1.0

Bugs fixed:
* Fixed onDetect not working with analyzeImage when autoStart is false in MobileScannerController
* [iOS] Explicit returned type for compactMap

## 3.1.1
Bugs fixed:
* [iOS] Fixed a bug that caused a crash when switching from camera.

## 3.1.0
Improvements:
* [iOS] No longer automatically focus on faces.
* [iOS] Fixed build error.
* [Web] Waiting for js libs to load.
* Do not returnImage if not specified.
* Added raw data in barcode object.
* Fixed several bugs.

## 3.0.0
This big release contains all improvements from the beta releases.
In addition to that, this release contains:

Improvements:
* Fixed an issue in which the scanner would freeze if two scanner widgets where placed in a page view,
and the paged was swiped. An example has been added in the example app.
You need to set startDelay: true if used in a page view.
* [Web] Automatically inject js libraries.
* [macOS] The minimum build version is now macOS 10.14 in according to the latest Flutter version.
* [Android] Fixed an issue in which the scanWindow would remain even after disposing the scanner.
* Updated dependencies.

## 3.0.0-beta.4
Fixes:
* Fixes a permission bug on Android where denying the permission would cause an infinite loop of permission requests.
* Updates the example app to handle permission errors with the new builder parameter.
  Now it no longer throws uncaught exceptions when the permission is denied.
* Updated several dependencies

Features:
* Added a new `errorBuilder` to the `MobileScanner` widget that can be used to customize the error state of the preview. (Thanks @navaronbracke !) 

## 3.0.0-beta.3
Deprecated:
* The `onStart` method has been renamed to `onScannerStarted`.
* The `onPermissionSet` argument of the `MobileScannerController` is now deprecated.

**BREAKING CHANGES:**

* `MobileScannerException` now uses an `errorCode` instead of a `message`.
* `MobileScannerException` now contains additional details from the original error.
* Refactored `MobileScannerController.start()` to throw `MobileScannerException`s
  with consistent error codes, rather than string messages.
  To handle permission errors, consider catching the result of `MobileScannerController.start()`.
* The `autoResume` attribute has been removed from the `MobileScanner` widget.
  The controller already automatically resumes, so it had no effect.
* Removed `MobileScannerCallback` and `MobileScannerArgumentsCallback` typedef.
* [Web] Replaced `jsqr` library with `zxing-js` for full barcode support.

Improvements:
* Toggling the device torch now does nothing if the device has no torch, rather than throwing an error.
* Removed `called stop while already stopped` messages.

Features:
* You can now provide a `scanWindow` to the `MobileScanner()` widget.
* You can now draw an overlay over the scanned barcode. See the barcode scanner window in the example app for more information.
* Added a new `placeholderBuilder` function to the `MobileScanner` widget to customize the preview placeholder.
* Added `autoStart` parameter to MobileScannerController(). If set to false, controller won't start automatically.
* Added `hasTorch` function on MobileScannerController(). After starting the controller, you can check if the device has a torch.
* [iOS] Support `torchEnabled` parameter from MobileScannerController() on iOS
* [Web] Added ability to use custom barcode scanning js libraries 
  by extending `WebBarcodeReaderBase` class and changing `barCodeReader` property in `MobileScannerWebPlugin`

Fixes:
* Fixes the missing gradle setup for the Android project, which prevented gradle sync from working.
* Fixes `MobileScannerController.stop()` throwing when already stopped.
* Fixes `MobileScannerController.toggleTorch()` throwing if the device has no torch.
  Now it does nothing if the torch is not available.
* Fixes a memory leak where the `MobileScanner` would keep listening to the barcode events.
* Fixes the `MobileScanner` preview depending on all attributes of `MediaQueryData`.
  Now it only depends on its layout constraints.
* Fixed a potential crash when the scanner is restarted due to the app being resumed.
* [iOS] Fix crash when changing torch state
  
## 3.0.0-beta.2

**BREAKING CHANGES:**

* The arguments parameter of onDetect is removed. The data is now returned by the onStart callback
in the MobileScanner widget.
* onDetect now returns the object BarcodeCapture, which contains a List of barcodes and, if enabled, an image.
* allowDuplicates is removed and replaced by MobileScannerSpeed enum.
* onPermissionSet in MobileScanner widget is deprecated and will be removed. Use the onPermissionSet
onPermissionSet callback in MobileScannerController instead.
* [iOS] The minimum deployment target is now 11.0 or higher.

Features:
* The returnImage is working for both iOS and Android. You can enable it in the MobileScannerController.
The image will be returned in the BarcodeCapture object provided by onDetect.
* You can now control the DetectionSpeed, as well as the timeout of the DetectionSpeed. For more
info see the DetectionSpeed documentation. This replaces the allowDuplicates function.

Other improvements:
* Both the [iOS] and [Android] codebases have been refactored completely.
* [iOS] Updated POD dependencies

## 3.0.0-beta.1

**BREAKING CHANGES:**

* [Android] SDK updated to SDK 33.

Features:
* [Web] Add binaryData for raw value.
* [iOS] Captures the last scanned barcode with Barcode.image.
* [iOS] Add support for multiple formats on iOS with BarcodeScannerOptions.
* Add displayValue which returns barcode value in a user-friendly format.
* Add autoResume option to MobileScannerController which automatically resumes the camera when the application is resumed

Other changes:
* [Android] Revert camera2 dependency to stable release
* [iOS] Update barcode scanning library to latest version
* Several minor code improvements

## 2.0.0

**BREAKING CHANGES:**

This version is only compatible with flutter 3.0.0 and later.

## 1.1.2-play-services
This version uses the MLKit play-services model on Android in order to save space.
With the example app, this version reduces the release version from 14.9MB to 7MB.
More information: https://developers.google.com/ml-kit/vision/barcode-scanning/android

## 1.1.2
This version is the last version that will run on Flutter 2.x

Bugfixes:
* Changed onDetect to be mandatory.

## 1.1.1-play-services
This version uses the MLKit play-services model on Android in order to save space.
With the example app, this version reduces the release version from 14.9MB to 7MB.
More information: https://developers.google.com/ml-kit/vision/barcode-scanning/android

## 1.1.1
Bugfixes:
* Add null checks for Android.
* Update camera dependency for Android.
* Fix return type for analyzeImage.
* Add fixes for Flutter 3.

## 1.1.0
Bugfixes:
* Fix for 'stream already listened to' exception.
* Fix building on Android with latest Flutter version.
* Add several WEB improvements.
* Upgraded several dependencies.

## 1.0.0

**BREAKING CHANGES:**

This version adds a new allowDuplicates option which now defaults to FALSE. this means that it will only call onDetect once after a scan.
If you still want duplicates, you can set allowDuplicates to true.
This also means that you don't have to check for duplicates yourself anymore.

New features:
* We now have web support! Keep in mind that only QR codes are supported right now.

Bugfixes:
* Fixed hot reload not working.
* Fixed Navigator.of(context).pop() not working in the example app due to duplicate MaterialApp declaration.
* Fixed iOS MLKit version not resolving the latest version.
* Updated all dependencies

## 0.2.0
You can provide a path to controller.analyzeImage(path) in order to scan a local photo from the gallery!
Check out the example app to see how you can use the image_picker plugin to retrieve a photo from
the gallery. Please keep in mind that this feature is only supported on Android and iOS.

Another feature that has been added is a format selector!
Just keep in mind that iOS for now only supports 1 selected barcode.

## 0.1.3
* Fixed crash after asking permission. [#29](https://github.com/juliansteenbakker/mobile_scanner/issues/29)
* Upgraded cameraX from 1.1.0-beta01 to 1.1.0-beta02

## 0.1.2
* MobileScannerArguments is now exported. [#7](https://github.com/juliansteenbakker/mobile_scanner/issues/7)

Bugfixes:
* Fixed application crashing when stop() or start() is called multiple times. [#5](https://github.com/juliansteenbakker/mobile_scanner/issues/5)
* Fixes controller not being disposed correctly. [#23](https://github.com/juliansteenbakker/mobile_scanner/issues/23)
* Catch error when no camera is found. [#19](https://github.com/juliansteenbakker/mobile_scanner/issues/19)

## 0.1.1
mobile_scanner is now compatible with sdk >= 2.12 and flutter >= 2.2.0

## 0.1.0
We now have MacOS support using Apple's Vision framework!
Keep in mind that for now, only the raw value of the barcode object is supported.

Bugfixes:
* Fixed a crash when dispose is called in a overridden method. [#5](https://github.com/juliansteenbakker/mobile_scanner/issues/5) 

## 0.0.3
* Added some API docs and README
* Updated the example app

## 0.0.2
Fixed on iOS:
* You can now set the torch
* You can select the camera you want to use

## 0.0.1
Initial release!
Things working on Android:
* Scanning barcodes using the latest version of MLKit and CameraX!
* Switching camera's
* Toggling of the torch (flash)

Things working on iOS:
* Scanning barcodes using the latest version of MLKit and AVFoundation!
