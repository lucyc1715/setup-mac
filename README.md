# setup-mac

Mac Pro 起手式自動化腳本

每次換電腦都要重複下載安裝軟體。
透過 `Makefile` 和 `Homebrew`，實現「一行指令」自動安裝所有開發環境與常用軟體。

## 開始！

### 1. 下載此專案
打開終端機 (Terminal)，將專案 Clone 到本地 (或是直接下載資料夾)：

```bash
git clone <repo網址> mac-setup
cd mac-setup
````

### 2\. 執行自動安裝

在資料夾內執行 `make` 指令：

```bash
make
```

> **這個指令會自動執行以下動作：**
>
>   * 🍺 安裝 **Homebrew** (套件管理器)
>   * 📦 讀取 `Brewfile` 安裝所有軟體 (Node, Docker, VS Code, Chrome...)
>   * ⚙️ 設定 macOS 系統偏好 (顯示隱藏檔、Dock 自動隱藏...)
>   * 🧛 設定 **Zsh** + **Dracula 主題** (包含自動建議與語法高亮插件)

-----

## 📋 軟體清單 (What's included)

所有安裝項目都列在 `Brewfile` 中，主要包含：

  * **Core**: Git, Node.js, pnpm, Homebrew
  * **Dev Tools**: Visual Studio Code, Docker, Postman, Android Studio, Google Cloud SDK (gcloud)
  * **Apps**: Google Chrome, Snipaste, Calibre
  * **Office & Chat**: Microsoft Word/Excel, Zoom
  * **Fonts**: Fira Code, Hack Nerd Font (為了 Terminal 圖示)

-----

## 手動設定清單 (Manual Setup)

受限於 Apple 安全隱私權政策，以下項目無法自動化，**請在腳本跑完後手動執行**：

### 1\. Xcode

  * 請直接至 **Mac App Store** 下載安裝 (檔案過大且需 Apple ID 驗證)。

### 2\. 隱私權設定 (Privacy & Security)

請至 `系統設定` \> `隱私權與安全性` 開啟權限：

  * **螢幕錄影 (Screen Recording)**: 允許 `Snipaste`, `Zoom`
  * **輔助使用 (Accessibility)**: 允許 `Snipaste` (讓截圖能偵測視窗邊緣)
  * **麥克風/攝影機**: 允許 `Zoom`

### 3\. Terminal 字型設定 (重要！)

為了讓 Dracula 主題顯示正確的圖示，請做以下設定：

1.  打開 Terminal (或 iTerm2 / VS Code)。
2.  進入設定 (Settings) \> 描述檔 (Profiles)。
3.  將字體更改為 **`Hack Nerd Font`**。

-----

## 維護更新

  * 新增軟體，直接編輯 `Brewfile`，加入 `brew "軟體名"` 或 `cask "軟體名"`。
  * 更新所有軟體，再次執行 `make` 即可 (Homebrew 會自動檢查更新)。

-----

## 🐣 給程式新手的安裝指南 (No-Code Friendly)
如果你是第一次接觸程式，電腦裡還沒有 Git，請依照以下步驟操作

<details>
  <summary>點擊看詳細內容</summary>
 
  ### 步驟 1：下載腳本
  1.  在 GitHub 頁面右上角找到綠色的 **<> Code** 按鈕。
  2.  點擊 **Download ZIP**。
  3.  解壓縮下載的檔案，你會看到一個資料夾（例如 `mac-setup-main`）。
  
  ### 步驟 2：打開終端機 (Terminal)
  1.  按下鍵盤上的 `Command ⌘` + `Space` (空白鍵)，叫出搜尋框。
  2.  輸入 `Terminal` 並按下 Enter，你會看到一個黑底或白底的視窗。
  
  ### 步驟 3：進入資料夾 (大招！)
  這一步最重要，請跟著做：
  1.  在終端機輸入 `cd` (後面要空一格)。
  2.  **不要按 Enter**，把剛剛解壓縮的資料夾直接**拖曳**到終端機視窗裡。
  3.  這時你會看到路徑自動出現，現在請按下 **Enter**。
  
  ### 步驟 4：開始自動安裝
  1.  輸入 `make` 並按下 Enter。
  2.  **重要提醒**：過程中如果它要求輸入 Password (密碼)：
      * 請輸入你的 **開機登入密碼**。
      * ⚠️ **注意：輸入時畫面不會有任何反應（沒有星星或圓點），這是正常的！**
      * 輸入完直接按 Enter 即可。
  
  ### 如果有不想裝的軟體怎麼辦？
  1.  在 `Brewfile` 這個檔案上按右鍵。
  2.  選擇 **「打開檔案的應用程式」** > **「文字編輯器 (TextEdit)」**。
  3.  找到你不想裝的軟體（例如 `microsoft-word`）。
  4.  在那一行最前面打上一個 `#` 號，變成這樣：
      `# cask "microsoft-word"`
  5.  存檔 (Command + S)，關閉。
  6.  現在可以去執行 `make` 了！
</details>
