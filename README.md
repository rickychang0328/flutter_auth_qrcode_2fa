# MustAuth Flutter (`flutter_auth_qrcode_2fa`)

Flutter 移植版 MustAuth（對照 Android NOSMS / andOTP 衍生），支援 OTP 帳戶管理、QR 掃描/相簿辨識、批次分享、加密本機儲存與備份還原。

## 規格文件

- [docs/requirements.md](docs/requirements.md) — 功能需求（FR-xx）
- [docs/design.md](docs/design.md) — 架構、URI、加密、Deep Link（§6.2 備份、§9 Deep Link）
- [docs/tasks.md](docs/tasks.md) — 實作任務清單

## 執行方式

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://maapi-dev.azuredigitaltech.com.tw:18443/api/ \
  --dart-define=WEB_BASE_URL=https://mustauth.com/
```

- `API_BASE_URL`：版本檢查 API 根路徑（對應 Android `BuildConfig`）
- `WEB_BASE_URL`：說明/隱私 WebView 基底（預留）

測試與靜態分析：

```bash
flutter test
dart analyze lib
```

## 與 Android 互通性

| 項目 | 說明 |
|------|------|
| **Keystore / `secrets.dat`** | Android 以 Keystore 包裝 `otp.key` 加密 `secrets.dat`；Flutter 使用 `flutter_secure_storage` 保存 AES 金鑰，**無法直接互換**本機資料庫檔案。請使用下方備份格式跨裝置遷移。 |
| **明文備份** | `otp_accounts.json` — JSON 陣列，欄位與 `Entry.toJSON()` 一致（`last_used`、`istag` 等）。 |
| **加密備份** | `otp_accounts.json.aes` — `[4B iterations BE][12B salt][AES-GCM ciphertext]`；PBKDF2-HmacSHA1，iter 1000–5000；256-bit 衍生，AES 金鑰取前 128 bit（匯入時亦嘗試 Android 全長 32-byte 金鑰）。 |
| **批次 QR / URI** | 支援 `mustauth://` / `otpauth://` 及 `mulitpleURL` 拼字（歷史 typo，不可改）。 |
| **手勢鎖** | Android 舊版以硬編碼 AES/ECB 儲存 `gesture_pwd_key`；Flutter 以 `shared_preferences` 儲存，**與舊版手勢密文不相容**。 |

## 已實作（原 deferred 任務）

| 任務 | 內容 |
|------|------|
| **T0.3** | Android `AndroidManifest.xml`、`ios/Runner/Info.plist` 註冊 `otpauth` / `mustauth` scheme；與 `app_links` + `DeepLinkHandler` 搭配。 |
| **T2.5** | `BackupService` / `BackupCrypto`：明文 JSON 與 `.json.aes` 匯出匯入；設定頁入口。 |
| **T3.4** | `image_picker` 相簿 QR；原生辨識（Android ZXing / iOS Vision）經 MethodChannel；即時掃描仍用 `mobile_scanner`；錯誤訊息繁體中文。 |
| **T8.5** | 本 README 與 spec 連結、互通限制說明。 |

## 平台設定備註

### Android

- `AndroidManifest.xml`：`CAMERA`、`READ_MEDIA_IMAGES`（及 API≤32 的 `READ_EXTERNAL_STORAGE`）
- Deep link：`intent-filter` VIEW + `otpauth` / `mustauth` hosts `totp`、`hotp`、`*`

### iOS

- `Info.plist`：`NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`
- `CFBundleURLTypes`：`otpauth`、`mustauth` URL schemes
- 相簿 QR 使用原生 **Vision**（`VNDetectBarcodesRequest`），需實機或模擬器；不支援 Web

### 相簿 QR 原生辨識

| 平台 | 實作 |
|------|------|
| **Android** | ZXing `QRCodeReader` + 多尺寸重試（512→2048 等），對照 nosms `LoadingPictureActivity` |
| **iOS** | Apple **Vision** `VNDetectBarcodesRequest`（QR symbology），無額外 CocoaPods |
| **Flutter** | MethodChannel `com.example.flutter_auth_qrcode_2fa/qr_decode` → `decodeFromImagePath` |

單元測試以 mock channel 驗證 Dart 層；`test/assets/qrcodetest1.png` 之實際解碼請在 Android/iOS 整合測試或實機驗證。

## 專案結構（摘要）

- `lib/domain/` — `OtpAccount`、`OtpUriParser`、`BatchQrCodec`
- `lib/data/` — `EncryptedAccountStore`、`BackupService`、`QrImageDecoder`
- `lib/presentation/` — Riverpod UI、`DeepLinkHandler`、設定與備份操作

## 參考 Android 原始碼

路徑：`/Users/ricky.chang/Documents/android_prog/nosms/`（`BackupHelper`、`LoadingPictureActivity`、`AndroidManifest` deep links）
