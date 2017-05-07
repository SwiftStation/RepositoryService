import XCTest
@testable import RepositoryService
import ConvenientRestKit

extension XCTestCase {
    func errorHandler(for expectation: XCTestExpectation) -> ((Error) -> Void) {
        return { error in
            XCTFail(error.localizedDescription)
            expectation.fulfill()
        }
    }
    
    var failErrorHandler: (Error) -> Void {
        return { error in
            XCTFail(error.localizedDescription)
        }
    }
}

class RepositoryServiceTests: XCTestCase {
    
    let github = GitHub(authorization: .basic(GitHub.Credentials(userName: "avriy", password: "Npn-1PA-4d9-7bR")))
    
    func performTest<RequstConfiguration: RequestConfigurationProtocol>(configuration: RequstConfiguration, name: String, condition: @escaping (RequstConfiguration.ResultType) -> Bool = { _ in return true }) {
        let exp = expectation(description: name)
        configuration.performTask(errorHandler: errorHandler(for: exp)) { result in
            XCTAssert(condition(result))
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func testRootCall() {
        performTest(configuration: RootGitHub(service: github), name: "Can create toot api call")
    }
    
    func testListing() {
        performTest(configuration: ListRepositories(service: github), name: "Can list repositories")
    }
    
    func random() -> (name: String, desctiption: String) {
        let uuidString = UUID().uuidString
        let shortUUID = uuidString.substring(to: uuidString.index(uuidString.startIndex, offsetBy: 5))
        let name = "Repository-Demo-" + shortUUID
        let description = "Testing github api call"
        return (name, description)
    }
    
    func testCreate() {
        let (name, description) = random()
        let configuration = CreateRepository(service: github, name: name, description: description)
        performTest(configuration: configuration, name: "Can create repo") { result in
            return result.name == name && result.description == description
        }
    }
    
    func testDeleteAnyTestRepository() {
        let listRepos = ListRepositories(service: github)
        let exp = expectation(description: "Network call is over")
        listRepos.performTask(errorHandler: errorHandler(for: exp)) { [unowned self] repos in
            
            let demoRepos = repos.filter { $0.name.range(of: "Repository-Demo") != nil }
            let group = DispatchGroup()
            
            for demoRepo in demoRepos {
                group.enter()
                let delete = DeleteRepository(service: self.github, userName: "avriy", repository: demoRepo)
                delete.performTask(errorHandler: self.failErrorHandler) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 60, handler: nil)
    }
    
    func testCreateAndDelete() {
        let (name, description) = random()
        let create = CreateRepository(service: github, name: name, description: description)
        let exp = expectation(description: "Can create and delete repo")
        let failer = failErrorHandler
        
        create.performTask(errorHandler: failer) { repository in
            let delete = DeleteRepository(service: self.github, userName: "avriy", repository: repository)
            
            delete.performTask(errorHandler: failer) {
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30, handler: nil)
    }

    static var allTests = [
        ("testRootCall", testRootCall),
    ]
}
