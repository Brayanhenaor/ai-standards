# Generate unit tests

Generate unit tests for pending changes or a specific commit.

**Usage:**
- `/user:test-dotnet` — tests for all pending changes (staged + unstaged)
- `/user:test-dotnet <commit-sha>` — tests for a specific commit

## Step 1 — Get the changes

If `$ARGUMENTS` is empty:
- Run `git diff HEAD` to get all pending changes
- Run `git diff --cached` to include staged-only changes

If `$ARGUMENTS` is a commit SHA:
- Run `git show $ARGUMENTS` to get the changes introduced by that commit

## Step 2 — Analyze what needs testing

For each modified or created file, identify:
- New or modified public methods and their signatures
- Business logic paths: conditions, loops, validations, error handling
- Dependencies that need to be mocked
- Edge cases: null inputs, empty collections, boundary values, concurrent access
- Error paths: expected exceptions, `Result<T>` failure cases

Skip: DTOs, migrations, configuration classes, Program.cs, mapping configs.

## Step 3 — Locate or create the test project

- Find the existing `*.Tests.Unit` project in the solution
- Place test classes mirroring the source structure:
  - `Application/Services/UserService.cs` → `Application/Services/UserServiceTests.cs`
- If the test project doesn't exist, note it as a prerequisite before generating tests

## Step 4 — Generate the tests

For each method that needs testing, generate a complete test class following these rules:

### Structure
```csharp
public class UserServiceTests
{
    // Mocks declared as fields
    private readonly IUserRepository _userRepository;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _userRepository = Substitute.For<IUserRepository>();
        _sut = new UserService(_userRepository);
    }

    [Fact]
    public async Task MethodName_Scenario_ExpectedResult()
    {
        // Arrange
        
        // Act
        
        // Assert
    }
}
```

### Rules
- Pattern AAA mandatory: explicit `// Arrange`, `// Act`, `// Assert` comments in every test
- Naming: `MethodName_Scenario_ExpectedResult` — describes the case, not the implementation
- Use NSubstitute for all external dependencies (`Substitute.For<T>()`)
- Use FluentAssertions for assertions (`result.Should().Be(...)`)
- SUT (System Under Test) named `_sut` — never instantiate it in each test
- Each test covers exactly one scenario — no multiple assertions on unrelated things
- Test behavior, not implementation: assert on return values and observable side effects, not on internal calls unless they are the behavior being tested

### Coverage required per method
Cover ALL of the following that apply:
- **Happy path** — valid input, expected output
- **Not found / empty** — when entity doesn't exist or collection is empty
- **Validation failure** — invalid input that should be rejected
- **Business rule violation** — domain rules that block the operation
- **Exception propagation** — when a dependency throws, what happens
- **Boundary values** — zero, max, min, exact thresholds

### Mocking guidelines
- Set up only the behavior relevant to each test — no over-specification
- Use `Arg.Any<T>()` for parameters not relevant to the scenario being tested
- Verify interactions (`Received()`) only when the call itself is the expected behavior
- Never mock the SUT itself

## Step 5 — Output

For each test class, output the complete file ready to copy.

After all tests, show a summary:
```
## Tests generated

| Method | Scenarios covered |
|---|---|
| CreateUserAsync | happy path, duplicate email, invalid input |
| ...             | ...                                         |

⚠️ Not covered (out of scope or integration test territory):
- [list anything skipped and why]
```
