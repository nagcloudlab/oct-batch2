import XCTest

/// Lab 8: the widget shows the real balance and follows payments; a tap deep-links to Send money;
/// a payment-request Live Activity counts down and opens Send money pre-filled; sign-out clears the widget.
final class Lab08: Driver {

  func test1_live_widget() {
    npay.launch()
    signIn()
    let allow = springboard.buttons["Allow"]
    if allow.waitForExistence(timeout: 20) { allow.tap() }
    dismissSavePassword()
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    sleep(2)
    addNPayWidget()
    let before = npayWidget(showing: "25,000.00")
    XCTAssertTrue(before.waitForExistence(timeout: 15), "widget shows the real balance ₹25,000.00")
    shot("08-widget-real-balance")
    before.tap()                                         // npay://send
    let amount = npay.textFields["amount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 20), "the widget opened Send money")
    shot("08-widget-opened-send")
    slowType(amount, "1500.50")
    npay.otherElements["pay"].tap()
    XCTAssertTrue(npay.otherElements["done"].waitForExistence(timeout: 30), "paid")
    npay.otherElements["done"].tap()                     // back to Home: it reloads and updates the widget
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    sleep(3)
    XCUIDevice.shared.press(.home)
    let after = npayWidget(showing: "23,499.50")
    XCTAssertTrue(after.waitForExistence(timeout: 20), "widget follows the payment: ₹23,499.50")
    shot("08-widget-after-payment")
  }

  func test2_live_activity() {
    npay.activate()
    let request = npay.otherElements["paymentRequest"]
    XCTAssertTrue(request.waitForExistence(timeout: 30), "Home")
    request.tap()
    sleep(2)
    XCUIDevice.shared.press(.home)
    sleep(3)
    shot("08-dynamic-island")
    // the Live Activity on the lock screen: swipe down from the top-left
    springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.005))
      .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)))
    sleep(2)
    let activity = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Payment request' OR label CONTAINS 'ravi@npay asks'")).firstMatch
    XCTAssertTrue(activity.waitForExistence(timeout: 15), "the Live Activity on the lock screen")
    shot("08-live-activity-lockscreen")
    sleep(5)
    shot("08-live-activity-5s-later")                   // the countdown has moved on by itself
    activity.tap()
    let amount = npay.textFields["amount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 30), "the Live Activity opened Send money")
    XCTAssertEqual(amount.value as? String, "500.00", "pre-filled from the request")
    shot("08-live-activity-opened-send")
    npay.otherElements["pay"].tap()                    // paying ends the request's Live Activity
    XCTAssertTrue(npay.otherElements["done"].waitForExistence(timeout: 30), "paid")
    shot("08-request-paid")
    XCUIDevice.shared.press(.home)
    springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.005))
      .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7)))
    let gone = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'ravi@npay asks'")).firstMatch
    XCTAssertFalse(gone.waitForExistence(timeout: 5), "the Live Activity ended after paying")
    shot("08-live-activity-ended")
    XCUIDevice.shared.press(.home)
  }

  func test3_sign_out_clears_widget() {
    npay.activate()
    if npay.otherElements["done"].waitForExistence(timeout: 10) { npay.otherElements["done"].tap() }   // back to Home
    let signOut = npay.otherElements["signOut"]
    XCTAssertTrue(signOut.waitForExistence(timeout: 20), "Home")
    signOut.tap()
    sleep(2)
    XCUIDevice.shared.press(.home)
    XCTAssertTrue(npayWidget(showing: "Open NPay").waitForExistence(timeout: 20), "widget cleared after sign-out")
    shot("08-widget-signed-out")
  }
}
