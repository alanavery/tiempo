import XCTest

@MainActor
final class TiempoUITests: XCTestCase {
    func testCreateTasksAndSwitchTimers() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let newProject = app.buttons["new-project"]
        XCTAssertTrue(newProject.waitForExistence(timeout: 5), app.debugDescription)
        newProject.click()

        let projectName = app.textFields["project-name"]
        XCTAssertTrue(projectName.waitForExistence(timeout: 2), app.debugDescription)
        projectName.click()
        projectName.typeText("Client")
        app.buttons["create-project"].click()

        createTask(named: "Design", in: app)
        createTask(named: "Review", in: app)

        let design = app.buttons["timer-Design"]
        let review = app.buttons["timer-Review"]
        XCTAssertTrue(design.waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertTrue(review.waitForExistence(timeout: 2), app.debugDescription)

        design.click()
        XCTAssertEqual(design.label, "Pause")
        XCTAssertEqual(review.label, "Start")

        let total = app.staticTexts["total-elapsed"]
        XCTAssertTrue(total.waitForExistence(timeout: 2))
        let ticking = NSPredicate(format: "label != %@", "00:00:00")
        expectation(for: ticking, evaluatedWith: total)
        waitForExpectations(timeout: 3)

        review.click()
        XCTAssertEqual(design.label, "Start")
        XCTAssertEqual(review.label, "Pause")

        review.click()
        XCTAssertEqual(design.label, "Start")
        XCTAssertEqual(review.label, "Start")

        app.buttons["reset-all"].click()
        let confirm = app.buttons["confirm-reset"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 2), app.debugDescription)
        confirm.click()

        let meetingConfirm = app.buttons["confirm-meeting-time"]
        XCTAssertTrue(meetingConfirm.waitForExistence(timeout: 2), app.debugDescription)
        meetingConfirm.click()

        let cleared = NSPredicate(format: "label == %@", "00:00:00")
        expectation(for: cleared, evaluatedWith: total)
        waitForExpectations(timeout: 2)
        XCTAssertEqual(design.label, "Start")
        XCTAssertEqual(review.label, "Start")
    }

    func testEditTaskTime() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let newProject = app.buttons["new-project"]
        XCTAssertTrue(newProject.waitForExistence(timeout: 5), app.debugDescription)
        newProject.click()
        let projectName = app.textFields["project-name"]
        XCTAssertTrue(projectName.waitForExistence(timeout: 2), app.debugDescription)
        projectName.click()
        projectName.typeText("Client")
        app.buttons["create-project"].click()

        createTask(named: "Design", in: app)

        let task = app.descendants(matching: .any)["task-Design"]
        XCTAssertTrue(task.waitForExistence(timeout: 2), app.debugDescription)
        task.rightClick()
        let editTime = app.menuItems["Edit Time"]
        XCTAssertTrue(editTime.waitForExistence(timeout: 2), app.debugDescription)
        editTime.click()

        let field = app.textFields["edit-time"]
        XCTAssertTrue(field.waitForExistence(timeout: 2), app.debugDescription)
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText("01:15:30")
        app.buttons["save-edit-time"].click()

        let elapsed = app.staticTexts["elapsed-Design"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 2), app.debugDescription)
        let showsEditedTime = NSPredicate(format: "label == %@ OR value == %@", "01:15:30", "01:15:30")
        expectation(for: showsEditedTime, evaluatedWith: elapsed)
        expectation(for: showsEditedTime, evaluatedWith: app.staticTexts["total-elapsed"])
        waitForExpectations(timeout: 2)
    }

    func testRenameProjectAndTask() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let newProject = app.buttons["new-project"]
        XCTAssertTrue(newProject.waitForExistence(timeout: 5), app.debugDescription)
        newProject.click()
        let projectName = app.textFields["project-name"]
        XCTAssertTrue(projectName.waitForExistence(timeout: 2), app.debugDescription)
        projectName.click()
        projectName.typeText("Client")
        app.buttons["create-project"].click()

        createTask(named: "Design", in: app)

        rename(app.descendants(matching: .any)["project-Client"], to: "Acme", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["project-Acme"].waitForExistence(timeout: 2), app.debugDescription)

        rename(app.descendants(matching: .any)["task-Design"], to: "Sketch", in: app)
        XCTAssertTrue(app.buttons["timer-Sketch"].waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertFalse(app.buttons["timer-Design"].exists)
    }

    private func rename(_ element: XCUIElement, to name: String, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 2), app.debugDescription)
        element.rightClick()
        let rename = app.menuItems["Rename"]
        XCTAssertTrue(rename.waitForExistence(timeout: 2), app.debugDescription)
        rename.click()

        let field = app.textFields["rename-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 2), app.debugDescription)
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText(name)
        app.buttons["save-rename"].click()
    }

    private func createTask(named name: String, in app: XCUIApplication) {
        let newTask = app.buttons["new-task"]
        XCTAssertTrue(newTask.waitForExistence(timeout: 2))
        XCTAssertTrue(newTask.isEnabled)
        newTask.click()

        let taskName = app.textFields["task-name"]
        XCTAssertTrue(taskName.waitForExistence(timeout: 2), app.debugDescription)
        taskName.click()
        taskName.typeText(name)
        app.buttons["create-task"].click()
        XCTAssertTrue(app.buttons["timer-\(name)"].waitForExistence(timeout: 2), app.debugDescription)
    }
}
