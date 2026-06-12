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

                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsScreen()
                    } label: {
                        Label("Alerts", systemImage: "bell.badge")
                    }
                }

                Section("Widgets") {
                    NavigationLink {
                        WidgetHelp()
                    } label: {
                        Label("Add a widget", systemImage: "rectangle.on.rectangle.angled")
                    }
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

/// Walkthrough for adding the Home Screen and Lock Screen widgets. iOS gives
/// apps no way to place a widget programmatically — the user adds them from
/// the Home/Lock Screen — so this screen simply explains the gestures.
private struct WidgetHelp: View {
    private let homeSteps = [
        "Touch and hold your Home Screen, then tap **Edit** and choose **Add Widget**.",
        "Search for **National Grid: Live**, then add the **Generation mix** or **Interconnectors** widget in the size you prefer.",
    ]
    private let lockSteps = [
        "Touch and hold your Lock Screen, then tap **Customise**.",
        "Tap the Lock Screen, then tap the widget area **below the time**.",
        "Choose **National Grid: Live**, then add the **Demand**, **Generation mix** or **Live Minimal** widget.",
    ]

    var body: some View {
        List {
            Section {
                stepRows(homeSteps)
            } header: {
                Text("Home Screen")
            } footer: {
                Text("Home Screen widgets show the live generation mix and interconnector flows in colour.")
            }
            Section {
                stepRows(lockSteps)
            } header: {
                Text("Lock Screen")
            } footer: {
                Text("Lock Screen widgets show **Demand** (Demand = Generation + Transfers), **Generation mix** (the live fuel breakdown and renewable share) and **Live Minimal** (demand, price and carbon with the top live sources). All widgets refresh automatically.")
            }
        }
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepRows(_ steps: [String]) -> some View {
        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
            HStack(alignment: .top, spacing: 14) {
                Text("\(index + 1)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.accentColor))
                Text(.init(step))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)
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
