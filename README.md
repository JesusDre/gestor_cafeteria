# gestor_cafeteria

App Flutter para gestionar los pedidos de una cafetería. Consume la API REST de [`mini_backend`](https://github.com/DMI-2026/mini_backend) mediante un cliente HTTP (`ApiClient`) que traduce cada respuesta de error a un `Failure` tipado: `NotFoundFailure`, `ConflictFailure`, `ValidationFailure`, `ServerFailure`, `UnexpectedFailure` o `NetworkFailure`. El cliente está cubierto por pruebas unitarias con `MockClient`.

Proyecto de la materia Desarrollo Móvil Integral.

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.47.2 (canal stable, Dart 3.13.2), obtenida con `flutter --version` |
| Node.js | 22.13 o superior (lo exige `mini_backend`) |
| Git | Cualquier versión reciente |

## Backend: mini_backend

`mini_backend` es **otro repositorio** y no se incluye en este proyecto.

- **Repositorio:** https://github.com/DMI-2026/mini_backend
- **Versión probada:** commit `94d2533` de la rama `master` (`git rev-parse --short HEAD` en su carpeta).

```powershell
git clone https://github.com/DMI-2026/mini_backend.git
cd mini_backend
git checkout 94d2533   # opcional: usar exactamente la versión probada
```

### Levantar el servidor

No requiere `npm install`; solo usa módulos integrados de Node.js.

```powershell
node server.js
```

El servidor escucha en el **puerto 8000**. Para comprobar que está activo:

```powershell
curl.exe http://localhost:8000/health
# {"status":"ok"}
```

## Ejecutar la app

Primero instala las dependencias:

```powershell
flutter pub get
```

La URL del backend se define con `--dart-define=API_URL=...`. Si no se indica, la app usa `http://localhost:8000` en web y `http://10.0.2.2:8000` en Android.

| Destino | Comando |
|---|---|
| Emulador de Android | `flutter run --dart-define=API_URL=http://10.0.2.2:8000` |
| Chrome | `flutter run -d chrome --dart-define=API_URL=http://localhost:8000` |
| Celular físico | `flutter run --dart-define=API_URL=http://<IP-de-tu-PC>:8000` |

- En el emulador, `10.0.2.2` es la dirección de la computadora anfitriona; `localhost` apuntaría al propio emulador.
- En el celular, la computadora y el teléfono deben estar en la **misma red wifi**. Obtén la IP de la computadora con `ipconfig` (campo "Dirección IPv4").

## Pruebas y análisis

```powershell
flutter test      # pruebas unitarias (Failure y ApiClient con MockClient)
flutter analyze   # análisis estático
```

Las pruebas no usan la red ni el servidor real, así que no hace falta tener `mini_backend` encendido.

## Estructura

```text
lib/
  main.dart                  App de ejemplo que lista los pedidos
  core/
    failure.dart             Jerarquía sellada de Failure
    http_client.dart         ApiClient: peticiones HTTP y mapeo de errores a Failure
test/
  core/
    failure_test.dart        Pruebas de la jerarquía de Failure
    http_client_test.dart    Pruebas de ApiClient con MockClient
android/, web/               Configuración de cada plataforma
```
