# Testing

## Stack

- **xUnit** as the runner. **NSubstitute** for substitutes.
- **Assertions:** `FluentAssertions` v8+ is now commercially licensed (paid). For new projects prefer
  a free, drop-in alternative — **AwesomeAssertions** (FA-compatible fork) or **Shouldly**. If a
  project already pays for / uses FA, keep it; don't churn it for its own sake. Flag the license
  implication when relevant.
- Projects: `<Name>.Tests.Unit` and `<Name>.Tests.Integration`.
- Test names: `Method_Scenario_ExpectedResult`.

## Structure — AAA

```csharp
public class UserServiceTests
{
    private readonly IUserRepository _repo = Substitute.For<IUserRepository>();
    private readonly UserService _sut;

    public UserServiceTests() => _sut = new UserService(_repo);

    [Fact]
    public async Task CreateAsync_WhenEmailExists_ThrowsConflict()
    {
        // Arrange
        _repo.ExistsAsync("a@b.com").Returns(true);

        // Act
        var act = () => _sut.CreateAsync(new("a@b.com"));

        // Assert
        await act.Should().ThrowAsync<ConflictException>();
    }
}
```

- One scenario per test; the SUT is `_sut`, built once in the constructor.
- Mark Arrange/Act/Assert. Only assert interactions (`Received()`) when the interaction *is* the
  behavior under test.

## Coverage per method

Cover the paths that apply: happy path, not-found, already-exists, validation failure, business-rule
violation, dependency failure (propagates), empty collection, boundary values.

## Integration tests

- `WebApplicationFactory<Program>` for endpoint tests — assert the full HTTP round-trip and status
  codes.
- **Testcontainers** for real dependencies (DB, Redis, broker); don't mock EF Core. SQLite in-memory
  is acceptable for simple repository tests.
- Fresh database per test class via `IAsyncLifetime`. Use `FakeTimeProvider` to control time.

## What not to test

Private methods (test through the public API), framework behavior, EF internals (cover with
integration tests), and trivial DTO/mapping in isolation.
