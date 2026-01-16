# Creational Patterns

Patterns that handle object creation mechanisms, increasing flexibility and reuse of existing code.

---

## Factory Method

**Problem**: Creating objects without specifying exact classes causes tight coupling between creator and concrete types.

**When to Use**:
- You don't know exact types beforehand
- You want to provide extension points for library users
- You need to reuse existing objects instead of rebuilding them

**Structure**:
- `Creator` - Declares factory method
- `ConcreteCreator` - Overrides factory method
- `Product` - Interface for objects
- `ConcreteProduct` - Implements product interface

**TypeScript Example**:
```typescript
// Product interface
interface Transport {
  deliver(): void;
}

// Concrete products
class Truck implements Transport {
  deliver(): void {
    console.log("Deliver by land in a box");
  }
}

class Ship implements Transport {
  deliver(): void {
    console.log("Deliver by sea in a container");
  }
}

// Creator
abstract class Logistics {
  // Factory method
  abstract createTransport(): Transport;

  planDelivery(): void {
    const transport = this.createTransport();
    transport.deliver();
  }
}

// Concrete creators
class RoadLogistics extends Logistics {
  createTransport(): Transport {
    return new Truck();
  }
}

class SeaLogistics extends Logistics {
  createTransport(): Transport {
    return new Ship();
  }
}

// Usage
const roadLogistics = new RoadLogistics();
roadLogistics.planDelivery(); // Deliver by land
```

**Pros**:
- Avoids coupling between creator and products
- Single Responsibility - centralized creation code
- Open/Closed - add new products without breaking existing code

**Cons**:
- Can require many subclasses

**Related**: Often evolves to Abstract Factory, Prototype, or Builder

---

## Abstract Factory

**Problem**: Need to create families of related objects while ensuring compatibility without depending on concrete classes.

**When to Use**:
- Code needs to work with various families of related products
- You can't predict product variants beforehand
- A class has multiple factory methods obscuring its main responsibility

**Structure**:
- `AbstractFactory` - Interface for creating product families
- `ConcreteFactory` - Implements creation methods for variants
- `AbstractProduct` - Interfaces for each product type
- `ConcreteProduct` - Implementations for each variant

**TypeScript Example**:
```typescript
// Abstract products
interface Button {
  render(): void;
}

interface Checkbox {
  render(): void;
}

// Windows products
class WindowsButton implements Button {
  render(): void {
    console.log("Render Windows button");
  }
}

class WindowsCheckbox implements Checkbox {
  render(): void {
    console.log("Render Windows checkbox");
  }
}

// Mac products
class MacButton implements Button {
  render(): void {
    console.log("Render Mac button");
  }
}

class MacCheckbox implements Checkbox {
  render(): void {
    console.log("Render Mac checkbox");
  }
}

// Abstract factory
interface GUIFactory {
  createButton(): Button;
  createCheckbox(): Checkbox;
}

// Concrete factories
class WindowsFactory implements GUIFactory {
  createButton(): Button {
    return new WindowsButton();
  }
  createCheckbox(): Checkbox {
    return new WindowsCheckbox();
  }
}

class MacFactory implements GUIFactory {
  createButton(): Button {
    return new MacButton();
  }
  createCheckbox(): Checkbox {
    return new MacCheckbox();
  }
}

// Usage
function renderUI(factory: GUIFactory) {
  const button = factory.createButton();
  const checkbox = factory.createCheckbox();
  button.render();
  checkbox.render();
}

const os = "Windows";
const factory = os === "Windows" ? new WindowsFactory() : new MacFactory();
renderUI(factory);
```

**Pros**:
- Ensures product compatibility
- Avoids tight coupling to concrete products
- Single Responsibility - centralized product creation
- Open/Closed - new variants without breaking existing code

**Cons**:
- Significant complexity with many new interfaces/classes

**Related**: Often evolves from Factory Method; can be implemented with Prototype or Builder

---

## Builder

**Problem**: Constructing complex objects with many optional parameters leads to giant constructors or subclass explosion.

**When to Use**:
- Telescoping constructors with many optional parameters
- Need to create different representations of a product
- Constructing complex composite objects like trees

**Structure**:
- `Builder` - Interface for construction steps
- `ConcreteBuilder` - Implements steps for specific representation
- `Director` - Defines construction order (optional)
- `Product` - Complex object being built

**TypeScript Example**:
```typescript
// Product
class House {
  walls?: string;
  doors?: number;
  windows?: number;
  roof?: string;
  garage?: boolean;

  describe(): void {
    console.log(`House with ${this.walls} walls, ${this.doors} doors, ` +
                `${this.windows} windows, ${this.roof} roof, ` +
                `garage: ${this.garage}`);
  }
}

// Builder interface
interface HouseBuilder {
  reset(): void;
  buildWalls(material: string): this;
  buildDoors(count: number): this;
  buildWindows(count: number): this;
  buildRoof(type: string): this;
  buildGarage(): this;
  getResult(): House;
}

// Concrete builder
class ConcreteHouseBuilder implements HouseBuilder {
  private house!: House;

  constructor() {
    this.reset();
  }

  reset(): void {
    this.house = new House();
  }

  buildWalls(material: string): this {
    this.house.walls = material;
    return this;
  }

  buildDoors(count: number): this {
    this.house.doors = count;
    return this;
  }

  buildWindows(count: number): this {
    this.house.windows = count;
    return this;
  }

  buildRoof(type: string): this {
    this.house.roof = type;
    return this;
  }

  buildGarage(): this {
    this.house.garage = true;
    return this;
  }

  getResult(): House {
    const result = this.house;
    this.reset();
    return result;
  }
}

// Usage
const builder = new ConcreteHouseBuilder();
const house = builder
  .buildWalls("brick")
  .buildDoors(2)
  .buildWindows(6)
  .buildRoof("tile")
  .buildGarage()
  .getResult();

house.describe();
```

**Pros**:
- Construct objects step-by-step
- Reuse construction code for different representations
- Single Responsibility - isolates complex construction

**Cons**:
- Increases code complexity with new classes

**Related**: Can combine with Composite for tree construction; often implemented alongside other creational patterns

---

## Singleton

**Problem**: Need to ensure a class has only one instance with global access point.

**When to Use**:
- Single shared resource (database, file) needs controlled access
- Need stricter control than global variables
- ⚠️ **Use sparingly** - often indicates design issues

**Structure**:
- Single class with private constructor and static instance field
- Static method to get instance (lazy initialization)

**TypeScript Example**:
```typescript
class Database {
  private static instance: Database;
  private connection: string;

  private constructor() {
    // Private constructor prevents direct instantiation
    this.connection = "Connected to database";
  }

  static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  query(sql: string): void {
    console.log(`Executing: ${sql}`);
  }
}

// Usage
const db1 = Database.getInstance();
const db2 = Database.getInstance();

console.log(db1 === db2); // true - same instance

db1.query("SELECT * FROM users");
```

**Pros**:
- Guarantees single instance
- Global access point
- Lazy initialization

**Cons**:
- Violates Single Responsibility Principle
- Can mask poor design
- Difficult to test (private constructor)
- Thread safety concerns in multi-threaded environments
- **Better alternative**: Use dependency injection

**Related**: Facade can become Singleton; many patterns can be implemented as Singletons

**⚠️ Warning**: Overuse of Singleton is an anti-pattern. Consider dependency injection instead.
