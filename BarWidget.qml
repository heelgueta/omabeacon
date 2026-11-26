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
  readonly property var palettes: ({
    "tokyo": ["#f7768e", "#ff9e64", "#e0af68", "#9ece6a", "#73daca", "#7dcfff", "#7aa2f7", "#bb9af7", "#ff79c6", "#c0caf5"],
    "neon": ["#ff0055", "#ff5500", "#ffcc00", "#39ff14", "#00ffcc", "#00e5ff", "#2979ff", "#aa00ff", "#ff00ff", "#ffffff"],
    "pastel": ["#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb", "#89b4fa", "#cba6f7", "#f5c2e7", "#cdd6f4"],
    "mono": ["#00ff66", "#22ee77", "#44dd88", "#66cc99", "#88ddaa", "#aaf0cc", "#ccffdd", "#a0c4b0", "#7aa899", "#e0fff0"],
    "fire": ["#ff1e42", "#ff4d2e", "#ff7700", "#ffa600", "#ffd000", "#ffe866", "#fff4b8", "#ff6b6b", "#ff3b8d", "#ffffff"]
  })
  readonly property var defaultPalette: palettes[paletteName] || palettes["tokyo"]

  property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  property var workspacesData: ({})
  property string fxMode: "scramble"
  property bool autoSense: true
  property bool flashHud: true
  property string hudStyle: "glitch"
  property string hudPos: "center"
  property string hudSize: "mega"
  property string hudColorFx: "mid"
  property string hudCase: "upper"
  property string paletteName: "tokyo"
  property string glyphPos: "above"
  property int hudPreviewSeq: -1
  property int pendingAutoHudWsId: -1
  property string sensedText: ""
  property int sensedWsId: -1

  // Current workspace computed properties
  readonly property var wsEntry: (workspacesData && workspacesData[String(activeWsId)]) ? workspacesData[String(activeWsId)] : null
  readonly property string wsGlyph: wsEntry && wsEntry.glyph ? String(wsEntry.glyph) : ""
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
    root.scrambleTick = 0
    scrambleTimer.restart()
  }

  function triggerHud(wsId, text, forceDemo) {
    if ((!root.flashHud && !forceDemo) || !text || text === "") return
    root.hudVisible = true
    root.hudScrambleTick = 0
    root.hudTargetText = text
    root.hudDisplayText = text
    hudScrambleTimer.restart()
    hudHideTimer.interval = (root.hudStyle === "glitch" || root.hudStyle === "arcade") ? 420 : 480
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
        if (root.rawDisplayNote !== "") {
          root.pendingAutoHudWsId = -1
          root.triggerHud(newWsId, root.rawDisplayNote, false)
        } else if (root.autoSense) {
          root.pendingAutoHudWsId = newWsId
        }
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
      root.fxMode = "scramble"
      root.autoSense = (data.autoSense === undefined) ? true : !!data.autoSense
      root.flashHud = (data.flashHud === undefined) ? true : !!data.flashHud
      var st = data.hudStyle || "glitch"
      if (st === "brutal" || st === "boss") st = "glitch"
      root.hudStyle = st
      root.hudPos = data.hudPos || "center"
      root.hudSize = data.hudSize || "mega"
      root.hudColorFx = data.hudColorFx || "mid"
      root.hudCase = data.hudCase || "upper"
      root.paletteName = data.palette || "tokyo"
      root.glyphPos = data.glyphPos || "above"
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
        if (root.pendingAutoHudWsId === root.activeWsId && root.manualNote === "" && root.sensedText !== "" && root.sensedText !== "empty") {
          root.pendingAutoHudWsId = -1
          root.triggerHud(root.activeWsId, "⚡ " + root.sensedText, false)
        }
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

  // Bar Pill UI
  WidgetButton {
    id: pillButton
    bar: root.bar
    hasVisualContent: true
    labelVisible: false
    horizontalMargin: 4
    verticalPadding: 3
    fixedWidth: Math.max(Style.space(36), contentRow.implicitWidth + Style.space(22))
    fixedHeight: root.barSize
    tooltipText: {
      var head = "Workspace " + root.activeWsId + (root.wsGlyph !== "" ? (" " + root.wsGlyph) : "")
      var body = root.rawDisplayNote !== "" ? root.rawDisplayNote : "No note set"
      return head + " — " + body + "\nHUD: " + root.hudStyle + " (" + root.hudSize + ")\nLeft-click: edit · Right-click: toggle HUD"
    }

    onPressed: function(button) {
      if (button === Qt.RightButton) {
        Quickshell.execDetached([root.cliPath, "hud", "toggle"])
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
        ? Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.52)
        : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.15)

      RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Style.space(6)

        // Beacon dot
        Rectangle {
          width: Style.space(8)
          height: Style.space(8)
          radius: width / 2
          color: root.hasNote ? root.wsColor : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.35)
        }

        // Workspace number badge + optional glyph
        Text {
          text: root.wsGlyph !== "" ? (root.activeWsId + " " + root.wsGlyph) : String(root.activeWsId)
          color: root.hasNote ? root.wsColor : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.55)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
        }

        // Note text container
        Item {
          visible: root.hasNote
          implicitWidth: Math.min(noteLabel.implicitWidth, Style.space(260))
          implicitHeight: noteLabel.implicitHeight
          clip: true

          Text {
            id: noteLabel
            text: root.displayNote
            color: root.bar ? root.bar.foreground : Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: !root.isSensed
            font.italic: root.isSensed
            elide: Text.ElideRight
            width: parent.width
          }
        }

        // Subtle "+ note" hint when empty
        Text {
          visible: !root.hasNote
          text: "+"
          color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.40)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }
      }
    }
  }

  // Optional Transparent Hacker Flash HUD (10 styles + size + color flare)
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

    readonly property real sizeMult: {
      if (root.hudSize === "sm") return 0.55
      if (root.hudSize === "lg") return 1.35
      if (root.hudSize === "xl") return 1.80
      if (root.hudSize === "xxl") return 2.35
      if (root.hudSize === "mega") return 3.15
      if (root.hudSize === "giga") return 4.50
      if (root.hudSize === "tera") return 6.20
      return 1.0
    }
    readonly property bool allowOverflow: root.hudSize === "xxl" || root.hudSize === "mega" || root.hudSize === "giga" || root.hudSize === "tera"
    readonly property real accentAlpha: root.hudColorFx === "low" ? 0.45 : (root.hudColorFx === "mid" ? 0.85 : 1.0)
    readonly property color effectiveAccent: Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, accentAlpha)
    readonly property color effectiveTextColor: root.hudColorFx === "high"
      ? Qt.tint(Color.foreground, Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.48))
      : Color.foreground

    Item {
      id: hudCard
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: root.hudPos === "top" ? parent.top : undefined
      anchors.topMargin: root.hudPos === "top" ? Style.space(56) : 0
      anchors.verticalCenter: root.hudPos === "center" ? parent.verticalCenter : undefined
      anchors.bottom: root.hudPos === "bottom" ? parent.bottom : undefined
      anchors.bottomMargin: root.hudPos === "bottom" ? Style.space(44) : 0
      width: parent.width - Style.gapsOut * 2
      height: Math.max(Style.space(90), hudMainCol.implicitHeight + Style.space(40))
      opacity: root.hudVisible ? 1.0 : 0.0
      scale: !root.hudVisible ? (root.hudStyle === "arcade" ? 1.12 : 0.94) : 1.0
      rotation: root.hudStyle === "arcade" ? -2.2 : 0

      Behavior on opacity {
        NumberAnimation { duration: root.hudVisible ? 45 : 95; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: root.hudVisible ? 55 : 95; easing.type: Easing.OutBack }
      }

      // --- FLARE FX (available on ANY style when hudColorFx === "flare") ---
      Item {
        visible: root.hudColorFx === "flare"
        anchors.centerIn: parent
        width: flashHudWindow.width
        height: Style.space(120) * flashHudWindow.sizeMult

        // Soft ambient color halo
        Rectangle {
          anchors.centerIn: parent
          width: parent.width * 0.72
          height: Style.space(44) * flashHudWindow.sizeMult
          radius: height / 2
          opacity: 0.22
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.wsColor }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }
        // Anamorphic horizontal lens-flare streak
        Rectangle {
          anchors.centerIn: parent
          width: root.hudVisible ? flashHudWindow.width * 0.96 : 0
          height: 3
          opacity: 0.9
          Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutExpo } }
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.35; color: root.wsColor }
            GradientStop { position: 0.5; color: "#ffffff" }
            GradientStop { position: 0.65; color: root.wsColor }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }
        // Vertical star-flare spike
        Rectangle {
          anchors.centerIn: parent
          width: 2
          height: root.hudVisible ? Style.space(90) * Math.min(2.0, flashHudWindow.sizeMult) : 0
          opacity: 0.65
          Behavior on height { NumberAnimation { duration: 110; easing.type: Easing.OutExpo } }
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.wsColor }
            GradientStop { position: 1.0; color: "transparent" }
          }
        }
      }

      // --- WIRE: floating corner reticle brackets ---
      Item {
        visible: root.hudStyle === "wire"
        anchors.centerIn: parent
        width: Math.min(parent.width, Math.max(Style.space(320), hudMainCol.implicitWidth + Style.space(56)))
        height: hudMainCol.implicitHeight + Style.space(28)

        Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: 20; height: 2; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: 2; height: 20; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 20; height: 2; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 2; height: 20; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 20; height: 2; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 2; height: 20; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 20; height: 2; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 2; height: 20; color: flashHudWindow.effectiveAccent }
      }

      // --- LASER: twin expanding razor beams ---
      Item {
        visible: root.hudStyle === "laser"
        anchors.centerIn: parent
        width: parent.width
        height: hudMainCol.implicitHeight + Style.space(26)
        Rectangle {
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.hudVisible ? parent.width * 0.88 : 0
          height: 2
          color: flashHudWindow.effectiveAccent
          Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutExpo } }
        }
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.hudVisible ? parent.width * 0.88 : 0
          height: 2
          color: flashHudWindow.effectiveAccent
          Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutExpo } }
        }
      }

      // --- ARCADE: slanted neon speed-stripes ---
      Row {
        visible: root.hudStyle === "arcade"
        anchors.centerIn: parent
        spacing: Style.space(18)
        opacity: 0.85
        Repeater {
          model: 2
          Rectangle {
            width: Style.space(180)
            height: 4
            color: flashHudWindow.effectiveAccent
            visible: false
          }
        }
      }
      Item {
        visible: root.hudStyle === "arcade"
        anchors.centerIn: parent
        width: Math.min(parent.width, hudMainCol.implicitWidth + Style.space(120))
        height: hudMainCol.implicitHeight + Style.space(24)
        Rectangle {
          anchors.top: parent.top; anchors.left: parent.left
          width: root.hudVisible ? parent.width * 0.42 : 0; height: 4
          color: flashHudWindow.effectiveAccent
          Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutExpo } }
        }
        Rectangle {
          anchors.bottom: parent.bottom; anchors.right: parent.right
          width: root.hudVisible ? parent.width * 0.42 : 0; height: 4
          color: flashHudWindow.effectiveAccent
          Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutExpo } }
        }
      }

      // --- CYBER: asymmetric edge ticks ---
      Item {
        visible: root.hudStyle === "cyber"
        anchors.centerIn: parent
        width: Math.min(parent.width, Math.max(Style.space(380), hudMainCol.implicitWidth + Style.space(80)))
        height: hudMainCol.implicitHeight + Style.space(28)
        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height * 0.7; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height * 0.7; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: Style.space(64); height: 2; color: flashHudWindow.effectiveAccent }
        Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: Style.space(64); height: 2; color: flashHudWindow.effectiveAccent }
      }

      // --- RADAR: concentric expanding sonar rings ---
      Item {
        visible: root.hudStyle === "radar"
        anchors.centerIn: parent
        width: Style.space(220); height: Style.space(220)
        Repeater {
          model: 2
          Rectangle {
            anchors.centerIn: parent
            width: root.hudVisible ? Style.space(140 + index * 90) : Style.space(20)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.45 - index * 0.18)
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutQuad } }
          }
        }
      }

      // --- SINE: animated 9-bar demoscene spectrum ---
      Row {
        visible: root.hudStyle === "sine"
        anchors.centerIn: parent
        spacing: Style.space(10)
        opacity: 0.28
        Repeater {
          model: 9
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(6)
            height: Style.space(24) + (index % 3) * Style.space(18)
            radius: 3
            color: flashHudWindow.effectiveAccent
            SequentialAnimation on height {
              running: root.hudStyle === "sine" && root.hudVisible
              loops: Animation.Infinite
              NumberAnimation { to: Style.space(70 - Math.abs(index - 4) * 8); duration: 140 + index * 20 }
              NumberAnimation { to: Style.space(18 + (index % 3) * 10); duration: 140 + index * 20 }
            }
          }
        }
      }

      // --- VHS: corner OSD stamp ---
      Text {
        visible: root.hudStyle === "vhs"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: Style.space(48)
        text: "▶ PLAY   00:" + (root.activeWsId < 10 ? "0" + root.activeWsId : String(root.activeWsId))
        color: flashHudWindow.effectiveAccent
        font.family: Style.font.monoFamily || "monospace"
        font.pixelSize: Style.font.body
        font.bold: true
      }

      // Optional Emoji / Glyph ABOVE (anchored to hudMainCol so text stays dead-center)
      Text {
        visible: root.wsGlyph !== "" && root.glyphPos === "above"
        anchors.horizontalCenter: hudMainCol.horizontalCenter
        anchors.bottom: hudMainCol.top
        anchors.bottomMargin: Style.space(8)
        text: root.wsGlyph
        color: flashHudWindow.effectiveAccent
        font.pixelSize: Math.round(Style.space(34) * flashHudWindow.sizeMult)
      }

      // Main HUD Content
      ColumnLayout {
        id: hudMainCol
        anchors.centerIn: parent
        spacing: Style.space(6)
        width: flashHudWindow.allowOverflow ? implicitWidth : (hudCard.width - Style.space(48))

        // Telemetry micro-header
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: {
            var wsStr = root.activeWsId < 10 ? "0" + root.activeWsId : String(root.activeWsId)
            if (root.hudStyle === "glitch") return ">>> WORKSPACE " + wsStr + " // LOCKED IN <<<"
            if (root.hudStyle === "arcade") return "STAGE " + wsStr + " // READY!"
            if (root.hudStyle === "cyber") return "SYS.NET // NODE_" + wsStr + " // ACTIVE"
            if (root.hudStyle === "dos") return "C:\\OMARCHY\\WS_" + wsStr + "> [OK]"
            if (root.hudStyle === "radar") return "+ TARGET ACQUIRED :: SECTOR " + wsStr + " +"
            if (root.hudStyle === "sine") return "~~ DEMOSCENE :: WS " + wsStr + " ~~"
            if (root.hudStyle === "vhs") return "CH-" + wsStr + " // SP"
            if (root.hudStyle === "laser") return "0x" + wsStr + " // VECTOR LOCK"
            return "RETICLE // WS " + wsStr
          }
          color: flashHudWindow.effectiveAccent
          font.family: Style.font.monoFamily || "monospace"
          font.pixelSize: (root.hudStyle === "glitch" || root.hudStyle === "arcade") ? Style.font.body : Style.font.caption
          font.bold: true
          font.letterSpacing: 2.5
        }

        // Main Text Stack (transparent floating over everything)
        Item {
          Layout.alignment: Qt.AlignHCenter
          implicitWidth: flashHudWindow.allowOverflow ? mainHudText.implicitWidth : Math.min(hudMainCol.width, mainHudText.implicitWidth)
          implicitHeight: mainHudText.implicitHeight

          // Dark legibility shadow (all transparent styles)
          Text {
            x: 2; y: 3
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: mainHudText.text
            color: Qt.rgba(0, 0, 0, 0.85)
            font: mainHudText.font
            elide: mainHudText.elide
          }

          // Cyan RGB-split ghost (glitch & vhs)
          Text {
            visible: root.hudStyle === "glitch" || root.hudStyle === "vhs"
            x: root.hudStyle === "vhs" ? -3 : -4
            y: root.hudStyle === "vhs" ? 0 : -2
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: mainHudText.text
            color: Qt.rgba(0.2, 0.95, 1.0, 0.65)
            font: mainHudText.font
            elide: mainHudText.elide
          }

          // Magenta RGB-split ghost (glitch & vhs)
          Text {
            visible: root.hudStyle === "glitch" || root.hudStyle === "vhs"
            x: root.hudStyle === "vhs" ? 3 : 4
            y: root.hudStyle === "vhs" ? 0 : 2
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: mainHudText.text
            color: Qt.rgba(1.0, 0.2, 0.55, 0.65)
            font: mainHudText.font
            elide: mainHudText.elide
          }

          // Accent shadow offset (arcade / cyber)
          Text {
            visible: root.hudStyle === "arcade" || root.hudStyle === "cyber"
            x: 4; y: 4
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: mainHudText.text
            color: Qt.rgba(root.wsColor.r, root.wsColor.g, root.wsColor.b, 0.55)
            font: mainHudText.font
            elide: mainHudText.elide
          }

          Text {
            id: mainHudText
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: {
              var base = root.hudDisplayText
              if (root.hudCase === "upper") base = base.toUpperCase()
              else if (root.hudCase === "lower") base = base.toLowerCase()
              if (root.hudStyle === "dos") return base + " █"
              return base
            }
            color: flashHudWindow.effectiveTextColor
            font.family: Style.font.monoFamily || "monospace"
            font.pixelSize: {
              var basePx = 36
              if (root.hudStyle === "glitch") basePx = 64
              else if (root.hudStyle === "arcade") basePx = 56
              else if (root.hudStyle === "cyber") basePx = 50
              else if (root.hudStyle === "sine") basePx = 44
              else if (root.hudStyle === "vhs") basePx = 44
              else if (root.hudStyle === "radar") basePx = 40
              else if (root.hudStyle === "dos") basePx = 38
              else if (root.hudStyle === "laser") basePx = 34
              else basePx = 28
              return Math.round(Style.space(basePx) * flashHudWindow.sizeMult)
            }
            font.bold: true
            font.letterSpacing: {
              if (root.hudStyle === "laser") return 4.5
              if (root.hudStyle === "glitch") return 3
              return 1.8
            }
            elide: flashHudWindow.allowOverflow ? Text.ElideNone : Text.ElideRight
          }
        }
      }

      // Optional Emoji / Glyph BELOW (anchored to hudMainCol so text stays dead-center)
      Text {
        visible: root.wsGlyph !== "" && root.glyphPos === "below"
        anchors.horizontalCenter: hudMainCol.horizontalCenter
        anchors.top: hudMainCol.bottom
        anchors.topMargin: Style.space(8)
        text: root.wsGlyph
        color: flashHudWindow.effectiveAccent
        font.pixelSize: Math.round(Style.space(34) * flashHudWindow.sizeMult)
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
