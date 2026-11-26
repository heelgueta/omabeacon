import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "heelgueta.omabeacon"
  implicitWidth: pillButton.implicitWidth
  implicitHeight: pillButton.implicitHeight

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateFilePath: home + "/.local/state/omarchy/omabeacon/state.json"
  readonly property string cliPath: Qt.resolvedUrl("bin/omabeacon").toString().replace(/^file:\/\//, "")

  readonly property var fxModes: ["clean", "pulse", "copper", "scramble", "marquee", "stealth"]
  readonly property var defaultPalette: [
    "#7aa2f7", "#bb9af7", "#7dcfff", "#9ece6a", "#e0af68",
    "#f7768e", "#ff9e64", "#73daca", "#c0caf5", "#2ac3de"
  ]

  property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  property var workspacesData: ({})
  property string fxMode: "clean"
  property bool autoSense: false
  property bool flashHud: true
  property string hudStyle: "banner"
  property int hudPreviewSeq: -1
  property string sensedText: ""
  property int sensedWsId: -1

  // Current workspace computed properties
  readonly property var wsEntry: (workspacesData && workspacesData[String(activeWsId)]) ? workspacesData[String(activeWsId)] : null
  readonly property string manualNote: wsEntry && wsEntry.note ? String(wsEntry.note) : ""
  readonly property bool isSensed: manualNote === "" && autoSense && sensedWsId === activeWsId && sensedText !== "" && sensedText !== "empty"
  readonly property string rawDisplayNote: manualNote !== "" ? manualNote : (isSensed ? ("⚡ " + sensedText) : "")
  readonly property bool hasNote: rawDisplayNote !== ""

  readonly property color wsColor: {
    if (wsEntry && wsEntry.color) return wsEntry.color
    var idx = Math.max(0, (activeWsId - 1) % defaultPalette.length)
    return hasNote ? defaultPalette[idx] : Color.accent
  }

  // Scramble FX state
  property string displayNote: ""
  property int scrambleTick: 0
  readonly property string scrambleGlyphs: "█▓▒░#@$%&/\\|=+*<>~"

  // Stealth FX state
  property bool stealthDimmed: false

  // Lower-third Flash HUD state
  property bool hudVisible: false
  property string hudDisplayText: ""
  property int hudScrambleTick: 0
  property int lastHudWsId: -1

  function triggerScramble(targetText) {
    if (targetText === "") {
      root.displayNote = ""
      scrambleTimer.stop()
      return
    }
    if (root.fxMode !== "scramble") {
      root.displayNote = targetText
      scrambleTimer.stop()
      return
    }
    root.scrambleTick = 0
    scrambleTimer.restart()
  }

  function triggerHud(wsId, text, forceDemo) {
    if ((!root.flashHud && !forceDemo) || !text || text === "") return
    root.hudVisible = true
    root.hudScrambleTick = 0
    root.hudTargetText = text
    if (root.hudStyle === "banner" || root.hudStyle === "splat" || root.hudStyle === "crt" || root.hudStyle === "brutal" || root.fxMode === "scramble" || root.fxMode === "copper") {
      root.hudDisplayText = text
      hudScrambleTimer.restart()
    } else {
      root.hudDisplayText = text
    }
    hudHideTimer.interval = (root.hudStyle === "brutal" || root.hudStyle === "splat") ? 650 : 760
    hudHideTimer.restart()
  }

  function handleWorkspaceChanged(newWsId) {
    if (!newWsId || newWsId < 1 || newWsId > 99) return
    var changed = (newWsId !== root.activeWsId)
    root.activeWsId = newWsId
    root.stealthDimmed = false
    if (root.fxMode === "stealth") stealthTimer.restart()

    if (root.autoSense) {
      senseDebounce.restart()
    }

    if (changed) {
      root.triggerScramble(root.rawDisplayNote)
      if (newWsId !== root.lastHudWsId) {
        root.lastHudWsId = newWsId
        root.triggerHud(newWsId, root.rawDisplayNote)
      }
    }
  }

  onRawDisplayNoteChanged: {
    triggerScramble(rawDisplayNote)
  }

  onFxModeChanged: {
    triggerScramble(rawDisplayNote)
    if (fxMode === "stealth") {
      stealthDimmed = false
      stealthTimer.restart()
    } else {
      stealthDimmed = false
      stealthTimer.stop()
    }
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
    if (!txt) {
      root.workspacesData = ({})
      root.fxMode = "clean"
      root.autoSense = false
      root.flashHud = true
      root.triggerScramble(root.rawDisplayNote)
      return
    }
    try {
      var data = JSON.parse(txt)
      root.workspacesData = data.workspaces || ({})
      root.fxMode = data.fx || "clean"
      root.autoSense = !!data.autoSense
      root.flashHud = (data.flashHud === undefined) ? true : !!data.flashHud
      root.hudStyle = data.hudStyle || "banner"
      var seq = parseInt(data.hudPreviewSeq || 0)
      var shouldDemo = (root.hudPreviewSeq !== -1 && seq !== root.hudPreviewSeq)
      root.hudPreviewSeq = seq
      root.triggerScramble(root.rawDisplayNote)
      if (root.autoSense) senseDebounce.restart()
      if (shouldDemo) {
        var demoTxt = root.rawDisplayNote !== "" ? root.rawDisplayNote : ("DEMO // WORKSPACE " + root.activeWsId)
        root.triggerHud(root.activeWsId, demoTxt, true)
      }
    } catch (e) {}
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = String(event && event.name ? event.name : "")
      if (name === "workspace" || name === "createworkspace") {
        var id = parseInt(String(event.data || "").split(",")[0])
        if (!isNaN(id)) root.handleWorkspaceChanged(id)
      } else if (name === "focusedmon") {
        var parts = String(event.data || "").split(",")
        if (parts.length >= 2) {
          var monId = parseInt(parts[1].trim())
          if (!isNaN(monId)) root.handleWorkspaceChanged(monId)
        }
      } else if (name === "openwindow" || name === "closewindow" || name === "movewindow") {
        if (root.autoSense) senseDebounce.restart()
      }
    }
  }

  readonly property var focusedWs: Hyprland.focusedWorkspace
  onFocusedWsChanged: {
    if (focusedWs && focusedWs.id) root.handleWorkspaceChanged(focusedWs.id)
  }

  // Local /proc + hyprctl sense process
  Process {
    id: senseProc
    property string buf: ""
    command: [root.cliPath, "sense", String(root.activeWsId)]
    stdout: SplitParser {
      onRead: data => { senseProc.buf += data }
    }
    onExited: (code) => {
      if (code === 0) {
        root.sensedWsId = root.activeWsId
        root.sensedText = senseProc.buf.trim()
      }
      senseProc.buf = ""
    }
  }

  Timer {
    id: senseDebounce
    interval: 160
    repeat: false
    onTriggered: {
      if (root.autoSense && !senseProc.running) {
        senseProc.buf = ""
        senseProc.command = [root.cliPath, "sense", String(root.activeWsId)]
        senseProc.running = true
      }
    }
  }

  Timer {
    id: sensePollTimer
    interval: 6000
    repeat: true
    running: root.autoSense
    onTriggered: {
      if (!senseProc.running) {
        senseProc.buf = ""
        senseProc.command = [root.cliPath, "sense", String(root.activeWsId)]
        senseProc.running = true
      }
    }
  }

  // Scramble decoder timer for BarWidget
  Timer {
    id: scrambleTimer
    interval: 32
    repeat: true
    onTriggered: {
      var target = root.rawDisplayNote
      if (!target) {
        root.displayNote = ""
        stop()
        return
      }
      root.scrambleTick += 1
      var totalTicks = 12
      var locked = Math.floor((root.scrambleTick / totalTicks) * target.length)
      if (root.scrambleTick >= totalTicks) {
        root.displayNote = target
        stop()
        return
      }
      var out = ""
      for (var i = 0; i < target.length; i++) {
        if (i < locked || target[i] === " ") {
          out += target[i]
        } else {
          var g = Math.floor(Math.random() * root.scrambleGlyphs.length)
          out += root.scrambleGlyphs[g]
        }
      }
      root.displayNote = out
    }
  }

  // Scramble decoder timer for Lower-Third HUD
  property string hudTargetText: ""
  Timer {
    id: hudScrambleTimer
    interval: 18
    repeat: true
    onTriggered: {
      var target = root.hudTargetText
      if (!target) {
        root.hudDisplayText = ""
        stop()
        return
      }
      root.hudScrambleTick += 1
      var totalTicks = 8
      var locked = Math.floor((root.hudScrambleTick / totalTicks) * target.length)
      if (root.hudScrambleTick >= totalTicks) {
        root.hudDisplayText = target
        stop()
        return
      }
      var out = ""
      for (var i = 0; i < target.length; i++) {
        if (i < locked || target[i] === " ") {
          out += target[i]
        } else {
          out += root.scrambleGlyphs[Math.floor(Math.random() * root.scrambleGlyphs.length)]
        }
      }
      root.hudDisplayText = out
    }
  }

  Timer {
    id: hudHideTimer
    interval: 1450
    repeat: false
    onTriggered: root.hudVisible = false
  }

  Timer {
    id: stealthTimer
    interval: 3500
    repeat: false
    onTriggered: {
      if (root.fxMode === "stealth" && !pillButton.tooltipHovered) {
        root.stealthDimmed = true
      }
    }
  }

  // Bar Pill UI
  WidgetButton {
    id: pillButton
    bar: root.bar
    hasVisualContent: true
    labelVisible: false
    horizontalMargin: 4
    verticalPadding: 3
    fixedWidth: Math.max(Style.space(34), contentRow.implicitWidth + Style.space(20))
    fixedHeight: root.barSize
    dimmed: root.fxMode === "stealth" && root.stealthDimmed && !pillButton.tooltipHovered

    onPressed: function(button) {
      if (button === Qt.RightButton) {
        var idx = root.fxModes.indexOf(root.fxMode)
        var nextFx = root.fxModes[(idx + 1) % root.fxModes.length]
        Quickshell.execDetached([root.cliPath, "fx", nextFx])
      } else {
        if (root.bar && root.bar.shell && typeof root.bar.shell.toggle === "function") {
          root.bar.shell.toggle("heelgueta.omabeacon")
        } else {
          Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "heelgueta.omabeacon"])
        }
      }
    }

    Rectangle {
      id: pillBg
      anchors.fill: parent
      anchors.margins: 1
      radius: Style.cornerRadius
      clip: true
      color: root.hasNote
        ? Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.16)
        : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.05)
      border.width: 1
      border.color: root.hasNote
        ? Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, root.fxMode === "pulse" ? pulseBorderAlpha : 0.50)
        : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)

      property real pulseBorderAlpha: 0.45
      SequentialAnimation on pulseBorderAlpha {
        running: root.fxMode === "pulse" && root.hasNote
        loops: Animation.Infinite
        NumberAnimation { to: 0.95; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.30; duration: 900; easing.type: Easing.InOutSine }
      }

      // Amiga Copperbar shimmer FX
      Rectangle {
        visible: root.fxMode === "copper" && root.hasNote
        width: parent.width * 0.45
        height: parent.height
        opacity: 0.32
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.5; color: root.wsColor }
          GradientStop { position: 1.0; color: "transparent" }
        }
        property real sweepX: -width
        x: sweepX
        SequentialAnimation on sweepX {
          running: root.fxMode === "copper" && root.hasNote
          loops: Animation.Infinite
          NumberAnimation { from: -pillBg.width * 0.5; to: pillBg.width * 1.1; duration: 1800; easing.type: Easing.InOutQuad }
          PauseAnimation { duration: 400 }
        }
      }

      // Subtle CRT scanline overlay in copper mode
      Column {
        visible: root.fxMode === "copper" && root.hasNote
        anchors.fill: parent
        spacing: 2
        Repeater {
          model: 8
          Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(0, 0, 0, 0.18)
          }
        }
      }

      RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.space(5)

        // Beacon dot + optional sonar ring
        Item {
          width: Style.space(10)
          height: Style.space(10)

          Rectangle {
            id: pulseRing
            visible: root.fxMode === "pulse" && root.hasNote
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: root.wsColor
            property real ringScale: 1.0
            property real ringAlpha: 0.8
            scale: ringScale
            opacity: ringAlpha
            ParallelAnimation {
              running: root.fxMode === "pulse" && root.hasNote
              loops: Animation.Infinite
              NumberAnimation { target: pulseRing; property: "ringScale"; from: 0.9; to: 2.1; duration: 1400; easing.type: Easing.OutQuad }
              NumberAnimation { target: pulseRing; property: "ringAlpha"; from: 0.85; to: 0.0; duration: 1400; easing.type: Easing.OutQuad }
            }
          }

          Rectangle {
            anchors.centerIn: parent
            width: Style.space(7)
            height: Style.space(7)
            radius: width / 2
            color: root.hasNote ? root.wsColor : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.35)
          }
        }

        // Workspace number badge
        Text {
          text: String(root.activeWsId)
          color: root.hasNote ? root.wsColor : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.55)
          font.family: Style.font.monoFamily || (root.bar ? root.bar.fontFamily : "")
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        // Note text container (supports marquee clipping)
        Item {
          visible: root.hasNote
          implicitWidth: Math.min(noteLabel.implicitWidth, Style.space(220))
          implicitHeight: noteLabel.implicitHeight
          clip: true

          Text {
            id: noteLabel
            text: root.displayNote
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: (root.fxMode === "scramble" || root.fxMode === "copper")
              ? (Style.font.monoFamily || (root.bar ? root.bar.fontFamily : ""))
              : (root.bar ? root.bar.fontFamily : "")
            font.pixelSize: Style.font.caption
            font.bold: !root.isSensed
            font.italic: root.isSensed
            elide: root.fxMode === "marquee" ? Text.ElideNone : Text.ElideRight
            width: root.fxMode === "marquee" ? implicitWidth : parent.width

            property real scrollX: 0
            x: root.fxMode === "marquee" && implicitWidth > parent.width ? scrollX : 0
            SequentialAnimation on scrollX {
              running: root.fxMode === "marquee" && root.hasNote && noteLabel.implicitWidth > noteLabel.parent.width
              loops: Animation.Infinite
              PauseAnimation { duration: 700 }
              NumberAnimation {
                from: 0
                to: -(noteLabel.implicitWidth - noteLabel.parent.width)
                duration: Math.max(1200, (noteLabel.implicitWidth - noteLabel.parent.width) * 28)
              }
              PauseAnimation { duration: 700 }
              NumberAnimation { to: 0; duration: 600 }
            }
          }
        }

        // Subtle "+ note" hint when empty
        Text {
          visible: !root.hasNote
          text: "+"
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.40)
          font.family: root.bar ? root.bar.fontFamily : ""
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  // Optional Hacker Flash HUD (ticker | banner | splat | crt | brutal)
  PanelWindow {
    id: flashHudWindow
    visible: root.hudVisible || hudCard.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omabeacon-hud"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    readonly property bool isCentered: root.hudStyle === "splat" || root.hudStyle === "brutal"
    readonly property bool isFullWidth: root.hudStyle === "banner" || root.hudStyle === "crt" || root.hudStyle === "brutal"

    Rectangle {
      id: hudCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: flashHudWindow.isCentered ? parent.verticalCenter : undefined
      anchors.bottom: flashHudWindow.isCentered ? undefined : parent.bottom
      anchors.bottomMargin: flashHudWindow.isCentered ? 0 : (root.hudStyle === "banner" || root.hudStyle === "crt" ? Style.space(28) : Style.space(48))
      width: {
        if (flashHudWindow.isFullWidth) return parent.width
        if (root.hudStyle === "splat") return Math.min(parent.width - Style.gapsOut * 4, Math.max(Style.space(520), parent.width * 0.78))
        return Math.min(parent.width - Style.gapsOut * 4, Math.max(Style.space(340), hudMainCol.implicitWidth + Style.space(48)))
      }
      height: {
        if (root.hudStyle === "brutal") return Style.space(210)
        if (root.hudStyle === "splat") return Style.space(160)
        if (root.hudStyle === "crt") return Style.space(132)
        if (root.hudStyle === "banner") return Style.space(78)
        return Style.space(52)
      }
      radius: flashHudWindow.isFullWidth ? 0 : Style.cornerRadius
      clip: true
      color: {
        if (root.hudStyle === "brutal") return Qt.rgba(0.03, 0.03, 0.05, 0.92)
        if (root.hudStyle === "crt") return Qt.rgba(0.04, 0.05, 0.08, 0.94)
        return Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.92)
      }
      border.width: flashHudWindow.isFullWidth ? 0 : 2
      border.color: root.wsColor
      opacity: root.hudVisible ? 1.0 : 0.0
      scale: (flashHudWindow.isCentered && !root.hudVisible) ? 0.94 : 1.0

      Behavior on opacity {
        NumberAnimation { duration: root.hudVisible ? 55 : 130; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: root.hudVisible ? 70 : 130; easing.type: Easing.OutBack }
      }

      // Top & bottom neon rails for full-width/centered styles
      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: (root.hudStyle === "brutal" || root.hudStyle === "splat") ? 3 : 2
        color: root.wsColor
      }
      Rectangle {
        visible: flashHudWindow.isFullWidth || root.hudStyle === "splat"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: (root.hudStyle === "brutal" || root.hudStyle === "splat") ? 3 : 2
        color: root.wsColor
      }

      // CRT / Amiga copper raster bars (for crt & brutal)
      Column {
        visible: root.hudStyle === "crt"
        anchors.fill: parent
        spacing: 2
        opacity: 0.28
        Repeater {
          model: 12
          Rectangle {
            width: parent.width
            height: 8
            color: index % 3 === 0 ? root.wsColor : (index % 3 === 1 ? "#7dcfff" : "#bb9af7")
          }
        }
      }

      // Heavy scanlines
      Column {
        anchors.fill: parent
        spacing: root.hudStyle === "crt" || root.hudStyle === "brutal" ? 2 : 3
        opacity: root.hudStyle === "crt" || root.hudStyle === "brutal" ? 0.26 : 0.12
        Repeater {
          model: 48
          Rectangle {
            width: parent.width
            height: 1
            color: "#000000"
          }
        }
      }

      // Main HUD Content
      ColumnLayout {
        id: hudMainCol
        anchors.centerIn: parent
        spacing: Style.space(6)
        width: Math.min(hudCard.width - Style.space(48), parent.width - Style.space(48))

        // Telemetry micro-header for banner / splat / crt / brutal
        Text {
          visible: root.hudStyle !== "ticker"
          Layout.alignment: Qt.AlignHCenter
          text: {
            var wsStr = root.activeWsId < 10 ? "0" + root.activeWsId : String(root.activeWsId)
            if (root.hudStyle === "brutal") return ">>> WORKSPACE " + wsStr + " // LOCKED IN <<<"
            if (root.hudStyle === "crt") return ":: AMIGA-BEACON 0x" + wsStr + " :: " + root.fxMode.toUpperCase() + " ::"
            if (root.hudStyle === "splat") return "[// WS " + wsStr + " //]"
            return "0x" + wsStr + " // ACTIVE WORKSPACE CONTEXT"
          }
          color: root.wsColor
          font.family: Style.font.monoFamily || "monospace"
          font.pixelSize: (root.hudStyle === "brutal" || root.hudStyle === "splat") ? Style.font.body : Style.font.caption
          font.bold: true
          font.letterSpacing: 2.5
        }

        // Ticker layout (compact row) vs Big centered layouts
        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: Style.space(12)

          Rectangle {
            visible: root.hudStyle === "ticker"
            radius: Style.space(4)
            color: Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.22)
            border.width: 1
            border.color: root.wsColor
            implicitWidth: wsTag.implicitWidth + Style.space(14)
            implicitHeight: Style.space(28)

            Text {
              id: wsTag
              anchors.centerIn: parent
              text: "WS " + (root.activeWsId < 10 ? "0" + root.activeWsId : String(root.activeWsId))
              color: root.wsColor
              font.family: Style.font.monoFamily || "monospace"
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          // RGB-split brutalist text stack
          Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.min(hudMainCol.width, mainHudText.implicitWidth)
            implicitHeight: mainHudText.implicitHeight

            // Cyan chromatic aberration ghost (brutal only)
            Text {
              visible: root.hudStyle === "brutal"
              x: -4; y: -2
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: mainHudText.text
              color: Qt.rgba(0.2, 0.95, 1.0, 0.65)
              font: mainHudText.font
              elide: Text.ElideRight
            }

            // Magenta chromatic aberration ghost (brutal only)
            Text {
              visible: root.hudStyle === "brutal"
              x: 4; y: 2
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: mainHudText.text
              color: Qt.rgba(1.0, 0.2, 0.55, 0.65)
              font: mainHudText.font
              elide: Text.ElideRight
            }

            Text {
              id: mainHudText
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              text: root.hudDisplayText.toUpperCase()
              color: Color.foreground
              font.family: Style.font.monoFamily || "monospace"
              font.pixelSize: {
                if (root.hudStyle === "brutal") return Style.space(64)
                if (root.hudStyle === "splat") return Style.space(48)
                if (root.hudStyle === "crt") return Style.space(40)
                if (root.hudStyle === "banner") return Style.space(26)
                return Style.font.title || 18
              }
              font.bold: true
              font.letterSpacing: root.hudStyle === "brutal" ? 3 : (root.hudStyle === "ticker" ? 0 : 1.5)
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }

  Component.onCompleted: {
    loadState()
    if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id) {
      activeWsId = Hyprland.focusedWorkspace.id
      lastHudWsId = activeWsId
    }
    if (autoSense) senseDebounce.restart()
  }
}
