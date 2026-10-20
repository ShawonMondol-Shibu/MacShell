import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    implicitWidth: 430
    implicitHeight: 720

    property string processor: "Detecting…"
    property string graphics: "Detecting…"
    property string memory: "Detecting…"
    property string startupDisk: "Detecting…"
    property string systemVersion: "Detecting…"
    property string kernel: ""
    property string cpuCores: ""
    property bool detailsVisible: false

    Process {
        running: true
        command: ["sh", "-c", "cpu=$(lscpu 2>/dev/null | awk -F': *' '/Model name:/ {print $2; exit}'); [ -n \"$cpu\" ] || cpu=$(uname -p); gpu=$(lspci 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' | sed 's/.*: //' | paste -sd ' / ' -); [ -n \"$gpu\" ] || gpu='Integrated graphics'; mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2; exit}'); [ -n \"$mem\" ] || mem='Unknown'; disk=$(findmnt -no SOURCE / 2>/dev/null || echo Unknown); . /etc/os-release 2>/dev/null || true; printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$cpu\" \"$gpu\" \"$mem\" \"$disk\" \"${PRETTY_NAME:-Linux}\" \"$(uname -r)\"; nproc 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var f = (lines[0] || "").split("\t");
                if (f.length >= 6) {
                    root.processor = f[0] || "Unknown processor";
                    root.graphics = f[1] || "Integrated graphics";
                    root.memory = f[2] || "Unknown";
                    root.startupDisk = f[3] || "Unknown";
                    root.systemVersion = f[4] || "Linux";
                    root.kernel = f[5] || "";
                }
                if (lines.length > 1 && lines[1]) root.cpuCores = lines[1] + " logical cores";
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#8f272b" }
            GradientStop { position: 0.52; color: "#711b20" }
            GradientStop { position: 1.0; color: "#4d1117" }
        }
        border.width: 1
        border.color: "#ffffff18"

        Row {
            x: 18; y: 16; spacing: 8
            Repeater {
                model: ["#ff5f57", "#febc2e", "#28c840"]
                delegate: Rectangle {
                    required property string modelData
                    width: 12; height: 12; radius: 6
                    color: modelData
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 46
            width: parent.width - 44
            spacing: 0

            Item {
                width: parent.width; height: 205
                Rectangle {
                    id: laptopScreen
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 8; width: 208; height: 134; radius: 8
                    color: "#17191d"; border.width: 2; border.color: "#aeb2b8"
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 5; radius: 4
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#3c8bc9" }
                            GradientStop { position: 0.55; color: "#1c5b9c" }
                            GradientStop { position: 1; color: "#15263e" }
                        }
                        Text { anchors.centerIn: parent; text: ""; color: "#ffffffcc"; font.pixelSize: 34 }
                    }
                }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 140; width: 252; height: 8; radius: 4; color: "#c8ccd2" }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 147; width: 286; height: 22; radius: 11; color: "#aeb3ba" }
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 153; width: 78; height: 8; radius: 4; color: "#8e949c" }
            }

            Text {
                width: parent.width; text: "MacBook Pro"; horizontalAlignment: Text.AlignHCenter
                color: "white"; font.family: "Open Runde"; font.pixelSize: 29; font.weight: Font.Medium
            }
            Text {
                width: parent.width; topPadding: 6; text: root.systemVersion
                horizontalAlignment: Text.AlignHCenter; color: "#ffffffb8"
                font.family: "Open Runde"; font.pixelSize: 12
            }
            Item { width: 1; height: 20 }
            Rectangle { width: parent.width; height: 1; color: "#ffffff20" }

            component InfoRow: Item {
                required property string label
                required property string value
                width: parent.width; height: 42
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter
                    width: 122; text: label; color: "#ffffffb8"; font.family: "Open Runde"; font.pixelSize: 12
                }
                Text {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 130; text: value; horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight; color: "white"; font.family: "Open Runde"; font.pixelSize: 12
                }
            }

            InfoRow { label: "Processor"; value: root.processor + (root.cpuCores !== "" ? " · " + root.cpuCores : "") }
            InfoRow { label: "Graphics"; value: root.graphics }
            InfoRow { label: "Memory"; value: root.memory }
            InfoRow { label: "Startup Disk"; value: root.startupDisk }
            InfoRow { label: "Serial Number"; value: "••••••••••••" }
            InfoRow { label: "System"; value: root.systemVersion }

            Item { width: 1; height: 8 }
            Rectangle {
                width: parent.width; height: 36; radius: 18
                color: moreMouse.pressed ? "#ffffff28" : "#ffffff16"
                border.width: 1; border.color: "#ffffff28"
                Text { anchors.centerIn: parent; text: root.detailsVisible ? "Hide Details" : "More Info…"; color: "white"; font.family: "Open Runde"; font.pixelSize: 12 }
                MouseArea { id: moreMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.detailsVisible = !root.detailsVisible }
            }
            Rectangle {
                visible: root.detailsVisible; width: parent.width; height: 70; radius: 12
                color: "#00000020"; border.width: 1; border.color: "#ffffff16"
                Column {
                    anchors.fill: parent; anchors.margins: 10; spacing: 5
                    Text { text: "Kernel: " + root.kernel; color: "#ffffffb8"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                    Text { text: "CPU: " + root.cpuCores; color: "#ffffffb8"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter; bottom: 14; width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            text: "Designed by Apple in California.\nRebuilt on Linux by two people who could not afford the Mac."
            color: "#ffffff70"; font.family: "Open Runde"; font.pixelSize: 9
        }
    }
}
