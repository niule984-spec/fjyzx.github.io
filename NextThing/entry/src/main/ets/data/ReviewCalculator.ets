import { FocusOutcome, TodayReview } from './PersistenceModels';

interface ReviewRecord {
  actualSeconds: number;
  outcome: FocusOutcome;
}

export function localDayKey(date: Date): string {
  const year = date.getFullYear().toString();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function calculateTodayReview(records: ReviewRecord[]): TodayReview {
  let actualSeconds = 0;
  let completedCount = 0;
  let unfinishedCount = 0;

  records.forEach((record) => {
    actualSeconds += record.actualSeconds;
    if (record.outcome === 'completed') {
      completedCount++;
    }
    if (record.outcome === 'unfinished' || record.outcome === 'changed') {
      unfinishedCount++;
    }
  });

  return {
    sessionCount: records.length,
    actualMinutes: Math.floor(actualSeconds / 60),
    completedCount,
    unfinishedCount
  };
}
