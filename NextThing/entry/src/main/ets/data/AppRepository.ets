import { common } from '@kit.AbilityKit';
import { NextThingRepository } from './NextThingRepository';

export const appRepository = new NextThingRepository();

export async function initializeRepository(context: common.Context): Promise<void> {
  await appRepository.initialize(context);
}
