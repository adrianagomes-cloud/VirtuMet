# VirtuMet

Plataforma web progresiva (PWA) para la gestión de clubes deportivos de la Universidad Metropolitana (UNIMET), desarrollada en **Flutter** con **Firebase** (Authentication y Cloud Firestore).

Proyecto del Departamento de Gestión de Proyectos y Sistemas, Sistemas de Información, trimestre 2627. Metodología OpenUP.

## Descripción

VirtuMet centraliza y automatiza la gestión deportiva universitaria: catálogo de disciplinas con cupos en tiempo real, inscripción con validación de estado del estudiante y pago opcional (PayPal Sandbox), ficha deportiva obligatoria, control de asistencia, y un espacio social con avisos, eventos, comunidad y reseñas.

Tiene tres roles, cada uno con su panel:

- **Estudiante:** consulta el catálogo, completa su ficha, se inscribe, y ve sus actividades, avisos y eventos.
- **Entrenador:** consulta a sus estudiantes inscritos, toma asistencia y ve las reseñas de sus disciplinas.
- **Administrador:** gestiona disciplinas, usuarios, fichas e inscripciones, eventos, avisos y estadísticas.

## Requisitos

- Flutter SDK (Dart 3.13 o superior)
- Visual Studio Code con la extensión de Flutter
- Google Chrome
- Git
- En Windows: activar el **Modo de desarrollador** (Configuración, Privacidad y seguridad, Para programadores), necesario para que Flutter cree enlaces simbólicos.

## Instalación y ejecución

La aplicación está en la carpeta `flutter_virtumet`.

```
cd flutter_virtumet
flutter pub get
flutter run -d web-server --web-port 8080
```

Abre `http://localhost:8080`. La primera carga en modo desarrollo es lenta, y la pantalla puede quedar en blanco hasta un minuto. También sirve `flutter run -d chrome`. Para una carga más rápida usa `flutter run -d chrome --release`.

Con la app en ejecución, en la terminal: `r` recarga en caliente, `R` reinicia y `q` detiene.

La conexión a Firebase ya está configurada en `lib/firebase_options.dart` (proyecto `virtumet-d4eff`). Para usar otro proyecto, vuelve a generarla con `flutterfire configure`.

## Despliegue en Firebase Hosting

`firebase.json` y `.firebaserc` ya están configurados. Con una cuenta que tenga acceso al proyecto:

```
npm install -g firebase-tools
firebase login
flutter build web
firebase deploy --only hosting
```

Después, en Firebase Console, Authentication, Configuración, **Dominios autorizados**, comprueba que el dominio publicado esté en la lista, o el inicio de sesión fallará.

## Estructura

| Ruta | Contenido |
|---|---|
| `lib/` | Código Dart, con los archivos agrupados por rol (`student_`, `teacher_`, `admin_`) y utilidades comunes |
| `lib/assets/` | Logotipo y música ambiental |
| `web/` | `index.html`, `manifest.json` (PWA), íconos y script de PayPal |
| `firebase.json`, `.firebaserc` | Configuración de Firebase Hosting y del proyecto |

## Notas

- El pago usa **PayPal en modo Sandbox**: no se mueve dinero real. El Client ID es público y el Client Secret nunca debe incluirse en el repositorio.
- La validación de solvencia se simula con el campo `estado` del estudiante (Activo o Inactivo).
- Las reglas de seguridad de Firestore están en modo de prueba. Deben reemplazarse por reglas por rol antes de un uso real.

## Equipo

Adriana Gomes, Daniel Angulo, Daniel Vera, Sebastian Mendez, Darickson Leiva e Isaac Charco. Grupo 1.
