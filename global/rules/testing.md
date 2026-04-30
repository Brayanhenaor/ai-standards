---
paths:
  - "**/*Tests.cs"
  - "**/*Test.cs"
  - "**/*Specs.cs"
  - "**/*Fixture*.cs"
---

# Testing standards

## Libraries and project structure

- xUnit + FluentAssertions + NSubstitute
- Projects: `[Name].Tests.Unit` and `[Name].Tests.Integration`
- Naming: `MethodName_Scenario_ExpectedResult`

## Unit test structure

```csharp
public class UserServiceTests
{
    private readonly IUserRepository _userRepository;
    private readonly IEmailService _emailService;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _userRepository = Substitute.For<IUserRepository>();
        _emailService = Substitute.For<IEmailService>();
        _sut = new UserService(_userRepository, _emailService);
    }

    [Fact]
    public async Task CreateAsync_WhenEmailAlreadyExists_ThrowsConflictException()
    {
        // Arrange
        var request = new CreateUserRequest { Email = "test@example.com" };
        _userRepository.ExistsAsync(request.Email).Returns(true);

        // Act
        var act = () => _sut.CreateAsync(request);

        // Assert
        await act.Should().ThrowAsync<ConflictException>()
            .WithMessage("*email*");
    }
}
```

## AAA — mandatory in every test

- Always include `// Arrange`, `// Act`, `// Assert` comments explicitly
- One test = one scenario — never assert unrelated things in the same test
- SUT (System Under Test) named `_sut` — instantiated once in constructor, never per test

## Coverage required per method

Cover ALL paths that apply:

| Scenario | Example |
|---|---|
| Happy path | Valid input → expected output |
| Not found | Entity doesn't exist → `NotFoundException` |
| Already exists | Duplicate → `ConflictException` |
| Validation failure | Invalid input → `ValidationException` |
| Business rule violation | Domain rule blocks operation → specific exception |
| Dependency failure | Repository throws → exception propagates correctly |
| Empty collection | No results → empty list, not null |
| Boundary values | Zero, max, exact thresholds |

## Mocking guidelines (NSubstitute)

```csharp
// Setup
_repository.GetByIdAsync(userId).Returns(user);
_repository.GetByIdAsync(Arg.Any<Guid>()).Returns((User?)null);

// Verify call happened (only when the call itself is the expected behavior)
await _repository.Received(1).SaveAsync(Arg.Is<User>(u => u.Email == "test@example.com"));

// Verify call did NOT happen
_emailService.DidNotReceive().SendAsync(Arg.Any<string>());
```

- Use `Arg.Any<T>()` for parameters not relevant to the scenario
- Only verify interactions (`Received()`) when the interaction *is* the behavior being tested
- Never mock the SUT itself — test the real implementation

## FluentAssertions

```csharp
result.Should().NotBeNull();
result.Should().BeEquivalentTo(expected);
result.Email.Should().Be("test@example.com");
results.Should().HaveCount(3);
results.Should().ContainSingle(u => u.IsActive);
await act.Should().ThrowAsync<NotFoundException>();
```

## Integration tests

- Use `WebApplicationFactory<Program>` for endpoint tests
- Use Testcontainers or SQLite in-memory for repository tests — never mock EF Core
- Each test class gets a fresh database — use `IAsyncLifetime` to seed/clean
- Test the full HTTP round-trip including serialization and status codes

```csharp
public class UsersEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersEndpointTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task POST_Users_Returns201_WhenValidRequest()
    {
        // Arrange
        var request = new CreateUserRequest { Email = "test@example.com" };

        // Act
        var response = await _client.PostAsJsonAsync("/api/Users", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }
}
```

## What NOT to test

- Private methods — test them through the public API
- EF Core internals — use integration tests for repositories
- Framework behavior (ASP.NET routing, DI container) — trust the framework
- DTOs / mapping configs in isolation — covered by integration tests
