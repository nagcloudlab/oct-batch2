import XCTest

/// Drives the real NPay app and iOS (SpringBoard) with real taps, for the labs' evidence.
/// Screenshots go to $UIDRIVER_OUT (a folder on the Mac). The shell script coordinates with the
/// tests through marker files in that folder ("ready-…" → the script sends a push).
class Driver: XCTestCase {
  let npay = XCUIApplication(bundleIdentifier: "com.npay.workshop")
  let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
  var out: String { ProcessInfo.processInfo.environment["UIDRIVER_OUT"] ?? "/tmp/uidriver" }

  override func setUp() { continueAfterFailure = false }

  func shot(_ name: String) {
    let png = XCUIScreen.main.screenshot().pngRepresentation
    try? png.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
  }

  func mark(_ name: String) {
    FileManager.default.createFile(atPath: "\(out)/\(name)", contents: nil)
  }

  func signIn() {
    let password = npay.secureTextFields["password"]
    XCTAssertTrue(password.waitForExistence(timeout: 60), "sign-in screen")
    password.tap()
    // the first launch after an erase can be slow to focus the field: tap again until it has the keyboard
    for _ in 0..<5 where !((password.value(forKey: "hasKeyboardFocus") as? Bool) ?? false) {
      sleep(1)
      password.tap()
    }
    password.typeText("npay-demo")
    npay.otherElements["signIn"].tap()
  }

  /// Types one character at a time: a controlled React Native TextInput can mix up fast typing.
  func slowType(_ field: XCUIElement, _ text: String) {
    field.tap()
    for ch in text {
      field.typeText(String(ch))
      usleep(150_000)
    }
  }

  /// Lab 7–8: home screen › long-press › Edit › Add Widget › search "NPay" › Add Widget › Done.
  /// `shots`: also take the gallery screenshots (Lab 7).
  func addNPayWidget(shots: Bool = false) {
    XCUIDevice.shared.press(.home)
    sleep(2)
    springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62)).press(forDuration: 1.6)
    XCTAssertTrue(springboard.buttons["Edit"].waitForExistence(timeout: 10), "edit mode")
    springboard.buttons["Edit"].tap()
    springboard.buttons["Add Widget"].tap()
    let search = springboard.searchFields["Search Widgets"]
    XCTAssertTrue(search.waitForExistence(timeout: 10), "widget gallery")
    search.tap()
    search.typeText("NPay")
    let app = springboard.cells["NPayRN"]
    XCTAssertTrue(app.waitForExistence(timeout: 10), "NPayRN in the gallery")
    app.tap()
    XCTAssertTrue(springboard.buttons["NPayRN, NPay Balance"].waitForExistence(timeout: 10), "the NPay Balance widget")
    if shots {
      shot("07-widget-gallery")
      springboard.swipeLeft()
      sleep(1)
      shot("07-widget-gallery-medium")
      springboard.swipeRight()
      sleep(1)
    }
    springboard.buttons[" Add Widget"].tap()
    sleep(2)
    springboard.buttons["Done"].tap()
    sleep(2)
  }

  /// The NPay widget on the home screen, found by what it shows.
  func npayWidget(showing text: String) -> XCUIElement {
    springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
  }

  /// iOS may offer to save the password after a sign-in form: answer "Not Now" if it appears.
  func dismissSavePassword() {
    for app in [npay, springboard] {
      let notNow = app.buttons["Not Now"]
      if notNow.waitForExistence(timeout: 3) { notNow.tap(); return }
    }
  }

  /// The notification banner, found by its title, wherever SpringBoard draws it.
  func banner(_ title: String) -> XCUIElement {
    springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
  }
}
