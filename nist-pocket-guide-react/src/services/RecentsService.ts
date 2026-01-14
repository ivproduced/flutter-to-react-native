// src/services/RecentsService.ts

import { db } from './DatabaseService';

const MAX_RECENTS = 50;

class RecentsService {
  private recents: string[] = [];

  async loadRecents(): Promise<void> {
    this.recents = await db.getPreference<string[]>('recent_controls', []);
  }

  async addRecent(controlId: string): Promise<void> {
    const normalized = controlId.toLowerCase();
    
    // Remove if already exists
    this.recents = this.recents.filter(id => id !== normalized);
    
    // Add to front
    this.recents.unshift(normalized);
    
    // Keep only latest MAX_RECENTS
    if (this.recents.length > MAX_RECENTS) {
      this.recents = this.recents.slice(0, MAX_RECENTS);
    }
    
    await this.persistRecents();
  }

  getRecents(): string[] {
    return [...this.recents];
  }

  async clearRecents(): Promise<void> {
    this.recents = [];
    await this.persistRecents();
  }

  private async persistRecents(): Promise<void> {
    await db.setPreference('recent_controls', this.recents);
  }
}

export const recentsService = new RecentsService();
