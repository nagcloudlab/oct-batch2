import XCTest

/// Lab 7: find NPay's widget in iOS's widget gallery, add it to the home screen, tap it.
final class Lab07: Driver {
  func test_add_widget() {
    npay.launch()                                   // iOS lists an app's widgets once the app has run
    sleep(3)
    addNPayWidget(shots: true)
    // the sample ₹25,000.00 in Lab 7; from Lab 8 on, signed out: "Open NPay to see your balance"
    let shows = NSPredicate(format: "label CONTAINS 'NPay Balance' OR label CONTAINS '25,000' OR label CONTAINS 'Open NPay'")
    let widget = springboard.descendants(matching: .any).matching(shows).firstMatch
    XCTAssertTrue(widget.waitForExistence(timeout: 10), "the widget on the home screen")
    shot("07-widget-home")
    widget.tap()                                     // a tap on a widget opens its app
    XCTAssertEqual(npay.wait(for: .runningForeground, timeout: 15), true, "NPay opened")
    sleep(2)
    shot("07-widget-opened-app")
  }
}
