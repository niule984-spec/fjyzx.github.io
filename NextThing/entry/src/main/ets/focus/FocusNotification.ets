import { FocusSession } from './FocusSession';
import { formatRemainingTime } from './FocusTimerEngine';

export const FOCUS_NOTIFICATION_ID = 1001;

export interface FocusNotificationPresentation {
  title: string;
  text: string;
  isCountDown: boolean;
}

function formatEndTime(timestamp: number): string {
  const date = new Date(timestamp);
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${hours}:${minutes}`;
}

export function createFocusNotificationPresentation(session: FocusSession): FocusNotificationPresentation | null {
  if (session.pageState === 'result') {
    return null;
  }

  if (session.timer.isRunning) {
    return {
      title: '正在专注',
      text: `${session.taskName} · 专注至 ${formatEndTime(session.timer.targetEndTime)}`,
      isCountDown: true
    };
  }

  return {
    title: '专注已暂停',
    text: `${session.taskName} · 剩余 ${formatRemainingTime(session.timer.remainingSeconds)}`,
    isCountDown: false
  };
}
