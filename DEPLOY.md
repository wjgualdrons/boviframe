# 🚀 Guía de Despliegue en Vercel

## Configuración de Vercel para Flutter Web

Este proyecto está configurado para desplegarse en Vercel como una aplicación Flutter Web.

### Archivos de Configuración

- `vercel.json`: Configuración principal de Vercel
- `vercel-build.sh`: Script de build que instala Flutter y construye la app
- `package.json`: Scripts de build para desarrollo local

### Variables de Entorno Necesarias

Si tu app usa Firebase u otros servicios que requieren variables de entorno, configura estas en Vercel:

1. Ve a tu proyecto en Vercel Dashboard
2. Settings → Environment Variables
3. Agrega las variables necesarias:
   - `FIREBASE_API_KEY`
   - `FIREBASE_AUTH_DOMAIN`
   - `FIREBASE_PROJECT_ID`
   - etc.

### Despliegue Automático desde GitHub

El proyecto está configurado para desplegarse automáticamente cuando hagas push a la rama `main` en GitHub.

### Despliegue Manual

1. Instala Vercel CLI:
```bash
npm i -g vercel
```

2. Despliega:
```bash
vercel
```

### Solución de Problemas

#### Error: Flutter no encontrado
- El script `vercel-build.sh` instala Flutter automáticamente
- Si falla, verifica que Vercel tenga permisos para ejecutar scripts bash

#### Error: Build falla
- Verifica que todas las dependencias estén en `pubspec.yaml`
- Asegúrate de que no hay código específico de plataforma que no funcione en web

#### Error: Variables de entorno faltantes
- Configura todas las variables necesarias en el dashboard de Vercel

### Build Local para Probar

```bash
# Obtener dependencias
flutter pub get

# Build para web
flutter build web --release

# Probar localmente
cd build/web
python -m http.server 8000
```

### Estructura del Build

El build genera archivos estáticos en `build/web/`:
- `index.html`: Punto de entrada
- `main.dart.js`: Código JavaScript compilado
- Assets y recursos estáticos

### Configuración de Rutas

Vercel está configurado para redirigir todas las rutas a `index.html` para soportar enrutamiento de Flutter Web (SPA).

