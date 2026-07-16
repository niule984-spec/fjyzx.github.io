import { ActiveSession } from '../data/PersistenceModels';

export function needsPendingRecord(session: ActiveSession): boolean {
  return session.pageState === 'result' && session.pendingRecordId === 0;
}
