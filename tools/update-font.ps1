#Requires -Version 7.0
[CmdletBinding()]
param([string]$PythonExe = 'python')
$ErrorActionPreference='Stop'
$ProjectRoot=Split-Path $PSScriptRoot -Parent
$FontCache=Join-Path $ProjectRoot '.tools\fonts'
$FontTools=Join-Path $ProjectRoot '.tools\font-tools'
New-Item -ItemType Directory -Path $FontCache -Force | Out-Null
$SourceFont=Join-Path $FontCache 'NotoSansSC.ttf'
if (-not (Test-Path -LiteralPath $SourceFont)) {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf' -OutFile $SourceFont
}
if (-not (Test-Path -LiteralPath (Join-Path $FontTools 'fontTools'))) {
    & $PythonExe -m pip install --target $FontTools fonttools --quiet
    if ($LASTEXITCODE -ne 0) { throw 'fonttools 安装失败' }
}
$PreviousPythonPath=$env:PYTHONPATH
try {
    $env:PYTHONPATH=$FontTools
    $StaticFont=Join-Path $FontCache 'static.ttf'
    & $PythonExe -m fontTools.varLib.instancer $SourceFont 'wght=650' "--output=$StaticFont"
    if ($LASTEXITCODE -ne 0) { throw '字体实例化失败' }
    $TextFiles=@(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'scripts') -Filter '*.gd') + @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'assets\licenses') -Filter '*.txt')
    $FontText=($TextFiles | Get-Content -Raw) -join ''
    $Characters=-join ($FontText.ToCharArray() | Sort-Object -Unique)
    $OutputFont=Join-Path $ProjectRoot 'assets\fonts\AdventureSans.ttf'
    & $PythonExe -m fontTools.subset $StaticFont "--output-file=$OutputFont" "--text=$Characters" '--unicodes=U+0000-00FF,U+2000-206F,U+2190-21FF' '--layout-features=*' '--name-IDs=*' '--name-languages=*' '--notdef-glyph' '--recommended-glyphs'
    if ($LASTEXITCODE -ne 0) { throw '字体子集生成失败' }
    Get-Item -LiteralPath $OutputFont | Select-Object FullName,Length
} finally { $env:PYTHONPATH=$PreviousPythonPath }
