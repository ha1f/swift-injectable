enum RegistrationScope {
    case singleton
    case factory
}

struct Registration: Sendable {
    let scope: RegistrationScope
    let factory: @Sendable (Container) -> any Sendable
}
