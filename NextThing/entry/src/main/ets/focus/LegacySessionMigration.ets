import { ActiveSession } from '../data/PersistenceModels';
import { FocusSession } from './FocusSession';

export function toActiveSession(session: FocusSession): ActiveSession {
  return {
    taskName: session.taskName,
    durationMinutes: session.durationMinutes,
    remainingSeconds: session.timer.remainingSeconds,
    targetEndTime: session.timer.targetEndTime,
    isRunning: session.timer.isRunning,
    pageState: session.pageState === 'result' ? 'result' : (session.timer.isRunning ? 'running' : 'paused'),
    pendingRecordId: 0,
    resultKey: ''
  };
}
