// About This Linux — the system information card for MacShell.
//
// It lives in the Settings window → About pane (MacDock.qml → paneAbout). One shell command detects
// the machine: CPU, GPU, RAM, startup disk, distribution, kernel, chassis type, model and the number
// of logical cores. Every command has a fallback, so the card always shows something sensible.
//
// The picture follows the hardware: a laptop when the chassis says "portable", a desktop tower and
// monitor otherwise. This is a Linux machine and the card says so — no Apple anything.
import QtQuick
import Quickshell
import Quickshell.Io
import "I18n.js" as I18n

Item {
    id: root

    implicitWidth: 430
    implicitHeight: cardContent.implicitHeight + 86

    property string processor: "Unknown processor"
    property string graphics: "Integrated graphics"
    property string memory: "Unknown"
    property string startupDisk: "Unknown"
    property string systemVersion: "Linux"
    property string kernel: "Unknown"
    property string cpuCores: ""
    property string deviceType: "desktop"
    property string deviceModel: "Linux Computer"
    property bool detailsVisible: false

    function toggleDetails() { detailsVisible = !detailsVisible; }

    // One shell command for the whole card. It never fails: every value falls back to something
    // readable, and the fields are printed tab-separated (one line) with the core count on the next.
    Process {
        id: detectProc
        running: true
        command: ["sh", "-c",
            "cpu=$(lscpu 2>/dev/null | awk -F': *' '/Model name:/ {print $2; exit}')\n"
            + "[ -n \"$cpu\" ] || cpu=$(uname -p 2>/dev/null)\n"
            + "[ -n \"$cpu\" ] || cpu=\"Unknown processor\"\n"
            + "gpu=$(lspci 2>/dev/null | grep -Ei 'VGA compatible controller|3D controller|Display controller' | sed 's/.*: //' | paste -sd ' / ' -)\n"
            + "[ -n \"$gpu\" ] || gpu=\"Integrated graphics\"\n"
            + "mem=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2; exit}')\n"
            + "[ -n \"$mem\" ] || mem=\"Unknown\"\n"
            + "disk=$(findmnt -no SOURCE / 2>/dev/null)\n"
            + "[ -n \"$disk\" ] || disk=\"Unknown\"\n"
            + ". /etc/os-release 2>/dev/null || true\n"
            + "os=${PRETTY_NAME:-}\n"
            + "[ -n \"$os\" ] || os=\"Linux\"\n"
            + "kernel=$(uname -r 2>/dev/null)\n"
            + "[ -n \"$kernel\" ] || kernel=\"Unknown\"\n"
            + "cores=$(nproc 2>/dev/null)\n"
            + "[ -n \"$cores\" ] || cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)\n"
            + "[ -n \"$cores\" ] || cores=\"\"\n"
            // chassis: DMI first, then hostnamectl, then dmidecode, then the battery bay
            + "chassis=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null | tr -d '[:space:]')\n"
            + "if [ -z \"$chassis\" ]; then chassis=$(hostnamectl chassis 2>/dev/null | tr -d '\\n' | sed 's/^[Cc]hassis:[[:space:]]*//'); fi\n"
            + "if [ -z \"$chassis\" ] && command -v dmidecode >/dev/null 2>&1; then chassis=$(dmidecode -s chassis-type 2>/dev/null | tr -d '[:space:]'); fi\n"
            + "chassis=$(printf '%s' \"$chassis\" | tr 'A-Z' 'a-z')\n"
            + "case \"$chassis\" in\n"
            + "  8|9|10|11|14|30|31|32|laptop*|notebook*|portable*|hand*held*|convertible*|detachable*|tablet*) kind=laptop ;;\n"
            + "  *) if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then kind=laptop; else kind=desktop; fi ;;\n"
            + "esac\n"
            // the model: vendor + product, e.g. "Dell Latitude 5400"
            + "vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | tr -d '\\n' | sed 's/[[:space:]]*,[[:space:]]*Inc\\.[[:space:]]*$//; s/[[:space:]]*Inc\\.[[:space:]]*$//; s/[.,][[:space:]]*$//; s/^[[:space:]]*//')\n"
            + "product=$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr -d '\\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')\n"
            + "if [ -z \"$product\" ]; then\n"
            + "  if [ \"$kind\" = laptop ]; then product=\"Linux Laptop\"; else product=\"Linux Desktop\"; fi\n"
            + "fi\n"
            + "if [ -n \"$vendor\" ]; then\n"
            + "  case \"$product\" in\n"
            + "    \"$vendor\"*) : ;;\n"
            + "    *) product=\"$vendor $product\" ;;\n"
            + "  esac\n"
            + "fi\n"
            + "printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$cpu\" \"$gpu\" \"$mem\" \"$disk\" \"$os\" \"$kernel\" \"$kind\" \"$product\"\n"
            + "printf '%s\\n' \"$cores\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var f = (lines[0] || "").split("\t");
                if (f.length >= 8) {
                    root.processor = f[0] || "Unknown processor";
                    root.graphics = f[1] || "Integrated graphics";
                    root.memory = f[2] || "Unknown";
                    root.startupDisk = f[3] || "Unknown";
                    root.systemVersion = f[4] || "Linux";
                    root.kernel = f[5] || "Unknown";
                    root.deviceType = f[6] === "laptop" ? "laptop" : "desktop";
                    root.deviceModel = f[7] || (root.deviceType === "laptop" ? "Linux Laptop" : "Linux Desktop");
                }
                if (lines.length > 1 && lines[1]) root.cpuCores = lines[1].trim();
            }
        }
    }

    // ── the laptop ──────────────────────────────────────────────────────────────────────────
    // A thin, dark metallic notebook: rounded lid, thin bezel, a glowing display and a base with a
    // keyboard and a trackpad. No logo, no branding.
    component LaptopIllustration: Item {
        width: 300
        height: 180

        // the shadow on the desktop
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 158; width: 252; height: 12; radius: 6
            color: "#2e000000"
        }

        // the lid
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 8; width: 176; height: 118; radius: 8
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b4047" }
                GradientStop { position: 1; color: "#1e2228" }
            }
            border.width: 1; border.color: "#4e545d"

            // the display
            Rectangle {
                anchors.fill: parent; anchors.margins: 6; radius: 4
                gradient: Gradient {
                    GradientStop { position: 0; color: "#3fa9ee" }
                    GradientStop { position: 0.55; color: "#1a72c4" }
                    GradientStop { position: 1; color: "#0a3a72" }
                }
                // the glow of the display
                Rectangle {
                    anchors.fill: parent; radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#38ffffff" }
                        GradientStop { position: 1; color: "#00ffffff" }
                    }
                }
                // the wallpaper
                Rectangle {
                    anchors.fill: parent; radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#00ffffff" }
                        GradientStop { position: 0.62; color: "#00ffffff" }
                        GradientStop { position: 1; color: "#4d000000" }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "LINUX"
                    color: "#d9ffffff"
                    font.family: "Open Runde"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                // the camera
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2; width: 3; height: 3; radius: 1.5; color: "#1b1f24"
                }
            }
        }

        // the base
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 124; width: 210; height: 26; radius: 3
            gradient: Gradient {
                GradientStop { position: 0; color: "#3c4148" }
                GradientStop { position: 1; color: "#22262c" }
            }
            // the keyboard
            Column {
                x: 14; y: 5
                spacing: 1.2
                Repeater {
                    model: 3
                    delegate: Row {
                        spacing: 1.4
                        Repeater {
                            model: 13
                            delegate: Rectangle { width: 10; height: 2.2; radius: 1; color: "#555c66" }
                        }
                    }
                }
            }
            // the trackpad
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 13; width: 46; height: 9; radius: 2
                color: "#2b3037"
                border.width: 1; border.color: "#4a515a"
            }
        }

        // the front edge of the base
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 149; width: 232; height: 9; radius: 4.5
            gradient: Gradient {
                GradientStop { position: 0; color: "#343941" }
                GradientStop { position: 1; color: "#1a1e23" }
            }
            // the dent you push to open the lid
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 46; height: 3.5; radius: 1.75; color: "#14171b"
            }
        }
    }

    // ── the desktop ─────────────────────────────────────────────────────────────────────────
    // A compact tower next to a monitor on a stand: a plain Linux workstation, no branding.
    component DesktopIllustration: Item {
        width: 300
        height: 180

        // the shadows on the desktop
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 158; width: 250; height: 12; radius: 6
            color: "#2e000000"
        }

        // the monitor
        Rectangle {
            x: 12; y: 14; width: 172; height: 112; radius: 8
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b4047" }
                GradientStop { position: 1; color: "#1e2228" }
            }
            border.width: 1; border.color: "#4e545d"
            // the display
            Rectangle {
                anchors.fill: parent; anchors.margins: 6; radius: 4
                gradient: Gradient {
                    GradientStop { position: 0; color: "#3fa9ee" }
                    GradientStop { position: 0.55; color: "#1a72c4" }
                    GradientStop { position: 1; color: "#0a3a72" }
                }
                Rectangle {
                    anchors.fill: parent; radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#38ffffff" }
                        GradientStop { position: 1; color: "#00ffffff" }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: 4
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#00ffffff" }
                        GradientStop { position: 0.62; color: "#00ffffff" }
                        GradientStop { position: 1; color: "#4d000000" }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "LINUX"
                    color: "#d9ffffff"
                    font.family: "Open Runde"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
            }
        }

        // the stand of the monitor
        Rectangle {
            x: 88; y: 126; width: 20; height: 20
            gradient: Gradient {
                GradientStop { position: 0; color: "#343941" }
                GradientStop { position: 1; color: "#1c2026" }
            }
        }
        Rectangle {
            x: 58; y: 145; width: 80; height: 8; radius: 4
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b4047" }
                GradientStop { position: 1; color: "#20242a" }
            }
        }

        // the tower
        Rectangle {
            x: 218; y: 24; width: 62; height: 132; radius: 8
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b4047" }
                GradientStop { position: 0.6; color: "#262b31" }
                GradientStop { position: 1; color: "#191d22" }
            }
            border.width: 1; border.color: "#4e545d"
            // the front panel
            Rectangle {
                x: 10; y: 14; width: 42; height: 104; radius: 4
                color: "#20252b"
                border.width: 1; border.color: "#31373e"
            }
            // the vents
            Repeater {
                model: 5
                delegate: Rectangle {
                    required property int index
                    x: 18; y: 24 + index * 7; width: 26; height: 2; radius: 1; color: "#0f1215"
                }
            }
            // the power button
            Rectangle {
                x: 28; y: 10; width: 6; height: 6; radius: 3; color: "#4ade80"
            }
            // the drive bay
            Rectangle {
                x: 18; y: 104; width: 26; height: 2; radius: 1; color: "#0f1215"
            }
        }
    }

    // A Loader cannot take an inline component as its sourceComponent (it loads nothing at all),
    // so both illustrations get wrapped in a real Component.
    Component {
        id: laptopComponent
        LaptopIllustration {}
    }
    Component {
        id: desktopComponent
        DesktopIllustration {}
    }

    // One line of the specification list: a bold right-aligned label and the value wrapped next to it.
    component SpecRow: Item {
        required property string label
        required property string value
        width: parent.width
        height: Math.max(labelText.implicitHeight, valueText.implicitHeight)
        Text {
            id: labelText
            width: 96
            text: parent.label
            horizontalAlignment: Text.AlignRight
            color: "#ffffff"
            font.family: "Open Runde"
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Text {
            id: valueText
            x: 108
            width: parent.width - 108
            text: parent.value
            wrapMode: Text.Wrap
            color: "#f2f2f2"
            font.family: "Open Runde"
            font.pixelSize: 13
        }
    }

    // ── the card ────────────────────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: root.implicitHeight
        radius: 18
        clip: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#8f272b" }
            GradientStop { position: 0.52; color: "#711b20" }
            GradientStop { position: 1.0; color: "#4d1117" }
        }
        border.width: 1
        border.color: "#18ffffff"

        // the window controls (they are decoration here: the Settings window owns the real ones)
        Row {
            x: 18; y: 16; spacing: 8
            Repeater {
                model: ["#ff5f57", "#febc2e", "#28c840"]
                delegate: Rectangle {
                    required property string modelData
                    width: 12; height: 12; radius: 6; color: modelData
                }
            }
        }

        Column {
            id: cardContent
            anchors.horizontalCenter: parent.horizontalCenter
            y: 44
            width: parent.width - 44
            spacing: 0

            // the picture of the machine
            Item {
                width: parent.width
                height: 180
                Loader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    sourceComponent: root.deviceType === "laptop" ? laptopComponent : desktopComponent
                }
            }

            // the title
            Text {
                width: parent.width
                text: I18n.tr("About This Linux")
                horizontalAlignment: Text.AlignHCenter
                color: "#ffffff"
                font.family: "Open Runde"
                font.pixelSize: 26
                font.weight: Font.DemiBold
            }

            // the model of the machine
            Text {
                width: parent.width
                topPadding: 4
                text: root.deviceModel
                horizontalAlignment: Text.AlignHCenter
                color: "#b8ffffff"
                font.family: "Open Runde"
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Item { width: 1; height: 16 }
            Rectangle { width: parent.width; height: 1; color: "#20ffffff" }
            Item { width: 1; height: 12 }

            // the specifications
            SpecRow {
                label: I18n.tr("Processor")
                value: root.processor + (root.cpuCores !== "" ? " \u00b7 " + root.cpuCores + I18n.tr(" logical cores") : "")
            }
            SpecRow {
                label: I18n.tr("Graphics")
                value: root.graphics
            }
            SpecRow {
                label: I18n.tr("Memory")
                value: root.memory
            }
            SpecRow {
                label: I18n.tr("Startup Disk")
                value: root.startupDisk
            }
            SpecRow {
                label: I18n.tr("Linux")
                value: root.systemVersion
            }

            Item { width: 1; height: 16 }

            // More Info…
            Item {
                x: Math.max(0, (parent.width - width) / 2)
                width: moreLabel.width + 44
                height: 30
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: moreMouse.pressed ? "#55ffffff" : "#3dffffff"
                    border.width: 1; border.color: "#28ffffff"
                }
                Text {
                    id: moreLabel
                    anchors.centerIn: parent
                    width: implicitWidth
                    text: root.detailsVisible ? I18n.tr("Hide Details") : I18n.tr("More Info…")
                    color: "#ffffff"
                    font.family: "Open Runde"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                MouseArea { id: moreMouse; objectName: "moreInfo"; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleDetails() }
            }

            // the extra rows
            Rectangle {
                x: Math.max(0, (parent.width - width) / 2)
                width: parent.width
                height: detailsCol.implicitHeight + 20; radius: 10
                visible: root.detailsVisible
                color: "#33000000"; border.width: 1; border.color: "#1fffffff"
                Column {
                    id: detailsCol
                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                    Text { text: I18n.tr("Kernel: ") + root.kernel; color: "#c8ffffff"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                    Text { text: I18n.tr("Device: ") + I18n.tr(root.deviceType); color: "#c8ffffff"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                    Text { text: I18n.tr("Model: ") + root.deviceModel; color: "#c8ffffff"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                    Text { text: I18n.tr("Cores: ") + (root.cpuCores !== "" ? root.cpuCores : I18n.tr("Unknown")); color: "#c8ffffff"; font.pixelSize: 11; font.family: "Open Runde"; width: parent.width; elide: Text.ElideRight }
                }
            }

            Item { width: 1; height: 18 }

            // the footer
            Text {
                width: parent.width
                text: I18n.tr("Linux on Hyprland with Quickshell")
                horizontalAlignment: Text.AlignHCenter
                color: "#70ffffff"
                font.family: "Open Runde"
                font.pixelSize: 10
            }
        }
    }
}
