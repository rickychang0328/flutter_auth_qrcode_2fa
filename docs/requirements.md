# 需求規格 — MustAuth (NOSMS) Flutter 移植

## 1. 產品概述

### 1.1 產品定位

**MustAuth（NOSMS）** 是一款本機優先的 **TOTP / HOTP / Steam Guard** 雙因素驗證器，衍生自 [andOTP](https://github.com/andOTP/andOTP) 架構並加入品牌擴充（`mustauth://` scheme、分組、批次 QR 分享、動態 API 網域）。應用 **不依賴簡訊**，所有 OTP 在本機以共享密鑰計算。

### 1.2 目標使用者

- 需管理多組 2FA 帳戶的一般使用者
- 需透過深連結由第三方 App 寫入或讀取 OTP 的整合場景
- 需在裝置間以 QR 批次轉移驗證碼的使用者

### 1.3 Flutter 移植目標

| 目標 | 說明 |
|------|------|
| 功能對等 | 涵蓋核心 OTP、帳戶 CRUD、分組、分享/匯入、安全鎖、版本檢查 |
| 資料互通 | 能解析 Android 版 `Entry` JSON、`otpauth`/`mustauth` URI、批次 `mulitpleURL` QR |
| 安全等級 | 本機加密儲存、生物辨識/手勢二次驗證、Panic 清除（平台適配） |
| 可選互通 | 與 Android `secrets.dat` 加解密格式相容（需實作相同 Keystore 包裝邏輯或提供匯入匯出橋接） |

---

## 2. 功能需求

### FR-01 帳戶列表與 OTP 顯示

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-01.1 | 顯示所有已儲存驗證碼 | 列表含 issuer、account、目前 OTP、TOTP 剩餘秒數 |
| FR-01.2 | TOTP 自動刷新 | 週期預設 30 秒，到期自動重算並更新 UI |
| FR-01.3 | HOTP 遞增計數 | 使用者觸發後 counter+1 並持久化 |
| FR-01.4 | Steam 類型 | 使用自訂 26 字元集，預設 5 位 |
| FR-01.5 | 複製 OTP | 一鍵複製至剪貼簿；可支援 `action=get` 深連結僅複製不新增 |
| FR-01.6 | 隱藏 OTP | HOTP 可設定 `ishideotp`，點擊後短暫顯示 |
| FR-01.7 | 置頂 | 支援 `istag`（JSON 鍵）置頂排序 |
| FR-01.8 | 搜尋 | 可搜尋 label、issuer、tags（設定可調） |
| FR-01.9 | 排序 | 支援未排序、依 label、依 last_used |

### FR-02 新增與編輯帳戶

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-02.1 | QR 掃描新增 | 解析標準 `otpauth://` 與 `mustauth://` |
| FR-02.2 | 手動輸入 | 可設定 type、secret、issuer、account、period、digits、algorithm、tags |
| FR-02.3 | 深連結新增 | `ACTION_VIEW` 等效：`otpauth`/`mustauth`，host `totp`/`hotp` |
| FR-02.4 | 剪貼簿偵測 | 偵測剪貼簿內 OTP URI 並提示新增（鍵 `cliboard`） |
| FR-02.5 | 重複處理 | 相同 secret 或業務規則重複時提示覆蓋或保留 |
| FR-02.6 | 編輯限制 | digits ≤ 8；secret 符合 Base32 `[a-zA-Z2-7]{2,}` |
| FR-02.7 | 唯一識別 | 每筆帳戶以 `last_used`（long）作為執行期唯一 ID；新建時建議 `System.nanoTime()` |

### FR-03 OTP URI 解析（相容 Android）

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-03.1 | Scheme | 支援 `otpauth`、`mustauth`（大小寫 scheme 正規化） |
| FR-03.2 | Host | `totp`→TOTP；`hotp`→HOTP；其他小寫 host 視為 TOTP 並補 path |
| FR-03.3 | Path / Label | path 去前導 `/` 為 label；**僅一個 `:`** 時拆為 issuer:account，否則整段為 account |
| FR-03.4 | Query 優先 | query 的 `issuer`、`account` 優先於 path 解析結果 |
| FR-03.5 | 必填 secret | `action` 為 create（`set` 或缺省）時必須有 `secret` |
| FR-03.6 | action | `set`→建立；`get`→僅複製 OTP，不寫入資料庫 |
| FR-03.7 | group | 支援重複 query `group`，寫入 Entry.groupList |
| FR-03.8 | 特殊字元 | path/query 需 URL encode/decode，與 Android `Entry(String)` 行為一致 |
| FR-03.9 | 匯出 account 冒號 | 匯出時若 account 僅含一個 `:`，末端自動補第二個 `:`（僅匯出側） |

### FR-04 分組管理

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-04.1 | 分組 CRUD | 建立、重新命名、刪除、釘選 |
| FR-04.2 | 上限 | 最多 **10** 組；超出匯入時截斷並提示 |
| FR-04.3 | 關聯 | 分組以 `codeLastIdList` 儲存 Entry 的 `last_used` |
| FR-04.4 | 篩選 | 主列表可依分組篩選 |
| FR-04.5 | 持久化 | JSON 存於 `grouplistjson`（SharedPreferences 等效） |

### FR-05 分享與批次匯入/匯出

| ID | 需求 | 驗收標準 |
| FR-05.1 | 選擇匯出 | 使用者勾選多筆帳戶產生 QR |
| FR-05.2 | 批次格式 | `mustauth://mulitpleshare/mulitpleshare?action=mulitpleshare&mulitpleURL=<encoded>...` |
| FR-05.3 | 每 QR 上限 | 每個 QR 最多 **8** 筆 `mulitpleURL` |
| FR-05.4 | 子 URI | 每筆為完整 `mustauth://totp|hotp/{label}?secret=...&action=set&group=...` |
| FR-05.5 | 匯入來源 | 相機掃描、相簿圖片 ZXing 辨識 |
| FR-05.6 | 歷史紀錄 | `shareaccountlistjson` 記錄匯入/匯出摘要 |
| FR-05.7 | 匯出前驗證 | 啟用安全驗證時，匯出/分享前需指紋或手勢通過 |

### FR-06 安全與隱私

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-06.1 | 本機加密 DB | `secrets.dat`：AES-GCM，IV 前 12 bytes |
| FR-06.2 | 金鑰管理 | Android：RSA 包裝 AES 金鑰存 `otp.key`；Flutter：建議 Secure Enclave / Keychain + 相容策略文件化 |
| FR-06.3 | 指紋解鎖 | 開關 `isSecurityValidation`；背景 **5 分鐘** 或 App 終止後需重新驗證 |
| FR-06.4 | 手勢鎖 | 九宮格最少 **4** 點；獨立於 app 解鎖 PIN（andOTP 遺留） |
| FR-06.5 | 背景模糊 | 進入背景且需驗證時，主畫面模糊並阻擋觸控 |
| FR-06.6 | Panic Button | 接收 `info.guardianproject.panic.action.TRIGGER`；依設定清除帳戶 DB/Keystore/設定 |
| FR-06.7 | 螢幕截圖 | 依 `pref_enable_screenshot` 控制（Android `FLAG_SECURE` 等效） |
| FR-06.8 | 備份加密 | 支援明文 JSON 與 PBKDF2+AES-GCM `.json.aes` 格式 |

### FR-07 備份與還原

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-07.1 | 明文備份 | `otp_accounts.json` 或 `otp_accounts_{datetime}.json` |
| FR-07.2 | 加密備份 | `.json.aes`：`[4B iterations][12B salt][ciphertext]` |
| FR-07.3 | 還原 | 解析 JSON 陣列為 Entry 列表並合併/覆蓋 |
| FR-07.4 | 廣播備份（可選） | `PLAIN_TEXT_BACKUP` / `ENCRYPTED_BACKUP` intent |

### FR-08 版本與網域 API

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-08.1 | 版本檢查 | `POST {api}/version?platform&version&mid&brand&model&os_version` |
| FR-08.2 | 動態網域 | 回應 `domain[]` 可更新 API / WebView base URL |
| FR-08.3 | 強制更新 | 依 `version_info` 顯示更新對話框與下載連結 |

### FR-09 設定與 UI（次要移植）

| ID | 需求 | 驗收標準 |
|----|------|----------|
| FR-09.1 | 主題/語系 | light/dark、locale |
| FR-09.2 | 卡片佈局 | default / full |
| FR-09.3 | Thumbnail | 依 issuer 對應圖示資源（可簡化為字母頭像） |
| FR-09.4 | 說明/隱私 | WebView 載入 `mustauth.com` 說明頁 |

---

## 3. 非功能需求

| ID | 類別 | 需求 |
|----|------|------|
| NFR-01 | 安全 | Secret 不得寫入 log；記憶體中盡量縮短明文存留時間 |
| NFR-02 | 效能 | 列表 100+ 帳戶時仍維持 60fps 滾動；TOTP 計時器精確到秒 |
| NFR-03 | 離線 | 除版本 API 外，核心 OTP 功能完全離線 |
| NFR-04 | 相容 | 與 Android 版 JSON 欄位名稱、URI 行為一致（見 design.md） |
| NFR-05 | 平台 | iOS/Android 使用 `local_auth`、`flutter_secure_storage` 等主流套件 |

---

## 4. 不在範圍（V1 可延後）

- OpenPGP 備份（`.json.gpg`）
- andOTP 遺留 PIN/密碼 app 解鎖完整 UI（若 Flutter 僅用生物辨識+手勢可簡化）
- `library/` 模組內 RecyclerView 進階手勢（Flutter 以標準列表+拖曳套件替代）
- Android `NOSMSBackupAgent` 雲端備份（可改為平台備份 API 或手動匯出）

---

## 5. 使用者故事（摘要）

1. **作為使用者**，我掃描 Google Authenticator QR，以便在 MustAuth 中看到 6 位 TOTP。
2. **作為使用者**，我將驗證碼分組為「工作/個人」，以便快速篩選。
3. **作為使用者**，我選取 5 個帳戶產生 QR 給新手機掃描，以便換機。
4. **作為第三方 App**，我透過 `mustauth://totp/...?action=get` 取得目前 OTP 到剪貼簿。
5. **作為注重安全的使用者**，我啟用指紋，App 在背景 5 分鐘後要求重新驗證。
6. **作為使用者**，我在緊急情況觸發 Panic Button，以便清除所有驗證碼資料。

---

## 6. 驗收測試向量（OTP 演算法）

以下測試應與 Android `TokenCalculator` 輸出一致（建議單元測試固定時間 mock）：

- **TOTP / SHA1 / 6 digits / period 30**：使用 RFC 6238 測試向量（Google 測試 key `JBSWY3DPEHPK3PXP` 等）
- **HOTP**：counter 遞增後碼值變化
- **Steam**：5 位自訂字元集輸出

URI 解析測試應覆蓋：

- `mustauth://totp/Issuer:account?secret=...&issuer=QueryIssuer`
- path 含多個 `:` 僅 account、issuer 來自 query
- `action=get` 不持久化
- 批次 `mulitpleURL` 8+1 筆分兩個 QR 字串
