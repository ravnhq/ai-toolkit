---
title: Room Database — Entities, Flow Queries, Migrations
impact: HIGH
tags: room, database, entities, flow, suspend, migration
---

## Room Database — Entities, Flow Queries, Migrations

Design entities with non-null defaults, choose `Flow` for reactive reads or `suspend` for one-shot reads, and always use versioned migrations in production.

### Entity Design

Use non-null Kotlin types with sensible defaults. Avoid nullable fields when a default value is appropriate, and use proper column types.

**Incorrect:**

```kotlin
// Bad - nullable fields that should have defaults
@Entity(tableName = "tasks")
data class TaskEntity(
    @PrimaryKey val id: String?,          // Primary key is nullable!
    val title: String?,                    // Should never be null
    val description: String?,              // Could default to ""
    val isCompleted: Boolean?,             // Should default to false
    val createdAt: Long?,                  // Should never be null
    val priority: String?                  // Untyped — "HIGH"? "high"? "1"?
)
```

**Correct:**

```kotlin
// Good - non-null with defaults, typed columns
@Entity(tableName = "tasks")
data class TaskEntity(
    @PrimaryKey
    val id: String,
    val title: String,
    val description: String = "",
    val isCompleted: Boolean = false,
    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis(),
    val priority: Int = Priority.MEDIUM   // Int enum, not free-form String
) {
    companion object {
        object Priority {
            const val LOW = 0
            const val MEDIUM = 1
            const val HIGH = 2
        }
    }
}

// Good - TypeConverter for complex types
class Converters {
    @TypeConverter
    fun fromInstant(value: Long?): Instant? = value?.let { Instant.fromEpochMilliseconds(it) }

    @TypeConverter
    fun toEpochMilli(instant: Instant?): Long? = instant?.toEpochMilliseconds()
}
```

### DAO Query Return Types — Flow vs Suspend

Use `Flow<T>` for reads the UI observes reactively. Use `suspend` for one-shot reads and all write operations — both are valid.

**Incorrect — using suspend reads to drive reactive UI:**

```kotlin
// Bad - suspend for a query the UI needs to stay in sync with
@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks WHERE is_completed = 0")
    suspend fun getActiveTasks(): List<TaskEntity>  // Stale after any write
}

// Bad - manual re-fetch loop to compensate for non-reactive query
class TaskViewModel(private val dao: TaskDao) : ViewModel() {
    private val _tasks = MutableStateFlow<List<Task>>(emptyList())

    fun loadTasks() {
        viewModelScope.launch {
            _tasks.value = dao.getActiveTasks()  // Must call again after every write
        }
    }

    fun completeTask(id: String) {
        viewModelScope.launch {
            dao.markCompleted(id)
            loadTasks()  // Easy to forget this re-fetch!
        }
    }
}
```

**Correct — Flow for reactive UI, suspend for one-shot reads and writes:**

```kotlin
@Dao
interface TaskDao {
    // Reactive — UI stays in sync automatically
    @Query("SELECT * FROM tasks WHERE is_completed = 0")
    fun observeActiveTasks(): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE id = :id")
    fun observeTask(id: String): Flow<TaskEntity?>

    // One-shot suspend reads — valid for non-reactive use cases
    @Query("SELECT * FROM tasks WHERE id = :id")
    suspend fun getTaskById(id: String): TaskEntity?

    @Query("SELECT COUNT(*) FROM tasks WHERE is_completed = 0")
    suspend fun countActiveTasks(): Int

    @Query("SELECT EXISTS(SELECT 1 FROM tasks WHERE id = :id)")
    suspend fun exists(id: String): Boolean

    // Writes are always suspend
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(task: TaskEntity)

    @Query("UPDATE tasks SET is_completed = 1 WHERE id = :id")
    suspend fun markCompleted(id: String)
}

// Repository wraps DAO, ViewModel depends on Repository interface
interface TaskRepository {
    fun observeActiveTasks(): Flow<List<Task>>
    suspend fun getTask(id: String): Task?
    suspend fun completeTask(id: String)
}

class TaskRepositoryImpl(
    private val taskDao: TaskDao
) : TaskRepository {
    override fun observeActiveTasks(): Flow<List<Task>> =
        taskDao.observeActiveTasks().map { entities -> entities.map { it.toDomain() } }

    override suspend fun getTask(id: String): Task? =
        taskDao.getTaskById(id)?.toDomain()

    override suspend fun completeTask(id: String) {
        taskDao.markCompleted(id)
    }
}

// ViewModel — Flow for observed state, suspend for actions
class TaskViewModel(
    private val taskRepository: TaskRepository
) : ViewModel() {
    val tasks: StateFlow<List<Task>> = taskRepository.observeActiveTasks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun completeTask(id: String) {
        viewModelScope.launch {
            taskRepository.completeTask(id)
            // No manual refresh needed — Flow re-emits automatically
        }
    }
}
```

**When to use suspend vs Flow:**
- **`Flow<T>`** — read queries the UI observes and should auto-update (lists, detail screens)
- **`suspend`** — write operations, plus one-shot reads like:
  - Checking existence before insert (`exists()`)
  - Loading data for WorkManager, export, or share
  - Pre-populating a form on first navigation
  - Fetching a count or aggregate for a one-time decision

### Versioned Migrations

Always provide explicit `Migration` objects when changing your Room schema. Never use `fallbackToDestructiveMigration()` in production — it deletes all user data.

**Incorrect:**

```kotlin
// Bad - destroys all data on schema change
val db = Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .fallbackToDestructiveMigration()  // Wipes everything!
    .build()
```

**Correct:**

```kotlin
// Good - explicit migration preserving data
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 1")
    }
}

val MIGRATION_2_3 = object : Migration(2, 3) {
    override fun migrate(db: SupportSQLiteDatabase) {
        // Create new table with correct schema
        db.execSQL("""
            CREATE TABLE tasks_new (
                id TEXT NOT NULL PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                is_completed INTEGER NOT NULL DEFAULT 0,
                priority INTEGER NOT NULL DEFAULT 1
            )
        """)
        // Copy data
        db.execSQL("""
            INSERT INTO tasks_new (id, title, description, is_completed, priority)
            SELECT id, title, COALESCE(description, ''), is_completed, priority
            FROM tasks
        """)
        // Swap tables
        db.execSQL("DROP TABLE tasks")
        db.execSQL("ALTER TABLE tasks_new RENAME TO tasks")
    }
}

val db = Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)
    .build()
```

**Testing migrations:**

```kotlin
@RunWith(AndroidJUnit4::class)
class MigrationTest {
    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        AppDatabase::class.java
    )

    @Test
    fun migrate1To2() {
        helper.createDatabase("test-db", 1).apply {
            execSQL("INSERT INTO tasks (id, title) VALUES ('1', 'Test')")
            close()
        }
        helper.runMigrationsAndValidate("test-db", 2, true, MIGRATION_1_2)
    }
}
```

**Why it matters:**
- Nullable primary keys cause crashes on insert; null checks propagate unnecessarily
- Room's Flow integration re-queries automatically — eliminates stale data bugs
- `fallbackToDestructiveMigration` silently deletes all user data
- Explicit migrations are auditable, testable, and preserve user content

Reference: [Room entities](https://developer.android.com/training/data-storage/room/defining-data) | [Async DAO queries](https://developer.android.com/training/data-storage/room/async-queries) | [Room migrations](https://developer.android.com/training/data-storage/room/migrating-db-versions)
