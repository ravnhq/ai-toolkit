---
title: Test RTL Languages (Arabic, Hebrew); Mirror Layouts and Adjust String Length
impact: MEDIUM
tags: layout, rtl, right-to-left, internationalization, testing
---

## Test RTL Languages (Arabic, Hebrew); Mirror Layouts and Adjust String Length

Right-to-left (RTL) languages (Arabic, Hebrew, Farsi) require mirrored layouts, longer string budgets, and bidirectional number handling. Design with RTL in mind from the start; do not retrofit it.

**Incorrect (LTR-only design; breaks in RTL):**

```swift
import SwiftUI

struct MessageThread: View {
    var messages: [Message]

    var body: some View {
        List {
            ForEach(messages) { message in
                HStack(spacing: 12) {
                    // Avatar on left; assumes LTR
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))

                    VStack(alignment: .leading) {  // ❌ Leading alignment assumes LTR
                        Text(message.sender)
                            .font(.headline)
                        Text(message.text)
                            .font(.body)
                        Text(message.time)
                            .font(.caption)
                    }

                    Spacer()  // ❌ Spacer positions content LTR
                }
                .padding()
            }
        }
    }
}
```

On Arabic device: avatar appears on right, text alignment is wrong, UI looks broken.

**Incorrect (fixed string width; breaks on translation):**

```swift
VStack {
    Text("Filter")  // ✅ 6 characters
        .font(.headline)
    Text(String(localized: "filterLabel"))  // ❌ May expand to 15+ characters in German/Polish
        .font(.body)
}
.frame(width: 100)  // ❌ Fixed width; text overflows in other languages
```

**Correct (environment-aware layout direction):**

```swift
import SwiftUI

struct MessageThread: View {
    @Environment(\.layoutDirection) var layoutDirection

    var messages: [Message]

    var body: some View {
        List {
            ForEach(messages) { message in
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))

                    VStack(alignment: .leading) {  // ✅ SwiftUI auto-mirrors in RTL
                        Text(message.sender)
                            .font(.headline)
                        Text(message.text)
                            .font(.body)
                            .lineLimit(nil)  // ✅ Allow text to wrap in any language
                        Text(message.time)
                            .font(.caption)
                    }

                    Spacer()  // ✅ SwiftUI automatically mirrors Spacer placement
                }
                .padding()
            }
        }
    }
}
```

SwiftUI automatically mirrors `.leading`/`.trailing`, `HStack` order, and Spacer placement for RTL. No manual intervention needed.

**Correct (UIKit RTL handling):**

```swift
import UIKit

class MessageViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView()
        stackView.semanticContentAttribute = .forceLeftToRight  // ❌ NEVER do this; breaks RTL
        // ✅ Instead, rely on autolayout and let UIKit mirror automatically

        let label = UILabel()
        label.textAlignment = .natural  // ✅ Adapts to device language (LTR/RTL)
    }
}
```

**Correct (flexible layout with i18n-aware spacing):**

```swift
import SwiftUI

struct ProfileHeader: View {
    @Environment(\.layoutDirection) var layoutDirection
    let user: User

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AsyncImage(url: user.avatarURL) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 4) {  // ✅ Auto-mirrors in RTL
                    Text(user.name)
                        .font(.headline)
                    Text(user.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // String may be longer in German (36 chars) than English (20 chars)
            Text(String(localized: "userBioDescription \(user.bio)"))
                .font(.body)
                .lineLimit(nil)  // ✅ Allow wrapping for text expansion
                .fixedSize(horizontal: false, vertical: true)  // ✅ Expand vertically as needed
        }
        .padding()
    }
}
```

**Correct (test with pseudo-localization):**

```swift
// In Xcode scheme, set App Language to "Pseudo-Right-to-Left" or "Arabic"
// This simulates RTL layout and longer strings (pseudo-localization expands to 30% longer)

// Inspect in preview:
#Preview {
    ProfileHeader(user: .mock)
        .environment(\.layoutDirection, .rightToLeft)  // ✅ Manual RTL preview
}
```

**Correct (number and date formatting):**

```swift
import SwiftUI

struct TransactionView: View {
    let amount: Decimal
    let date: Date

    var body: some View {
        VStack {
            // ✅ Number formatting respects locale (RTL number direction, grouping)
            Text(String(localized: "amount \(amount.formatted(.currency(code: "USD")))"))

            // ✅ Date formatting adapts to locale
            Text(date.formatted(date: .abbreviated, time: .omitted))
        }
    }
}
```

**Why it matters**

- **RTL layout flipping** — Avatar, icons, and layout direction flip automatically in RTL languages; manual positioning breaks the UI.
- **String expansion** — Translated text is 20–35% longer in German, Polish, and other languages. Fixed-width layouts cause overflow.
- **Number direction** — Arabic numbers are read right-to-left (٥٣١ instead of 135), but Western numerals must be handled contextually.
- **User experience** — Users in RTL regions expect native RTL layouts. LTR-only UI is confusing and signals poor localization effort.

Design with RTL from the start:
- Use `.leading`/`.trailing` instead of `.left`/`.right`.
- Use `textAlignment: .natural` (UIKit) or rely on SwiftUI default mirroring.
- Allow flexible spacing and line wrapping.
- Test with device language set to Arabic, Hebrew, or Farsi in Settings → General → Language.
- Use pseudo-localization tools to simulate text expansion and RTL mirroring.
