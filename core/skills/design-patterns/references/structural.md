# Structural Patterns

Patterns that explain how to assemble objects and classes into larger structures while keeping these structures flexible and efficient.

---

## Adapter

**Problem**: Incompatible interfaces prevent objects from working together (e.g., integrating a JSON-based library into an XML-based application).

**When to Use**:
- Need to use an existing class with an incompatible interface
- Want to reuse subclasses lacking common functionality
- Working with third-party libraries that don't match your interface

**Structure**:
- `Target` - Interface expected by client
- `Adapter` - Implements target, delegates to adaptee
- `Adaptee` - Existing class with incompatible interface
- `Client` - Works with target interface

**TypeScript Example**:
```typescript
// Existing system expects this interface
interface MediaPlayer {
  play(filename: string): void;
}

// Legacy audio player
class AudioPlayer implements MediaPlayer {
  play(filename: string): void {
    if (filename.endsWith('.mp3')) {
      console.log(`Playing MP3 file: ${filename}`);
    } else {
      console.log(`Format not supported`);
    }
  }
}

// Advanced player with different interface (adaptee)
class AdvancedMediaPlayer {
  playVlc(filename: string): void {
    console.log(`Playing VLC file: ${filename}`);
  }

  playMp4(filename: string): void {
    console.log(`Playing MP4 file: ${filename}`);
  }
}

// Adapter
class MediaAdapter implements MediaPlayer {
  private advancedPlayer: AdvancedMediaPlayer;

  constructor() {
    this.advancedPlayer = new AdvancedMediaPlayer();
  }

  play(filename: string): void {
    if (filename.endsWith('.vlc')) {
      this.advancedPlayer.playVlc(filename);
    } else if (filename.endsWith('.mp4')) {
      this.advancedPlayer.playMp4(filename);
    }
  }
}

// Enhanced audio player using adapter
class EnhancedAudioPlayer implements MediaPlayer {
  private adapter?: MediaAdapter;

  play(filename: string): void {
    if (filename.endsWith('.mp3')) {
      console.log(`Playing MP3 file: ${filename}`);
    } else if (filename.endsWith('.vlc') || filename.endsWith('.mp4')) {
      this.adapter = new MediaAdapter();
      this.adapter.play(filename);
    } else {
      console.log(`Invalid format: ${filename}`);
    }
  }
}

// Usage
const player = new EnhancedAudioPlayer();
player.play('song.mp3');
player.play('video.mp4');
player.play('movie.vlc');
```

**Pros**:
- Single Responsibility - separates interface conversion from business logic
- Open/Closed - add new adapters without breaking existing code

**Cons**:
- Increases overall complexity
- Sometimes simpler to modify the service class directly

**Related**: Bridge (designed upfront vs. retrofitted), Decorator (changes interface), Facade (new simple interface)

---

## Decorator

**Problem**: Need to add behaviors to objects dynamically without creating an explosion of subclasses.

**When to Use**:
- Assign extra behaviors at runtime without breaking existing code
- Inheritance is impractical (e.g., `final` classes)
- Need to combine multiple behaviors flexibly

**Structure**:
- `Component` - Interface for objects
- `ConcreteComponent` - Basic implementation
- `Decorator` - Base class wrapping a component
- `ConcreteDecorator` - Adds specific behavior

**TypeScript Example**:
```typescript
// Component interface
interface DataSource {
  writeData(data: string): void;
  readData(): string;
}

// Concrete component
class FileDataSource implements DataSource {
  private filename: string;
  private data: string = '';

  constructor(filename: string) {
    this.filename = filename;
  }

  writeData(data: string): void {
    console.log(`Writing to file: ${this.filename}`);
    this.data = data;
  }

  readData(): string {
    console.log(`Reading from file: ${this.filename}`);
    return this.data;
  }
}

// Base decorator
abstract class DataSourceDecorator implements DataSource {
  protected wrappee: DataSource;

  constructor(source: DataSource) {
    this.wrappee = source;
  }

  writeData(data: string): void {
    this.wrappee.writeData(data);
  }

  readData(): string {
    return this.wrappee.readData();
  }
}

// Concrete decorators
class EncryptionDecorator extends DataSourceDecorator {
  writeData(data: string): void {
    const encrypted = this.encrypt(data);
    super.writeData(encrypted);
  }

  readData(): string {
    const data = super.readData();
    return this.decrypt(data);
  }

  private encrypt(data: string): string {
    console.log('Encrypting data');
    return Buffer.from(data).toString('base64');
  }

  private decrypt(data: string): string {
    console.log('Decrypting data');
    return Buffer.from(data, 'base64').toString();
  }
}

class CompressionDecorator extends DataSourceDecorator {
  writeData(data: string): void {
    const compressed = this.compress(data);
    super.writeData(compressed);
  }

  readData(): string {
    const data = super.readData();
    return this.decompress(data);
  }

  private compress(data: string): string {
    console.log('Compressing data');
    return `compressed(${data})`;
  }

  private decompress(data: string): string {
    console.log('Decompressing data');
    return data.replace('compressed(', '').replace(')', '');
  }
}

// Usage - layer decorators
let source: DataSource = new FileDataSource('data.txt');
source = new EncryptionDecorator(source);
source = new CompressionDecorator(source);

source.writeData('Hello World');
console.log(source.readData());
```

**Pros**:
- Extend behavior without new subclasses
- Add/remove responsibilities at runtime
- Combine multiple behaviors
- Single Responsibility - divide monolithic class

**Cons**:
- Hard to remove specific wrappers from stack
- Behavior depends on decorator order
- Initial configuration can be complex

**Related**: Adapter (changes interface), Proxy (different purpose), Composite (aggregates results)

---

## Facade

**Problem**: Working with complex subsystems requires extensive initialization, dependency tracking, and correct method execution order.

**When to Use**:
- Need a simple interface to a complex subsystem
- Subsystem is complex with many configuration details
- Want to layer a subsystem with entry points at each level

**Structure**:
- `Facade` - Provides simple interface to subsystem
- `Subsystem Classes` - Implement functionality, unaware of facade

**TypeScript Example**:
```typescript
// Complex subsystem classes
class CPU {
  freeze(): void {
    console.log('CPU: Freezing');
  }

  jump(position: number): void {
    console.log(`CPU: Jumping to ${position}`);
  }

  execute(): void {
    console.log('CPU: Executing');
  }
}

class Memory {
  load(position: number, data: string): void {
    console.log(`Memory: Loading "${data}" at ${position}`);
  }
}

class HardDrive {
  read(sector: number, size: number): string {
    console.log(`HardDrive: Reading ${size} bytes from sector ${sector}`);
    return 'boot data';
  }
}

// Facade
class ComputerFacade {
  private cpu: CPU;
  private memory: Memory;
  private hardDrive: HardDrive;

  constructor() {
    this.cpu = new CPU();
    this.memory = new Memory();
    this.hardDrive = new HardDrive();
  }

  start(): void {
    console.log('Starting computer...');
    this.cpu.freeze();
    const bootData = this.hardDrive.read(0, 1024);
    this.memory.load(0, bootData);
    this.cpu.jump(0);
    this.cpu.execute();
    console.log('Computer started!');
  }
}

// Usage - simple interface hides complexity
const computer = new ComputerFacade();
computer.start();
```

**Pros**:
- Isolates code from subsystem complexity
- Provides clean, simple interface

**Cons**:
- Can become a god object coupled to all classes

**Related**: Adapter (wraps single object), Abstract Factory (hides creation), Mediator (centralizes communication)

**Note**: Facade defines new interface; Adapter makes existing interfaces compatible.
