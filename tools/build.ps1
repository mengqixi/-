#Requires -Version 7.0
[CmdletBinding()]
param([string]$GodotExe)
$ErrorActionPreference = 'Stop'
$GameRoot = Split-Path $PSScriptRoot -Parent
if (-not $GodotExe) { $GodotExe = Join-Path $GameRoot '.tools\godot\editor\Godot_v4.7.2-stable_win64_console.exe' }
if (-not (Test-Path -LiteralPath $GodotExe)) { throw '请通过 -GodotExe 指定 Godot 4.7.2 控制台版本' }
if (-not (Test-Path -LiteralPath (Join-Path $GameRoot '.tools\godot\windows_release_x86_64.exe'))) { throw '请先执行 tools\fetch-windows-template.ps1' }
$DeliveryDir = Join-Path $GameRoot '交付'
New-Item -ItemType Directory -Path $DeliveryDir -Force | Out-Null
$GameExe = Join-Path $DeliveryDir 'ry马里奥之旅.exe'
$ImportLog = & $GodotExe --headless --path $GameRoot --import 2>&1
$ImportCode = $LASTEXITCODE
if ($ImportCode -ne 0 -or ($ImportLog -match 'SCRIPT ERROR:|^ERROR:')) { $ImportLog | Write-Output; throw '资源导入失败' }
$ExportLog = & $GodotExe --headless --path $GameRoot --export-release 'Windows Desktop' $GameExe 2>&1
$ExportCode = $LASTEXITCODE
if ($ExportCode -ne 0 -or ($ExportLog -match 'SCRIPT ERROR:|^ERROR:')) { $ExportLog | Write-Output; throw '单文件导出失败' }
if (-not (Test-Path -LiteralPath $GameExe)) { throw 'EXE 未生成' }
if (Test-Path -LiteralPath (Join-Path $DeliveryDir 'ry马里奥之旅.pck')) { throw '发现外置 PCK，请检查 embed_pck 配置' }
$GameFile = Get-Item -LiteralPath $GameExe
$ExecutableBytes = [IO.File]::ReadAllBytes($GameExe)
if ($ExecutableBytes[0] -ne 0x4D -or $ExecutableBytes[1] -ne 0x5A) { throw '输出不是 Windows 可执行文件' }
if ([Text.Encoding]::ASCII.GetString($ExecutableBytes,$ExecutableBytes.Length-4,4) -ne 'GDPC') { throw '没有找到嵌入的 Godot 游戏数据尾标记' }
[pscustomobject]@{ File=$GameFile.FullName; SizeMiB=[Math]::Round($GameFile.Length/1MB,2); SHA256=(Get-FileHash -LiteralPath $GameExe -Algorithm SHA256).Hash; EmbeddedPCK=$true } | ConvertTo-Json
