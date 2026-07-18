import { FocusTimerState, refreshFocusTimer } from './FocusTimerEngine';

export interface StoredFocusTimer {
  durationSeconds?: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
}

export function restoreFocusSession(session: StoredFocusTimer, now: number): FocusTimerState {
  const durationSeconds = Math.max(session.remainingSeconds, session.durationSeconds ?? 0);
  const storedTimer: FocusTimerState = {
    durationSeconds,
    remainingSeconds: session.remainingSeconds,
    targetEndTime: session.targetEndTime,
    isRunning: session.isRunning
  };
  return refreshFocusTimer(storedTimer, now);
}
