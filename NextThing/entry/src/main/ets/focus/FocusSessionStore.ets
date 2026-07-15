import preferences from '@ohos.data.preferences';
import { decodeFocusSession, encodeFocusSession, FocusSession } from './FocusSession';

const ACTIVE_SESSION_KEY = 'active_focus_session';

export class FocusSessionStore {
  constructor(private readonly preferences: preferences.Preferences) {}

  load(): FocusSession | null {
    try {
      const raw = this.preferences.getSync(ACTIVE_SESSION_KEY, '');
      if (typeof raw !== 'string' || raw.length === 0) {
        return null;
      }

      const session = decodeFocusSession(raw);
      if (session === null) {
        this.clear();
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  save(session: FocusSession): boolean {
    try {
      this.preferences.putSync(ACTIVE_SESSION_KEY, encodeFocusSession(session));
      this.preferences.flushSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  clear(): boolean {
    try {
      this.preferences.deleteSync(ACTIVE_SESSION_KEY);
      this.preferences.flushSync();
      return true;
    } catch (_) {
      return false;
    }
  }
}
