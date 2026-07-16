import { describe, expect, it } from '@ohos/hypium';
import { filterInboxTasks, sortInboxTasks, validatePlannedMinutes } from '../main/ets/inbox/TaskManagement';
import { InboxTask } from '../main/ets/data/PersistenceModels';

const tasks: InboxTask[] = [
  { id: 2, title: 'Reply mail', createdAt: 200, plannedMinutes: 10, sortOrder: 2 },
  { id: 1, title: 'Arrange files', createdAt: 100, plannedMinutes: 25, sortOrder: 1 }
];

export default function taskManagementTest() {
  describe('task management', () => {
    it('accepts positive custom minutes', 0, () => {
      expect(validatePlannedMinutes('30')).assertEqual(30);
    });
    it('rejects non-positive custom minutes', 0, () => {
      expect(validatePlannedMinutes('0')).assertEqual(undefined);
    });
    it('filters titles without case sensitivity', 0, () => {
      expect(filterInboxTasks(tasks, 'MAIL').length).assertEqual(1);
    });
    it('sorts tasks by title', 0, () => {
      expect(sortInboxTasks(tasks, 'title')[0].title).assertEqual('Arrange files');
    });
  });
}
