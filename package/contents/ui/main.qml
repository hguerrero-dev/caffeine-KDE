import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property bool active: false
    property bool busy: false

    readonly property string activeIcon: "redshift-status-on"
    readonly property string inactiveIcon: "redshift-status-off"

    readonly property string checkCmd: "systemctl --user is-active keep-awake.service"
    readonly property string startCmd: "systemctl --user start keep-awake.service"
    readonly property string stopCmd:  "systemctl --user stop keep-awake.service"

    Plasmoid.icon: active ? activeIcon : inactiveIcon
    Plasmoid.status: active ? PlasmaCore.Types.ActiveStatus
                            : PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Keep Awake")
    toolTipSubText: active
        ? i18n("Active — system will not sleep (screen can still turn off)")
        : i18n("Inactive — normal power management")

    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            const stdout = (data["stdout"] !== undefined ? data["stdout"] : "").toString().trim()
            const exitCode = data["exit code"]
            disconnectSource(sourceName)

            if (sourceName === root.checkCmd) {
                root.active = (stdout === "active")
            } else {
                // start/stop finished — re-poll state shortly after
                root.busy = false
                recheckTimer.restart()
            }
        }

        function run(cmd) {
            // Ensure a fresh run even if the same command was queried recently
            disconnectSource(cmd)
            connectSource(cmd)
        }
    }

    function refresh() {
        runner.run(checkCmd)
    }

    function toggle() {
        if (busy) return
        busy = true
        runner.run(active ? stopCmd : startCmd)
    }

    Timer {
        id: pollTimer
        interval: 5000
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

    compactRepresentation: MouseArea {
        id: compactRoot
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.expanded = !root.expanded
            } else if (mouse.button === Qt.MiddleButton) {
                root.toggle()
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: root.active ? root.activeIcon : root.inactiveIcon
            active: compactRoot.containsMouse
            opacity: root.busy ? 0.6 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.preferredHeight: Kirigami.Units.gridUnit * 11
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
            source: root.active ? root.activeIcon : root.inactiveIcon
            opacity: root.busy ? 0.6 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
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
            text: root.active
                ? i18n("Suspend is blocked. Screen can still turn off normally.")
                : i18n("System will sleep according to power settings.")
        }

        Item { Layout.fillHeight: true }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.largeSpacing
            enabled: !root.busy
            text: root.active ? i18n("Turn Off") : i18n("Turn On")
            icon.name: root.active ? "media-playback-stop" : "media-playback-start"
            onClicked: root.toggle()
        }
    }
}
