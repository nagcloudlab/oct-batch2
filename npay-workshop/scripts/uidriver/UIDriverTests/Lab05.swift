import XCTest

/// Lab 5: permission, a notification while NPay is open, in the background, and when NPay isn't running.
final class Lab05: Driver {

  func test1_permission_and_foreground() {
    npay.launch()
    signIn()
    let allow = springboard.buttons["Allow"]
    XCTAssertTrue(allow.waitForExistence(timeout: 30), "iOS permission prompt")
    shot("05-permission-prompt")
    allow.tap()
    dismissSavePassword()
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    mark("ready-foreground")                         // the script now sends the push
    let b = banner("Payment sent")
    XCTAssertTrue(b.waitForExistence(timeout: 60), "banner while NPay is open")
    shot("05-banner-foreground")
    b.tap()
    XCTAssertTrue(npay.staticTexts["₹1,500.50"].waitForExistence(timeout: 30), "Payment detail")
    shot("05-opened-from-foreground")
  }

  func test2_background() {
    npay.activate()
    XCUIDevice.shared.press(.home)
    mark("ready-background")
    let b = banner("Payment sent")
    XCTAssertTrue(b.waitForExistence(timeout: 60), "banner on the home screen")
    shot("05-banner-background")
    b.tap()
    XCTAssertTrue(npay.staticTexts["₹1,500.50"].waitForExistence(timeout: 30), "Payment detail after the tap")
    shot("05-opened-from-background")
  }

  func test3_not_running() {
    npay.terminate()
    mark("ready-notrunning")
    let b = banner("Payment sent")
    XCTAssertTrue(b.waitForExistence(timeout: 60), "banner while NPay is not running")
    b.tap()
    signIn()                                        // the tapped payment waits until Asha is signed in
    dismissSavePassword()
    XCTAssertTrue(npay.staticTexts["₹1,500.50"].waitForExistence(timeout: 60), "Payment detail after signing in")
    shot("05-opened-from-launch")
  }
}
