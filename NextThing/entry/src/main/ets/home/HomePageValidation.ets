export interface TaskValidationResult {
  isValid: boolean;
  taskTitle: string;
}

export function validateTaskTitle(taskTitle: string): TaskValidationResult {
  const normalizedTitle = taskTitle.trim();
  return {
    isValid: normalizedTitle.length > 0,
    taskTitle: normalizedTitle
  };
}
