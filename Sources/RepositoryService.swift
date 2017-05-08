import Foundation

public protocol RepositoryProtocol {
    var name: String { get }
    var url: URL { get }
}

/// Minimum information needed to create a repository
public struct RepositoryPrototype {
    let name: String
    let description: String?
    
    public init(name: String, description: String?) {
        self.name = name; self.description = description
    }
}

public protocol RepositoryServiceProtocol {
    associatedtype RepositoryType: RepositoryProtocol
    
    func createRepository(repository: RepositoryPrototype, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (RepositoryType) -> Void)
    func readRepositories(errorHandler: @escaping (Error) -> Void, successHandler: @escaping ([RepositoryType]) -> Void)
    func updateRepository(repository: RepositoryType, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (Void) -> Void)
    func deleteRepository(repository: RepositoryType, errorHandler: @escaping (Error) -> Void, successHandler: @escaping (Void) -> Void)
}
