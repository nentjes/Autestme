// ColorMode.swift
import SwiftUI

enum ColorMode: String, CaseIterable, Identifiable {
    case fixed, random  // Vast of willekeurig

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .fixed: return "Vaste kleur per vorm"
        case .random: return "Willekeurige kleur"
        }
    }
}
