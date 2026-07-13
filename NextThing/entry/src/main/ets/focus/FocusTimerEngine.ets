export interface FocusTimerState {
  durationSeconds: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
}

export function createFocusTimer(durationMinutes: number, now: number): FocusTimerState {
  const durationSeconds = Math.max(0, Math.floor(durationMinutes * 60));
  return {
    durationSeconds,
    remainingSeconds: durationSeconds,
    targetEndTime: now + durationSeconds * 1_000,
    isRunning: durationSeconds > 0
  };
}

export function refreshFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  if (!timer.isRunning) {
    return timer;
  }

  const remainingSeconds = Math.max(0, Math.floor((timer.targetEndTime - now) / 1_000));
  return {
    durationSeconds: timer.durationSeconds,
    remainingSeconds,
    targetEndTime: remainingSeconds === 0 ? 0 : timer.targetEndTime,
    isRunning: remainingSeconds > 0
  };
}

export function pauseFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  const refreshed = refreshFocusTimer(timer, now);
  return {
    durationSeconds: refreshed.durationSeconds,
    remainingSeconds: refreshed.remainingSeconds,
    targetEndTime: 0,
    isRunning: false
  };
}

export function resumeFocusTimer(timer: FocusTimerState, now: number): FocusTimerState {
  if (timer.remainingSeconds === 0) {
    return timer;
  }

  return {
    durationSeconds: timer.durationSeconds,
    remainingSeconds: timer.remainingSeconds,
    targetEndTime: now + timer.remainingSeconds * 1_000,
    isRunning: true
  };
}

export function formatRemainingTime(remainingSeconds: number): string {
  const safeSeconds = Math.max(0, Math.floor(remainingSeconds));
  const minutes = Math.floor(safeSeconds / 60).toString().padStart(2, '0');
  const seconds = (safeSeconds % 60).toString().padStart(2, '0');
  return `${minutes}:${seconds}`;
}
