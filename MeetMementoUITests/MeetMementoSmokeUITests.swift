import XCTest

final class MeetMementoSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_launch_doesNotCrash() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launchEnvironment["MEETMEMENTO_UI_TEST"] = "1"
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
    }

    func test_welcome_showsPrimaryControlsAfterAuthSettles() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launchEnvironment["MEETMEMENTO_UI_TEST"] = "1"
        app.launch()

        let welcomeVisible = NSPredicate(
            format: "identifier == %@ OR label CONTAINS[c] %@",
            "welcome.continueApple",
            "Reflect while you journal"
        )
        XCTAssertTrue(
            app.descendants(matching: .any).matching(welcomeVisible).firstMatch.waitForExistence(timeout: 30)
        )
    }
}
