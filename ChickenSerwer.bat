@echo off
rem ChickenSerwer — serwer dedykowany Chicken RPG (okno z konfiguracja, logiem i konsola komend).
rem Gracze dolaczaja zwyklym ChickenRPG: menu -> "Serwer online" -> IP serwera, port 7777 (UDP).
rem Dla graczy z internetu przekieruj w routerze port UDP 7777 na ten komputer (UPnP probuje to zrobic sam).
cd /d "%~dp0"
start "" "Godot_v4.7.2-stable_win64.exe" --path . -- --server
