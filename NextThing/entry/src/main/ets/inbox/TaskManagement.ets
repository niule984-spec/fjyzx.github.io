import { InboxSortMode, InboxTask } from '../data/PersistenceModels';

export function validatePlannedMinutes(value: string): number | undefined {
  if (!/^[1-9][0-9]*$/.test(value)) {
    return undefined;
  }
  const minutes = Number(value);
  if (!Number.isFinite(minutes) || Math.floor(minutes) !== minutes || minutes <= 0) {
    return undefined;
  }
  return minutes;
}

export function filterInboxTasks(tasks: InboxTask[], query: string): InboxTask[] {
  const normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.length === 0) {
    return tasks.slice();
  }
  return tasks.filter((task: InboxTask) => task.title.toLowerCase().includes(normalizedQuery));
}

export function sortInboxTasks(tasks: InboxTask[], mode: InboxSortMode): InboxTask[] {
  const sorted = tasks.slice();
  if (mode === 'oldest') {
    return sorted.sort((left, right) => left.createdAt - right.createdAt || left.id - right.id);
  }
  if (mode === 'title') {
    return sorted.sort((left, right) => left.title.localeCompare(right.title) || left.id - right.id);
  }
  if (mode === 'manual') {
    return sorted.sort((left, right) => left.sortOrder - right.sortOrder || left.id - right.id);
  }
  return sorted.sort((left, right) => right.createdAt - left.createdAt || right.id - left.id);
}
