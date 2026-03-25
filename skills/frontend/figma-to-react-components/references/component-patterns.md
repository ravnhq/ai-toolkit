# React Component Patterns

Proven patterns for implementing React components with design tokens, React Aria, and accessibility best practices. All examples use placeholder token comments — replace with your project's actual token references.

## General Component Structure

All components follow this structure:

```tsx
import React from 'react';
import { useComponentHook } from 'react-aria';
import type { AriaComponentProps } from 'react-aria';
import './ComponentName.scss'; // or .module.scss, .css, etc.

interface ComponentNameProps extends AriaComponentProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary';
  // ... other props from Figma extraction
}

export const ComponentName = ({
  size = 'md',
  variant = 'primary',
  ...ariaProps
}: ComponentNameProps) => {
  const ref = React.useRef(null);
  const { componentProps } = useComponentHook(ariaProps, ref);

  return (
    <element
      {...componentProps}
      ref={ref}
      className={`component-name component-name--${size} component-name--${variant}`}
    >
      {/* Component content */}
    </element>
  );
};
```

---

## Button Pattern

```tsx
import React from 'react';
import { useButton } from 'react-aria';
import type { AriaButtonProps } from 'react-aria';
import './Button.scss';

interface ButtonProps extends AriaButtonProps {
  size?: 'sm' | 'md' | 'lg';
  variant?: 'primary' | 'secondary' | 'destructive';
  isDisabled?: boolean;
  icon?: React.ReactNode;
  iconPosition?: 'left' | 'right';
  children: React.ReactNode;
}

export const Button = ({
  size = 'md',
  variant = 'primary',
  isDisabled = false,
  icon,
  iconPosition = 'left',
  children,
  ...ariaProps
}: ButtonProps) => {
  const ref = React.useRef(null);
  const { buttonProps } = useButton(
    { ...ariaProps, isDisabled },
    ref
  );

  return (
    <button
      {...buttonProps}
      ref={ref}
      className={`
        button
        button--${size}
        button--${variant}
        ${icon ? 'button--with-icon' : ''}
      `.trim()}
      disabled={isDisabled}
    >
      {icon && iconPosition === 'left' && (
        <span className="button__icon button__icon--left">{icon}</span>
      )}
      <span className="button__text">{children}</span>
      {icon && iconPosition === 'right' && (
        <span className="button__icon button__icon--right">{icon}</span>
      )}
    </button>
  );
};
```

**Styles:**
```scss
/* Import your project's token system */
/* @import 'path/to/your/tokens'; */

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: /* token: spacing-sm */;
  border: none;
  border-radius: /* token: radius-md */;
  cursor: pointer;
  transition: background-color 0.2s, box-shadow 0.2s;
  font-family: /* token: font-family-primary */;
  font-weight: /* token: font-weight-medium */;
  line-height: 1;

  &:focus-visible {
    outline: none;
    box-shadow: /* token: focus-ring */;
  }

  &:disabled {
    cursor: not-allowed;
    opacity: 1; /* Use token colors for disabled state, not opacity */
  }

  /* Primary variant */
  &--primary {
    background-color: /* token: action-primary-bg */;
    color: /* token: action-primary-text */;
    box-shadow: /* token: elevation-button */;

    &:hover:not(:disabled) {
      background-color: /* token: action-primary-bg-hover */;
    }

    &:active:not(:disabled) {
      background-color: /* token: action-primary-bg-pressed */;
    }

    &:disabled {
      background-color: /* token: action-primary-bg-disabled */;
      box-shadow: none;
    }
  }

  /* Secondary variant */
  &--secondary {
    background-color: /* token: action-secondary-bg */;
    color: /* token: action-secondary-text */;
    border: 1px solid /* token: action-secondary-border */;

    &:hover:not(:disabled) {
      background-color: /* token: action-secondary-bg-hover */;
      border-color: /* token: action-secondary-border-hover */;
    }

    &:active:not(:disabled) {
      background-color: /* token: action-secondary-bg-pressed */;
      border-color: /* token: action-secondary-border-pressed */;
    }

    &:disabled {
      background-color: /* token: action-secondary-bg-disabled */;
      border-color: /* token: action-secondary-border-disabled */;
      color: /* token: text-disabled */;
    }
  }

  /* Destructive variant */
  &--destructive {
    background-color: /* token: action-destructive-bg */;
    color: /* token: action-destructive-text */;

    &:hover:not(:disabled) {
      background-color: /* token: action-destructive-bg-hover */;
    }

    &:active:not(:disabled) {
      background-color: /* token: action-destructive-bg-pressed */;
    }
  }

  /* Size variants */
  &--sm {
    height: /* token: height-sm */;
    padding-inline: /* token: spacing-sm */;
    font-size: /* token: font-size-sm */;
  }

  &--md {
    height: /* token: height-md */;
    padding-inline: /* token: spacing-md */;
    font-size: /* token: font-size-md */;
  }

  &--lg {
    height: /* token: height-lg */;
    padding-inline: /* token: spacing-lg */;
    font-size: /* token: font-size-md */;
  }

  /* Icon positioning */
  &__icon {
    display: inline-flex;
    align-items: center;

    svg {
      width: /* token: icon-size-sm */;
      height: /* token: icon-size-sm */;
    }
  }
}
```

---

## TextField Pattern

```tsx
import React from 'react';
import { useTextField } from 'react-aria';
import type { AriaTextFieldProps } from 'react-aria';
import './TextField.scss';

interface TextFieldProps extends AriaTextFieldProps {
  label: string;
  errorMessage?: string;
  description?: string;
}

export const TextField = ({
  label,
  errorMessage,
  description,
  ...ariaProps
}: TextFieldProps) => {
  const ref = React.useRef(null);
  const { labelProps, inputProps, descriptionProps, errorMessageProps } =
    useTextField(ariaProps, ref);

  const hasError = !!errorMessage;

  return (
    <div className="text-field">
      <label {...labelProps} className="text-field__label">
        {label}
      </label>
      {description && (
        <div {...descriptionProps} className="text-field__description">
          {description}
        </div>
      )}
      <input
        {...inputProps}
        ref={ref}
        className={`text-field__input ${hasError ? 'text-field__input--error' : ''}`}
      />
      {hasError && (
        <div {...errorMessageProps} className="text-field__error">
          {errorMessage}
        </div>
      )}
    </div>
  );
};
```

**Styles:**
```scss
.text-field {
  display: flex;
  flex-direction: column;
  gap: /* token: spacing-xs */;

  &__label {
    font-size: /* token: font-size-sm */;
    font-weight: /* token: font-weight-medium */;
    color: /* token: text-primary */;
  }

  &__description {
    font-size: /* token: font-size-sm */;
    color: /* token: text-secondary */;
  }

  &__input {
    height: /* token: height-md */;
    padding: /* token: spacing-sm */ /* token: spacing-md */;
    border: 1px solid /* token: border-input-default */;
    border-radius: /* token: radius-md */;
    font-size: /* token: font-size-md */;
    color: /* token: text-primary */;
    background-color: /* token: surface-primary */;
    transition: border-color 0.2s, box-shadow 0.2s;

    &::placeholder {
      color: /* token: text-disabled */;
    }

    &:hover:not(:disabled) {
      border-color: /* token: border-input-hover */;
    }

    &:focus-visible {
      outline: none;
      border-color: /* token: border-input-active */;
      box-shadow: /* token: focus-ring */;
    }

    &:disabled {
      background-color: /* token: surface-disabled */;
      border-color: /* token: border-input-disabled */;
      color: /* token: text-disabled */;
      cursor: not-allowed;
    }

    &--error {
      border-color: /* token: border-error */;

      &:focus-visible {
        box-shadow: /* token: focus-error */;
      }
    }
  }

  &__error {
    font-size: /* token: font-size-sm */;
    color: /* token: text-error */;
  }
}
```

---

## Checkbox Pattern

```tsx
import React from 'react';
import { useCheckbox } from 'react-aria';
import { useToggleState } from 'react-stately';
import type { AriaCheckboxProps } from 'react-aria';
import './Checkbox.scss';

interface CheckboxProps extends AriaCheckboxProps {
  label: string;
}

export const Checkbox = ({ label, ...ariaProps }: CheckboxProps) => {
  const ref = React.useRef(null);
  const state = useToggleState(ariaProps);
  const { inputProps } = useCheckbox(ariaProps, state, ref);

  return (
    <label className="checkbox">
      <input {...inputProps} ref={ref} className="checkbox__input" />
      <span className="checkbox__box">
        {state.isSelected && (
          <svg viewBox="0 0 16 16" className="checkbox__check">
            <path
              d="M3 8l3 3 7-7"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        )}
      </span>
      <span className="checkbox__label">{label}</span>
    </label>
  );
};
```

**Styles:**
```scss
.checkbox {
  display: inline-flex;
  align-items: center;
  gap: /* token: spacing-sm */;
  cursor: pointer;

  &__input {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;

    &:focus-visible + .checkbox__box {
      box-shadow: /* token: focus-ring */;
    }

    &:disabled ~ .checkbox__box {
      background-color: /* token: surface-disabled */;
      border-color: /* token: border-disabled */;
      cursor: not-allowed;
    }

    &:disabled ~ .checkbox__label {
      color: /* token: text-disabled */;
      cursor: not-allowed;
    }
  }

  &__box {
    position: relative;
    width: 20px;
    height: 20px;
    border: 1px solid /* token: border-input-default */;
    border-radius: /* token: radius-sm */;
    background-color: /* token: surface-primary */;
    transition: all 0.2s;

    .checkbox__input:checked ~ & {
      background-color: /* token: action-primary-bg */;
      border-color: /* token: action-primary-bg */;
    }

    .checkbox__input:hover:not(:disabled) ~ & {
      border-color: /* token: border-input-hover */;
    }
  }

  &__check {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 12px;
    height: 12px;
    color: /* token: text-on-action-primary */;
  }

  &__label {
    font-size: /* token: font-size-md */;
    color: /* token: text-primary */;
  }
}
```

---

## Select/Dropdown Pattern

```tsx
import React from 'react';
import { useSelect } from 'react-aria';
import { useSelectState } from 'react-stately';
import type { AriaSelectProps } from 'react-aria';
import './Select.scss';

interface SelectProps<T> extends AriaSelectProps<T> {
  label: string;
}

export function Select<T extends object>({
  label,
  ...ariaProps
}: SelectProps<T>) {
  const ref = React.useRef(null);
  const state = useSelectState(ariaProps);
  const {
    labelProps,
    triggerProps,
    valueProps,
    menuProps,
  } = useSelect(ariaProps, state, ref);

  return (
    <div className="select">
      <label {...labelProps} className="select__label">
        {label}
      </label>
      <button
        {...triggerProps}
        ref={ref}
        className="select__trigger"
      >
        <span {...valueProps} className="select__value">
          {state.selectedItem?.rendered || 'Select an option'}
        </span>
        <span className="select__arrow">&#x25BC;</span>
      </button>
      {state.isOpen && (
        <div className="select__menu">
          {/* Menu items rendered using useListBox and useOption */}
        </div>
      )}
    </div>
  );
}
```

---

## Card Pattern (Interactive)

```tsx
import React from 'react';
import { useFocusRing } from 'react-aria';
import './Card.scss';

interface CardProps {
  title: string;
  description?: string;
  children?: React.ReactNode;
  onClick?: () => void;
  href?: string;
}

export const Card = ({
  title,
  description,
  children,
  onClick,
  href,
}: CardProps) => {
  const { isFocusVisible, focusProps } = useFocusRing();
  const isInteractive = !!(onClick || href);

  const Element = href ? 'a' : onClick ? 'button' : 'div';

  return (
    <Element
      {...(isInteractive ? focusProps : {})}
      onClick={onClick}
      href={href}
      className={`
        card
        ${isInteractive ? 'card--interactive' : ''}
        ${isFocusVisible ? 'card--focus-visible' : ''}
      `.trim()}
    >
      <h3 className="card__title">{title}</h3>
      {description && (
        <p className="card__description">{description}</p>
      )}
      {children && (
        <div className="card__content">{children}</div>
      )}
    </Element>
  );
};
```

**Styles:**
```scss
.card {
  display: flex;
  flex-direction: column;
  gap: /* token: spacing-sm */;
  padding: /* token: spacing-lg */;
  background-color: /* token: surface-primary */;
  border-radius: /* token: radius-md */;
  box-shadow: /* token: elevation-md */;
  transition: all 0.2s;

  &--interactive {
    cursor: pointer;
    text-decoration: none;
    color: inherit;
    border: none;
    text-align: left;
    width: 100%;

    &:hover {
      background-color: /* token: surface-hover */;
      box-shadow: /* token: elevation-lg */;
    }

    &:active {
      background-color: /* token: surface-pressed */;
    }
  }

  &--focus-visible {
    outline: none;
    box-shadow: /* token: focus-ring */, /* token: elevation-md */;
  }

  &__title {
    margin: 0;
    font-size: /* token: font-size-lg */;
    font-weight: /* token: font-weight-medium */;
    color: /* token: text-primary */;
  }

  &__description {
    margin: 0;
    font-size: /* token: font-size-md */;
    color: /* token: text-secondary */;
  }

  &__content {
    margin-top: /* token: spacing-sm */;
  }
}
```

---

## Modal/Dialog Pattern

```tsx
import React from 'react';
import { useDialog } from 'react-aria';
import type { AriaDialogProps } from 'react-aria';
import './Modal.scss';

interface ModalProps extends AriaDialogProps {
  title: string;
  children: React.ReactNode;
  isOpen: boolean;
  onClose: () => void;
}

export const Modal = ({
  title,
  children,
  isOpen,
  onClose,
  ...ariaProps
}: ModalProps) => {
  const ref = React.useRef(null);
  const { dialogProps, titleProps } = useDialog(ariaProps, ref);

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        {...dialogProps}
        ref={ref}
        className="modal"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal__header">
          <h2 {...titleProps} className="modal__title">
            {title}
          </h2>
          <button
            className="modal__close"
            onClick={onClose}
            aria-label="Close"
          >
            &times;
          </button>
        </div>
        <div className="modal__content">{children}</div>
      </div>
    </div>
  );
};
```

**Styles:**
```scss
.modal-overlay {
  position: fixed;
  inset: 0;
  background-color: /* token: overlay-dark */;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background-color: /* token: surface-primary */;
  border-radius: /* token: radius-md */;
  box-shadow: /* token: elevation-xl */;
  max-width: 90%;
  max-height: 90%;
  overflow: auto;

  &__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: /* token: spacing-lg */;
    border-bottom: 1px solid /* token: border-divider */;
  }

  &__title {
    margin: 0;
    font-size: /* token: font-size-xl */;
    font-weight: /* token: font-weight-medium */;
    color: /* token: text-primary */;
  }

  &__close {
    background: none;
    border: none;
    font-size: 32px;
    cursor: pointer;
    color: /* token: text-secondary */;
    padding: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: /* token: radius-sm */;

    &:hover {
      background-color: /* token: surface-hover */;
    }

    &:focus-visible {
      outline: none;
      box-shadow: /* token: focus-ring */;
    }
  }

  &__content {
    padding: /* token: spacing-lg */;
  }
}
```

---

## Accessibility Best Practices

### Focus Management
1. Always use `:focus-visible` instead of `:focus`
2. Provide clear focus indicators using your project's focus tokens
3. Never remove outline without providing alternative visual feedback
4. Use `useFocusRing` hook from React Aria for consistent focus styling

### Keyboard Navigation
1. All interactive elements must be keyboard accessible
2. Use React Aria hooks to handle keyboard events correctly
3. Implement proper tab order with logical DOM structure
4. Provide keyboard shortcuts where appropriate (document with `aria-keyshortcuts`)

### Screen Readers
1. Use semantic HTML elements (`button`, `input`, `label`, etc.)
2. Provide descriptive labels for all form inputs
3. Use `aria-label` or `aria-labelledby` when visual labels aren't present
4. Announce state changes with `aria-live` regions when appropriate

### Color Contrast
1. Use high-contrast token variants where available
2. Test all color combinations meet WCAG AA standards (4.5:1 for normal text)
3. Provide visual indicators beyond color alone
4. Use disabled state tokens that maintain readability

### Component States
Document and implement all states:
- Default
- Hover
- Focus
- Active/Pressed
- Disabled
- Loading (if applicable)
- Error (if applicable)
