$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Установите Flutter SDK и добавьте flutter в PATH.'
}
if ((Test-Path android) -or (Test-Path ios)) {
    throw 'Платформы уже существуют. Проверьте настройки по README.'
}
$source = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'lib/main.dart'))
$pubspec = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'pubspec.yaml'))
try {
    flutter create --platforms=android,ios --empty --no-pub --project-name=students_lab --org=org.studentlab .
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось сгенерировать платформы Flutter.' }
} finally {
    [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'lib/main.dart'), $source)
    [IO.File]::WriteAllBytes((Join-Path $PSScriptRoot 'pubspec.yaml'), $pubspec)
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Не удалось установить зависимости Flutter.' }
Write-Host 'Далее настройте Firebase, URL-схемы и AndroidManifest.xml по README.'
