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
  readonly property var hudStyles: ["glitch", "wire", "laser", "arcade", "cyber", "dos", "radar", "sine", "boss", "vhs"]
  readonly property var hudPositions: ["top", "center", "bottom"]
  readonly property var hudSizes: ["sm", "md", "lg", "xl", "xxl", "mega"]
  readonly property var hudColorFxs: ["low", "mid", "high", "flare"]
  readonly property var hudCases: ["upper", "asis", "lower"]
  readonly property var glyphPositions: ["off", "above", "below"]
  readonly property var quickGlyphs: ["⚡", "🔥", "🧪", "💀", "👾", "🚀", "🛠", "🧠", "📡", "☣", "◈", "✦"]
  readonly property var paletteNames: ["tokyo", "neon", "pastel", "mono", "fire"]
  readonly property var palettes: ({
    "tokyo": ["#f7768e", "#ff9e64", "#e0af68", "#9ece6a", "#73daca", "#7dcfff", "#7aa2f7", "#bb9af7", "#ff79c6", "#c0caf5"],
    "neon": ["#ff0055", "#ff5500", "#ffcc00", "#39ff14", "#00ffcc", "#00e5ff", "#2979ff", "#aa00ff", "#ff00ff", "#ffffff"],
    "pastel": ["#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb", "#89b4fa", "#cba6f7", "#f5c2e7", "#cdd6f4"],
    "mono": ["#00ff66", "#22ee77", "#44dd88", "#66cc99", "#88ddaa", "#aaf0cc", "#ccffdd", "#a0c4b0", "#7aa899", "#e0fff0"],
    "fire": ["#ff1e42", "#ff4d2e", "#ff7700", "#ffa600", "#ffd000", "#ffe866", "#fff4b8", "#ff6b6b", "#ff3b8d", "#ffffff"]
  })
  readonly property var palette: palettes[paletteName] || palettes["tokyo"]

  property bool opened: false
  property int editWsId: 1
  property string selectedColor: ""
  property var workspacesData: ({})
  property string fxMode: "clean"
  property string hudStyle: "glitch"
  property string hudPos: "center"
  property string hudSize: "md"
  property string hudColorFx: "mid"
  property string hudCase: "upper"
  property string paletteName: "tokyo"
  property string glyphPos: "above"
  property string currentKeybind: "SUPER + N"
  property bool editingKeybind: false
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
      var st = data.hudStyle || "glitch"
      if (st === "brutal") st = "glitch"
      root.hudStyle = st
      root.hudPos = data.hudPos || "center"
      root.hudSize = data.hudSize || "md"
      root.hudColorFx = data.hudColorFx || "mid"
      root.hudCase = data.hudCase || "upper"
      root.paletteName = data.palette || "tokyo"
      root.glyphPos = data.glyphPos || "above"
      root.currentKeybind = data.keybind || "SUPER + N"
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

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!root.opened) return
      var name = String(event && event.name ? event.name : "")
      if (name === "workspace" || name === "createworkspace") {
        var id = parseInt(String(event.data || "").split(",")[0])
        if (!isNaN(id) && id >= 1 && id <= 99 && id !== root.editWsId) {
          root.selectWorkspace(id)
        }
      } else if (name === "focusedmon") {
        var parts = String(event.data || "").split(",")
        if (parts.length >= 2) {
          var monId = parseInt(parts[1].trim())
          if (!isNaN(monId) && monId >= 1 && monId <= 99 && monId !== root.editWsId) {
            root.selectWorkspace(monId)
          }
        }
      }
    }
  }

  readonly property var focusedWs: Hyprland.focusedWorkspace
  onFocusedWsChanged: {
    if (root.opened && focusedWs && focusedWs.id && focusedWs.id !== root.editWsId) {
      root.selectWorkspace(focusedWs.id)
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
        width: Math.min(Style.space(600), parent.width - Style.gapsOut * 2)
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

          // Color swatches row (1-0 spectrum) + Lock Color toggle
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

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
                width: Style.space(20)
                height: Style.space(20)
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

            // Lock workspace color against palette switches
            Rectangle {
              id: lockBtn
              readonly property var wsObj: (root.workspacesData && root.workspacesData[String(root.editWsId)]) ? root.workspacesData[String(root.editWsId)] : null
              readonly property bool isLocked: !!(wsObj && wsObj.lockedColor)
              radius: Style.space(4)
              color: lockBtn.isLocked
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: lockBtn.isLocked ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: lockLabel.implicitWidth + Style.space(10)
              implicitHeight: Style.space(22)

              Text {
                id: lockLabel
                anchors.centerIn: parent
                text: lockBtn.isLocked ? "🔒 Locked" : "🔓 Auto"
                color: lockBtn.isLocked ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "lock", String(root.editWsId), "toggle"])
                  noteInput.forceActiveFocus()
                }
              }
            }
          }

          // Palette selector (overrides unlocked workspaces)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "PALETTE"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.paletteNames
              delegate: Rectangle {
                readonly property bool active: root.paletteName === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: palLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: palLabel
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
                    Quickshell.execDetached([root.cliPath, "palette", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }
          }

          // Emoji / Glyph picker + Position (off | above | below)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(4)

            Text {
              text: "GLYPH"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.quickGlyphs
              delegate: Rectangle {
                readonly property var wsObj: (root.workspacesData && root.workspacesData[String(root.editWsId)]) ? root.workspacesData[String(root.editWsId)] : null
                readonly property bool active: !!(wsObj && wsObj.glyph === modelData)
                width: Style.space(22)
                height: Style.space(22)
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.28)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"

                Text {
                  anchors.centerIn: parent
                  text: modelData
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached([root.cliPath, "glyph", String(root.editWsId), active ? "" : modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }

            Repeater {
              model: root.glyphPositions
              delegate: Rectangle {
                readonly property bool active: root.glyphPos === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: gPosLabel.implicitWidth + Style.space(8)
                implicitHeight: Style.space(22)

                Text {
                  id: gPosLabel
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
                    Quickshell.execDetached([root.cliPath, "glyphpos", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }
          }

          // Divider
          Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.1)
          }

          // HUD Style selector (10 styles, wrapping flow, clicking triggers live demo)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              Layout.alignment: Qt.AlignTop
              Layout.topMargin: Style.space(4)
              text: "HUD FX"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Flow {
              Layout.fillWidth: true
              spacing: Style.space(5)

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
                  width: hudStyleLabel.implicitWidth + Style.space(10)
                  height: Style.space(22)

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
            }
          }

          // HUD Size selector (sm | md | lg | xl | xxl | mega)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "SIZE"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.hudSizes
              delegate: Rectangle {
                readonly property bool active: root.hudSize === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: hudSizeLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: hudSizeLabel
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
                    Quickshell.execDetached([root.cliPath, "hudsize", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }

            Item { Layout.fillWidth: true }

            Text {
              text: "COLOR"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.hudColorFxs
              delegate: Rectangle {
                readonly property bool active: root.hudColorFx === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: hudCfxLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: hudCfxLabel
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
                    Quickshell.execDetached([root.cliPath, "hudcolor", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
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

            Text {
              text: "CASE"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Repeater {
              model: root.hudCases
              delegate: Rectangle {
                readonly property bool active: root.hudCase === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: hudCaseLabel.implicitWidth + Style.space(10)
                implicitHeight: Style.space(22)

                Text {
                  id: hudCaseLabel
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
                    Quickshell.execDetached([root.cliPath, "hudcase", modelData, "--demo"])
                    noteInput.forceActiveFocus()
                  }
                }
              }
            }
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

            // Editable Keybind pill
            Rectangle {
              radius: Style.space(4)
              color: root.editingKeybind
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.22)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: root.editingKeybind ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: root.editingKeybind ? Style.space(130) : (kbLabel.implicitWidth + Style.space(14))
              implicitHeight: Style.space(24)

              Text {
                id: kbLabel
                visible: !root.editingKeybind
                anchors.centerIn: parent
                text: "⌨ " + root.currentKeybind
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              TextInput {
                id: kbInput
                visible: root.editingKeybind
                anchors.fill: parent
                anchors.leftMargin: Style.space(6)
                anchors.rightMargin: Style.space(6)
                verticalAlignment: TextInput.AlignVCenter
                color: root.foreground
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
                Keys.onPressed: function(event) {
                  if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    event.accepted = true
                    var val = kbInput.text.trim()
                    if (val !== "") Quickshell.execDetached([root.cliPath, "keybind", val])
                    root.editingKeybind = false
                    noteInput.forceActiveFocus()
                  } else if (event.key === Qt.Key_Escape) {
                    event.accepted = true
                    root.editingKeybind = false
                    noteInput.forceActiveFocus()
                  }
                }
              }

              MouseArea {
                visible: !root.editingKeybind
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  kbInput.text = root.currentKeybind
                  root.editingKeybind = true
                  Qt.callLater(function() {
                    kbInput.forceActiveFocus()
                    kbInput.selectAll()
                  })
                }
              }
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
