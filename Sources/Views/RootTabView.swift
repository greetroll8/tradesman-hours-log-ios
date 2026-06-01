import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("tab.today", systemImage: "timer")
                }

            JobsView()
                .tabItem {
                    Label("tab.jobs", systemImage: "hammer")
                }

            ClientsView()
                .tabItem {
                    Label("tab.clients", systemImage: "person.2")
                }

            ReportsView()
                .tabItem {
                    Label("tab.reports", systemImage: "doc.text")
                }

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape")
                }
        }
    }
}
