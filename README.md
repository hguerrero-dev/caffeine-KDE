# ☕ Caffeine KDE

Widget para **KDE Plasma 6** con forma de **taza de café** que evita que tu
computadora se suspenda y que la pantalla se apague. Un clic (o un atajo de
teclado) y listo.

- **Apagado:** taza sola → todo normal, la pantalla se puede apagar y el equipo suspender.
- **Encendido:** taza con humo naranja → el sistema **no** se suspende y la pantalla **no** se apaga.

> Fork de [keep-awake-kde](https://github.com/burakgon/keep-awake-kde) de Burak,
> rediseñado: icono de café propio, toggle con un solo clic (sin popup),
> atajo global de teclado e instalador único que hace todo.

---

## ✨ Características

- 🖱️ **Un solo clic** en la taza para encender/apagar. Sin ventanas ni menús.
- ⌨️ **Atajo global `Super + Alt + C`** que funciona desde cualquier aplicación.
- 🔄 **El icono se actualiza solo**: si cambias el estado con el clic, el atajo o la terminal, la taza lo refleja en ~2 segundos.
- 🖥️ **Vista completa**: si agregas el widget al escritorio verás una tarjeta grande con botón Encender/Apagar.
- 🧊 **Liviano**: sin demonios propios. Todo el trabajo lo hacen `systemd` y Plasma; el widget solo enciende/apaga servicios.
- 🛠️ **Un solo instalador**: `./install.sh` hace absolutamente todo.

## ✅ Requisitos

- **KDE Plasma 6** (probado en Plasma 6.7, Fedora / Wayland).
- `systemd` con user manager (estándar en casi todas las distros).
- `kpackagetool6` (viene con Plasma 6).
- `python3` + `dbus-python` (para registrar el atajo; casi siempre ya instalados).
- `git` para clonar el repo.

## 📦 Instalación paso a paso

```bash
git clone git@github.com:hguerrero-dev/caffeine-KDE.git
cd caffeine-KDE
./install.sh
```

Eso es todo. El script hace **5 pasos** automáticamente:

| Paso | Qué hace |
| ---- | -------- |
| 1/5 | Copia los servicios `keep-awake.service` y `keep-awake-full.service` a `~/.config/systemd/user/` y recarga systemd. |
| 2/5 | Instala o actualiza el widget con `kpackagetool6` en `~/.local/share/plasma/plasmoids/`. |
| 3/5 | Instala el comando `keep-awake-toggle` en `~/.local/bin/`. |
| 4/5 | Crea el lanzador `.desktop`, lo registra en `kglobalshortcutsrc` y lo **activa en caliente** con `Super + Alt + C` (sin cerrar sesión). |
| 5/5 | Te pregunta si quieres reiniciar Plasma para recargar el widget al instante. |

Después agrega el widget a tu barra:

1. Clic derecho en el panel → **Add or Manage Widgets**.
2. Busca **Caffeine KDE** → **Add**.
3. Cierra el editor. Verás la taza marrón ☕.

> Puedes correr `./install.sh` cuantas veces quieras: es **idempotente** (no duplica nada).

### Cambiar la tecla del atajo

```bash
SHORTCUT_KEY="Meta+Alt+X" ./install.sh
# o solo re-registrar la tecla:
SHORTCUT_KEY="Meta+Alt+X" ./setup-shortcut.sh
```

Verifica que la combinación esté libre antes (p. ej. `Super+Alt+K` ya la usa el cambio de idioma).

## 🚀 Uso

| Acción | Resultado |
| ------ | --------- |
| **Clic izquierdo** en la taza | Alterna ON/OFF |
| **Clic central** en la taza | Alterna ON/OFF |
| **Clic derecho** en la taza | Menú con Encender/Apagar |
| **`Super + Alt + C`** en cualquier lado | Alterna ON/OFF |
| Pasar el mouse por encima | Tooltip con el estado actual |

Desde terminal (útil para alias, scripts o gestos):

```bash
keep-awake-toggle                                  # alterna
systemctl --user start keep-awake-full.service     # forzar ON
systemctl --user stop keep-awake.service keep-awake-full.service   # forzar OFF
systemd-inhibit --list | grep keep-awake           # ver el bloqueo activo
systemctl --user is-active keep-awake-full.service # active = ON, inactive = OFF
```

## 🛠️ Cómo funciona

```
 ┌──────────────┐  1 clic / atajo / comando   ┌──────────────────────────┐  systemd-inhibit  ┌──────────────┐
 │ Widget QML   │ ─────────────────────────▶ │ keep-awake-full.service │ ────────────────▶ │ logind lock  │
 │ (taza café)  │  systemctl --user           │ sleep infinity          │  --what=sleep:idle │ --mode=block │
 └──────┬───────┘  start/stop                 └──────────────────────────┘                   └──────────────┘
        │                ▲ polling cada 2 s: systemctl --user is-active
        └────────────────┘
```

- **ON** = corre `keep-awake-full.service`, que ejecuta
  `systemd-inhibit --what=sleep:idle --mode=block sleep infinity`.
  Se bloquea la suspensión **y** la detección de inactividad (la pantalla no se apaga).
- **OFF** = ambos servicios detenidos, sin locks. Todo vuelve a lo normal.
- El widget **no guarda estado propio**: cada 2 segundos pregunta a systemd
  (`systemctl --user is-active ...`), así el icono siempre muestra la realidad
  aunque cambies el estado desde otro lado.
- El atajo global vive en KWin (`org.kde.kglobalaccel`) como componente
  `keep-awake-toggle.desktop`, acción `_launch`, registrado por
  `setup-shortcut.sh` vía D-Bus (sin cerrar sesión). Al presionarlo, KWin
  ejecuta `keep-awake-toggle` y el widget lo refleja solo.

## 🧰 Con qué está hecho / herramientas

| Parte | Tecnología |
| ----- | ---------- |
| Interfaz del widget | **QML** (`QtQuick`, `QtQuick.Layouts`, `QtQuick.Controls`) + APIs de Plasma 6 (`org.kde.plasma.plasmoid`, `PlasmaCore`, `PlasmaComponents`, `Kirigami`) |
| Lógica de encendido | `systemd` user units + `systemd-inhibit` (sin demonios propios) |
| Instalación y toggle | **Bash** (`install.sh`, `uninstall.sh`, `toggle.sh`, `setup-shortcut.sh`) |
| Registro del atajo | **Python 3** + `dbus-python` contra `org.kde.kglobalaccel` (KWin), config en `kglobalshortcutsrc`, lanzador `.desktop` |
| Iconos | **SVG** propios (`package/contents/images/coffee-off.svg`, `coffee-on.svg`): taza marrón visible en paneles claros y oscuros, humo naranja solo en ON |

### Estructura del repo

```
caffeine-KDE/
├── install.sh                        # instalador único (haz solo esto)
├── uninstall.sh                      # desinstalador completo
├── setup-shortcut.sh                 # registra el atajo (lo llama install.sh)
├── toggle.sh                         # lógica on/off → se instala como keep-awake-toggle
├── package/
│   ├── metadata.json                 # nombre "Caffeine KDE", versión, icono
│   └── contents/
│       ├── ui/main.qml               # widget: taza + polling + tarjeta completa
│       ├── images/coffee-off.svg     # taza sola (OFF)
│       ├── images/coffee-on.svg      # taza con humo (ON)
│       └── config/main.xml           # (reservado, sin opciones por ahora)
├── systemd/
│   ├── keep-awake.service            # compat: bloquea solo suspensión
│   └── keep-awake-full.service       # el que se usa: bloquea suspensión + pantalla
└── README.md
```

> Nota técnica: el ID interno del plasmoid (`com.burakgon.keepawake`) y los
> nombres de los servicios se conservan del proyecto original a propósito,
> para que actualizar no deje widgets fantasmas en el panel.

## 🎨 Personalización

- **Otra tecla**: `SHORTCUT_KEY="Meta+Alt+X" ./setup-shortcut.sh`.
- **Otros iconos**: reemplaza los dos `.svg` en `package/contents/images/`
  (mismo nombre de archivo) y corre `./install.sh`.
- **Polling más rápido/lento**: cambia `interval: 2000` (ms) en `main.qml`.

## 🧪 Verifica que hace lo que crees

1. Ajustes → Energía: **apagar pantalla en 1 min**, **suspender en 2 min**.
2. Activa la taza (clic o `Super+Alt+C`).
3. Aléjate 3 minutos.
4. La pantalla **no** debe apagarse. Con la taza apagada, sí se apaga normal.

## 🧹 Desinstalación

```bash
./uninstall.sh
```

Detiene los servicios, borra units, widget, comando, lanzador y atajo.
Quita el widget del panel si aún está ahí.

## ❓ Problemas comunes

- **Agrego el widget y sale un hueco en blanco**: tenías la versión vieja en
  memoria. Reinicia Plasma (`systemctl --user restart plasma-plasmashell.service`),
  quita el hueco y vuelve a agregar **Caffeine KDE**.
- **El atajo no hace nada**: confirma que esté registrado con
  `grep -A2 keep-awake-toggle ~/.config/kglobalshortcutsrc` y que la
  combinación esté libre. Re-corre `./setup-shortcut.sh`.
- **La pantalla igual se apaga estando ON**: algunos drivers/powerdevil
  ignoran inhibits (bugs conocidos de KDE). Prueba con `systemd-inhibit --list`.

## 📄 Licencia y créditos

MIT (ver [LICENSE](LICENSE)).
Proyecto original [keep-awake-kde](https://github.com/burakgon/keep-awake-kde)
por Burak; modificaciones Caffeine KDE por
[hguerrero-dev](https://github.com/hguerrero-dev).
