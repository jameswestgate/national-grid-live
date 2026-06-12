import SwiftUI
import UserNotifications

/// Settings → Notifications: five opt-in alerts with fixed thresholds (see
/// `GridAlert`). Turning on the first toggle asks for notification permission;
/// if the user has denied it in the system Settings, an explanatory section
/// with a deep link appears instead of failing silently.
struct NotificationSettingsScreen: View {
    @AppStorage(AppSettings.alertHighCarbonKey) private var highCarbon = false
    @AppStorage(AppSettings.alertLowCarbonKey) private var lowCarbon = false
    @AppStorage(AppSettings.alertHighPriceKey) private var highPrice = false
    @AppStorage(AppSettings.alertLowPriceKey) private var lowPrice = false
    @AppStorage(AppSettings.alertNegativePriceKey) private var negativePrice = false

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @Environment(\.scenePhase) private var scenePhase

    private var anyAlertOn: Bool {
        highCarbon || lowCarbon || highPrice || lowPrice || negativePrice
    }

    var body: some View {
        List {
            if authStatus == .denied && anyAlertOn {
                Section {
                    Label(
                        "Notifications are turned off for this app, so alerts can't be delivered.",
                        systemImage: "bell.slash")
                    .font(.subheadline)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            Section("Carbon intensity") {
                alertToggle("High carbon intensity",
                            detail: "Above \(Int(GridAlert.highCarbonThreshold)) g/kWh",
                            isOn: $highCarbon)
                alertToggle("Low carbon intensity",
                            detail: "Below \(Int(GridAlert.lowCarbonThreshold)) g/kWh",
                            isOn: $lowCarbon)
            }

            Section {
                alertToggle("High price",
                            detail: "Above £\(Int(GridAlert.highPriceThreshold))/MWh",
                            isOn: $highPrice)
                alertToggle("Low price",
                            detail: "Below £\(Int(GridAlert.lowPriceThreshold))/MWh",
                            isOn: $lowPrice)
                alertToggle("Negative price",
                            detail: "Below £0/MWh",
                            isOn: $negativePrice)
            } header: {
                Text("Price")
            } footer: {
                Text("You'll get at most one alert of each type per day.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshAuthStatus() }
        .onChange(of: scenePhase) { _, phase in
            // Re-check after a trip to the system Settings app.
            if phase == .active {
                Task { await refreshAuthStatus() }
            }
        }
    }

    private func alertToggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: isOn.wrappedValue) { _, nowOn in
            if nowOn { Task { await authorizeIfNeeded() } }
        }
    }

    private func refreshAuthStatus() async {
        authStatus = await GridAlertCenter().authorizationStatus()
    }

    private func authorizeIfNeeded() async {
        if authStatus == .notDetermined {
            _ = await GridAlertCenter().requestAuthorization()
        }
        await refreshAuthStatus()
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
}
