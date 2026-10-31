import XCTest

/// Lab 9: the refresh token in the Keychain. The script (scripts/lab09-run.sh) does the parts outside the app:
/// inspecting files, restarting the server, reinstalling NPay. It answers each "ready-…" marker with a "done-…" file.
final class Lab09: Driver {

  func waitForScript(_ step: String) {
    mark("ready-\(step)")
    let done = "\(out)/done-\(step)"
    let deadline = Date().addingTimeInterval(120)
    while !FileManager.default.fileExists(atPath: done) && Date() < deadline { usleep(300_000) }
    XCTAssertTrue(FileManager.default.fileExists(atPath: done), "the script finished \(step)")
  }

  var home: XCUIElement { npay.otherElements["balanceCard"] }
  var signInScreen: XCUIElement { npay.secureTextFields["password"] }

  func test1_relaunch_stays_signed_in() {
    npay.launch()
    signIn()
    let allow = springboard.buttons["Allow"]
    if allow.waitForExistence(timeout: 20) { allow.tap() }
    dismissSavePassword()
    XCTAssertTrue(home.waitForExistence(timeout: 30), "Home")
    waitForScript("inspect")                          // the token: in the app's files? in the Keychain database?
    npay.terminate()
    npay.launch()                                     // no password this time
    XCTAssertTrue(home.waitForExistence(timeout: 30), "Home straight away after a relaunch")
    XCTAssertFalse(signInScreen.exists, "no sign-in screen")
    shot("09-relaunch-signed-in")
  }

  func test2_server_restart_signs_out() {
    npay.terminate()
    waitForScript("restart")                          // the server forgets every session
    npay.launch()
    XCTAssertTrue(signInScreen.waitForExistence(timeout: 30), "the refresh token was refused: sign in")
    shot("09-after-server-restart")
    signIn()
    dismissSavePassword()
    XCTAssertTrue(home.waitForExistence(timeout: 30), "signed in again")
  }

  func test3_keychain_survives_reinstall() {
    npay.terminate()
    waitForScript("reinstall")                        // NPay deleted and installed again
    npay.launchArguments = ["-skipFreshInstallCheck", "YES"]   // what an app WITHOUT the check would do
    npay.launch()
    XCTAssertTrue(home.waitForExistence(timeout: 30), "still signed in after delete + reinstall: the Keychain survived")
    shot("09-reinstall-without-check")
    npay.terminate()
    npay.launchArguments = []
    npay.launch()                                     // with the check: the old item is removed
    XCTAssertTrue(signInScreen.waitForExistence(timeout: 30), "the fresh-install check cleared it")
    shot("09-reinstall-with-check")
  }

  func test4_sign_out() {
    if signInScreen.waitForExistence(timeout: 5) { signIn(); dismissSavePassword() }
    XCTAssertTrue(home.waitForExistence(timeout: 30), "Home")
    npay.otherElements["signOut"].tap()
    XCTAssertTrue(signInScreen.waitForExistence(timeout: 20), "signed out")
    npay.terminate()
    npay.launch()
    XCTAssertTrue(signInScreen.waitForExistence(timeout: 30), "still signed out after a relaunch")
    shot("09-signed-out-relaunch")
  }
}
