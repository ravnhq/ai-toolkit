---
title: Escape Key Should Close Modals
impact: MEDIUM
tags: keyboard, modals, dialogs
---

## Escape Key Should Close Modals

Modals and dialogs must close when pressing Escape. Most component libraries handle this automatically.

**Incorrect (no keyboard close):**

```tsx
// Bad - no Escape handling
function Modal({ isOpen, onClose }) {
  if (!isOpen) return null;

  return (
    <div className="modal-backdrop">
      <div className="modal-content">
        {/* Only X button to close */}
        <button onClick={onClose}>×</button>
        {children}
      </div>
    </div>
  );
}
```

**Correct (Escape closes modal):**

```tsx
// Good - using component library (handles this)
import { Dialog } from '@/components/ui/dialog';

<Dialog open={isOpen} onOpenChange={setIsOpen}>
  <DialogContent>
    {/* Escape key works automatically */}
  </DialogContent>
</Dialog>

// Good - custom implementation
function Modal({ isOpen, onClose, children }) {
  useEffect(() => {
    function handleEscape(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape);
    }

    return () => {
      document.removeEventListener('keydown', handleEscape);
    };
  }, [isOpen, onClose]);

  // ...
}
```

**Modal accessibility checklist:**

- [ ] Escape closes the modal
- [ ] Focus moves into modal when opened
- [ ] Focus is trapped inside modal
- [ ] Focus returns to trigger when closed
- [ ] Click outside closes (optional but expected)

**Why it matters:**
- Standard keyboard expectation
- Keyboard users need to exit without mouse
- Radix/shadcn Dialog handles this automatically

Reference: [ARIA Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
