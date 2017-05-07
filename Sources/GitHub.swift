import Foundation
import ConvenientRestKit
import SwiftyJSON

struct GitHub {
    
    struct Credentials {
        let userName: String
        let password: String
        
        var urlCredential: URLCredential {
            return URLCredential(user: userName, password: password, persistence: .synchronizable)
        }
    }
    
    enum Authorization {
        case basic(Credentials)
        case token(String)
        
        var configuration: URLSessionConfiguration {
            let result = URLSessionConfiguration.default
            
            
            switch self {
            case .basic(let credentials):
                let userPasswordString = credentials.userName + ":" + credentials.password
                let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
                let base64EncodedCredential = userPasswordData!.base64EncodedString()
                result.httpAdditionalHeaders = ["Authorization" : "Basic " + base64EncodedCredential]
            case .token(let accessToken):
                result.httpAdditionalHeaders = ["Authorization" : "Bearer " + accessToken]
            }
            return result
        }
    }
    
    struct Repository: RepositoryProtocol {
        let id: Int
        let name: String
        let url: URL
        let description: String?
    }
    
    struct Domain: DomainProtocol {
        let baseURL = URL(string: "https://api.github.com")!
    }
    
    private let authorization: (Void) -> Authorization
    private let sessionDelegate: SessionDelegate
    fileprivate let session: URLSession
    
    init(authorization: @escaping @autoclosure (Void) -> Authorization) {
        self.authorization = authorization
        self.sessionDelegate = SessionDelegate(authorization: authorization)
        
        session = URLSession(configuration: authorization().configuration, delegate: self.sessionDelegate, delegateQueue: nil)
    }
    
    private class SessionDelegate: NSObject, URLSessionDelegate {
        let authorization: (Void) -> URLCredential
        
        init(authorization: @escaping (Void) -> Authorization) {
            self.authorization = {
                switch authorization() {
                case .basic(let credentials):
                    return credentials.urlCredential
                case .token(_):
                    fatalError("You should not expect")
                }
            }
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
            
        }
        
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.useCredential, authorization())
        }
    }
}

extension GitHub: RepositoryServiceProtocol {
    
    func readRepositories(errorHandler: @escaping (Error) -> Void, successHandler: @escaping ([Repository]) -> Void) {
        ListRepositories(service: self).performTask(errorHandler: errorHandler, successHandler: successHandler)
    }
    
    func createRepository(repository: RepositoryPrototype, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (Repository) -> Void) {
        CreateRepository(service: self, name: repository.name, description: repository.description)
            .performTask(errorHandler: errorHandler, successHandler: successHandler)
    }
    
    func updateRepository(repository: GitHub.Repository, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (Void) -> Void) {
        
    }
    
    func deleteRepository(repository: GitHub.Repository, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (Void) -> Void) {
        DeleteRepository(service: self, userName: "avriy", repository: repository)
            .performTask(errorHandler: errorHandler, successHandler: successHandler)
    }
    
}

protocol GitHubConfiguration {
    var service: GitHub { get }
}

extension GitHubConfiguration {
    var session: URLSession {
        return service.session
    }
    
    var domain: GitHub.Domain {
        return GitHub.Domain()
    }
}

struct RootGitHub: GitHubConfiguration, GetRequestConfigurationProtocol {
    typealias ResultType = Result
    
    let service: GitHub
    let apiPath: String = ""
    
    static func parseResult(from data: Data) throws -> RootGitHub.Result {
        let jsonObject = JSON(data: data)
        return try Result(json: jsonObject)
    }

    struct Result: JSONInitializable {
        
        init(json: JSON) throws {
            
        }
    }
}

extension GitHub.Repository: JSONInitializable {
    
    enum CodingKeys: String, KeyCodable {
        case id, name, description, url
    }
    
    init(json: JSON) throws {
        self.id = try json.intValue(forKey: CodingKeys.id)
        self.name = try json.stringValue(forKey: CodingKeys.name)
        self.url = try json.value(forKey: CodingKeys.url, jsonModifier: {
            guard let string = $0.string else {
                return nil
            }
            return URL(string: string)
        })
        self.description = json.string(forKey: CodingKeys.description)
    }
    
    var json: JSON {
        
        var dictionary: [AnyHashable: Any] = [CodingKeys.id.rawValue: id, CodingKeys.name: name, CodingKeys.url.rawValue: url.path]
        dictionary[CodingKeys.description.rawValue] = description
        return JSON(dictionary)
    }
}

struct ListRepositories: GitHubConfiguration, GetRequestConfigurationProtocol {
    typealias ResultType = [GitHub.Repository]

    let service: GitHub
    let apiPath: String = "user/repos"
    
    static func parseResult(from data: Data) throws -> [GitHub.Repository] {
        let jsonObject = JSON(data: data)
        let jsonArray = jsonObject.arrayValue
        return try jsonArray.map(GitHub.Repository.init(json: ))
    }
}

struct DeleteRepository: GitHubConfiguration, RequestConfigurationProtocol {
    let service: GitHub
    let userName: String
    let repository: GitHub.Repository
    var apiPath: String {
        return "repos/" + userName + "/" + repository.name
    }
    let methodType: HTTPMethodType = .delete
    let content: RequestContent = .none
    
    static func processResponse(response: HTTPURLResponse, data: Data?) throws {
        
    }
}

struct CreateRepository: GitHubConfiguration, RequestConfigurationProtocol {
    let service: GitHub
    let name: String
    let description: String?
    
    let apiPath: String = "user/repos"
    let methodType: HTTPMethodType = .post
    
    typealias ResultType = GitHub.Repository
    
    var content: RequestContent {
        let dictionary = ["name": name, "description": description, "homepage": "https://github.com"]
        let json = JSON(dictionary)
        return .json(json)
    }
}
