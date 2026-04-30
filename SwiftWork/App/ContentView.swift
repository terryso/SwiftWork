import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sidebar")
                .navigationTitle("SwiftWork")
        } detail: {
            Text("Workspace")
        }
    }
}

#Preview {
    ContentView()
}
