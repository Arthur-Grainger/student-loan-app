# Minimal static file server for local preview (no Node/Python needed).
# Usage: powershell -ExecutionPolicy Bypass -File dev\serve.ps1 [-Port 8123]
param([int]$Port = 8123)

$Root = Split-Path $PSScriptRoot -Parent
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Serving $Root at http://localhost:$Port/ (Ctrl+C to stop)"

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "text/javascript; charset=utf-8"
  ".mjs"  = "text/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  if ($path.EndsWith("/")) { $path = $path + "index.html" }
  $file = Join-Path $Root ($path.TrimStart("/") -replace "/", "\")
  $fullRoot = (Resolve-Path $Root).Path
  $fullFile = $null
  try { $fullFile = (Resolve-Path $file -ErrorAction Stop).Path } catch {}
  if ($fullFile -and $fullFile.StartsWith($fullRoot) -and (Test-Path $fullFile -PathType Leaf)) {
    $bytes = [System.IO.File]::ReadAllBytes($fullFile)
    $ext = [System.IO.Path]::GetExtension($fullFile).ToLower()
    if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
    $b = [System.Text.Encoding]::UTF8.GetBytes("Not found: $path")
    $ctx.Response.OutputStream.Write($b, 0, $b.Length)
  }
  $ctx.Response.Close()
}
