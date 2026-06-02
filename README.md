# mac-automation

Mac 起手式 + 日常自動化腳本（可攜版）。

把整個 `~/mac-automation` 資料夾複製到任何 Mac，用 `make` 一鍵部署。
包含兩大部分：

1. **新電腦起手式** — 用 `Homebrew` + `Brewfile` 自動安裝開發環境與常用軟體、設定 Zsh 主題與 macOS 偏好。
2. **日常自動化** — 低電量自動關閉模擬器的 LaunchAgent，以及凌晨睡眠排程。

直接執行 `make` 會列出所有可用指令：

```bash
cd ~/mac-automation
make
```

---

## 一、新電腦起手式

### 執行自動安裝

```bash
make bootstrap
```

> **這個指令會自動執行以下動作：**
>
>   * 🔑 取得 sudo 授權並在安裝期間保持登入
>   * 🍺 安裝 **Homebrew** (套件管理器)
>   * 📦 讀取 `Brewfile` 安裝所有軟體 (Node, Docker, VS Code, Chrome...)
>   * 🧛 設定 **Zsh** + **Dracula 主題** (含自動建議與語法高亮插件)
>   * ⚙️ 設定 macOS 系統偏好 (顯示隱藏檔、Dock 自動隱藏...)
>   * 📋 最後列出需手動完成的清單

### 📋 軟體清單 (What's included)

所有安裝項目都列在 `Brewfile` 中，主要包含：

  * **Core**: Git, Node.js, pnpm, mas
  * **Dev Tools**: Visual Studio Code, Docker, Postman, Android Studio, Google Cloud SDK (gcloud)
  * **Apps**: Google Chrome, Snipaste, Calibre
  * **Office & Chat**: Microsoft Word/Excel, Zoom
  * **Fonts**: Fira Code, Hack Nerd Font (為了 Terminal 圖示)

### 手動設定清單 (Manual Setup)

受限於 Apple 安全隱私權政策，以下項目無法自動化，**請在 `make bootstrap` 跑完後手動執行**（或隨時 `make manual-setup` 再看一次）：

  * **Xcode**：請直接至 Mac App Store 下載安裝 (檔案過大且需 Apple ID 驗證)。
  * **隱私權設定**（系統設定 > 隱私權與安全性）：
    * 螢幕錄影 (Screen Recording)：允許 `Snipaste`, `Zoom`
    * 輔助使用 (Accessibility)：允許 `Snipaste`
    * 麥克風/攝影機：允許 `Zoom`
  * **Terminal 字型**：將字體改為 `Hack Nerd Font`，Dracula 主題圖示才會正確顯示。
  * **重啟 Terminal**：`source ~/.zshrc` 或重開視窗即生效。

### 維護更新

  * 新增軟體：直接編輯 `Brewfile`，加入 `brew "軟體名"` 或 `cask "軟體名"`。
  * 不想裝某軟體：在該行最前面加上 `#` 註解掉。
  * 更新所有軟體：再次執行 `make install-apps` (Homebrew 會自動檢查更新)。

---

## 二、低電量提醒 + 自動關閉模擬器

在「用電池供電且放電中」時，LaunchAgent 每 60 秒檢查一次電量：

- **≤ 30%** → 跳通知提醒「記得接電源」（含提示音）。
- **≤ 20%** → 自動關閉 iOS Simulator 與 Android Emulator，並再跳一次通知。

每次掉電各只提醒一次，**接上電源充電後自動重置**，下次放電會再提醒。門檻可在 [low-battery-quit-emulator.sh](low-battery-quit-emulator.sh) 開頭的 `WARN_THRESHOLD` / `CRIT_THRESHOLD` 調整（改完跑 `make reload`）。此功能**不會讓 Mac 休眠**。

| 指令 | 說明 |
| --- | --- |
| `make install` | 部署腳本與 plist 並載入 LaunchAgent（新電腦用這個） |
| `make reload` | 改完來源檔後重新部署並載入 |
| `make status` | 顯示代理狀態與目前電量 |
| `make test` | 立即手動跑一次（高電量時不會關任何東西） |
| `make logs` | 查看低電量動作紀錄 |
| `make uninstall` | 卸載代理並移除已安裝的檔案 |

**通知圖示(小小兵 🟡)**:macOS 會擋掉 terminal-notifier 的 `-appIcon`,所以要讓通知的「主圖示」變成小小兵,得從一個帶該圖示的 app 發通知。`make deploy` 會自動用本機的 terminal-notifier 複製出一個 `~/Library/Scripts/LowBatteryMinion.app`(換上 `minions-bob.png`、改 bundle id、重簽),腳本就會優先用它發通知。因為是在當台機器即時產生(不把二進位放進 repo),所以 Intel/ARM 換機都沒問題;沒有 terminal-notifier 或圖檔時會自動降級,不影響功能。換圖只要替換 `minions-bob.png` 再 `make reload`。

相關檔案：

  * `low-battery-quit-emulator.sh` — 實際偵測電量、關閉模擬器並發通知的腳本。
  * `com.user.lowbattery.emulator.plist.template` — LaunchAgent 範本（部署時依當前使用者路徑產生）。
  * `build-minion-notifier.sh` — 產生小小兵圖示通知 app（由 `make deploy` 自動呼叫）。
  * `minions-bob.png` — 通知用的小小兵圖（512×512）。

---

## 三、凌晨睡眠排程

> ⚠️ 需要 `sudo`，請務必在 **Terminal.app** 內執行（不要在 IDE 整合終端機）。

| 指令 | 說明 |
| --- | --- |
| `make schedule-sleep` | 設定每天 02:00 自動睡眠 |
| `make cancel-sleep` | 取消睡眠排程 |
| `make show-sleep` | 顯示目前電源排程 |

---

## 🐣 給程式新手的安裝指南 (No-Code Friendly)

如果你是第一次接觸程式，電腦裡還沒有 Git，請依照以下步驟操作。

<details>
  <summary>點擊看詳細內容</summary>

  ### 步驟 1：下載腳本
  1.  在 GitHub 頁面右上角找到綠色的 **<> Code** 按鈕。
  2.  點擊 **Download ZIP**。
  3.  解壓縮下載的檔案。

  ### 步驟 2：打開終端機 (Terminal)
  1.  按下鍵盤上的 `Command ⌘` + `Space` (空白鍵)，叫出搜尋框。
  2.  輸入 `Terminal` 並按下 Enter。

  ### 步驟 3：進入資料夾 (大招！)
  1.  在終端機輸入 `cd` (後面要空一格)。
  2.  **不要按 Enter**，把剛剛解壓縮的資料夾直接**拖曳**到終端機視窗裡。
  3.  路徑自動出現後，按下 **Enter**。

  ### 步驟 4：開始自動安裝
  1.  輸入 `make bootstrap` 並按下 Enter。
  2.  **重要提醒**：過程中如果要求輸入 Password (密碼)：
      * 請輸入你的 **開機登入密碼**。
      * ⚠️ **輸入時畫面不會有任何反應（沒有星星或圓點），這是正常的！**
      * 輸入完直接按 Enter 即可。

  ### 如果有不想裝的軟體怎麼辦？
  1.  用文字編輯器打開 `Brewfile`。
  2.  找到你不想裝的軟體（例如 `microsoft-word`）。
  3.  在那一行最前面打上 `#` 號：`# cask "microsoft-word"`。
  4.  存檔後再執行 `make bootstrap`。
</details>
