import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateFilePath: home + "/.local/state/omarchy/omabeacon/state.json"
  readonly property string cliPath: Qt.resolvedUrl("bin/omabeacon").toString().replace(/^file:\/\//, "")

  readonly property var fxModes: ["clean", "pulse", "copper", "scramble", "marquee", "stealth"]
  readonly property var hudStyles: ["wire", "laser", "amiga", "glitch", "brutal"]
  readonly property var hudPositions: ["top", "center", "bottom"]
  readonly property var palette: [
    "#7aa2f7", // 1: electric blue
    "#bb9af7", // 2: neon violet
    "#7dcfff", // 3: cyan
    "#9ece6a", // 4: acid green
    "#e0af68", // 5: amber
    "#f7768e", // 6: crimson
    "#ff9e64", // 7: tangerine
    "#73daca", // 8: mint
    "#c0caf5"  // 9: ice
  ]

  property bool opened: false
  property int editWsId: 1
  property string selectedColor: ""
  property var workspacesData: ({})
  property string fxMode: "clean"
  property string hudStyle: "brutal"
  property string hudPos: "center"
  property bool autoSense: true
  property bool flashHud: true
  property string sensedSummary: ""

  readonly property color background: Color.menu.background
  readonly property color foreground: Color.menu.text
  readonly property color border: Color.menu.border
  readonly property color scrim: Color.menu.scrim
  readonly property color selectedBackground: Color.menu.selectedBackground
  readonly property color selectedText: Color.menu.selectedText
  readonly property string fontFamily: Style.font.menuFamily
  readonly property string monoFamily: Style.font.monoFamily || "monospace"

  readonly property color activeAccent: {
    if (selectedColor !== "") return selectedColor
    return palette[(Math.max(1, editWsId) - 1) % palette.length]
  }

  function open(payloadJson) {
    loadState()
    var ws = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id) ? Hyprland.focusedWorkspace.id : 1
    selectWorkspace(ws)
    root.opened = true
    Qt.callLater(function() {
      noteInput.forceActiveFocus()
      noteInput.selectAll()
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide((root.manifest && root.manifest.id) || "heelgueta.omabeacon")
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function selectWorkspace(wsId) {
    root.editWsId = wsId
    var entry = (root.workspacesData && root.workspacesData[String(wsId)]) ? root.workspacesData[String(wsId)] : null
    noteInput.text = (entry && entry.note) ? String(entry.note) : ""
    root.selectedColor = (entry && entry.color) ? String(entry.color) : ""
    root.sensedSummary = ""
    runSense(wsId)
    Qt.callLater(function() {
      noteInput.forceActiveFocus()
      noteInput.selectAll()
    })
  }

  function saveAndDismiss() {
    var txt = noteInput.text.trim()
    if (txt === "") {
      Quickshell.execDetached([root.cliPath, "clear", String(root.editWsId)])
    } else {
      var cmd = [root.cliPath, "set", String(root.editWsId), txt]
      if (root.selectedColor !== "") {
        cmd.push("--color")
        cmd.push(root.selectedColor)
      }
      Quickshell.execDetached(cmd)
    }
    root.dismiss()
  }

  function clearAndDismiss() {
    Quickshell.execDetached([root.cliPath, "clear", String(root.editWsId)])
    root.dismiss()
  }

  function runSense(wsId) {
    if (senseProc.running) senseProc.running = false
    senseProc.buf = ""
    senseProc.command = [root.cliPath, "sense", String(wsId)]
    senseProc.running = true
  }

  FileView {
    id: stateWatcher
    path: root.stateFilePath
    watchChanges: true
    onLoaded: root.loadState()
    onFileChanged: reload()
  }

  function loadState() {
    var txt = stateWatcher.text()
    if (!txt) return
    try {
      var data = JSON.parse(txt)
      root.workspacesData = data.workspaces || ({})
      root.fxMode = data.fx || "clean"
      root.hudStyle = data.hudStyle || "brutal"
      root.hudPos = data.hudPos || "center"
      root.autoSense = (data.autoSense === undefined) ? true : !!data.autoSense
      root.flashHud = (data.flashHud === undefined) ? true : !!data.flashHud
    } catch (e) {}
  }

  Process {
    id: senseProc
    property string buf: ""
    stdout: SplitParser {
      onRead: data => { senseProc.buf += data }
    }
    onExited: (code) => {
      if (code === 0) root.sensedSummary = senseProc.buf.trim()
      senseProc.buf = ""
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-omabeacon"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Scrim backdrop
    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: root.opened ? 1 : 0

      MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
      }

      // Main card
      Rectangle {
        id: card
        width: Math.min(Style.space(540), parent.width - Style.gapsOut * 2)
        height: cardCol.implicitHeight + Style.space(32)
        anchors.centerIn: parent
        radius: Style.cornerRadius
        color: root.background
        border.width: 1.5
        border.color: root.activeAccent

        // Absorb clicks inside card
        MouseArea { anchors.fill: parent }

        ColumnLayout {
          id: cardCol
          anchors.fill: parent
          anchors.margins: Style.space(16)
          spacing: Style.space(12)

          // Header row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Rectangle {
              width: Style.space(10)
              height: Style.space(10)
              radius: width / 2
              color: root.activeAccent
            }

            Text {
              text: "WORKSPACE " + root.editWsId
              color: root.activeAccent
              font.family: root.monoFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Fill from local sense button
            Rectangle {
              visible: root.sensedSummary !== "" && root.sensedSummary !== "empty"
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              border.width: 1
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
              implicitWidth: senseBtnTxt.implicitWidth + Style.space(14)
              implicitHeight: Style.space(24)

              Text {
                id: senseBtnTxt
                anchors.centerIn: parent
                text: "⚡ Use Sense (Ctrl+S)"
                color: root.foreground
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  noteInput.text = root.sensedSummary
                  noteInput.forceActiveFocus()
                }
              }
            }

            // Clear button
            Rectangle {
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              implicitWidth: clearBtnTxt.implicitWidth + Style.space(12)
              implicitHeight: Style.space(24)

              Text {
                id: clearBtnTxt
                anchors.centerIn: parent
                text: "Clear"
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAndDismiss()
              }
            }
          }

          // Text input box
          Rectangle {
            Layout.fillWidth: true
            height: Style.space(42)
            radius: Style.space(6)
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
            border.width: 1.5
            border.color: noteInput.activeFocus ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)

            TextInput {
              id: noteInput
              anchors.fill: parent
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              verticalAlignment: TextInput.AlignVCenter
              color: root.foreground
              selectionColor: root.activeAccent
              selectedTextColor: root.background
              font.family: root.fontFamily
              font.pixelSize: Style.font.title || 16
              clip: true

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "What is this workspace about? (Enter to save, Esc to cancel)"
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
                font: noteInput.font
                visible: noteInput.text === ""
              }

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  event.accepted = true
                  root.saveAndDismiss()
                } else if (event.key === Qt.Key_Escape) {
                  event.accepted = true
                  root.dismiss()
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Backspace) {
                  event.accepted = true
                  root.clearAndDismiss()
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                  event.accepted = true
                  if (root.sensedSummary !== "" && root.sensedSummary !== "empty") {
                    noteInput.text = root.sensedSummary
                  }
                } else if ((event.modifiers & Qt.ControlModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                  event.accepted = true
                  root.selectedColor = root.palette[event.key - Qt.Key_1]
                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_0) {
                  event.accepted = true
                  root.selectedColor = ""
                } else if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                  event.accepted = true
                  root.selectWorkspace(event.key - Qt.Key_0)
                } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_0) {
                  event.accepted = true
                  root.selectWorkspace(10)
                }
              }
            }
          }

          // Local sense readout
          Text {
            Layout.fillWidth: true
            visible: root.sensedSummary !== ""
            text: "⚡ Local sense: " + root.sensedSummary
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
            font.family: root.monoFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          // Color swatches row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: "COLOR"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.palette
              delegate: Rectangle {
                width: Style.space(22)
                height: Style.space(22)
                radius: width / 2
                color: modelData
                border.width: root.selectedColor === modelData ? 2.5 : 1
                border.color: root.selectedColor === modelData ? root.foreground : Qt.rgba(0, 0, 0, 0.3)
                scale: root.selectedColor === modelData ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.selectedColor = (root.selectedColor === modelData) ? "" : modelData
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "Ctrl+1..9"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
            }
          }

          // Divider
          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
          }

          // HUD Style selector (clicking triggers live demo)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "HUD FX"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.hudStyles
              delegate: Rectangle {
                readonly property bool active: root.hudStyle === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: hudStyleLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: hudStyleLabel
                  anchors.centerIn: parent
                  text: modelData
                  color: active ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                  font.family: root.monoFamily
                  font.pixelSize: Style.font.caption
                  font.bold: active
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached([root.cliPath, "hudstyle", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "click = demo"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
            }
          }

          // HUD Position selector (top | center | bottom)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "HUD POS"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.hudPositions
              delegate: Rectangle {
                readonly property bool active: root.hudPos === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: hudPosLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: hudPosLabel
                  anchors.centerIn: parent
                  text: modelData
                  color: active ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                  font.family: root.monoFamily
                  font.pixelSize: Style.font.caption
                  font.bold: active
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached([root.cliPath, "hudpos", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }
          }

          // Lab FX + Toggles
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "LAB FX"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.fxModes
              delegate: Rectangle {
                readonly property bool active: root.fxMode === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: fxLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: fxLabel
                  anchors.centerIn: parent
                  text: modelData
                  color: active ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                  font.family: root.monoFamily
                  font.pixelSize: Style.font.caption
                  font.bold: active
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached([root.cliPath, "fx", modelData])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }
          }

          // Toggles row (Auto-Sense & Flash HUD)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)

            // Auto-Sense toggle
            Rectangle {
              radius: Style.space(4)
              color: root.autoSense
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.22)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: root.autoSense ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: autoLabel.implicitWidth + Style.space(14)
              implicitHeight: Style.space(24)

              Text {
                id: autoLabel
                anchors.centerIn: parent
                text: "⚡ Auto-Sense: " + (root.autoSense ? "ON" : "OFF")
                color: root.autoSense ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "autosense", "toggle"])
                  noteInput.forceActiveFocus()
                }
              }
            }

            // Lower-Third Flash HUD toggle
            Rectangle {
              radius: Style.space(4)
              color: root.flashHud
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.22)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: root.flashHud ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: hudLabel.implicitWidth + Style.space(14)
              implicitHeight: Style.space(24)

              Text {
                id: hudLabel
                anchors.centerIn: parent
                text: "📺 Flash HUD: " + (root.flashHud ? "ON" : "OFF")
                color: root.flashHud ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "hud", "toggle"])
                  noteInput.forceActiveFocus()
                }
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "Alt+1..0 switch ws"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
            }
          }

          // 1-0 Workspace Minimap
          GridLayout {
            Layout.fillWidth: true
            columns: 5
            columnSpacing: Style.space(6)
            rowSpacing: Style.space(6)

            Repeater {
              model: 10
              delegate: Rectangle {
                readonly property int wsNum: index + 1
                readonly property var entry: (root.workspacesData && root.workspacesData[String(wsNum)]) ? root.workspacesData[String(wsNum)] : null
                readonly property string wsNote: (entry && entry.note) ? String(entry.note) : ""
                readonly property color dotColor: (entry && entry.color) ? entry.color : root.palette[index % root.palette.length]
                readonly property bool isEditing: root.editWsId === wsNum

                Layout.fillWidth: true
                height: Style.space(28)
                radius: Style.space(4)
                color: isEditing
                  ? Qt.rgba(dotColor.r, dotColor.g, dotColor.b, 0.22)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                border.width: 1
                border.color: isEditing ? dotColor : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(6)
                  anchors.rightMargin: Style.space(6)
                  spacing: Style.space(4)

                  Rectangle {
                    width: Style.space(6)
                    height: Style.space(6)
                    radius: width / 2
                    color: wsNote !== "" ? dotColor : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
                  }

                  Text {
                    text: String(wsNum)
                    color: wsNote !== "" ? dotColor : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
                    font.family: root.monoFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    Layout.fillWidth: true
                    text: wsNote !== "" ? wsNote : "—"
                    color: wsNote !== "" ? root.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.25)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: function(mouse) {
                    if (mouse.modifiers & Qt.ShiftModifier) {
                      Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsNum)])
                      root.dismiss()
                    } else {
                      root.selectWorkspace(wsNum)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
