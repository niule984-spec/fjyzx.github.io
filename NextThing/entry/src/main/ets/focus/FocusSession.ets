import { createFocusTimer, FocusTimerState, refreshFocusTimer } from './FocusTimerEngine';

export type FocusPageState = 'running' | 'result';

export interface FocusSession {
  taskName: string;
  durationMinutes: number;
  timer: FocusTimerState;
  pageState: FocusPageState;
}

export function createFocusSession(taskName: string, durationMinutes: number, now: number): FocusSession {
  return {
    taskName,
    durationMinutes,
    timer: createFocusTimer(durationMinutes, now),
    pageState: 'running'
  };
}

export function restoreFocusSession(session: FocusSession, now: number): FocusSession {
  const timer = session.pageState === 'running'
    ? refreshFocusTimer(session.timer, now)
    : session.timer;
  return {
    taskName: session.taskName,
    durationMinutes: session.durationMinutes,
    timer,
    pageState: session.pageState === 'result' || timer.remainingSeconds === 0 ? 'result' : 'running'
  };
}

export function decodeFocusSession(raw: string): FocusSession | null {
  try {
    const value = JSON.parse(raw) as FocusSession;
    if (
      typeof value.taskName !== 'string' || value.taskName.trim().length === 0 ||
      !Number.isInteger(value.durationMinutes) || value.durationMinutes <= 0 ||
      typeof value.timer !== 'object' || value.timer === null ||
      !Number.isInteger(value.timer.durationSeconds) || value.timer.durationSeconds <= 0 ||
      !Number.isInteger(value.timer.remainingSeconds) || value.timer.remainingSeconds < 0 ||
      value.timer.remainingSeconds > value.timer.durationSeconds ||
      typeof value.timer.targetEndTime !== 'number' || value.timer.targetEndTime < 0 ||
      typeof value.timer.isRunning !== 'boolean' ||
      (value.pageState !== 'running' && value.pageState !== 'result')
    ) {
      return null;
    }
    return value;
  } catch (_) {
    return null;
  }
}
