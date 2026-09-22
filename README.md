# boviframe

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Inicialización de base de datos por usuario (SQLite)

BoviFrame usa una base de datos SQLite por usuario: cada usuario tiene un archivo
storage/db/{user_id}.sqlite que contiene su propio esquema y evaluaciones.
Al registrarse, la aplicación debe crear ese archivo y ejecutar el esquema
ubicado en db/schema.sqlite.sql.

Scripts incluidos:
- scripts/init_user_db.js — Node.js (requiere sqlite3). Uso:
  npm install sqlite3 && node scripts/init_user_db.js <user_id> <email>
- scripts/init_user_db.ps1 — PowerShell (requiere sqlite3 CLI). Uso:
  .\scripts\init_user_db.ps1 -UserId <id> -Email <email>

Notas:
- Hacer backup de storage/db si se requiere persistencia y recuperación.
- Para sincronización o despliegues multiusuario considerar PostgreSQL y
  una estrategia multitenant (esquema por usuario o DB dedicada) e incluir
  migraciones centralizadas.

## Generar instalable Android (release)

Pasos rápidos para crear APK/AAB release en Android (requiere Flutter en PATH):

1. Preparar keystore (solo la primera vez):
   - keytool -genkey -v -keystore ~/bovikey.jks -alias boviframe -keyalg RSA -keysize 2048 -validity 10000
   - Guarda el keystore fuera del repositorio y crea android/key.properties con las credenciales.
2. Configura signingConfig en android/app/build.gradle (plantilla Flutter estándar).
3. En la raíz del proyecto ejecutar (Linux/macOS):
   - ./scripts/build_android.sh
   o PowerShell (Windows):
   - .\scripts\build_android.ps1
4. Archivos generados:
   - APK: build/app/outputs/flutter-apk/app-release.apk
   - AAB: build/app/outputs/bundle/release/app-release.aab
5. Instalar APK en dispositivo (requiere adb):
   - adb install -r build/app/outputs/flutter-apk/app-release.apk

Nota: No subas el keystore ni credenciales al repositorio. Para CI/CD recomendamos crear un workflow que firme y publique automáticamente a Play Console.

