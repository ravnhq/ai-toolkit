# Behavioral Patterns

Patterns concerned with algorithms and the assignment of responsibilities between objects.

---

## Observer

**Problem**: Multiple objects need to be notified about state changes in another object without tight coupling.

**When to Use**:
- Changes in one object require changing others, and the set of objects is dynamic or unknown
- GUI classes need to react to user actions
- Objects need to observe others temporarily or in specific cases

**Structure**:
- `Publisher` - Maintains subscriber list, notifies on state changes
- `Subscriber` - Interface with update method
- `ConcreteSubscriber` - Implements update to react to changes

**TypeScript Example**:
```typescript
// Subscriber interface
interface Observer {
  update(data: any): void;
}

// Publisher
class EventManager {
  private observers: Map<string, Observer[]> = new Map();

  subscribe(eventType: string, observer: Observer): void {
    if (!this.observers.has(eventType)) {
      this.observers.set(eventType, []);
    }
    this.observers.get(eventType)!.push(observer);
  }

  unsubscribe(eventType: string, observer: Observer): void {
    const subscribers = this.observers.get(eventType);
    if (subscribers) {
      const index = subscribers.indexOf(observer);
      if (index > -1) {
        subscribers.splice(index, 1);
      }
    }
  }

  notify(eventType: string, data: any): void {
    const subscribers = this.observers.get(eventType);
    if (subscribers) {
      subscribers.forEach(observer => observer.update(data));
    }
  }
}

class Editor {
  private events: EventManager;
  private file?: string;

  constructor() {
    this.events = new EventManager();
  }

  getEvents(): EventManager {
    return this.events;
  }

  openFile(path: string): void {
    this.file = path;
    this.events.notify('open', path);
  }

  saveFile(): void {
    if (this.file) {
      this.events.notify('save', this.file);
    }
  }
}

// Concrete observers
class EmailNotificationListener implements Observer {
  private email: string;

  constructor(email: string) {
    this.email = email;
  }

  update(data: any): void {
    console.log(`Email to ${this.email}: File ${data} was saved`);
  }
}

class LoggingListener implements Observer {
  update(data: any): void {
    console.log(`Log: Someone performed operation on file ${data}`);
  }
}

// Usage
const editor = new Editor();
const emailListener = new EmailNotificationListener('admin@example.com');
const loggingListener = new LoggingListener();

editor.getEvents().subscribe('save', emailListener);
editor.getEvents().subscribe('save', loggingListener);

editor.openFile('test.txt');
editor.saveFile();
```

**Pros**:
- Open/Closed - add new subscribers without modifying publisher
- Establish relationships at runtime

**Cons**:
- Subscribers notified in random order
- Can cause memory leaks if not unsubscribed

**Related**: Mediator (eliminates direct connections), Command/Chain of Responsibility (different sender-receiver relationships)

---

## Strategy

**Problem**: Multiple algorithm variants within a single class cause code bloat and make changes risky.

**When to Use**:
- Need to use different variants of an algorithm and switch at runtime
- Similar classes differ only in behavior execution
- Want to isolate business logic from implementation details
- Class has massive conditionals selecting between algorithms

**Structure**:
- `Context` - Maintains reference to strategy
- `Strategy` - Interface for algorithms
- `ConcreteStrategy` - Implements specific algorithm

**TypeScript Example**:
```typescript
// Strategy interface
interface PaymentStrategy {
  pay(amount: number): void;
}

// Concrete strategies
class CreditCardPayment implements PaymentStrategy {
  private cardNumber: string;

  constructor(cardNumber: string) {
    this.cardNumber = cardNumber;
  }

  pay(amount: number): void {
    console.log(`Paid $${amount} using credit card ${this.cardNumber}`);
  }
}

class PayPalPayment implements PaymentStrategy {
  private email: string;

  constructor(email: string) {
    this.email = email;
  }

  pay(amount: number): void {
    console.log(`Paid $${amount} using PayPal account ${this.email}`);
  }
}

class CryptoPayment implements PaymentStrategy {
  private walletAddress: string;

  constructor(walletAddress: string) {
    this.walletAddress = walletAddress;
  }

  pay(amount: number): void {
    console.log(`Paid $${amount} using crypto wallet ${this.walletAddress}`);
  }
}

// Context
class ShoppingCart {
  private items: string[] = [];
  private paymentStrategy?: PaymentStrategy;

  addItem(item: string): void {
    this.items.push(item);
  }

  setPaymentStrategy(strategy: PaymentStrategy): void {
    this.paymentStrategy = strategy;
  }

  checkout(amount: number): void {
    if (!this.paymentStrategy) {
      console.log('Please select a payment method');
      return;
    }
    this.paymentStrategy.pay(amount);
  }
}

// Usage - swap strategies at runtime
const cart = new ShoppingCart();
cart.addItem('Book');
cart.addItem('Laptop');

// Pay with credit card
cart.setPaymentStrategy(new CreditCardPayment('1234-5678-9012-3456'));
cart.checkout(500);

// Change to PayPal
cart.setPaymentStrategy(new PayPalPayment('user@example.com'));
cart.checkout(500);
```

**Pros**:
- Swap algorithms at runtime
- Isolate implementation from usage
- Use composition instead of inheritance
- Open/Closed - add new strategies without changing context

**Cons**:
- Overkill for few rarely-changing algorithms
- Clients must understand strategy differences
- Modern functional programming may reduce need

**Related**: Command (turns operations to objects), State (strategies may be aware of each other), Template Method (class-level vs object-level)

---

## Command

**Problem**: Tight coupling between GUI elements and business logic makes code difficult to reuse and extend.

**When to Use**:
- Parameterize objects with operations
- Queue, schedule, or execute operations remotely
- Implement reversible operations (undo/redo)
- Want to log or persist operations

**Structure**:
- `Command` - Interface with execute method
- `ConcreteCommand` - Implements execute, stores receiver and parameters
- `Invoker` - Triggers commands
- `Receiver` - Contains business logic

**TypeScript Example**:
```typescript
// Receiver
class TextEditor {
  private text: string = '';

  getText(): string {
    return this.text;
  }

  insertText(text: string): void {
    this.text += text;
  }

  deleteText(length: number): void {
    this.text = this.text.slice(0, -length);
  }
}

// Command interface
interface Command {
  execute(): void;
  undo(): void;
}

// Concrete commands
class InsertTextCommand implements Command {
  private editor: TextEditor;
  private text: string;

  constructor(editor: TextEditor, text: string) {
    this.editor = editor;
    this.text = text;
  }

  execute(): void {
    this.editor.insertText(this.text);
  }

  undo(): void {
    this.editor.deleteText(this.text.length);
  }
}

class DeleteTextCommand implements Command {
  private editor: TextEditor;
  private length: number;
  private deletedText: string = '';

  constructor(editor: TextEditor, length: number) {
    this.editor = editor;
    this.length = length;
  }

  execute(): void {
    const text = this.editor.getText();
    this.deletedText = text.slice(-this.length);
    this.editor.deleteText(this.length);
  }

  undo(): void {
    this.editor.insertText(this.deletedText);
  }
}

// Invoker
class CommandHistory {
  private history: Command[] = [];
  private current: number = -1;

  execute(command: Command): void {
    // Remove any commands after current position
    this.history = this.history.slice(0, this.current + 1);

    command.execute();
    this.history.push(command);
    this.current++;
  }

  undo(): void {
    if (this.current >= 0) {
      this.history[this.current].undo();
      this.current--;
    }
  }

  redo(): void {
    if (this.current < this.history.length - 1) {
      this.current++;
      this.history[this.current].execute();
    }
  }
}

// Usage
const editor = new TextEditor();
const history = new CommandHistory();

history.execute(new InsertTextCommand(editor, 'Hello '));
history.execute(new InsertTextCommand(editor, 'World'));
console.log(editor.getText()); // "Hello World"

history.undo();
console.log(editor.getText()); // "Hello "

history.redo();
console.log(editor.getText()); // "Hello World"
```

**Pros**:
- Decouples invokers from performers (Single Responsibility)
- Open/Closed - new commands without modifying existing code
- Implements undo/redo
- Supports deferred execution
- Compose simple commands into complex ones

**Cons**:
- Adds new layer between senders and receivers

**Related**: Chain of Responsibility/Mediator/Observer (sender-receiver patterns), Memento (undo state), Strategy (operation to object)

---

## State

**Problem**: Objects behave differently based on state, leading to massive conditionals that are hard to maintain.

**When to Use**:
- Object behavior depends on state with numerous states and frequent changes
- Class has bulky conditionals altering behavior based on field values
- Similar states have duplicate code in state machine

**Structure**:
- `Context` - Maintains current state, delegates requests
- `State` - Interface declaring state-specific methods
- `ConcreteState` - Implements behavior for specific state

**TypeScript Example**:
```typescript
// State interface
interface State {
  insertCoin(): void;
  ejectCoin(): void;
  selectProduct(): void;
  dispense(): void;
}

// Context
class VendingMachine {
  private state: State;
  private hasProduct: boolean = true;

  constructor() {
    this.state = new NoCoinState(this);
  }

  setState(state: State): void {
    this.state = state;
  }

  insertCoin(): void {
    this.state.insertCoin();
  }

  ejectCoin(): void {
    this.state.ejectCoin();
  }

  selectProduct(): void {
    this.state.selectProduct();
  }

  dispense(): void {
    this.state.dispense();
  }

  hasProductAvailable(): boolean {
    return this.hasProduct;
  }

  releaseProduct(): void {
    if (this.hasProduct) {
      console.log('Product dispensed');
      this.hasProduct = false;
    }
  }
}

// Concrete states
class NoCoinState implements State {
  private machine: VendingMachine;

  constructor(machine: VendingMachine) {
    this.machine = machine;
  }

  insertCoin(): void {
    console.log('Coin inserted');
    this.machine.setState(new HasCoinState(this.machine));
  }

  ejectCoin(): void {
    console.log('No coin to eject');
  }

  selectProduct(): void {
    console.log('Insert coin first');
  }

  dispense(): void {
    console.log('Insert coin first');
  }
}

class HasCoinState implements State {
  private machine: VendingMachine;

  constructor(machine: VendingMachine) {
    this.machine = machine;
  }

  insertCoin(): void {
    console.log('Coin already inserted');
  }

  ejectCoin(): void {
    console.log('Coin ejected');
    this.machine.setState(new NoCoinState(this.machine));
  }

  selectProduct(): void {
    console.log('Product selected');
    this.machine.setState(new DispensingState(this.machine));
  }

  dispense(): void {
    console.log('Select product first');
  }
}

class DispensingState implements State {
  private machine: VendingMachine;

  constructor(machine: VendingMachine) {
    this.machine = machine;
  }

  insertCoin(): void {
    console.log('Please wait, dispensing product');
  }

  ejectCoin(): void {
    console.log('Cannot eject, dispensing product');
  }

  selectProduct(): void {
    console.log('Already dispensing');
  }

  dispense(): void {
    this.machine.releaseProduct();
    if (this.machine.hasProductAvailable()) {
      this.machine.setState(new NoCoinState(this.machine));
    } else {
      this.machine.setState(new SoldOutState(this.machine));
    }
  }
}

class SoldOutState implements State {
  private machine: VendingMachine;

  constructor(machine: VendingMachine) {
    this.machine = machine;
  }

  insertCoin(): void {
    console.log('Sold out');
  }

  ejectCoin(): void {
    console.log('No coin to eject');
  }

  selectProduct(): void {
    console.log('Sold out');
  }

  dispense(): void {
    console.log('Sold out');
  }
}

// Usage
const machine = new VendingMachine();
machine.insertCoin();
machine.selectProduct();
machine.dispense();
```

**Pros**:
- Single Responsibility - organize state-related code
- Open/Closed - add new states without modifying existing
- Eliminates bulky conditionals

**Cons**:
- Overkill for simple state machines with few states

**Related**: Bridge/Strategy (structure), but State allows states to be aware of each other and change context state

---

## Template Method

**Problem**: Multiple classes implement similar algorithms with slight variations, causing code duplication.

**When to Use**:
- Let clients extend specific algorithm steps, not the whole structure
- Several classes contain nearly identical algorithms with minor differences
- Want to eliminate code duplication while preserving structure

**Structure**:
- `AbstractClass` - Defines template method and abstract steps
- `ConcreteClass` - Implements abstract steps

**TypeScript Example**:
```typescript
// Abstract class
abstract class DataMiner {
  // Template method
  public mine(path: string): void {
    const file = this.openFile(path);
    const rawData = this.extractData(file);
    const data = this.parseData(rawData);
    const analysis = this.analyzeData(data);
    this.sendReport(analysis);
    this.closeFile(file);
  }

  protected openFile(path: string): string {
    console.log(`Opening file: ${path}`);
    return path;
  }

  protected closeFile(file: string): void {
    console.log(`Closing file: ${file}`);
  }

  // Abstract steps - must be implemented
  protected abstract extractData(file: string): string;
  protected abstract parseData(data: string): any;

  // Hook - can be overridden
  protected analyzeData(data: any): string {
    console.log('Performing basic analysis');
    return 'Basic analysis results';
  }

  protected sendReport(analysis: string): void {
    console.log(`Report: ${analysis}`);
  }
}

// Concrete implementations
class PDFDataMiner extends DataMiner {
  protected extractData(file: string): string {
    console.log('Extracting data from PDF');
    return 'PDF raw data';
  }

  protected parseData(data: string): any {
    console.log('Parsing PDF data');
    return { type: 'PDF', content: data };
  }
}

class CSVDataMiner extends DataMiner {
  protected extractData(file: string): string {
    console.log('Extracting data from CSV');
    return 'CSV raw data';
  }

  protected parseData(data: string): any {
    console.log('Parsing CSV data');
    return { type: 'CSV', rows: data.split('\n') };
  }

  protected analyzeData(data: any): string {
    console.log('Performing advanced CSV analysis');
    return `CSV analysis: ${data.rows.length} rows`;
  }
}

// Usage
const pdfMiner = new PDFDataMiner();
pdfMiner.mine('data.pdf');

console.log('---');

const csvMiner = new CSVDataMiner();
csvMiner.mine('data.csv');
```

**Pros**:
- Clients override only specific algorithm parts
- Pull duplicate code to superclass

**Cons**:
- Clients limited by provided skeleton
- Can violate Liskov Substitution Principle
- Harder to maintain with many steps

**Related**: Factory Method (specialization of Template Method), Strategy (uses composition and runtime switching vs inheritance)

**Note**: Template Method works at class level (static), Strategy at object level (dynamic runtime switching).

---

## Memento

**Problem**: Need to save and restore an object's previous state without breaking encapsulation or exposing internal details.

**When to Use**:
- Need to produce snapshots of object state to restore previous states
- Implement undo/redo functionality
- Handle transaction rollback on errors
- Direct access to object fields would violate encapsulation

**Structure**:
- `Originator` - Creates memento containing snapshot of its state
- `Memento` - Value object acting as snapshot of originator's state
- `Caretaker` - Knows when and why to save/restore originator state

**TypeScript Example**:
```typescript
// Memento - stores snapshot
class EditorMemento {
  constructor(
    private readonly content: string,
    private readonly cursorPosition: number
  ) {}

  getContent(): string {
    return this.content;
  }

  getCursorPosition(): number {
    return this.cursorPosition;
  }
}

// Originator - creates and restores from mementos
class TextEditor {
  private content: string = '';
  private cursorPosition: number = 0;

  type(text: string): void {
    this.content = this.content.slice(0, this.cursorPosition) +
                   text +
                   this.content.slice(this.cursorPosition);
    this.cursorPosition += text.length;
  }

  setCursor(position: number): void {
    this.cursorPosition = Math.max(0, Math.min(position, this.content.length));
  }

  getContent(): string {
    return this.content;
  }

  // Create memento
  save(): EditorMemento {
    return new EditorMemento(this.content, this.cursorPosition);
  }

  // Restore from memento
  restore(memento: EditorMemento): void {
    this.content = memento.getContent();
    this.cursorPosition = memento.getCursorPosition();
  }
}

// Caretaker - manages mementos
class History {
  private mementos: EditorMemento[] = [];
  private currentIndex: number = -1;

  push(memento: EditorMemento): void {
    // Remove any mementos after current index
    this.mementos = this.mementos.slice(0, this.currentIndex + 1);
    this.mementos.push(memento);
    this.currentIndex++;
  }

  undo(): EditorMemento | null {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      return this.mementos[this.currentIndex];
    }
    return null;
  }

  redo(): EditorMemento | null {
    if (this.currentIndex < this.mementos.length - 1) {
      this.currentIndex++;
      return this.mementos[this.currentIndex];
    }
    return null;
  }
}

// Usage
const editor = new TextEditor();
const history = new History();

// Initial save
history.push(editor.save());

editor.type('Hello ');
history.push(editor.save());

editor.type('World');
history.push(editor.save());

console.log(editor.getContent()); // "Hello World"

// Undo
const undoState = history.undo();
if (undoState) {
  editor.restore(undoState);
  console.log(editor.getContent()); // "Hello "
}

// Undo again
const undoState2 = history.undo();
if (undoState2) {
  editor.restore(undoState2);
  console.log(editor.getContent()); // ""
}

// Redo
const redoState = history.redo();
if (redoState) {
  editor.restore(redoState);
  console.log(editor.getContent()); // "Hello "
}
```

**Pros**:
- Produce snapshots without violating encapsulation
- Simplifies originator by delegating history management to caretakers
- Maintains clean separation between state management and business logic

**Cons**:
- High RAM consumption if snapshots created frequently
- Caretakers must track originator lifecycle for cleanup
- Dynamic languages cannot guarantee memento state integrity

**Related**: Command + Memento (commands execute operations, mementos store pre-execution state for undo), Iterator (can capture iteration state), Prototype (simpler alternative for basic cloning)

**Note**: Memento is often used with Command pattern - Command handles the operation execution while Memento handles state restoration for undo.
