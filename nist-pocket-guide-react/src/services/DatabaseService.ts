// src/services/DatabaseService.ts

import Dexie, { Table } from 'dexie';
import { InformationSystem } from '../models/InformationSystem';

export interface UserPreference {
  key: string;
  value: any;
}

export interface OnboardingData {
  welcomeSeen: boolean;
  lastOnboardingVersion: string;
}

/**
 * Database service using Dexie (IndexedDB wrapper)
 * Replaces Flutter's sqflite with browser-based storage
 */
export class DatabaseService extends Dexie {
  informationSystems!: Table<InformationSystem, string>;
  preferences!: Table<UserPreference, string>;
  onboarding!: Table<OnboardingData, number>;

  constructor() {
    super('NISTDatabase');
    
    this.version(1).stores({
      informationSystems: 'id, name, createdAt, updatedAt',
      preferences: 'key',
      onboarding: '++id',
    });
  }

  // Information System Methods
  async getAllInformationSystems(): Promise<InformationSystem[]> {
    return await this.informationSystems.toArray();
  }

  async getInformationSystemById(id: string): Promise<InformationSystem | undefined> {
    return await this.informationSystems.get(id);
  }

  async createInformationSystem(system: InformationSystem): Promise<string> {
    await this.informationSystems.add(system);
    return system.id;
  }

  async updateInformationSystem(system: InformationSystem): Promise<void> {
    await this.informationSystems.put(system);
  }

  async deleteInformationSystem(id: string): Promise<void> {
    await this.informationSystems.delete(id);
  }

  // Preferences Methods
  async getPreference<T = any>(key: string, defaultValue: T): Promise<T> {
    const pref = await this.preferences.get(key);
    return pref ? (pref.value as T) : defaultValue;
  }

  async setPreference(key: string, value: any): Promise<void> {
    await this.preferences.put({ key, value });
  }

  async deletePreference(key: string): Promise<void> {
    await this.preferences.delete(key);
  }

  // Onboarding Methods
  async isWelcomeSeen(): Promise<boolean> {
    const data = await this.onboarding.get(1);
    return data?.welcomeSeen ?? false;
  }

  async setWelcomeSeen(): Promise<void> {
    await this.onboarding.put({ welcomeSeen: true, lastOnboardingVersion: '1.0.0' }, 1);
  }
}

export const db = new DatabaseService();
