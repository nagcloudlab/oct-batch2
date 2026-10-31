import XCTest

/// Lab 5, "try it": emojis in a notification are just text in the payload.
final class Lab05Emoji: Driver {
  func test_emoji_banner() {
    npay.launch()
    signIn()
    let allow = springboard.buttons["Allow"]
    if allow.waitForExistence(timeout: 20) { allow.tap() }
    dismissSavePassword()
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    XCUIDevice.shared.press(.home)
    mark("ready-emoji")
    let b = banner("✅ Payment sent")
    XCTAssertTrue(b.waitForExistence(timeout: 60), "banner with emojis")
    shot("05-banner-emoji")
  }
}
