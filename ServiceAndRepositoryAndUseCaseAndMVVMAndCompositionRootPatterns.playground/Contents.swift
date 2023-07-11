import UIKit

struct User {
    let nick: String
    let password: String
}

// Service Pattern

protocol UserServiceProtocol {
    func fetchUsers() async throws -> [User]
}

class UserService: UserServiceProtocol {

    // a connection to the outside world like DB, Remote Server, API, Bluetooth

    func fetchUsers() async throws -> [User] {
        // call the connection to retry data
        sleep(3)
        let user1 = User(nick: "", password: "")
        let user2 = User(nick: "", password: "")

        return [user1, user2]
    }
}

// Repository Pattern

protocol UserRepositoryProtocol {
    var service: UserServiceProtocol { get }
    func create(nick: String, password: String) -> User
    func fetchUsers() async throws -> [User]
}

class UserRepository: UserRepositoryProtocol {

    let service: UserServiceProtocol

    init(service: UserServiceProtocol) { // constructor DI
        self.service = service
    }

    func create(nick: String, password: String) -> User {
        User(nick: nick, password: password)
    }

    func fetchUsers() async throws -> [User] {
        try await service.fetchUsers()
    }
}

// Use Case Pattern

protocol CreateUserUseCaseProtocol {
    var repository: UserRepositoryProtocol { get }
    func execute(nick: String, password: String) -> User
}

class CreateUserUseCase: CreateUserUseCaseProtocol {

    let repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute(nick: String, password: String) -> User {
        // all business rules here
        let user = repository.create(nick: nick, password: password)
        return user
    }
}

protocol FetchUsersUseCaseProtocol {
    var repository: UserRepositoryProtocol { get }
    func execute() async throws -> [User]
}

class FetchUsersUseCase: FetchUsersUseCaseProtocol {

    var repository: UserRepositoryProtocol

    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [User] {
        try await repository.fetchUsers()
    }
}

// MVVM Pattern

protocol LoginViewModelProtocol {
    var createUserUseCase: CreateUserUseCaseProtocol { get }
    var fetchUsersUseCase: FetchUsersUseCaseProtocol { get }
    var user: User? { get set }
    var users: [User]? { get set }
    func createNewUser(nick: String, password: String)
    func fetchUsers() async
}

class LoginViewModel: LoginViewModelProtocol {

    let createUserUseCase: CreateUserUseCaseProtocol
    var fetchUsersUseCase: FetchUsersUseCaseProtocol
    var user: User?
    var users: [User]?

    init(createUserUseCase: CreateUserUseCaseProtocol, fetchUsersUseCase: FetchUsersUseCaseProtocol) {
        self.createUserUseCase = createUserUseCase
        self.fetchUsersUseCase = fetchUsersUseCase
    }

    func createNewUser(nick: String, password: String) {
        let user = createUserUseCase.execute(nick: nick, password: password)
        self.user = user
    }

    func fetchUsers() async {
        do {
            let users = try await fetchUsersUseCase.execute()
            self.users = users
        } catch {
            // handle with error
        }
    }
}

class LoginViewController: UIViewController {

    var viewModel: LoginViewModelProtocol?

    init(viewModel: LoginViewModelProtocol) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createNewUser() {
        viewModel?.createNewUser(nick: "test", password: "123")
    }

    func fetchUsers() {
        Task {
            await viewModel?.fetchUsers()
        }
    }
}

// Composition Root

final class CompositionRoot {

    static let shared = CompositionRoot()

    private init() { }

    func buildLoginViewController() -> UIViewController {
        LoginViewController(viewModel: buildLoginViewModel())
    }

    func buildLoginViewModel() -> LoginViewModel {
        LoginViewModel(createUserUseCase: buildCreateUserUseCase(), fetchUsersUseCase: buildFetchUserUseCase())
    }

    func buildCreateUserUseCase() -> CreateUserUseCaseProtocol {
        CreateUserUseCase(repository: buildUserRepository())
    }

    func buildFetchUserUseCase() -> FetchUsersUseCaseProtocol {
        FetchUsersUseCase(repository: buildUserRepository())
    }

    func buildUserRepository() -> UserRepositoryProtocol {
        UserRepository(service: buildUserService())
    }

    func buildUserService() -> UserServiceProtocol {
        UserService()
    }
}

CompositionRoot.shared.buildLoginViewController()
