import { getApps, initializeApp } from "firebase-admin/app";

// Tests run against the Firestore emulator, launched via
// `firebase emulators:exec --only firestore "vitest run"` (see package.json
// `test` script). Never points at a real project.
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.GCLOUD_PROJECT ??= "autestme-test";

if (getApps().length === 0) {
  initializeApp({ projectId: "autestme-test" });
}
