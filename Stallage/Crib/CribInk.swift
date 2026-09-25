import SwiftUI

/// Role: Crib. Named colours and SF Pro. Hex lives only here: #1D161A #291E24 #F2EDF0 #DD5F9E #A8949E.
enum CribInk {
    static let face = "SF Pro"

    enum Hex {
        static let background = "#1D161A"
        static let surface = "#291E24"
        static let ink = "#F2EDF0"
        static let accent = "#DD5F9E"
        static let muted = "#A8949E"
    }

    enum Palette {
        static let background = Color("background")
        static let surface = Color("surface")
        static let ink = Color("ink")
        static let accent = Color("slgAccent")
        static let muted = Color("muted")
    }
}
