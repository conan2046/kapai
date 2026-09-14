@echo off
chcp 65001 >nul
REM kapai 单机版 GM 后台 —— 本地 Web 控制台启动脚本
REM 前提: 本地 LocalServer(kapai.exe) 已运行(进入 Unity Play 即自动起服, 端口 8711)
REM 启动后会自动打开浏览器; 端口默认 8081(8080 被 Unity MCP 占用)
cd /d "%~dp0"

where python >nul 2>nul
if %errorlevel%==0 (
  python gm_web.py
) else (
  py -3 gm_web.py
)
pause
