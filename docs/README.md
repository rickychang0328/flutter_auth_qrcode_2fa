# NOSMS → Flutter 移植 SDD 套件

本目錄為 **Spec-Driven Development (SDD)** 文件，由 Android 專案 `nosms`（MustAuth 驗證器）完整逆向整理，供另一個 **Flutter** 專案實作功能對等與資料互通。

## 文件清單

| 檔案 | 用途 |
|------|------|
| **[SDD.md](./SDD.md)** | **Flutter 實作軟體設計文件**（架構、類別、Mermaid 圖表、實作狀態） |
| [spec.json](./spec.json) | 規格元資料、版本、相容目標 |
| [requirements.md](./requirements.md) | 功能與非功能需求、驗收標準 |
| [design.md](./design.md) | 架構、資料契約、演算法、API、加密、Deep Link |
| [tasks.md](./tasks.md) | 分階段實作任務清單 |

## 建議使用方式（Flutter 團隊）

1. 將整個 `nosms-flutter-port` 資料夾複製到 Flutter 專案的 `docs/` 或 `.kiro/specs/`。
2. 先閱讀 `requirements.md` 確認範圍，再依 `design.md` 實作 domain/data 層。
3. 以 `tasks.md` Phase 1～2 為 MVP（OTP + 儲存 + URI），再迭代 UI 與分享。
4. 單元測試必須對齊 `design.md` §3、§4、§5 與 Android `TokenCalculator` / `Entry` 行為。

## 關鍵互通點（摘要）

- URI：`otpauth://` 與 **`mustauth://`**
- 批次 QR：`mustauth://mulitpleshare/...&mulitpleURL=...`（每 QR 最多 8 筆）
- 帳戶 JSON 欄位名：見 `design.md` §2.2
- 本機 DB：`secrets.dat` = AES-GCM(JSON 陣列)

## 原始專案

- Package：`com.xtxgcsydsu.nosms`
- versionName：`1.3.0`（見 `app/build.gradle`）
