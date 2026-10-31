import XCTest

/// Lab 5, step 5: after "Don't Allow", a push shows nothing. Needs a fresh install.
final class Lab05DontAllow: Driver {
  func test_dont_allow() {
    npay.launch()
    signIn()
    let dontAllow = springboard.buttons["Don’t Allow"]
    XCTAssertTrue(dontAllow.waitForExistence(timeout: 30), "iOS permission prompt")
    dontAllow.tap()
    dismissSavePassword()
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    mark("ready-dontallow")
    XCTAssertFalse(banner("Payment sent").waitForExistence(timeout: 15), "no banner after Don't Allow")
    shot("05-dont-allow-no-banner")
  }
}
