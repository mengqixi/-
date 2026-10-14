#Requires -Version 7.0
[CmdletBinding()]
param([string]$Version = '4.7.2-stable')
$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ToolDir = Join-Path $ProjectRoot '.tools\godot'
New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
$Release = Invoke-RestMethod "https://api.github.com/repos/godotengine/godot/releases/tags/$Version" -Headers @{ 'User-Agent' = 'JumpAdventure' }
$Asset = $Release.assets | Where-Object name -eq "Godot_v$Version`_export_templates.tpz"
if (@($Asset).Count -ne 1) { throw '没有找到匹配的导出模板' }
function Get-ArchiveRange([long]$Start, [long]$End) {
    $Response = Invoke-WebRequest -Uri $Asset.browser_download_url -Headers @{ Range = "bytes=$Start-$End" }
    if ($Response.StatusCode -ne 206 -or $Response.RawContentLength -ne ($End-$Start+1)) { throw '服务器未返回预期的字节区间' }
    return ,([byte[]]$Response.Content)
}
# 只下载 ZIP 中的 Windows x64 发布模板，不下载其他平台的大体积文件。
$TailStart = [long]$Asset.size - 65536
$Tail = Get-ArchiveRange $TailStart ([long]$Asset.size-1)
$EndRecord = -1
for ($Index = $Tail.Length-22; $Index -ge 0; $Index--) {
    if ([BitConverter]::ToUInt32($Tail,$Index) -eq 0x06054b50) { $EndRecord=$Index; break }
}
if ($EndRecord -lt 0) { throw 'ZIP 中央目录不存在' }
$DirectorySize = [BitConverter]::ToUInt32($Tail,$EndRecord+12)
$DirectoryOffset = [BitConverter]::ToUInt32($Tail,$EndRecord+16)
$Directory = Get-ArchiveRange $DirectoryOffset ($DirectoryOffset+$DirectorySize-1)
$Cursor=0
$Found=$false
while ($Cursor -lt $Directory.Length) {
    if ([BitConverter]::ToUInt32($Directory,$Cursor) -ne 0x02014b50) { throw 'ZIP 目录格式错误' }
    $NameLength=[BitConverter]::ToUInt16($Directory,$Cursor+28)
    $ExtraLength=[BitConverter]::ToUInt16($Directory,$Cursor+30)
    $CommentLength=[BitConverter]::ToUInt16($Directory,$Cursor+32)
    $EntryName=[Text.Encoding]::UTF8.GetString($Directory,$Cursor+46,$NameLength)
    if ($EntryName -eq 'templates/windows_release_x86_64.exe') {
        $Method=[BitConverter]::ToUInt16($Directory,$Cursor+10)
        $CompressedSize=[BitConverter]::ToUInt32($Directory,$Cursor+20)
        $UncompressedSize=[BitConverter]::ToUInt32($Directory,$Cursor+24)
        $LocalOffset=[BitConverter]::ToUInt32($Directory,$Cursor+42)
        $Found=$true
        break
    }
    $Cursor+=46+$NameLength+$ExtraLength+$CommentLength
}
if (-not $Found) { throw '没有找到 Windows x64 发布模板' }
$Header=Get-ArchiveRange $LocalOffset ($LocalOffset+29)
if ([BitConverter]::ToUInt32($Header,0) -ne 0x04034b50) { throw 'ZIP 本地记录错误' }
$DataOffset=$LocalOffset+30+[BitConverter]::ToUInt16($Header,26)+[BitConverter]::ToUInt16($Header,28)
$Compressed=Get-ArchiveRange $DataOffset ($DataOffset+$CompressedSize-1)
$OutputPath=Join-Path $ToolDir 'windows_release_x86_64.exe'
$Output=[IO.File]::Create($OutputPath)
try {
    if ($Method -eq 8) {
        $InputStream=[IO.MemoryStream]::new($Compressed,$false)
        $Inflater=[IO.Compression.DeflateStream]::new($InputStream,[IO.Compression.CompressionMode]::Decompress)
        try { $Inflater.CopyTo($Output) } finally { $Inflater.Dispose(); $InputStream.Dispose() }
    } elseif ($Method -eq 0) { $Output.Write($Compressed) } else { throw "不支持压缩方式 $Method" }
} finally { $Output.Dispose() }
if ((Get-Item -LiteralPath $OutputPath).Length -ne $UncompressedSize) { throw '解压后模板大小错误' }
Get-Item -LiteralPath $OutputPath | Select-Object FullName,Length
