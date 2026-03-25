---
title: Runtime Permissions — Check, Rationale, Request
impact: HIGH
tags: permissions, runtime, compose, security
---

## Runtime Permissions — Check, Rationale, Request

Always check before use, show rationale after denial, and request via the Activity Result API. Never cache permission state or use the deprecated `requestPermissions()` pattern.

### Check at Point of Use

Never assume a permission is granted — users can revoke in Settings at any time. Check immediately before accessing protected APIs.

**Incorrect:**

```kotlin
// Bad - no check, crashes with SecurityException if revoked
suspend fun getCurrentLocation(): Location {
    return fusedLocationClient.lastLocation.await()
}

// Bad - cached check goes stale
var hasPermission = false  // User can revoke anytime
```

**Correct:**

```kotlin
// Good - check at point of use, return Result
class LocationRepositoryImpl(
    private val fusedLocationClient: FusedLocationProviderClient,
    @ApplicationContext private val context: Context
) : LocationRepository {

    override suspend fun getCurrentLocation(): Result<Location> {
        if (ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return Result.failure(PermissionDeniedException("Location permission required"))
        }
        return runCatching { fusedLocationClient.lastLocation.await() }
    }
}

// Good - re-check on resume in Compose (user may return from Settings)
val lifecycleOwner = LocalLifecycleOwner.current
var permissionGranted by remember { mutableStateOf(false) }

DisposableEffect(lifecycleOwner) {
    val observer = LifecycleEventObserver { _, event ->
        if (event == Lifecycle.Event.ON_RESUME) {
            permissionGranted = ContextCompat.checkSelfPermission(
                context, Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        }
    }
    lifecycleOwner.lifecycle.addObserver(observer)
    onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
}
```

### Rationale and Request Flow

Check status → show rationale if previously denied → request. Handle "don't ask again" by guiding to Settings.

**Permission flow:**

1. `checkSelfPermission` → GRANTED → proceed
2. `shouldShowRequestPermissionRationale` → true → show explanation dialog → request
3. Otherwise → request directly (first time or "don't ask again" was set)

**Correct (full flow in Compose):**

```kotlin
@Composable
fun MicrophoneButton(onRecord: () -> Unit) {
    val context = LocalContext.current
    val activity = context.findActivity()
    var showRationale by remember { mutableStateOf(false) }

    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) onRecord()
    }

    Button(onClick = {
        when {
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.RECORD_AUDIO
            ) == PackageManager.PERMISSION_GRANTED -> onRecord()

            activity.shouldShowRequestPermissionRationale(
                Manifest.permission.RECORD_AUDIO
            ) -> showRationale = true

            else -> launcher.launch(Manifest.permission.RECORD_AUDIO)
        }
    }) { Text("Record") }

    if (showRationale) {
        AlertDialog(
            onDismissRequest = { showRationale = false },
            title = { Text("Microphone Access Needed") },
            text = { Text("Voice recording requires microphone access to capture audio.") },
            confirmButton = {
                TextButton(onClick = {
                    showRationale = false
                    launcher.launch(Manifest.permission.RECORD_AUDIO)
                }) { Text("Continue") }
            },
            dismissButton = {
                TextButton(onClick = { showRationale = false }) { Text("Not Now") }
            }
        )
    }
}
```

### Multiple Permissions and Accompanist

```kotlin
// Multiple permissions with Activity Result API
val launcher = rememberLauncherForActivityResult(
    ActivityResultContracts.RequestMultiplePermissions()
) { permissions ->
    val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
    val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
}

launcher.launch(arrayOf(
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION
))

// Accompanist for cleaner Compose API
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CameraScreen() {
    val cameraPermission = rememberPermissionState(Manifest.permission.CAMERA)

    when {
        cameraPermission.status.isGranted -> CameraPreview()
        cameraPermission.status.shouldShowRationale ->
            RationaleDialog(onConfirm = { cameraPermission.launchPermissionRequest() })
        else ->
            Button(onClick = { cameraPermission.launchPermissionRequest() }) {
                Text("Grant Camera Permission")
            }
    }
}
```

### Handling "Don't Ask Again"

When the user selects "don't ask again", `shouldShowRequestPermissionRationale` returns false and the system dialog won't appear. Guide them to app Settings instead.

```kotlin
if (!granted && !activity.shouldShowRequestPermissionRationale(permission)) {
    // Guide to app settings
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", context.packageName, null)
    }
    context.startActivity(intent)
}
```

**Why it matters:**
- Accessing a protected API without permission throws `SecurityException` and crashes the app
- Unexplained permission requests get denied — clear rationale increases grant rates significantly
- `requestPermissions()` / `onRequestPermissionsResult()` is deprecated and fragile
- Google Play policy requires permission justification for sensitive permissions

Reference: [Request runtime permissions](https://developer.android.com/training/permissions/requesting)
