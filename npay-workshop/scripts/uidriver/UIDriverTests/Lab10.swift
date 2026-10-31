import XCTest

/// Lab 10: sign in over HTTPS; the script installs different builds and trusts different roots between tests.
/// Each test signs in and records what happened in $UIDRIVER_OUT/10-<name>.result: "home" or the error shown.
final class Lab10: Driver {
  func signInAndRecord(_ name: String) {
    npay.launch()
    signIn()
    let home = npay.otherElements["balanceCard"]
    let error = npay.staticTexts.matching(NSPredicate(format: "label CONTAINS 'NPay' AND label CONTAINS 'reach'")).firstMatch
    var result = "nothing after 20 s"
    let deadline = Date().addingTimeInterval(20)
    while Date() < deadline {
      if home.exists { result = "home"; break }
      if error.exists { result = "error: \(error.label)"; break }
      let allow = springboard.buttons["Allow"]
      if allow.exists { allow.tap() }
      usleep(300_000)
    }
    dismissSavePassword()
    shot("10-\(name)")
    try? result.write(toFile: "\(out)/10-\(name).result", atomically: true, encoding: .utf8)
    npay.terminate()
  }
  func test_signin() {
    signInAndRecord(ProcessInfo.processInfo.environment["LAB10_CASE"] ?? "case")
  }
}
