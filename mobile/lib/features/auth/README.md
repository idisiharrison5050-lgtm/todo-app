# Authentication

The mobile client uses a local-first session boundary. Access tokens returned by login or registration are stored through `TokenStorage`, which is backed by platform secure storage. The application shell restores the session before showing the task workspace.

The task database remains local and independent of authentication so existing offline task behavior is preserved while the cloud-sync layer is developed separately.
