---
title: Fix with the smallest possible change
impact: CRITICAL
tags:
  - qa
  - bug-fix
  - minimal
  - surgical
---

## Rule

Every fix must be the smallest change that resolves the reported bug. Do not refactor surrounding code, add features, improve error messages beyond what is broken, or change method signatures unless absolutely required by the fix.

## Incorrect

```java
// Bug: missing null check on user.getEmail() in line 45
// "Fix" that refactors the entire method:
public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
    // Rewrote entire method with Optional pattern
    return userRepository.findById(id)
        .map(user -> {
            var dto = new UserDTO();
            dto.setName(Optional.ofNullable(user.getName()).orElse("Unknown"));
            dto.setEmail(Optional.ofNullable(user.getEmail()).orElse(""));
            dto.setRole(Optional.ofNullable(user.getRole()).orElse(Role.VIEWER));
            return ResponseEntity.ok(dto);
        })
        .orElseThrow(() -> new ResourceNotFoundException("User not found"));
}
```

- Error: Refactored the entire method instead of adding the missing null check.
- Cause: Engineer treated a bug fix as an opportunity to improve code style.

## Correct

```java
// Bug: missing null check on user.getEmail() in line 45
// Fix: add the null check on line 45
dto.setEmail(user.getEmail() != null ? user.getEmail() : "");
```

- One line changed — exactly the missing null check.
- Surrounding code untouched — no risk of introducing new bugs.

## Why it matters

Every line of code changed is a line that could introduce a new bug. Refactoring during bug fixes mixes two concerns (fixing vs improving), makes code review harder, increases risk, and makes it impossible to revert the fix without losing the refactoring. Fix first, refactor separately.
