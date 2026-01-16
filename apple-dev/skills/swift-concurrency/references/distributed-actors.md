# Distributed Actors

Actors that work across process boundaries for distributed computing.

## Overview

Distributed actors extend the actor model to work across processes and machines. They provide the same data isolation guarantees as regular actors, but with serialization and networking handled automatically.

**Key concept**: Distributed actors enforce safe data isolation across process boundaries, making distributed systems feel like local Swift code.

## When to Use Distributed Actors

| Use Case | Appropriate |
|----------|-------------|
| Multiplayer games (peer-to-peer) | Yes |
| Distributed compute across machines | Yes |
| Microservices in Swift | Yes |
| Cross-device synchronization | Yes |
| Single-process app | No (use regular actors) |

## Basic Syntax

```swift
import Distributed

distributed actor GamePlayer {
    typealias ActorSystem = LocalTestingDistributedActorSystem

    var score: Int = 0

    distributed func makeMove(_ move: Move) async throws -> MoveResult {
        // Process move
        return .success
    }

    distributed func getScore() -> Int {
        return score
    }
}
```

### Key Differences from Regular Actors

| Feature | Regular Actor | Distributed Actor |
|---------|---------------|-------------------|
| Keyword | `actor` | `distributed actor` |
| Method access | `await actor.method()` | `try await actor.method()` |
| Can throw | Optional | Always (network can fail) |
| Requires ActorSystem | No | Yes |
| Cross-process | No | Yes |

## Actor Systems

Distributed actors require an `ActorSystem` that handles:
- Serialization of messages
- Network transport
- Actor lifecycle management

### Standard Library System

For testing and local development:

```swift
import Distributed

distributed actor MyActor {
    typealias ActorSystem = LocalTestingDistributedActorSystem
}
```

### Cluster System (Server-Side)

For production distributed systems, use [swift-distributed-actors](https://github.com/apple/swift-distributed-actors):

```swift
import DistributedCluster

distributed actor Worker {
    typealias ActorSystem = ClusterSystem

    distributed func process(_ data: Data) async throws -> Result {
        // Process work
    }
}
```

## Serialization Requirements

All parameters and return values must be `Codable`:

```swift
struct Move: Codable, Sendable {
    let position: Position
    let player: PlayerID
}

distributed actor GamePlayer {
    // Parameters and return types must be Codable
    distributed func makeMove(_ move: Move) async throws -> MoveResult {
        // ...
    }
}
```

## Example: Multiplayer Game

Apple's sample project [TicTacFish](https://developer.apple.com/documentation/swift/tictacfish_implementing_a_game_using_distributed_actors) demonstrates distributed actors:

```swift
distributed actor GameSession {
    typealias ActorSystem = SampleWebSocketActorSystem

    var players: [Player] = []
    var board: GameBoard = .empty

    distributed func join(_ player: Player) async throws {
        guard players.count < 2 else {
            throw GameError.sessionFull
        }
        players.append(player)
    }

    distributed func makeMove(player: Player, position: Position) async throws -> GameState {
        guard isPlayerTurn(player) else {
            throw GameError.notYourTurn
        }
        board.place(player.mark, at: position)
        return evaluateGameState()
    }
}
```

## Error Handling

Distributed actor calls can fail due to network issues:

```swift
do {
    let result = try await remotePlayer.makeMove(move)
    handleResult(result)
} catch let error as DistributedActorError {
    // Handle distributed system errors
    switch error {
    case .actorNotFound:
        handleDisconnectedPlayer()
    case .serializationFailed:
        logError(error)
    default:
        retryOrFail()
    }
} catch {
    // Handle application errors
    handleGameError(error)
}
```

## Location Transparency

One of the key benefits: code doesn't need to know if an actor is local or remote:

```swift
func playGame(with opponent: GamePlayer) async throws {
    // Works identically whether opponent is local or remote
    let result = try await opponent.makeMove(myMove)
    updateUI(with: result)
}
```

## Best Practices

1. **Design for failure** - Network calls can fail; handle errors gracefully
2. **Keep messages small** - Minimize serialization overhead
3. **Use Codable types** - All distributed method parameters must be Codable
4. **Test locally first** - Use `LocalTestingDistributedActorSystem` before deploying
5. **Consider latency** - Remote calls have network overhead

## Installation

**Standard library** (local testing):
```swift
// Built into Swift 5.7+
import Distributed
```

**Cluster system** (production):
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-distributed-actors", from: "1.0.0")
]
```

## Limitations

- Requires Swift 5.7+
- Actor system configuration can be complex
- Debugging distributed systems is harder than local code
- Not suitable for simple single-process apps

## Further Reading

- [Swift Evolution: Distributed Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0336-distributed-actor-isolation.md)
- [TicTacFish Sample Project](https://developer.apple.com/documentation/swift/tictacfish_implementing_a_game_using_distributed_actors)
- [swift-distributed-actors Package](https://github.com/apple/swift-distributed-actors)
- [WWDC 2022: Meet Distributed Actors](https://developer.apple.com/videos/play/wwdc2022/110356/)
