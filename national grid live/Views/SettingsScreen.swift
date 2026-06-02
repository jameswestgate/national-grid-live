import SwiftUI

/// App settings, presented as a sheet from the gear in the Live / Historic
/// navigation bars.
struct SettingsScreen: View {
    @AppStorage(AppSettings.generationVisualisationKey) private var visualisation: GenerationVisualisation = .bar
    @AppStorage(AppSettings.themeKey) private var theme: AppTheme = .system
    @AppStorage(AppSettings.showGraphLegendsKey) private var showGraphLegends = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Charts") {
                    Picker("Style", selection: $visualisation) {
                        ForEach(GenerationVisualisation.allCases) { option in
                            Label(option.displayName, systemImage: option.systemImage).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // Headerless section: separates the toggle into its own card
                // while it still reads as part of "Charts" above.
                Section {
                    Toggle("Show graph legends", isOn: $showGraphLegends)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        ForEach(AppTheme.allCases) { option in
                            Label(option.displayName, systemImage: option.systemImage).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Lock screen") {
                    Label("Widget", systemImage: "rectangle.on.rectangle.angled")
                        .foregroundStyle(.secondary)
                        .badge("Coming soon")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension View {
    /// Presents `SettingsScreen` as a sheet. The trigger is the settings icon in
    /// `ScreenHeader`; shared by the Live and Historic screens.
    func settingsSheet(_ isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) { SettingsScreen() }
    }
}

#Preview {
    SettingsScreen()
}
