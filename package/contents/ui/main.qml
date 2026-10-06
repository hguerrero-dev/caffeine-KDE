import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // ---- state ----
    // sleepOnly: legacy service (display can sleep). We still detect it so
    // old activations show as ON, but new activations always use fullOn
    // (sleep:idle) so the screen NEVER turns off while active, as requested.
    property bool sleepOnly: false
    property bool fullOn: false
    property bool busy: false

    readonly property bool active: sleepOnly || fullOn

    readonly property string svcSleep: "keep-awake.service"
    readonly property string svcFull: "keep-awake-full.service"

    readonly property string checkSleep: "systemctl --user is-active " + svcSleep
    readonly property string checkFull: "systemctl --user is-active " + svcFull

    // Local coffee-cup icons (bundled SVGs):
    //   off = plain cup, on = cup with steam/humo
    readonly property url iconOff: Qt.resolvedUrl("../images/coffee-off.svg")
    readonly property url iconOn: Qt.resolvedUrl("../images/coffee-on.svg")

    // Panel shows the compact cup; desktop/popups show the full card.
    // Both toggle with one click.
    preferredRepresentation: compactRepresentation

    Plasmoid.icon: "preferences-system-power-management"

    Plasmoid.status: active ? PlasmaCore.Types.ActiveStatus
                            : PlasmaCore.Types.PassiveStatus

    // Right-click menu entry (also toggleable via keyboard once the user
    // assigns a key in the widget's "Keyboard Shortcuts" settings).
    Plasmoid.contextualActions: [toggleAction]

    PlasmaCore.Action {
        id: toggleAction
        text: root.active ? i18n("Turn Off") : i18n("Turn On")
        icon.name: "preferences-system-power-management"
        onTriggered: root.toggle()
    }

    toolTipMainText: i18n("Keep Awake")
    toolTipSubText: !active
        ? i18n("Off — normal power management (click to keep screen on)")
        : i18n("On — system and screen stay awake (click to turn off)")

    // ---- runner ----
    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = (data["stdout"] !== undefined ? data["stdout"] : "").toString().trim()
            disconnectSource(sourceName)

            if (sourceName === root.checkSleep) {
                root.sleepOnly = (stdout === "active")
            } else if (sourceName === root.checkFull) {
                root.fullOn = (stdout === "active")
            } else {
                // start/stop finished — re-poll state shortly after
                root.busy = false
                recheckTimer.restart()
            }
        }

        function run(cmd) {
            disconnectSource(cmd)
            connectSource(cmd)
        }
    }

    function refresh() {
        runner.run(checkSleep)
        runner.run(checkFull)
    }

    function toggle() {
        if (busy) return
        busy = true
        if (active) {
            // Turn OFF: stop both (covers legacy sleep-only too).
            runner.run("systemctl --user stop " + svcSleep + " " + svcFull)
        } else {
            // Turn ON: block suspend AND idle, so the screen stays on.
            runner.run("systemctl --user start " + svcFull)
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    Timer {
        id: recheckTimer
        interval: 400
        repeat: false
        onTriggered: refresh()
    }

    // ---- panel icon: single-click coffee cup ----
    compactRepresentation: Item {
        id: compactRoot

        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small

        // Layer 1 (bottom): theme icon fallback, visible if SVG not ready.
        Kirigami.Icon {
            anchors.fill: parent
            source: "preferences-system-power-management"
            visible: cupImage.status !== Image.Ready
            opacity: root.busy ? 0.6 : 1.0
        }

        // Layer 2: custom coffee cup.
        Image {
            id: cupImage
            anchors.fill: parent
            anchors.margins: 1
            source: root.active ? root.iconOn : root.iconOff
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: root.busy ? 0.6 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            scale: clickArea.containsMouse ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }
        }

        // Layer 3 (top): click catcher.
        MouseArea {
            id: clickArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: root.toggle()
        }
    }

    // ---- full card (desktop widget / expanded view): also one-click ----
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredHeight: Kirigami.Units.gridUnit * 16
        spacing: Kirigami.Units.smallSpacing

        MouseArea {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.enormous
            Layout.preferredHeight: Kirigami.Units.iconSizes.enormous
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: root.toggle()

            Image {
                anchors.fill: parent
                source: root.active ? root.iconOn : root.iconOff
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                opacity: root.busy ? 0.6 : 1.0
            }
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.active ? i18n("Keep Awake is ON") : i18n("Keep Awake is OFF")
            font.bold: true
        }

        PlasmaComponents.Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.largeSpacing
            Layout.rightMargin: Kirigami.Units.largeSpacing
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.7
            text: !root.active
                ? i18n("Click the cup: screen will stay on.")
                : i18n("System and screen stay awake. Click to turn off.")
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            enabled: !root.busy
            text: root.active ? i18n("Turn Off") : i18n("Turn On")
            onClicked: root.toggle()
        }
    }
}
