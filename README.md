# 國中英文文法教材

這是一套可直接開啟瀏覽的國中程度英文文法教材網站，內容已完成 `42` 個章節，適合用在自學、課堂教學、複習與練習。

## 內容特色

- 單頁首頁入口，完整列出 `42` 章教材
- 每章都有獨立頁面，例如 `chapter-01.html`
- 每章都包含：
  - 白話解釋
  - 常見錯誤
  - 正確句型
  - 生活例句
  - 練習題
  - 答案與解析
- 手機與電腦都可閱讀

## 如何開啟

1. 進入專案資料夾 `c:\Grammar-for-Beginners`
2. 直接用瀏覽器開啟 `index.html`
3. 從首頁點選任一章節開始閱讀

## 主要檔案

- `index.html`
  - 教材首頁與 42 章目錄
- `styles.css`
  - 全站共用樣式
- `chapter-01.html` 到 `chapter-42.html`
  - 各章教材內容

## 本機使用

最簡單的方式是直接雙擊 `index.html`。

如果你想用本機伺服器開啟，也可以在 PowerShell 執行：

```powershell
cd c:\Grammar-for-Beginners
python -m http.server 8000
```

然後在瀏覽器打開：

```text
http://localhost:8000
```

## GitHub Pages 上傳方式

這個專案已經是靜態網站格式，可直接上傳到 GitHub Pages。

### 方法 1：直接上傳整個資料夾內容

1. 建立 GitHub repository
2. 把以下檔案上傳到 repository 根目錄：
   - `index.html`
   - `styles.css`
   - `chapter-01.html` 到 `chapter-42.html`
   - `404.html`
   - `sitemap.xml`
   - `README.md`
   - `.gitignore`
3. 到 GitHub repository 的 `Settings > Pages`
4. 在 `Build and deployment` 中選擇：
   - `Source: Deploy from a branch`
   - `Branch: main`
   - `Folder: / (root)`
5. 儲存後等待 GitHub Pages 發布

### 方法 2：用 Git 指令上傳

```powershell
cd c:\Grammar-for-Beginners
git init
git add .
git commit -m "Publish grammar ebook"
git branch -M main
git remote add origin <你的-repo-網址>
git push -u origin main
```

之後同樣到 GitHub 的 `Settings > Pages` 開啟 Pages。

## 建議發布前檢查

- 確認 `index.html` 能正常打開
- 確認首頁每張章節卡片都能點開
- 確認 `chapter-01.html` 到 `chapter-42.html` 都存在
- 確認 `styles.css` 和頁面有正確連結

## 適合的用途

- 國中英文文法自學教材
- 補習班或學校課堂投影片輔助教材
- GitHub Pages 線上教材網站
- ebook 網頁版本原稿

## 目前狀態

- `42 / 42` 章已完成
- 首頁已整理為正式封面
- 各章已有前後章導覽
- 可直接作為 GitHub Pages 靜態網站使用

## 額外檔案

- `404.html`
  - GitHub Pages 用的找不到頁面
- `GITHUB_REPO_COPY.md`
  - GitHub repository 首頁展示文案與封面截圖建議
