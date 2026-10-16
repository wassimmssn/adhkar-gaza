@echo off
echo Building AdhkarGaza PWA...
call flutter build web --release --no-tree-shake-icons --pwa-strategy=offline-first
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ============================================
    echo   ERROR: Flutter build FAILED! Aborting.
    echo ============================================
    exit /b 1
)
echo Generating Offline Service Worker...
call dart run scripts/generate_offline_worker.dart
echo Copying _headers...
copy web\_headers build\web\_headers
echo.
echo Deploying to Cloudflare Pages (Production)...
call npx.cmd -y wrangler pages deploy build/web --project-name=adhkar-gaza --branch main --commit-dirty=true
echo.
echo ============================================
echo   SUCCESS: Build and Deploy complete!
echo ============================================