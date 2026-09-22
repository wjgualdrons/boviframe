<#
scripts\setup_and_init.ps1
Comprueba la presencia de Flutter, Node y sqlite3 en la máquina.
- Ejecuta `flutter pub get` si Flutter está instalado.
- Inicializa la base de datos del usuario usando (preferente) Node script (instala sqlite3 con --no-save)
  o, si no existe Node pero existe sqlite3 CLI, usa el script PowerShell existente.

Uso:
  .\scripts\setup_and_init.ps1 -UserId <id> -Email <email>
#>

param (
  [Parameter(Mandatory=$false)] [string]$UserId = "testuser",
  [Parameter(Mandatory=$false)] [string]$Email = "test@example.com"
)

$projectRoot = Split-Path -Parent $PSScriptRoot
Write-Host "Proyecto: $projectRoot"
Set-Location $projectRoot

function Has-Command($name) {
  return (Get-Command $name -ErrorAction SilentlyContinue) -ne $null
}

$hasFlutter = Has-Command flutter
$hasNode = Has-Command node
$hasNpm = Has-Command npm
$hasSqliteCli = Has-Command sqlite3

if ($hasFlutter) {
  Write-Host "Flutter detectado. Ejecutando: flutter pub get"
  try {
    flutter pub get
    Write-Host "flutter pub get completado."
  } catch {
    Write-Warning "flutter pub get falló: $_"
  }
} else {
  Write-Host "Flutter no detectado en PATH. Omite flutter pub get."
}

$storageDir = Join-Path $projectRoot 'storage\db'
if (-not (Test-Path $storageDir)) { New-Item -ItemType Directory -Path $storageDir -Force | Out-Null }
$targetDb = Join-Path $storageDir ("$UserId.sqlite")

if (Test-Path $targetDb) {
  Write-Host "La DB del usuario ya existe: $targetDb. Se omitirá la inicialización."
  exit 0
}

# Preferir Node path
if ($hasNode) {
  Write-Host "Node disponible. Preparando a ejecutar scripts/init_user_db.js"
  # Instalar sqlite3 temporalmente para este proyecto sin modificar package.json
  if ($hasNpm) {
    Write-Host "npm detectado. Instalando sqlite3 (sin guardar en package.json)..."
    try {
      npm install sqlite3 --no-save
      Write-Host "sqlite3 instalado (node module)."
    } catch {
      Write-Warning "npm install sqlite3 falló: $_"
    }
  } else {
    Write-Host "npm no encontrado. Intentando ejecutar node script sin instalar dependencias (puede fallar)."
  }

  Write-Host "Ejecutando: node scripts\init_user_db.js $UserId $Email"
  try {
    node "scripts/init_user_db.js" $UserId $Email
    Write-Host "Inicialización vía Node completada. DB creada en: $targetDb"
    exit 0
  } catch {
    Write-Warning "Ejecución del script Node falló: $_"
    # continuar a la alternativa si sqlite3 CLI existe
  }
}

if ($hasSqliteCli) {
  Write-Host "sqlite3 CLI detectado. Ejecutando scripts/init_user_db.ps1 con sqlite3"
  try {
    & .\scripts\init_user_db.ps1 -UserId $UserId -Email $Email
    Write-Host "Inicialización vía sqlite3 CLI completada. DB creada en: $targetDb"
    exit 0
  } catch {
    Write-Warning "Ejecución del script PowerShell falló: $_"
    exit 2
  }
}

Write-Warning "No se encontró Node ni sqlite3 CLI. No se pudo inicializar la DB automáticamente."
Write-Host "Opciones:
 - Instalar Node y ejecutar este script de nuevo (preferido), o
 - Instalar sqlite3 CLI y ejecutar: .\scripts\init_user_db.ps1 -UserId <id> -Email <email>, o
 - Desde la app Flutter (una vez instalado flutter), ejecutar la pantalla de ejemplo creada en lib/screens/db_init_example.dart"

exit 3
