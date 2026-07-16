export function shouldPersistActiveSession(isFinished: boolean): boolean {
  return !isFinished;
}

export function canFinishResult(pendingRecordId: number, isFinishing: boolean): boolean {
  return pendingRecordId !== 0 && !isFinishing;
}
