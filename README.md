# LearningDashboard

iOS learning dashboard with mock sign-in, a course list, lesson completion, and an on-device cache that survives restarts.

## Architecture

SwiftUI views stay passive. Each screen’s view model owns screen state and calls a repository. The repository is the only type that knows about both the API and local storage.

```
View → ViewModel → Repository → CourseAPI
                              → CourseLocalStore (SwiftData)
```

`Course` and `Lesson` are the shared models. Progress is derived from lesson completion (`completed / total`, `0` when a course has no lessons), so the dashboard and detail screen cannot drift.

The dashboard view model is the source of truth for the loaded courses. Course details reads that same object and toggles a lesson through `toggleLesson`. The list’s progress updates as soon as the model publishes the change.

## Offline strategy

`CourseRepository.fetchCourses()` always tries the API first and writes a successful response to the local store. If the API throws and the store already has courses, those cached courses are returned. If the API throws and the cache is empty, the original error is surfaced and the dashboard shows a retry state.

Lesson completion does not wait for the network. `saveCourses` writes the current list straight to the local store. The bundled `courses.json` file is a static catalog, so a later successful fetch would otherwise replace those flags. The repository copies completion state from the cache onto the freshly fetched catalog before saving.

There is no network-path monitor. The mock API reads local JSON, and failure is simulated by `CourseAPI` (`MockCourseAPI(forcedError:)` or a test double).

## Storage choice

SwiftData persists `CachedCourse` on disk (`isStoredInMemoryOnly: false`), so the cache is still there after a restart. Lessons are encoded as JSON on that record. That keeps the API `Course` model unchanged and avoids a second lesson schema for this assignment.

UserDefaults is a poor fit for a course catalog: it is not a database, it is easy to overwrite, and it is the wrong place for credentials.

## Security and tokens

Sign-in in this project is a mock. It checks email shape and password length, then waits briefly. It does not issue or store a token.

In a production app the access token and refresh token belong in the Keychain, not UserDefaults. The API client would attach the access token as a bearer header, refresh it when the server returns 401, and delete both items on logout. Keychain items should be accessible only after the device is unlocked (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` is a typical choice).

## Scaling to 1M users and hundreds of courses

One million users is mostly a backend problem: stateless API instances, a catalog cached at the edge, and progress stored per user so writes do not contend on one row. The client should not download every course and every lesson on launch.

For a learner with hundreds of courses:

- The dashboard requests a paged summary (title, instructor, progress, lesson count), not full lesson lists.
- Course details loads lessons for the opened course only.
- Images and large content come from a CDN.
- Progress changes are saved locally immediately, then uploaded as a small sync queue when the network is available. The server timestamp wins if the same lesson was completed on another device.
- The phone caches the signed-in learner’s enrolled courses, not the global catalog.

SwiftData stays the on-device store. Background delivery and conflict handling move to the repository; the views do not change.

## Testing strategy

Unit tests use Swift Testing and in-memory doubles for `CourseAPI` and `CourseLocalStore`. They do not open SwiftData.

Covered behavior:

- Progress: 2/4 lessons is 50, 5/5 is 100, no lessons is 0.
- Repository: a successful fetch is cached, a failed fetch returns the cache, a failed fetch with an empty cache throws.
- A later successful fetch keeps locally saved completion.
- Toggling a lesson persists without another API call, and a failed save leaves the previous value on screen.

## Screenshots
<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/74b39d51-3fda-4f69-b0a8-d08f598216b8" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/7b5eb688-fb9a-4738-a8a65-78ab0522c548" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/4e26d67d-ff31-4b43-bbac-677cf9118aee" width="200"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/48a47015-709e-438d-aff7-4652cba33154" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/55548546-5991-40c7-b99f-1ad1745bd926" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/55f71ba6-e777-4138-97d0-b85aa2b0e4e2" width="200"/></td>
  </tr>
</table>

## Video Reference


https://github.com/user-attachments/assets/30bcaa7f-3bcb-4c24-b610-e45b2f52928f







