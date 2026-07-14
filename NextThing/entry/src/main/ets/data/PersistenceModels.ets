export type FocusOutcome = 'pending' | 'completed' | 'unfinished' | 'changed';

export interface InboxTask {
  id: number;
  title: string;
  createdAt: number;
}

export interface FocusRecord {
  id: number;
  taskTitle: string;
  plannedMinutes: number;
  actualSeconds: number;
  endedAt: number;
  outcome: FocusOutcome;
}

export interface PendingFocusRecord {
  taskTitle: string;
  plannedMinutes: number;
  actualSeconds: number;
  endedAt: number;
  outcome: FocusOutcome;
}

export interface ActiveSession {
  taskName: string;
  durationMinutes: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
  pageState: 'running' | 'paused' | 'result';
  pendingRecordId: number;
}

export interface TodayReview {
  sessionCount: number;
  actualMinutes: number;
  completedCount: number;
  unfinishedCount: number;
}
