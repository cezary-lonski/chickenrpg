@echo off
rem ChickenSerwer bez okna (tryb --headless): startuje od razu. Zmiana portu: --port 7777, nazwy: --name "Moj serwer", limitu: --max 16.
rem Komendy admina: zaloguj sie w grze postacia admina i uzywaj czatu (T), np. /help.
cd /d "%~dp0"
"Godot_v4.7.2-stable_win64_console.exe" --headless --path . -- --server --autostart %*
