# ⚠️ iOS Development Workflow Rules

## Mandatory Workflow Requirements

This document defines **MANDATORY** development practices that must be followed for every code change. These rules ensure code quality and prevent regressions.

## 🚨 CRITICAL: Build & Test Requirements

### **EVERY Swift File Change Must:**

1. **✅ Build Successfully** (Cmd+B)
2. **✅ Pass All Tests** (Cmd+U)  
3. **✅ Have No Compiler Warnings**
4. **✅ Have No SwiftUI Preview Errors**

### **Never Commit Without:**
- [ ] Successful build (no compilation errors)
- [ ] All tests passing (unit and UI tests)
- [ ] Zero compiler warnings
- [ ] Zero SwiftUI preview crashes
- [ ] Code review approval (if working in team)

```bash
# Essential commands after EVERY Swift file change:
# 1. Build project
Cmd+B
# Must see: Build Succeeded

# 2. Run all tests  
Cmd+U
# Must see: All tests passed

# 3. Check previews work
# Open any SwiftUI file and verify preview loads without errors

# 4. Clean build if issues persist
Cmd+Shift+K (Clean Build Folder)
```

## 🔄 Development Process

### 1. Before Starting Any Feature

```swift
// 1. Pull latest changes
git pull origin main

// 2. Create feature branch
git checkout -b feature/user-authentication

// 3. Verify clean starting state
// Build project (Cmd+B) - should succeed
// Run tests (Cmd+U) - should pass
```

### 2. During Development

```swift
// After EVERY Swift file change:

// 1. Save file (Cmd+S)
// 2. Build project (Cmd+B)
//    ❌ If build fails: Fix compilation errors before continuing
//    ✅ If build succeeds: Continue to tests

// 3. Run tests (Cmd+U)  
//    ❌ If tests fail: Fix failing tests before continuing
//    ✅ If tests pass: Continue development

// 4. Check SwiftUI previews
//    ❌ If preview errors: Fix preview issues
//    ✅ If previews work: Ready for next change
```

### 3. Before Committing

```swift
// Final verification checklist:

// 1. Build entire project
Cmd+B
// Must succeed with zero warnings

// 2. Run complete test suite
Cmd+U  
// All tests must pass

// 3. Verify key SwiftUI previews
// Check 2-3 main views for preview functionality

// 4. Clean build verification (optional but recommended)
Cmd+Shift+K  // Clean build folder
Cmd+B        // Build again
Cmd+U        // Test again

// 5. Commit with descriptive message
git add .
git commit -m "feat: implement user authentication with JWT token storage"
```

## 🎯 Test-Driven Development (TDD) Workflow

### Red → Green → Refactor Cycle

```swift
// 🔴 RED: Write failing test first
func testLoginViewModel_ShowsErrorForInvalidEmail() async {
    // Given
    let viewModel = LoginViewModel()
    viewModel.email = "invalid-email"
    viewModel.password = "password123"
    
    // When
    await viewModel.login()
    
    // Then
    XCTAssertTrue(viewModel.showError)
    XCTAssertEqual(viewModel.errorMessage, "Please enter a valid email address")
}
// ❌ Run test - it should FAIL

// 🟢 GREEN: Write minimal code to pass
@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showError = false
    @Published var errorMessage = ""
    
    func login() async {
        guard email.contains("@") else {
            showError = true
            errorMessage = "Please enter a valid email address"
            return
        }
        // Minimal implementation to pass test
    }
}
// ✅ Run test - it should PASS

// 🔵 BLUE: Refactor and improve
// Improve email validation, add more tests, enhance error handling
```

### TDD Command Sequence

```bash
# 1. Write failing test
# Save file (Cmd+S)
# Run specific test (click diamond in gutter)
# ❌ Verify test fails for right reason

# 2. Write minimal implementation  
# Save file (Cmd+S)
# Build (Cmd+B) - fix any compilation errors
# Run specific test (click diamond)
# ✅ Verify test passes

# 3. Refactor if needed
# Save file (Cmd+S)  
# Build (Cmd+B)
# Run all tests (Cmd+U) - ensure no regressions
# ✅ All tests should still pass
```

## ⚡ Fast Iteration Guidelines

### Quick Feedback Loop

```swift
// For rapid development, use this sequence:

// 1. Make small change
// 2. Cmd+S (save)
// 3. Cmd+B (build) 
//    - If error: fix immediately, don't continue
//    - If success: continue
// 4. Check SwiftUI preview (if applicable)
//    - Preview should update automatically
//    - If error: fix preview issues
// 5. Continue to next small change

// Every 3-5 small changes:
// Run tests (Cmd+U) to catch regressions early
```

### Preview-Driven Development

```swift
// For SwiftUI views, use previews for rapid iteration:

struct LoginView: View {
    var body: some View {
        // Make changes here
    }
}

#Preview {
    LoginView()
        .environmentObject(LoginViewModel())
}

// Workflow:
// 1. Modify view code
// 2. Save (Cmd+S)
// 3. Preview auto-updates
// 4. If preview crashes, fix immediately
// 5. Continue iteration
```

## 🚨 Failure Response Protocols

### When Build Fails

```swift
// 🔴 STOP EVERYTHING - Fix compilation errors first

// 1. Read error message carefully
// 2. Click on error to navigate to problem
// 3. Fix the specific issue
// 4. Build again (Cmd+B)
// 5. Only continue when build succeeds

// Common fixes:
// - Missing imports
// - Type mismatches  
// - Syntax errors
// - Missing protocol conformances
```

### When Tests Fail

```swift
// 🟡 PAUSE FEATURE WORK - Fix tests before continuing

// 1. Identify which test failed
// 2. Run specific failing test to isolate issue
// 3. Debug test:
//    - Check test logic
//    - Verify implementation matches expected behavior
//    - Add print statements if needed
// 4. Fix either test or implementation
// 5. Run test again to verify fix
// 6. Run full test suite to check for regressions

// Test failure triage:
// - Is the test correct? (Maybe expectation changed)
// - Is the implementation wrong? (Fix the code)
// - Is there a race condition? (Add proper async handling)
```

### When SwiftUI Preview Crashes

```swift
// 🟠 FIX PREVIEW ISSUES - Impacts development velocity

// 1. Check preview error message
// 2. Common issues:
//    - Missing environment objects
//    - Force unwrapping nil values
//    - Preview data not configured
//    - Missing dependencies

// 3. Fix patterns:
#Preview {
    LoginView()
        .environmentObject(LoginViewModel()) // Add missing environment
}

// Or provide mock data:
#Preview {
    let viewModel = LoginViewModel()
    viewModel.isLoading = true  // Set preview state
    return LoginView()
        .environmentObject(viewModel)
}
```

## 📊 Performance Monitoring

### Build Time Optimization

```swift
// Keep build times under 30 seconds:

// 1. Avoid massive files (keep under 200 lines)
// 2. Minimize complex type inference:
let items = [String]() // ✅ Explicit type
let items = []          // ❌ Compiler has to infer

// 3. Use @_spi for internal APIs
@_spi(Internal) import SomeFramework

// 4. Split large SwiftUI views:
// ❌ One massive view
struct MassiveView: View { /* 500 lines */ }

// ✅ Composed smaller views  
struct MainView: View {
    var body: some View {
        VStack {
            HeaderView()
            ContentView() 
            FooterView()
        }
    }
}
```

### Test Execution Time

```swift
// Keep tests under 5 seconds total:

// 1. Use mocks instead of real networking
// 2. Minimize async delays in tests
// 3. Avoid UI tests for everything (use unit tests)
// 4. Parallelize test execution where possible

// Fast test pattern:
func testLoginValidation() {
    // Synchronous test - runs instantly
    let validator = EmailValidator()
    XCTAssertFalse(validator.isValid("invalid"))
    XCTAssertTrue(validator.isValid("valid@example.com"))
}

// Slow test pattern (avoid):
func testAPIIntegration() async {
    // Real network call - takes 5+ seconds
    let service = AuthService()
    let response = try await service.login(...)
}
```

## 🔧 Debugging Workflow

### When Code Doesn't Work as Expected

```swift
// 1. Add breakpoints strategically
//    - Start of function/method
//    - Before suspected problem line
//    - After suspected problem line

// 2. Use Xcode debugger effectively
//    - Check variable values in debug area
//    - Use "po" command in console to print objects
//    - Step through code line by line

// 3. Add temporary logging
print("DEBUG: Login attempt for email: \(email)")
print("DEBUG: API response: \(response)")

// 4. Use SwiftUI debug modifiers
Text("Hello")
    .border(Color.red) // Visualize layout issues
    .background(Color.yellow) // Check view bounds

// 5. Remove debug code before committing
```

### AsyncAwait Debugging

```swift
// For async functions, use proper debugging:

func debugAsyncFunction() async {
    print("🔍 Starting async operation")
    
    do {
        let result = try await someAsyncCall()
        print("✅ Success: \(result)")
    } catch {
        print("❌ Error: \(error)")
        // Set breakpoint here to inspect error
    }
    
    print("🏁 Async operation completed")
}
```

## 📋 Daily Checklist

### Morning Startup Routine

```bash
# 1. Pull latest changes
git pull origin main

# 2. Verify clean state
Cmd+B  # Build should succeed
Cmd+U  # Tests should pass

# 3. If anything fails:
#    - Fix issues before starting new work
#    - Ask team if problems persist
```

### End of Day Routine

```bash
# 1. Commit current progress
git add .
git commit -m "WIP: feature progress - tests passing"

# 2. Final verification
Cmd+B  # Build
Cmd+U  # Tests

# 3. Push if ready
git push origin feature/branch-name

# 4. Update task status
# Mark completed tasks, note any blockers
```

## 🎯 Quality Gates

### Code Review Requirements

```swift
// Before requesting review, ensure:

// ✅ Technical requirements:
// - All tests pass
// - No compiler warnings
// - Code follows architecture patterns
// - Proper error handling implemented

// ✅ Documentation requirements:
// - Public APIs have doc comments
// - Complex logic is explained
// - README updated if needed

// ✅ Testing requirements:
// - New functionality has tests
// - Edge cases are covered
// - Error scenarios are tested
```

### Definition of Done

A feature is complete when:

- [ ] **Functionality**: Feature works as specified
- [ ] **Tests**: Unit tests written and passing
- [ ] **Integration**: Integrates with existing features
- [ ] **Error Handling**: Graceful error handling implemented
- [ ] **Documentation**: Code is self-documenting with comments
- [ ] **Performance**: No significant performance regressions
- [ ] **Security**: No security vulnerabilities introduced
- [ ] **UI/UX**: Follows design guidelines and accessibility standards

## 🚀 Automation Opportunities

### Git Hooks (Optional)

```bash
# Pre-commit hook to enforce quality:
#!/bin/bash
# .git/hooks/pre-commit

echo "Running pre-commit checks..."

# Build project
xcodebuild -project MoneyApp.xcodeproj -scheme MoneyApp -destination 'platform=iOS Simulator,name=iPhone 15' build
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Commit rejected."
    exit 1
fi

# Run tests
xcodebuild test -project MoneyApp.xcodeproj -scheme MoneyApp -destination 'platform=iOS Simulator,name=iPhone 15'
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit rejected."
    exit 1
fi

echo "✅ All checks passed. Proceeding with commit."
```

## 📚 Quick Reference Commands

```bash
# Essential Xcode shortcuts:
Cmd+B           # Build
Cmd+U           # Run tests
Cmd+Shift+K     # Clean build folder
Cmd+R           # Run app
Cmd+.           # Stop running

# Test shortcuts:
Click diamond   # Run single test
Cmd+6          # Show test navigator
Cmd+9          # Show issue navigator

# Preview shortcuts:
Cmd+Opt+P      # Resume preview
Cmd+Opt+Enter  # Canvas focus

# Git shortcuts:
git status     # Check changes
git add .      # Stage all changes
git commit -m  # Commit with message
git push       # Push to remote
```

## ⚠️ Remember

**The goal is fast, confident iteration. These workflows enable:**

- 🚀 **Rapid feedback**: Know immediately if changes break anything
- 🛡️ **Confidence**: Tests ensure regressions are caught early
- 🎯 **Quality**: Consistent practices maintain high code quality
- 👥 **Collaboration**: Standardized workflows enable team productivity

**Every minute spent following these workflows saves hours of debugging later.** 🕐