// src/services/FavoritesService.ts

import { db } from './DatabaseService';

class FavoritesService {
  private favorites: Set<string> = new Set();

  async loadFavorites(): Promise<void> {
    const favs = await db.getPreference<string[]>('favorites', []);
    this.favorites = new Set(favs);
  }

  async addFavorite(controlId: string): Promise<void> {
    this.favorites.add(controlId.toLowerCase());
    await this.saveFavorites();
  }

  async removeFavorite(controlId: string): Promise<void> {
    this.favorites.delete(controlId.toLowerCase());
    await this.saveFavorites();
  }

  async toggleFavorite(controlId: string): Promise<boolean> {
    const normalized = controlId.toLowerCase();
    if (this.favorites.has(normalized)) {
      await this.removeFavorite(normalized);
      return false;
    } else {
      await this.addFavorite(normalized);
      return true;
    }
  }

  isFavorite(controlId: string): boolean {
    return this.favorites.has(controlId.toLowerCase());
  }

  getFavorites(): string[] {
    return Array.from(this.favorites);
  }

  private async saveFavorites(): Promise<void> {
    await db.setPreference('favorites', Array.from(this.favorites));
  }
}

export const favoritesService = new FavoritesService();
