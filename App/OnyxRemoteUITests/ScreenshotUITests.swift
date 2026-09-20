import XCTest

/// Walks every screen against the default `MockConsoleAdapter` sample data
/// and attaches a screenshot of each with `.keepAlways`, so CI can export
/// them as artifacts for review from a phone (see .github/workflows/ci.yml
/// and docs/PLAN.md M0 acceptance).
final class ScreenshotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureEveryScreen() {
        let app = XCUIApplication()
        app.launch()

        attach(app, name: "01-patch-map")

        if app.buttons["List"].waitForExistence(timeout: 2) {
            app.buttons["List"].tap()
            attach(app, name: "02-patch-list")
        }

        if app.buttons["Walk"].waitForExistence(timeout: 2) {
            app.buttons["Walk"].tap()
            attach(app, name: "03-patch-walk")
        }

        app.buttons["tab.Program"].tap()
        attach(app, name: "04-program-intensity")

        if app.buttons["Color"].waitForExistence(timeout: 2) {
            app.buttons["Color"].tap()
            attach(app, name: "05-program-color")
        }

        if app.buttons["Position"].waitForExistence(timeout: 2) {
            app.buttons["Position"].tap()
            attach(app, name: "06-program-position")
        }

        if app.buttons["Beam"].waitForExistence(timeout: 2) {
            app.buttons["Beam"].tap()
            attach(app, name: "07-program-beam")
        }

        app.buttons["tab.Keypad"].tap()
        attach(app, name: "08-keypad")

        app.buttons["tab.Cues"].tap()
        attach(app, name: "09-cues")
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
