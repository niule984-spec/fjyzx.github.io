export type FocusOutcome = 'pending' | 'completed' | 'unfinished' | 'changed';

export type InboxSortMode = 'newest' | 'oldest' | 'title' | 'manual';

export interface InboxTask {
  id: number;
  title: string;
  createdAt: number;
  plannedMinutes: number;
  sortOrder: number;
}

export interface NextTask {
  title: string;
  plannedMinutes: number;
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
  resultKey: string;
}

export interface ActiveSession {
  taskName: string;
  durationMinutes: number;
  remainingSeconds: number;
  targetEndTime: number;
  isRunning: boolean;
  pageState: 'running' | 'paused' | 'result';
  pendingRecordId: number;
  resultKey: string;
}

export interface TodayReview {
  sessionCount: number;
  actualMinutes: number;
  completedCount: number;
  unfinishedCount: number;
}
