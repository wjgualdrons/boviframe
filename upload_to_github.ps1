# Script para subir el proyecto a GitHub
# Ejecutar desde PowerShell en la carpeta del proyecto

Write-Host "📦 Preparando proyecto para subir a GitHub..." -ForegroundColor Cyan

# Verificar si Git está disponible
try {
    $gitVersion = git --version 2>&1
    Write-Host "✅ Git encontrado: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "Por favor instala Git desde: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

# Verificar si hay un repositorio Git
if (Test-Path .git) {
    Write-Host "✅ Repositorio Git ya existe" -ForegroundColor Green
} else {
    Write-Host "📝 Inicializando repositorio Git..." -ForegroundColor Cyan
    git init
}

# Verificar remotes
Write-Host "🔍 Verificando remotes..." -ForegroundColor Cyan
$remotes = git remote -v
if ($remotes -match "github.com/AlejandroMendoza334/boviframe") {
    Write-Host "✅ Remote ya configurado" -ForegroundColor Green
} else {
    Write-Host "📝 Agregando remote..." -ForegroundColor Cyan
    git remote add origin https://github.com/AlejandroMendoza334/boviframe.git
}

# Agregar todos los archivos
Write-Host "📝 Agregando archivos..." -ForegroundColor Cyan
git add .

# Verificar si hay cambios para hacer commit
$status = git status --porcelain
if ($status) {
    Write-Host "📝 Haciendo commit..." -ForegroundColor Cyan
    git commit -m "Initial commit: Boviframe Flutter project con soporte offline"
} else {
    Write-Host "ℹ️ No hay cambios para commitear" -ForegroundColor Yellow
}

# Configurar branch main
Write-Host "🌿 Configurando branch main..." -ForegroundColor Cyan
git branch -M main

# Subir a GitHub
Write-Host "🚀 Subiendo a GitHub..." -ForegroundColor Cyan
Write-Host "⚠️  Si es la primera vez, te pedirá credenciales" -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ¡Proyecto subido exitosamente a GitHub!" -ForegroundColor Green
    Write-Host "🔗 Repositorio: https://github.com/AlejandroMendoza334/boviframe" -ForegroundColor Cyan
} else {
    Write-Host "❌ Error al subir. Verifica tus credenciales de GitHub." -ForegroundColor Red
}



