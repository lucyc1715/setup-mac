# 定義預設任務：輸入 make 就會跑這四個步驟
.PHONY: all install-homebrew install-apps setup-zsh setup-macos help

all: sudo-keep-alive install-homebrew install-apps setup-zsh setup-macos help

# --- 0. 權限延長 (Sudo Keep-alive) ---
# 1. sudo -v 會立刻要求使用者輸入密碼 (只要這一次)
# 2. while loop 會在背景每 60 秒幫你更新一次權限
# 3. 這樣不管安裝跑多久，都不會因為逾時而中斷
sudo-keep-alive:
	@echo "🔑 [0/5] 請輸入密碼以授權安裝 (之後就可以去喝咖啡了)..."
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	@echo "✅ 已取得授權，將保持登入狀態直到安裝完成"

# 步驟 1: 安裝 Homebrew
install-homebrew:
	@echo "🍺 [1/5] 檢查 Homebrew..."
	@which brew > /dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@echo "✅ Homebrew 準備就緒"

# 步驟 2: 依照 Brewfile 安裝軟體
install-apps:
	@echo "📦 [2/5] 開始安裝軟體清單 (這需要一點時間，可以去喝杯咖啡)..."
	brew bundle --file=./Brewfile
	@echo "✅ 軟體安裝完成"

# 步驟 3: 設定 Zsh + Dracula 主題 + 插件
setup-zsh:
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

# 步驟 4: Mac 系統偏好設定
setup-macos:
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

# 步驟 5: 顯示手動清單
help:
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
