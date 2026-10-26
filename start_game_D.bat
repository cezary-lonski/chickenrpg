@echo off
rem Uruchamia grę tak, żeby zapisy i ustawienia Godota leżały na dysku D: (D:\GodotData\Godot\app_userdata\Chicken Brawl).
rem Folder D:\GodotData\Godot już zawiera kopię obecnych zapisów.
set APPDATA=D:\GodotData
start "" "%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe" --path "%~dp0"
