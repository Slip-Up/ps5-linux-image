// qml ps5-splash.qml -- <status file>
// Status file: percent (-1 = none), headline, detail; "quit" fades out.

import QtQuick
import QtQuick.Window
import QtQuick.Shapes

Window {
    id: root
    visible: true
    visibility: Window.FullScreen
    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    title: "PS5 Linux"          // ps5-splash looks for this title
    color: "#0a0d12"

    // Laid out for 1080 lines.
    readonly property real u: height / 1080
    readonly property string face: "Adwaita Sans"

    readonly property color textMain: "#f4f6f9"
    readonly property color textDim: "#93a0ae"
    readonly property color textFaint: "#4a5563"
    readonly property color accentA: "#1ac8ff"
    readonly property color accentB: "#2d73ff"

    property int percent: -1
    property string headline: "Starting Steam"
    property string detail: ""
    property bool leaving: false
    readonly property bool measured: percent >= 0

    readonly property string statusFile: {
        var a = Qt.application.arguments
        return a.length > 0 ? a[a.length - 1] : ""
    }

    function poll() {
        if (statusFile === "" || statusFile.endsWith(".qml"))
            return
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            var lines = (xhr.responseText || "").split("\n")
            if (lines.length === 0 || lines[0] === "")
                return
            if (lines[0].indexOf("quit") === 0) {
                root.leaving = true
                return
            }
            var p = parseInt(lines[0])
            root.percent = isNaN(p) ? -1 : Math.max(-1, Math.min(100, p))
            if (lines.length > 1 && lines[1] !== "")
                root.headline = lines[1]
            root.detail = lines.length > 2 ? lines[2] : ""
        }
        xhr.open("GET", "file://" + statusFile)
        xhr.send()
    }

    Timer { interval: 250; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.poll() }

    // ---- Background -------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#131a24" }
            GradientStop { position: 0.5; color: "#0d1219" }
            GradientStop { position: 1.0; color: "#07090d" }
        }
    }

    component SoftLight: Shape {
        id: light
        property color tint: "#1a8fe6"
        property real strength: 0.16
        function a(k) { return Qt.rgba(tint.r, tint.g, tint.b, strength * k) }
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: light.width / 2; centerY: light.height / 2
                focalX: centerX; focalY: centerY
                centerRadius: light.width / 2
                GradientStop { position: 0.00; color: light.a(1.00) }
                GradientStop { position: 0.12; color: light.a(0.86) }
                GradientStop { position: 0.25; color: light.a(0.66) }
                GradientStop { position: 0.40; color: light.a(0.44) }
                GradientStop { position: 0.55; color: light.a(0.26) }
                GradientStop { position: 0.70; color: light.a(0.13) }
                GradientStop { position: 0.85; color: light.a(0.045) }
                GradientStop { position: 1.00; color: light.a(0.0) }
            }
            startX: 0; startY: 0
            PathLine { x: light.width; y: 0 }
            PathLine { x: light.width; y: light.height }
            PathLine { x: 0; y: light.height }
            PathLine { x: 0; y: 0 }
        }
    }

    SoftLight {
        x: -420 * root.u; y: -620 * root.u
        width: 1500 * root.u; height: width
        tint: "#3f6bd6"; strength: 0.10
    }
    SoftLight {
        id: centreLight
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40 * root.u
        width: 1700 * root.u; height: width
        tint: "#1a8fe6"; strength: 0.17
        opacity: 0.7
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 1.0; duration: 4600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.7; duration: 4600; easing.type: Easing.InOutSine }
        }
    }

    // Fine grain, drawn once. It breaks up the steps an 8-bit display would
    // otherwise show in the two lights.
    Canvas {
        id: grain
        anchors.fill: parent
        opacity: 0.9
        renderStrategy: Canvas.Immediate
        onPaint: {
            var ctx = getContext("2d")
            var w = Math.max(1, Math.floor(width)), h = Math.max(1, Math.floor(height))
            var img = ctx.createImageData(w, h)
            var d = img.data
            for (var i = 0; i < d.length; i += 4) {
                var v = Math.random() < 0.5 ? 0 : 255
                d[i] = v; d[i + 1] = v; d[i + 2] = v
                d[i + 3] = Math.random() * 7
            }
            ctx.putImageData(img, 0, 0)
        }
    }

    // ---- Content ----------------------------------------------------------
    Item {
        id: stage
        anchors.fill: parent
        opacity: 0

        Item {
            id: block
            width: 540 * root.u
            height: 330 * root.u
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -10 * root.u

            // Spinner
            Item {
                id: ring
                width: 84 * root.u
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0

                readonly property real r: width / 2 - 5 * root.u
                readonly property real stroke: 3.5 * root.u
                readonly property real minSweep: 4       // degrees
                readonly property real travel: 286       // degrees

                property real t: 0
                property real base: 0
                function ease(x) { return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2 }
                readonly property real grow: ease(Math.min(1, t * 2))
                readonly property real shrink: ease(Math.max(0, t * 2 - 1))
                readonly property real tail: base + travel * shrink
                readonly property real head: base + minSweep + travel * grow

                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { target: ring; property: "t"; from: 0; to: 1; duration: 1500 }
                    ScriptAction { script: { ring.base = (ring.base + ring.travel) % 360; ring.t = 0 } }
                }

                // faint full circle
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: "#17ffffff"
                        strokeWidth: ring.stroke
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: ring.width / 2; centerY: ring.height / 2
                            radiusX: ring.r; radiusY: ring.r
                            startAngle: 0; sweepAngle: 360
                        }
                    }
                }

                Item {
                    id: turning
                    anchors.fill: parent
                    RotationAnimator on rotation { from: -90; to: 270; duration: 2600; loops: Animation.Infinite }

                    // soft halo under the arc
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        opacity: 0.22
                        ShapePath {
                            strokeColor: root.accentA
                            strokeWidth: ring.stroke * 3.2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: ring.width / 2; centerY: ring.height / 2
                                radiusX: ring.r; radiusY: ring.r
                                startAngle: ring.tail; sweepAngle: ring.head - ring.tail
                            }
                        }
                    }
                    // the arc
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: root.accentA
                            strokeWidth: ring.stroke
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: ring.width / 2; centerY: ring.height / 2
                                radiusX: ring.r; radiusY: ring.r
                                startAngle: ring.tail; sweepAngle: ring.head - ring.tail
                            }
                        }
                    }
                }
            }

            // Headline
            Item {
                id: headlineBox
                width: parent.width
                height: 48 * root.u
                y: ring.height + 46 * root.u
                property string shown: root.headline

                Text {
                    id: headlineText
                    anchors.centerIn: parent
                    text: headlineBox.shown
                    color: root.textMain
                    font.family: root.face
                    font.pixelSize: 38 * root.u
                    font.weight: Font.Light
                    font.letterSpacing: 0.2 * root.u
                }
                Connections {
                    target: root
                    function onHeadlineChanged() { swap.restart() }
                }
                SequentialAnimation {
                    id: swap
                    NumberAnimation { target: headlineText; property: "opacity"; to: 0; duration: 160 }
                    ScriptAction { script: headlineBox.shown = root.headline }
                    NumberAnimation { target: headlineText; property: "opacity"; to: 1; duration: 260 }
                }
            }

            // Progress
            Item {
                id: progress
                width: parent.width
                height: 70 * root.u
                y: headlineBox.y + headlineBox.height + 50 * root.u
                opacity: root.measured ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                Text {
                    anchors.left: parent.left
                    text: root.detail
                    color: root.textDim
                    font.family: root.face
                    font.pixelSize: 17 * root.u
                }
                Text {
                    anchors.right: parent.right
                    text: Math.max(0, root.percent) + "%"
                    color: root.textMain
                    font.family: root.face
                    font.pixelSize: 17 * root.u
                    font.weight: Font.Medium
                    font.features: { "tnum": 1 }
                }

                Item {
                    id: bar
                    width: parent.width
                    height: 5 * root.u
                    y: 36 * root.u

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: "#16ffffff"
                    }
                    // soft halo under the filled part
                    Rectangle {
                        x: 0
                        y: -3 * root.u
                        width: fill.width
                        height: bar.height + 6 * root.u
                        radius: height / 2
                        color: root.accentA
                        opacity: 0.16
                    }
                    Rectangle {
                        id: fill
                        height: parent.height
                        radius: height / 2
                        width: Math.max(height, bar.width * Math.max(0, root.percent) / 100)
                        Behavior on width { SmoothedAnimation { velocity: 220 * root.u; duration: 700 } }
                        clip: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: root.accentB }
                            GradientStop { position: 1.0; color: root.accentA }
                        }
                        Rectangle {
                            id: sheen
                            width: 120 * root.u
                            height: parent.height
                            x: -width
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#00ffffff" }
                                GradientStop { position: 0.5; color: "#66ffffff" }
                                GradientStop { position: 1.0; color: "#00ffffff" }
                            }
                            SequentialAnimation on x {
                                loops: Animation.Infinite
                                NumberAnimation { from: -sheen.width; to: bar.width; duration: 1900; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 900 }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: headlineBox.y + headlineBox.height + 14 * root.u
                text: root.detail
                color: root.textDim
                font.family: root.face
                font.pixelSize: 17 * root.u
                opacity: (!root.measured && root.detail !== "") ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
        }

        // Footer
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60 * root.u
            spacing: 18 * root.u

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "This is only needed the first time."
                color: root.textDim
                font.family: root.face
                font.pixelSize: 15 * root.u
                opacity: root.measured ? 0.85 : 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 28 * root.u
                height: Math.max(1, Math.round(1 * root.u))
                color: "#2a3340"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PS5 LINUX"
                color: root.textFaint
                font.family: root.face
                font.pixelSize: 12 * root.u
                font.weight: Font.DemiBold
                font.letterSpacing: 5 * root.u
            }
        }

        NumberAnimation on opacity { from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
    }

    // Fade out and quit
    Rectangle {
        id: curtain
        anchors.fill: parent
        color: "#000000"
        opacity: 0
        states: State {
            when: root.leaving
            PropertyChanges { target: curtain; opacity: 1 }
        }
        transitions: Transition {
            SequentialAnimation {
                NumberAnimation { property: "opacity"; duration: 320; easing.type: Easing.InCubic }
                ScriptAction { script: Qt.quit() }
            }
        }
    }
}
