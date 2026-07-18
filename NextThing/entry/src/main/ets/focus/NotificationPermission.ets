export async function ensureNotificationPermission(
  isEnabled: () => boolean,
  requestEnable: () => Promise<void>
): Promise<boolean> {
  if (isEnabled()) return true;

  try {
    await requestEnable();
    return isEnabled();
  } catch (_) {
    return false;
  }
}
