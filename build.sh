#!/bin/bash
set -e

echo "🚀 Iniciando build de Flutter Web..."

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado"
    echo "📦 Instalando Flutter..."
    
    # Instalar Flutter en el sistema
    FLUTTER_VERSION="3.24.5"
    FLUTTER_SDK_PATH="$HOME/flutter"
    
    if [ ! -d "$FLUTTER_SDK_PATH" ]; then
        git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_SDK_PATH
    fi
    
    export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
fi

# Verificar Flutter doctor
flutter doctor

# Obtener dependencias
echo "📦 Obteniendo dependencias..."
flutter pub get

# Limpiar build anterior
echo "🧹 Limpiando builds anteriores..."
flutter clean

# Construir para web
echo "🔨 Construyendo para web..."
flutter build web --release --base-href="/"

echo "✅ Build completado exitosamente!"

