import SwiftUI

// An empty app: Xcode's UI-test runner needs a host. The tests drive NPay by its bundle id.
@main
struct HostApp: App {
  var body: some Scene { WindowGroup { Text("UIDriver host") } }
}
