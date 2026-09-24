#!/bin/bash
set -e

echo "🚀 Build para Vercel iniciado..."

# Instalar Flutter si no está disponible
if ! command -v flutter &> /dev/null; then
    echo "📦 Instalando Flutter..."
    
    # Descargar Flutter SDK (usar caché si está disponible)
    FLUTTER_SDK_PATH="${FLUTTER_SDK_PATH:-/tmp/flutter}"
    
    if [ ! -d "$FLUTTER_SDK_PATH" ]; then
        echo "Clonando Flutter SDK..."
        git clone --depth 1 --branch stable https://github.com/flutter/flutter.git $FLUTTER_SDK_PATH
    else
        echo "Usando Flutter SDK existente en caché..."
        cd $FLUTTER_SDK_PATH
        git pull --depth 1 || true
        cd - > /dev/null
    fi
    
    export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
    
    # Verificar instalación
    flutter --version
    flutter doctor -v || true
fi

# Habilitar web
echo "🌐 Habilitando soporte web..."
flutter config --enable-web || true

# Obtener dependencias (usar caché de pub si existe)
echo "📦 Obteniendo dependencias..."
flutter pub get

# Limpiar solo lo necesario (no limpiar todo para ahorrar tiempo)
echo "🧹 Limpiando builds web anteriores..."
rm -rf build/web || true

# Build para web
echo "🔨 Construyendo para web..."
flutter build web --release --base-href="/" --web-renderer canvaskit

echo "✅ Build completado! Archivos en build/web/"
if [ -d "build/web" ]; then
    echo "Archivos generados:"
    ls -la build/web/ | head -20
else
    echo "❌ Error: build/web no existe"
    exit 1
fi

