import XCTest

/// Lab 6: the server sends "Payment sent" after a real payment; the app schedules its own reminder.
final class Lab06: Driver {

  func test1_server_push_after_payment() {
    npay.launch()
    signIn()
    let allow = springboard.buttons["Allow"]
    if allow.waitForExistence(timeout: 20) { allow.tap() }
    dismissSavePassword()
    XCTAssertTrue(npay.otherElements["balanceCard"].waitForExistence(timeout: 30), "Home")
    npay.otherElements["sendMoney"].tap()
    let amount = npay.textFields["amount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 10))
    slowType(amount, "1500.50")
    npay.otherElements["pay"].tap()
    XCTAssertTrue(npay.staticTexts["✓ Sent"].waitForExistence(timeout: 30), "payment sent")
    let b = banner("Payment sent")                       // sent by the NPay server, not by us
    XCTAssertTrue(b.waitForExistence(timeout: 30), "the server's notification")
    shot("06-server-push-banner")
    npay.otherElements["done"].tap()
    XCUIDevice.shared.press(.home)
    let again = banner("Payment sent")
    if !again.waitForExistence(timeout: 3) {             // the banner may be gone: open it from Notification Center
      XCUIDevice.shared.press(.home)
    }
    shot("06-home-after-payment")
  }

  func test2_reminder() {
    npay.launch()                                        // fresh start: sign in again (the token is in memory only)
    signIn()
    dismissSavePassword()
    let send = npay.otherElements["sendMoney"]
    XCTAssertTrue(send.waitForExistence(timeout: 30), "Home")
    send.tap()
    let amount = npay.textFields["amount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 10))
    slowType(amount, "450")
    let remind = npay.otherElements["remindMe"]
    remind.tap()
    // a Pressable's text becomes the button's own accessibility label
    let set = NSPredicate(format: "label CONTAINS 'Reminder set'")
    XCTAssertEqual(XCTWaiter.wait(for: [expectation(for: set, evaluatedWith: remind)], timeout: 10), .completed, "scheduled")
    shot("06-reminder-set")
    XCUIDevice.shared.press(.home)
    let b = banner("Payment reminder")
    XCTAssertTrue(b.waitForExistence(timeout: 30), "the reminder, about 10 seconds later")
    shot("06-reminder-banner")
    b.tap()
    XCTAssertTrue(npay.textFields["amount"].waitForExistence(timeout: 30), "Send money")
    XCTAssertEqual(npay.textFields["amount"].value as? String, "450.00", "pre-filled amount")
    shot("06-reminder-opened")
  }
}
