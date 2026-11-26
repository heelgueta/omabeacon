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
  property string omarchyPath: Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy"
  readonly property string stateFilePath: home + "/.local/state/omarchy/omabeacon/state.json"
  readonly property string cliPath: Qt.resolvedUrl("bin/omabeacon").toString().replace(/^file:\/\//, "")

  readonly property var fxModes: ["clean", "pulse", "copper", "scramble", "marquee", "stealth"]
  readonly property var hudStyles: ["glitch", "wire", "laser", "arcade", "cyber", "dos", "radar", "sine", "vhs"]
  readonly property var hudPositions: ["top", "center", "bottom"]
  readonly property var hudSizes: ["sm", "md", "lg", "xl", "xxl", "mega", "giga", "tera"]
  readonly property var hudColorFxs: ["low", "mid", "high", "flare"]
  readonly property var hudCases: ["upper", "asis", "lower"]
  readonly property var glyphPositions: ["off", "above", "below"]
  readonly property var iconGlyphs: [
    { e: "󰆍", k: "terminal bash shell console cli", t: "icons" },
    { e: "󰊢", k: "git branch commit merge", t: "icons" },
    { e: "󰊤", k: "github repo code", t: "icons" },
    { e: "󰣇", k: "arch linux distro", t: "icons" },
    { e: "󰌽", k: "linux tux kernel os", t: "icons" },
    { e: "󰇧", k: "docker container whale", t: "icons" },
    { e: "󱃾", k: "kubernetes k8s cluster pods", t: "icons" },
    { e: "󰒍", k: "server rack backend host", t: "icons" },
    { e: "󰆼", k: "database sql postgres data", t: "icons" },
    { e: "󰖟", k: "web browser globe internet", t: "icons" },
    { e: "󰛳", k: "network lan ssh wifi", t: "icons" },
    { e: "󰖂", k: "cloud sync aws", t: "icons" },
    { e: "󰄨", k: "code brackets dev", t: "icons" },
    { e: "󰃖", k: "bug debug fix issue", t: "icons" },
    { e: "󰙨", k: "lab flask test experiment", t: "icons" },
    { e: "󰚩", k: "ai robot bot llm agent", t: "icons" },
    { e: "󰘚", k: "cpu chip hardware perf", t: "icons" },
    { e: "󰒓", k: "settings gear config", t: "icons" },
    { e: "󰌾", k: "lock security auth key", t: "icons" },
    { e: "󰍉", k: "search find grep", t: "icons" },
    { e: "󰑐", k: "sync refresh loop", t: "icons" },
    { e: "󰝚", k: "music audio spotify", t: "icons" },
    { e: "󰈙", k: "docs file notes markdown", t: "icons" },
    { e: "󰊴", k: "game controller arcade", t: "icons" },
    { e: "󰏗", k: "package box build", t: "icons" },
    { e: "󰗶", k: "fire hot flame", t: "icons" },
    { e: "󰀦", k: "alert warning danger", t: "icons" },
    { e: "󰓅", k: "speedometer fast perf", t: "icons" },
    { e: "󰐊", k: "play run start", t: "icons" },
    { e: "󰚌", k: "skull dead danger", t: "icons" },
    { e: "󰨞", k: "vscode editor ide", t: "icons" },
    { e: "󰡨", k: "python snake script", t: "icons" },
    { e: "󰌞", k: "javascript js node", t: "icons" },
    { e: "󱘗", k: "rust cargo crab", t: "icons" },
    { e: "󰟓", k: "golang go", t: "icons" },
    { e: "󰂚", k: "bell notification", t: "icons" },
    { e: "󰄬", k: "check done ok", t: "icons" },
    { e: "󰅖", k: "close x cross", t: "icons" },
    { e: "󰁔", k: "arrow right next", t: "icons" },
    { e: "󰓎", k: "star favorite", t: "icons" },
    { e: "󰄛", k: "cat kitty", t: "icons" },
    { e: "󰙀", k: "eye watch monitor", t: "icons" },
    { e: "◈", k: "diamond geometric glyph", t: "icons" },
    { e: "✦", k: "sparkle star glyph", t: "icons" },
    { e: "⌘", k: "command loop symbol", t: "icons" },
    { e: "⚡", k: "lightning bolt zap fast", t: "icons" },
    { e: "☣", k: "biohazard toxic", t: "icons" },
    { e: "☢", k: "radioactive nuke", t: "icons" }
  ]
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
  property string hudSize: "mega"
  property string hudColorFx: "mid"
  property string hudCase: "upper"
  property string paletteName: "tokyo"
  property string glyphPos: "above"
  property string currentKeybind: "SUPER + N"
  property bool extraKeys: true
  property bool editingKeybind: false
  property bool glyphPickerOpen: false
  property string glyphTab: "all"
  property string glyphFilter: ""
  property var emojiList: []
  property bool vaultMode: false
  property bool slotPickerOpen: false
  property var vaultItems: []
  property var vaultOccupied: []
  property var vaultFree: []
  property int vaultIndex: 0
  property string pendingThawId: ""
  property int pendingOrigWs: 1
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
    root.glyphPickerOpen = false
    root.slotPickerOpen = false
    root.vaultMode = false
    var ws = (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id) ? Hyprland.focusedWorkspace.id : 1
    selectWorkspace(ws)
    root.opened = true
    Qt.callLater(function() {
      noteInput.forceActiveFocus()
      noteInput.selectAll()
    })
  }

  IpcHandler {
    target: "omabeacon"
    function openVault(): void {
      if (root.opened && root.vaultMode) {
        root.dismiss()
      } else {
        loadState()
        root.glyphPickerOpen = false
        root.opened = true
        root.openVault()
      }
    }
    function openEdit(): void {
      root.open("{}")
    }
  }

  function openVault() {
    root.vaultMode = true
    root.slotPickerOpen = false
    root.vaultIndex = 0
    refreshVault()
    Qt.callLater(function() { vaultKeyCatcher.forceActiveFocus() })
  }

  function refreshVault() {
    if (vaultListProc.running) vaultListProc.running = false
    vaultListProc.buf = ""
    vaultListProc.command = [root.cliPath, "vault-list"]
    vaultListProc.running = true
  }

  function attemptThaw(vid, targetWs) {
    if (!vid || thawProc.running) return
    thawProc.buf = ""
    var cmd = [root.cliPath, "thaw", vid]
    if (targetWs > 0) {
      cmd.push("--ws")
      cmd.push(String(targetWs))
    }
    thawProc.command = cmd
    thawProc.running = true
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
      if (st === "brutal" || st === "boss") st = "glitch"
      root.hudStyle = st
      root.hudPos = data.hudPos || "center"
      root.hudSize = data.hudSize || "mega"
      root.hudColorFx = data.hudColorFx || "mid"
      root.hudCase = data.hudCase || "upper"
      root.paletteName = data.palette || "tokyo"
      root.glyphPos = data.glyphPos || "above"
      root.currentKeybind = data.keybind || "SUPER + N"
      root.extraKeys = (data.extraKeys === undefined) ? true : !!data.extraKeys
      root.autoSense = (data.autoSense === undefined) ? true : !!data.autoSense
      root.flashHud = (data.flashHud === undefined) ? true : !!data.flashHud
    } catch (e) {}
  }

  ListModel { id: glyphGridModel }

  FileView {
    id: emojiFileWatcher
    path: root.omarchyPath + "/shell/plugins/emojis/emojis.json"
    onLoaded: {
      var raw = emojiFileWatcher.text()
      if (!raw) return
      try {
        root.emojiList = JSON.parse(raw)
        if (root.glyphPickerOpen) root.rebuildGlyphGrid()
      } catch (e) {}
    }
  }

  function openGlyphPicker() {
    root.glyphFilter = ""
    glyphSearchInput.text = ""
    root.glyphPickerOpen = true
    root.rebuildGlyphGrid()
    Qt.callLater(function() { glyphSearchInput.forceActiveFocus() })
  }

  readonly property var emojiAliases: ({
    "🐛": "caterpillar larva",
    "🪱": "worm earthworm",
    "🦋": "butterfly moth",
    "🐞": "ladybug beetle",
    "🐝": "bee honeybee",
    "🐜": "ant",
    "🕷": "spider",
    "🦂": "scorpion"
  })

  function rebuildGlyphGrid() {
    glyphGridModel.clear()
    var q = root.glyphFilter.trim().toLowerCase()
    var limit = 2500
    var count = 0

    if (root.glyphTab === "all" || root.glyphTab === "icons") {
      for (var i = 0; i < root.iconGlyphs.length && count < limit; i++) {
        var ic = root.iconGlyphs[i]
        if (q === "" || ic.k.indexOf(q) !== -1 || ic.e === q) {
          glyphGridModel.append({ glyph: ic.e, keywords: ic.k })
          count++
        }
      }
    }

    if (root.glyphTab === "all" || root.glyphTab === "emoji") {
      for (var j = 0; j < root.emojiList.length && count < limit; j++) {
        var em = root.emojiList[j]
        var kw = em.k ? String(em.k).toLowerCase() : ""
        if (root.emojiAliases[em.e]) kw += " " + root.emojiAliases[em.e]
        if (q === "" || kw.indexOf(q) !== -1 || em.e === q) {
          glyphGridModel.append({ glyph: em.e, keywords: kw })
          count++
        }
      }
    }
  }

  Process {
    id: vaultListProc
    property string buf: ""
    stdout: SplitParser {
      onRead: data => { vaultListProc.buf += data }
    }
    onExited: (code) => {
      if (code === 0 && vaultListProc.buf.trim() !== "") {
        try {
          var d = JSON.parse(vaultListProc.buf)
          root.vaultItems = d.items || []
          root.vaultOccupied = d.occupied || []
          root.vaultFree = d.free || []
          if (root.vaultIndex >= root.vaultItems.length) {
            root.vaultIndex = Math.max(0, root.vaultItems.length - 1)
          }
        } catch (e) {}
      }
      vaultListProc.buf = ""
    }
  }

  Process {
    id: thawProc
    property string buf: ""
    stdout: SplitParser {
      onRead: data => { thawProc.buf += data }
    }
    onExited: (code) => {
      if (code === 2) {
        try {
          var d = JSON.parse(thawProc.buf)
          root.vaultFree = d.free || []
          root.vaultOccupied = d.occupied || []
          root.pendingOrigWs = d.origWs || 1
          root.slotPickerOpen = true
          Qt.callLater(function() { vaultKeyCatcher.forceActiveFocus() })
        } catch (e) {}
      } else if (code === 0) {
        root.slotPickerOpen = false
        root.dismiss()
      }
      thawProc.buf = ""
    }
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
        visible: !root.vaultMode
        width: Math.min(Style.space(900), parent.width - Style.gapsOut * 2)
        height: cardCol.implicitHeight + Style.space(44)
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
          anchors.margins: Style.space(22)
          spacing: Style.space(14)

          // Header row
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)

            Rectangle {
              width: Style.space(12)
              height: Style.space(12)
              radius: width / 2
              color: root.activeAccent
            }

            Text {
              text: "WORKSPACE " + root.editWsId
              color: root.activeAccent
              font.family: root.monoFamily
              font.pixelSize: Style.font.heading || Style.font.title
              font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Open Cryo Vault (Stasis Wheel) button
            Rectangle {
              radius: Style.space(4)
              color: Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.16)
              border.width: 1
              border.color: root.activeAccent
              implicitWidth: vaultBtnTxt.implicitWidth + Style.space(14)
              implicitHeight: Style.space(26)

              Text {
                id: vaultBtnTxt
                anchors.centerIn: parent
                text: "❄ Vault (F12)"
                color: root.activeAccent
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openVault()
              }
            }

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
            height: Style.space(50)
            radius: Style.space(6)
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
            border.width: 1.5
            border.color: noteInput.activeFocus ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.2)

            TextInput {
              id: noteInput
              anchors.fill: parent
              anchors.leftMargin: Style.space(14)
              anchors.rightMargin: Style.space(14)
              verticalAlignment: TextInput.AlignVCenter
              color: root.foreground
              selectionColor: root.activeAccent
              selectedTextColor: root.background
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading || 20
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
                width: Style.space(24)
                height: Style.space(24)
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
                implicitHeight: Style.space(26)

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

          // Emoji / Glyph picker button + Position (off | above | below)
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "GLYPH"
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Rectangle {
              id: pickGlyphBtn
              readonly property var wsObj: (root.workspacesData && root.workspacesData[String(root.editWsId)]) ? root.workspacesData[String(root.editWsId)] : null
              readonly property string curGlyph: (wsObj && wsObj.glyph) ? String(wsObj.glyph) : ""
              radius: Style.space(4)
              color: curGlyph !== ""
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.22)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              border.width: 1
              border.color: curGlyph !== "" ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.16)
              implicitWidth: pickGlyphLbl.implicitWidth + Style.space(14)
              implicitHeight: Style.space(22)

              Text {
                id: pickGlyphLbl
                anchors.centerIn: parent
                text: pickGlyphBtn.curGlyph !== "" ? (pickGlyphBtn.curGlyph + "  Change...") : "+ Pick Emoji / Icon..."
                color: pickGlyphBtn.curGlyph !== "" ? root.activeAccent : root.foreground
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openGlyphPicker()
              }
            }

            Rectangle {
              visible: pickGlyphBtn.curGlyph !== ""
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              implicitWidth: clearGlyphLbl.implicitWidth + Style.space(10)
              implicitHeight: Style.space(22)

              Text {
                id: clearGlyphLbl
                anchors.centerIn: parent
                text: "Clear"
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.6)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "glyph", String(root.editWsId), "", "--demo"])
                  noteInput.forceActiveFocus()
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
                implicitHeight: Style.space(26)

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
                implicitHeight: Style.space(26)

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
                implicitHeight: Style.space(26)

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
                implicitHeight: Style.space(26)

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
                implicitHeight: Style.space(26)

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

            // Extra 11-20 (F1-F10) + F11/F12 keybindings toggle
            Rectangle {
              radius: Style.space(4)
              color: root.extraKeys
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.22)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: root.extraKeys ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: extraLabel.implicitWidth + Style.space(14)
              implicitHeight: Style.space(26)

              Text {
                id: extraLabel
                anchors.centerIn: parent
                text: "⌨ F1–F10 (11–20): " + (root.extraKeys ? "ON" : "OFF")
                color: root.extraKeys ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "extrakeys", "toggle"])
                  noteInput.forceActiveFocus()
                }
              }
            }

            Item { Layout.fillWidth: true }

            // Reset visual/HUD settings to defaults (preserves workspace notes)
            Rectangle {
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
              border.width: 1
              border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)
              implicitWidth: resetLabel.implicitWidth + Style.space(12)
              implicitHeight: Style.space(26)

              Text {
                id: resetLabel
                anchors.centerIn: parent
                text: "↺ Reset FX"
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "reset"])
                  noteInput.forceActiveFocus()
                }
              }
            }

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
                height: Style.space(36)
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

      // Compact Searchable Emoji / Icon Picker Popup
      Rectangle {
        id: glyphPickerCard
        visible: root.glyphPickerOpen
        width: Math.min(Style.space(640), parent.width - Style.gapsOut * 4)
        height: Math.min(Style.space(520), parent.height - Style.gapsOut * 4)
        anchors.centerIn: parent
        radius: Style.cornerRadius
        color: root.background
        border.width: 2
        border.color: root.activeAccent
        z: 10

        MouseArea { anchors.fill: parent }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(12)
          spacing: Style.space(8)

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Text {
              text: "PICK EMOJI / ICON"
              color: root.activeAccent
              font.family: root.monoFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Item { Layout.fillWidth: true }

            Repeater {
              model: ["all", "emoji", "icons"]
              delegate: Rectangle {
                readonly property bool active: root.glyphTab === modelData
                radius: Style.space(4)
                color: active
                  ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.25)
                  : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
                border.width: 1
                border.color: active ? root.activeAccent : "transparent"
                implicitWidth: tabLbl.implicitWidth + Style.space(10)
                implicitHeight: Style.space(20)

                Text {
                  id: tabLbl
                  anchors.centerIn: parent
                  text: modelData
                  color: active ? root.activeAccent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                  font.family: root.monoFamily
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.glyphTab = modelData
                    root.rebuildGlyphGrid()
                    glyphSearchInput.forceActiveFocus()
                  }
                }
              }
            }

            Rectangle {
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              implicitWidth: closePickLbl.implicitWidth + Style.space(10)
              implicitHeight: Style.space(20)
              Text {
                id: closePickLbl
                anchors.centerIn: parent
                text: "✕"
                color: root.foreground
                font.pixelSize: Style.font.caption
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.glyphPickerOpen = false
                  noteInput.forceActiveFocus()
                }
              }
            }
          }

          // Search box
          Rectangle {
            Layout.fillWidth: true
            height: Style.space(32)
            radius: Style.space(6)
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.06)
            border.width: 1
            border.color: root.activeAccent

            TextInput {
              id: glyphSearchInput
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              verticalAlignment: TextInput.AlignVCenter
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              onTextChanged: {
                root.glyphFilter = text
                root.rebuildGlyphGrid()
              }
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  event.accepted = true
                  root.glyphPickerOpen = false
                  noteInput.forceActiveFocus()
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && glyphGridModel.count > 0) {
                  event.accepted = true
                  var first = glyphGridModel.get(0).glyph
                  Quickshell.execDetached([root.cliPath, "glyph", String(root.editWsId), first, "--demo"])
                  root.glyphPickerOpen = false
                  noteInput.forceActiveFocus()
                }
              }

              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "Search (fire, git, code, skull, docker...)"
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.35)
                font: glyphSearchInput.font
                visible: glyphSearchInput.text === ""
              }
            }
          }

          // Scrollable Grid of Emojis + Nerd-Font Icons
          GridView {
            id: glyphGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Style.space(48)
            cellHeight: Style.space(48)
            model: glyphGridModel

            delegate: Rectangle {
              width: glyphGrid.cellWidth - 4
              height: glyphGrid.cellHeight - 4
              radius: Style.space(6)
              color: cellMouse.containsMouse
                ? Qt.rgba(root.activeAccent.r, root.activeAccent.g, root.activeAccent.b, 0.28)
                : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)
              border.width: cellMouse.containsMouse ? 1 : 0
              border.color: root.activeAccent

              Text {
                anchors.centerIn: parent
                text: glyph
                color: root.foreground
                font.pixelSize: Style.space(24)
              }

              MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached([root.cliPath, "glyph", String(root.editWsId), glyph, "--demo"])
                  root.glyphPickerOpen = false
                  noteInput.forceActiveFocus()
                }
              }
            }
          }
        }
      }

      // --- STASIS WHEEL (Fullscreen, Borderless, L33T Hyperspin-style) ---
      Rectangle {
        id: vaultCard
        visible: root.vaultMode
        anchors.fill: parent
        color: Qt.rgba(0.015, 0.015, 0.025, 0.94)
        border.width: 0

        readonly property var selItem: (root.vaultItems.length > 0 && root.vaultIndex >= 0 && root.vaultIndex < root.vaultItems.length)
          ? root.vaultItems[root.vaultIndex]
          : null
        readonly property color selColor: (selItem && selItem.color) ? selItem.color : root.activeAccent

        MouseArea { anchors.fill: parent }

        // Keyboard controller for Stasis Wheel & Slot Picker
        Item {
          id: vaultKeyCatcher
          focus: root.opened && root.vaultMode
          Keys.onPressed: function(event) {
            if (root.slotPickerOpen) {
              var picked = -1
              if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) picked = event.key - Qt.Key_0
              else if (event.key === Qt.Key_0) picked = 10
              else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F10) picked = 11 + (event.key - Qt.Key_F1)

              if (picked > 0) {
                event.accepted = true
                if (root.vaultFree.indexOf(picked) !== -1) {
                  root.attemptThaw(root.pendingThawId, picked)
                }
                return
              }
              if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.slotPickerOpen = false
                return
              }
              return
            }

            if (event.key === Qt.Key_Escape) {
              event.accepted = true
              root.dismiss()
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
              event.accepted = true
              if (root.vaultItems.length > 0) {
                root.vaultIndex = (root.vaultIndex - 1 + root.vaultItems.length) % root.vaultItems.length
              }
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
              event.accepted = true
              if (root.vaultItems.length > 0) {
                root.vaultIndex = (root.vaultIndex + 1) % root.vaultItems.length
              }
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              event.accepted = true
              if (vaultCard.selItem) {
                root.pendingThawId = vaultCard.selItem.id
                root.attemptThaw(vaultCard.selItem.id, 0)
              }
            } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
              event.accepted = true
              if (vaultCard.selItem) {
                Quickshell.execDetached([root.cliPath, "vault-delete", vaultCard.selItem.id])
                Qt.callLater(root.refreshVault)
              }
            } else if (event.key === Qt.Key_F11) {
              event.accepted = true
              Quickshell.execDetached([root.cliPath, "freeze"])
              root.dismiss()
            }
          }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.space(22)
          spacing: Style.space(14)

          // Vault Header
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)

            Text {
              text: ">>> STASIS VAULT // CRYO-FROZEN WORKSPACES <<<"
              color: vaultCard.selColor
              font.family: root.monoFamily
              font.pixelSize: Style.font.heading || 18
              font.bold: true
              font.letterSpacing: 2.0
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              radius: Style.space(4)
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
              implicitWidth: backBtnLbl.implicitWidth + Style.space(14)
              implicitHeight: Style.space(28)
              Text {
                id: backBtnLbl
                anchors.centerIn: parent
                text: "← Edit Mode"
                color: root.foreground
                font.family: root.monoFamily
                font.pixelSize: Style.font.caption
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.vaultMode = false
                  Qt.callLater(function() { noteInput.forceActiveFocus() })
                }
              }
            }
          }

          // Empty vault message
          Item {
            visible: root.vaultItems.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Column {
              anchors.centerIn: parent
              spacing: Style.space(10)
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NO CRYO-FROZEN WORKSPACES"
                color: vaultCard.selColor
                font.family: root.monoFamily
                font.pixelSize: Style.font.heading || 22
                font.bold: true
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press SUPER + F11 on any occupied workspace to freeze & free its slot."
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.65)
                font.family: root.monoFamily
                font.pixelSize: Style.font.body
              }
            }
          }

          // Split View: Left Screenshot Preview + Right Arcade Wheel
          RowLayout {
            visible: root.vaultItems.length > 0 && !root.slotPickerOpen
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.space(20)

            // LEFT: Huge Borderless Preview + Giant Glitch Title
            ColumnLayout {
              Layout.preferredWidth: vaultCard.width * 0.54
              Layout.fillHeight: true
              spacing: Style.space(16)

              // Giant L33T Glitch Workspace Title
              Item {
                Layout.fillWidth: true
                implicitHeight: leftTitleTxt.implicitHeight

                readonly property string bigTitle: vaultCard.selItem
                  ? (((vaultCard.selItem.glyph ? vaultCard.selItem.glyph + " " : "") + (vaultCard.selItem.note || "UNTITLED")).toUpperCase())
                  : ""

                Text {
                  x: 2; y: 3
                  width: parent.width
                  text: parent.bigTitle
                  color: Qt.rgba(0, 0, 0, 0.85)
                  font.family: root.monoFamily
                  font.pixelSize: Style.space(52)
                  font.bold: true
                  font.letterSpacing: 2.5
                  elide: Text.ElideRight
                }
                Text {
                  x: -4; y: -2
                  width: parent.width
                  text: parent.bigTitle
                  color: Qt.rgba(0.2, 0.95, 1.0, 0.65)
                  font.family: root.monoFamily
                  font.pixelSize: Style.space(52)
                  font.bold: true
                  font.letterSpacing: 2.5
                  elide: Text.ElideRight
                }
                Text {
                  x: 4; y: 2
                  width: parent.width
                  text: parent.bigTitle
                  color: Qt.rgba(1.0, 0.2, 0.55, 0.65)
                  font.family: root.monoFamily
                  font.pixelSize: Style.space(52)
                  font.bold: true
                  font.letterSpacing: 2.5
                  elide: Text.ElideRight
                }
                Text {
                  id: leftTitleTxt
                  width: parent.width
                  text: parent.bigTitle
                  color: Color.foreground
                  font.family: root.monoFamily
                  font.pixelSize: Style.space(52)
                  font.bold: true
                  font.letterSpacing: 2.5
                  elide: Text.ElideRight
                }
              }

              // Borderless Screenshot Preview with CRT scanlines
              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Image {
                  anchors.fill: parent
                  source: (vaultCard.selItem && vaultCard.selItem.thumb) ? ("file://" + vaultCard.selItem.thumb) : ""
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                }

                // Subtle CRT scanlines over preview
                Column {
                  anchors.fill: parent
                  spacing: 3
                  opacity: 0.16
                  Repeater {
                    model: 120
                    Rectangle { width: parent.width; height: 1; color: "#000000" }
                  }
                }
              }

              // Manifest info
              Text {
                Layout.fillWidth: true
                text: vaultCard.selItem
                  ? ("ORIG WS " + vaultCard.selItem.origWs + "  ·  " + vaultCard.selItem.windowCount + " WINDOWS  ·  " + (vaultCard.selItem.summary || ""))
                  : ""
                color: vaultCard.selColor
                font.family: root.monoFamily
                font.pixelSize: Style.font.bodySmall || Style.font.caption
                font.bold: true
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: Style.space(10)

                Rectangle {
                  radius: Style.space(4)
                  color: Qt.rgba(vaultCard.selColor.r, vaultCard.selColor.g, vaultCard.selColor.b, 0.25)
                  border.width: 1
                  border.color: vaultCard.selColor
                  implicitWidth: thawBtnLbl.implicitWidth + Style.space(18)
                  implicitHeight: Style.space(32)
                  Text {
                    id: thawBtnLbl
                    anchors.centerIn: parent
                    text: "[ENTER] THAW"
                    color: vaultCard.selColor
                    font.family: root.monoFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (vaultCard.selItem) {
                        root.pendingThawId = vaultCard.selItem.id
                        root.attemptThaw(vaultCard.selItem.id, 0)
                      }
                    }
                  }
                }

                Rectangle {
                  radius: Style.space(4)
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                  implicitWidth: purgeBtnLbl.implicitWidth + Style.space(14)
                  implicitHeight: Style.space(32)
                  Text {
                    id: purgeBtnLbl
                    anchors.centerIn: parent
                    text: "[DEL] PURGE"
                    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.7)
                    font.family: root.monoFamily
                    font.pixelSize: Style.font.caption
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (vaultCard.selItem) {
                        Quickshell.execDetached([root.cliPath, "vault-delete", vaultCard.selItem.id])
                        Qt.callLater(root.refreshVault)
                      }
                    }
                  }
                }

                Item { Layout.fillWidth: true }
              }
            }

            // RIGHT: Borderless Hyperspin Curved Arcade Wheel
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true

              // Sweeping dark wheel disc backdrop on right edge
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: Style.space(40)
                width: parent.height * 1.4
                height: parent.height * 1.4
                radius: width / 2
                color: Qt.rgba(0, 0, 0, 0.62)
                border.width: 2
                border.color: Qt.rgba(vaultCard.selColor.r, vaultCard.selColor.g, vaultCard.selColor.b, 0.30)
              }

              ListView {
                id: wheelList
                anchors.fill: parent
                model: root.vaultItems
                currentIndex: root.vaultIndex
                preferredHighlightBegin: height * 0.40
                preferredHighlightEnd: height * 0.60
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 130
                spacing: Style.space(18)

                delegate: Item {
                  readonly property int dist: index - root.vaultIndex
                  readonly property int absDist: Math.abs(dist)
                  readonly property bool selected: dist === 0
                  readonly property color itemCol: modelData.color || root.activeAccent
                  readonly property string itemTitle: ((modelData.glyph ? modelData.glyph + " " : "") + (modelData.note || "UNTITLED")).toUpperCase()
                  readonly property real arcOffset: Math.min(Style.space(180), Math.pow(absDist, 1.5) * Style.space(36)) + Style.space(40)
                  width: wheelList.width
                  height: selected ? Style.space(86) : Style.space(52)
                  opacity: selected ? 1.0 : Math.max(0.18, 0.78 - absDist * 0.20)
                  scale: selected ? 1.04 : Math.max(0.58, 0.84 - absDist * 0.08)
                  rotation: Math.max(-20, Math.min(20, dist * 4.5))

                  Behavior on opacity { NumberAnimation { duration: 110 } }
                  Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                  Behavior on rotation { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                  Item {
                    anchors.verticalCenter: parent.verticalCenter
                    x: arcOffset
                    width: parent.width - arcOffset - Style.space(16)
                    height: parent.height

                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    // Dark legibility shadow
                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      x: 2; y: 3
                      width: parent.width
                      text: itemTitle
                      color: Qt.rgba(0, 0, 0, 0.90)
                      font.family: root.monoFamily
                      font.pixelSize: selected ? Style.space(44) : Style.space(26)
                      font.bold: true
                      font.letterSpacing: selected ? 2.5 : 1.0
                      elide: Text.ElideRight
                    }

                    // Cyan & Magenta RGB-split ghosts on selected item
                    Text {
                      visible: selected
                      anchors.verticalCenter: parent.verticalCenter
                      x: -4; y: -2
                      width: parent.width
                      text: itemTitle
                      color: Qt.rgba(0.2, 0.95, 1.0, 0.70)
                      font.family: root.monoFamily
                      font.pixelSize: Style.space(44)
                      font.bold: true
                      font.letterSpacing: 2.5
                      elide: Text.ElideRight
                    }
                    Text {
                      visible: selected
                      anchors.verticalCenter: parent.verticalCenter
                      x: 4; y: 2
                      width: parent.width
                      text: itemTitle
                      color: Qt.rgba(1.0, 0.2, 0.55, 0.70)
                      font.family: root.monoFamily
                      font.pixelSize: Style.space(44)
                      font.bold: true
                      font.letterSpacing: 2.5
                      elide: Text.ElideRight
                    }

                    Text {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width
                      text: itemTitle
                      color: selected ? Color.foreground : itemCol
                      font.family: root.monoFamily
                      font.pixelSize: selected ? Style.space(44) : Style.space(26)
                      font.bold: true
                      font.letterSpacing: selected ? 2.5 : 1.0
                      elide: Text.ElideRight
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (selected) {
                        root.pendingThawId = modelData.id
                        root.attemptThaw(modelData.id, 0)
                      } else {
                        root.vaultIndex = index
                      }
                    }
                  }
                }
              }
            }
          }

          // SLOT PICKER (shown when origWs is occupied!)
          ColumnLayout {
            visible: root.slotPickerOpen
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.space(16)

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.vaultFree.length > 0
                ? ("⚠ WS " + root.pendingOrigWs + " IS OCCUPIED // PRESS 1–0 OR F1–F10 FOR AN EMPTY SLOT")
                : "⚠ ALL 20 WORKSPACES ARE OCCUPIED // CLOSE ONE OR FORCE INTO CURRENT WS"
              color: "#f7768e"
              font.family: root.monoFamily
              font.pixelSize: Style.font.heading || 18
              font.bold: true
            }

            GridLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              columns: 5
              columnSpacing: Style.space(12)
              rowSpacing: Style.space(12)

              Repeater {
                model: 20
                delegate: Rectangle {
                  readonly property int wsNum: index + 1
                  readonly property bool isFree: root.vaultFree.indexOf(wsNum) !== -1
                  readonly property string keyHint: wsNum <= 9 ? String(wsNum) : (wsNum === 10 ? "0" : ("F" + (wsNum - 10)))
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  radius: Style.space(6)
                  color: isFree
                    ? Qt.rgba(vaultCard.selColor.r, vaultCard.selColor.g, vaultCard.selColor.b, 0.18)
                    : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.04)
                  border.width: isFree ? 2 : 1
                  border.color: isFree ? vaultCard.selColor : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.12)
                  opacity: isFree ? 1.0 : 0.35

                  Column {
                    anchors.centerIn: parent
                    spacing: Style.space(4)
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: "WS " + wsNum
                      color: isFree ? vaultCard.selColor : root.foreground
                      font.family: root.monoFamily
                      font.pixelSize: Style.font.heading || 18
                      font.bold: true
                    }
                    Text {
                      anchors.horizontalCenter: parent.horizontalCenter
                      text: isFree ? ("[" + keyHint + "] FREE") : "OCCUPIED"
                      color: isFree ? Color.foreground : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.5)
                      font.family: root.monoFamily
                      font.pixelSize: Style.font.caption
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    enabled: isFree
                    cursorShape: isFree ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.attemptThaw(root.pendingThawId, wsNum)
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
