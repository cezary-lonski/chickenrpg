@echo off
rem ChickenSerwer w konsoli (bez okna graficznego): logi i komendy w tym oknie terminala.
rem Komendy wpisujesz tu (z ukosnikiem lub bez): help, list, status, say tekst, op nick, stop (albo exit).
rem Opcje: --port 7777  --name "Moj serwer"  --max 16
cd /d "%~dp0"
if exist "ChickenSerwer-konsola.exe" (
  "ChickenSerwer-konsola.exe" --headless -- --server --autostart %*
) else (
  "Godot_v4.7.2-stable_win64_console.exe" --headless --path . -- --server --autostart %*
)
pause
