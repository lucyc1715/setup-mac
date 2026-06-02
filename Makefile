# Mac automation 管理（可攜版）
# 把整個 ~/mac-automation 資料夾複製到任何 Mac 即可部署。
#   - 新電腦起手式：make bootstrap   （裝 Homebrew / 軟體 / Zsh / 系統偏好）
#   - 低電量代理：  make install     （部署並載入 LaunchAgent）
# 用法：cd ~/mac-automation && make <target>（直接打 make 會列出所有指令）

LABEL    := com.user.lowbattery.emulator
UID      := $(shell id -u)

# 來源檔（放在本資料夾，跟著 repo 走）
SRC_SCRIPT   := $(CURDIR)/low-battery-quit-emulator.sh
SRC_TEMPLATE := $(CURDIR)/$(LABEL).plist.template
SRC_ICON     := $(CURDIR)/minions-bob.png

# 安裝目標（依當前使用者 $(HOME) 自動決定，換人/換機都正確）
DST_SCRIPT := $(HOME)/Library/Scripts/low-battery-quit-emulator.sh
DST_ICON   := $(HOME)/Library/Scripts/minions-bob.png
DST_PLIST  := $(HOME)/Library/LaunchAgents/$(LABEL).plist
ERR_LOG    := $(HOME)/Library/Logs/low-battery-quit-emulator.err.log
LOG        := $(HOME)/Library/Logs/low-battery-quit-emulator.log

SLEEP_TIME := 02:00:00
SLEEP_DAYS := MTWRFSU

.DEFAULT_GOAL := help

.PHONY: help
help: ## 顯示所有可用指令
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ========== 新電腦起手式（Homebrew / 軟體 / Zsh / 系統偏好） ==========

.PHONY: bootstrap sudo-keep-alive install-homebrew install-apps setup-zsh setup-macos manual-setup

bootstrap: sudo-keep-alive install-homebrew install-apps setup-zsh setup-macos manual-setup ## 新電腦一鍵安裝（Homebrew→軟體→Zsh→系統偏好）

# --- 0. 權限延長 (Sudo Keep-alive) ---
# 1. sudo -v 會立刻要求使用者輸入密碼 (只要這一次)
# 2. while loop 會在背景每 60 秒幫你更新一次權限
# 3. 這樣不管安裝跑多久，都不會因為逾時而中斷
sudo-keep-alive: ## 取得 sudo 授權並在安裝期間保持登入
	@echo "🔑 [0/5] 請輸入密碼以授權安裝 (之後就可以去喝咖啡了)..."
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	@echo "✅ 已取得授權，將保持登入狀態直到安裝完成"

install-homebrew: ## [1/5] 安裝 Homebrew
	@echo "🍺 [1/5] 檢查 Homebrew..."
	@if ! which brew > /dev/null; then \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo 'eval "$$(/opt/homebrew/bin/brew shellenv)"' >> $$HOME/.zprofile; \
		eval "$$(/opt/homebrew/bin/brew shellenv)"; \
	fi
	@echo "✅ Homebrew 準備就緒"

install-apps: ## [2/5] 依照 Brewfile 安裝軟體
	@echo "📦 [2/5] 開始安裝軟體清單..."
	# 先載入 brew 路徑設定，再依本資料夾的 Brewfile 安裝
	@eval "$$(/opt/homebrew/bin/brew shellenv)" && brew bundle --file="$(CURDIR)/Brewfile" || true
	@echo "✅ 軟體安裝完成"

setup-zsh: ## [3/5] 設定 Zsh + Dracula 主題 + 插件
	@echo "🧛 [3/5] 設定 Zsh 與 Dracula 主題..."
	# (A) 安裝 Oh My Zsh
	@if [ ! -d "$$HOME/.oh-my-zsh" ]; then \
		echo "正在安裝 Oh My Zsh..."; \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
	fi
	# (B) 下載 Dracula 主題
	@if [ ! -d "$$HOME/.oh-my-zsh/custom/themes/dracula" ]; then \
		git clone https://github.com/dracula/zsh.git $$HOME/.oh-my-zsh/custom/themes/dracula; \
		ln -sf $$HOME/.oh-my-zsh/custom/themes/dracula/dracula.zsh-theme $$HOME/.oh-my-zsh/custom/themes/dracula.zsh-theme; \
	fi
	# (C) 下載好用的插件 (自動建議 + 語法高亮)
	@if [ ! -d "$$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then \
		git clone https://github.com/zsh-users/zsh-autosuggestions $$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions; \
	fi
	@if [ ! -d "$$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting; \
	fi
	# (D) 修改 .zshrc 設定檔
	@echo "正在修改 .zshrc..."
	@cp $$HOME/.zshrc $$HOME/.zshrc.backup 2>/dev/null || true
	@sed -i '' 's/^ZSH_THEME=".*"/ZSH_THEME="dracula"/' $$HOME/.zshrc
	@sed -i '' 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' $$HOME/.zshrc
	@echo "✅ Zsh 美化完成"

setup-macos: ## [4/5] 設定 macOS 系統偏好（Finder/Dock）
	@echo "⚙️  [4/5] 設定 macOS 偏好..."
	# Finder: 顯示副檔名、顯示路徑列
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write com.apple.finder ShowPathbar -bool true
	# Dock: 自動隱藏
	defaults write com.apple.dock autohide -bool true
	# 重啟 Finder 和 Dock
	killall Finder
	killall Dock
	@echo "✅ 系統設定完成"

manual-setup: ## [5/5] 顯示需手動完成的設定清單
	@echo ""
	@echo "🎉🎉🎉 自動安裝全部完成！ 🎉🎉🎉"
	@echo ""
	@echo "⚠️  最後請記得手動執行以下步驟："
	@echo "1. [Xcode]: 請至 App Store 下載安裝 (太大且需 Apple ID，無法自動化)。"
	@echo "2. [字型設定]: 打開 Terminal 設定 -> 描述檔 -> 字體改為 'Hack Nerd Font' 以顯示圖示。"
	@echo "3. [隱私權設定] (System Settings -> Privacy & Security):"
	@echo "   - Screen Recording: 允許 Snipaste, Zoom"
	@echo "   - Accessibility: 允許 Snipaste"
	@echo "   - Microphone/Camera: 允許 Zoom"
	@echo "4. [重啟 Terminal]: 輸入 'source ~/.zshrc' 或重開視窗即生效。"
	@echo "==================================================="

# ========== 低電量模擬器代理 ==========

.PHONY: deploy
deploy: ## 從本資料夾把腳本與 plist 部署到 ~/Library（依當前路徑產生）
	mkdir -p "$(HOME)/Library/Scripts" "$(HOME)/Library/LaunchAgents" "$(HOME)/Library/Logs"
	cp "$(SRC_SCRIPT)" "$(DST_SCRIPT)"
	chmod +x "$(DST_SCRIPT)"
	@[ -f "$(SRC_ICON)" ] && cp "$(SRC_ICON)" "$(DST_ICON)" && echo "已複製通知圖示" || echo "（無 minions-bob.png，通知不帶圖）"
	sed -e 's|__SCRIPT__|$(DST_SCRIPT)|g' \
	    -e 's|__ERRLOG__|$(ERR_LOG)|g' \
	    "$(SRC_TEMPLATE)" > "$(DST_PLIST)"
	plutil -lint "$(DST_PLIST)"
	@echo "已部署腳本與 plist"

.PHONY: install
install: deploy ## 部署並載入低電量 LaunchAgent（新電腦用這個）
	-launchctl bootout gui/$(UID)/$(LABEL) 2>/dev/null
	launchctl bootstrap gui/$(UID) "$(DST_PLIST)"
	@echo "已載入 $(LABEL)"

.PHONY: uninstall
uninstall: ## 卸載代理並移除已安裝的檔案
	-launchctl bootout gui/$(UID)/$(LABEL) 2>/dev/null
	rm -f "$(DST_PLIST)" "$(DST_SCRIPT)" "$(DST_ICON)"
	@echo "已卸載並清除 $(LABEL)"

.PHONY: reload
reload: install ## 重新部署並載入（改完來源檔後用）

.PHONY: status
status: ## 顯示代理狀態與目前電量
	@echo "--- 代理狀態 ---"
	@launchctl print gui/$(UID)/$(LABEL) 2>/dev/null | grep -E "state|run interval" | head -4 || echo "未載入"
	@echo "--- 目前電量 ---"
	@pmset -g batt

.PHONY: test
test: ## 立即手動跑一次低電量腳本（高電量時不會關任何東西）
	bash "$(DST_SCRIPT)"; echo "exit: $$?"

.PHONY: logs
logs: ## 查看低電量動作紀錄
	@touch "$(LOG)"; tail -n 30 "$(LOG)" || echo "(尚無紀錄)"

# ========== 凌晨睡眠排程（需要 sudo，務必在 Terminal.app 執行） ==========

.PHONY: schedule-sleep
schedule-sleep: ## 設定每天 2AM 睡眠（需在 Terminal.app 執行，會問密碼）
	sudo pmset repeat sleep $(SLEEP_DAYS) $(SLEEP_TIME)
	@echo "已排程：每天 $(SLEEP_TIME) 睡眠"

.PHONY: cancel-sleep
cancel-sleep: ## 取消睡眠排程
	sudo pmset repeat cancel
	@echo "已取消睡眠排程"

.PHONY: show-sleep
show-sleep: ## 顯示目前電源排程
	pmset -g sched
