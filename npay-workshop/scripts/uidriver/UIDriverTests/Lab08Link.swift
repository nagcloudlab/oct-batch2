import XCTest

/// Lab 8, step 3: a deep link from outside the app (`xcrun simctl openurl`), with NPay signed out.
final class Lab08Link: Driver {
  func test_openurl_signed_out() {
    npay.terminate()
    mark("ready-openurl")                              // the script runs: simctl openurl … npay://send?to=ravi@npay&amount=45000
    let open = springboard.buttons["Open"]
    XCTAssertTrue(open.waitForExistence(timeout: 30), "iOS asks: Open in NPayRN?")
    shot("08-openurl-confirm")
    open.tap()
    signIn()                                           // the link waits until Asha is signed in
    dismissSavePassword()
    let amount = npay.textFields["amount"]
    XCTAssertTrue(amount.waitForExistence(timeout: 30), "Send money")
    XCTAssertEqual(amount.value as? String, "450.00", "pre-filled from the link")
    shot("08-openurl-send")
  }
}
