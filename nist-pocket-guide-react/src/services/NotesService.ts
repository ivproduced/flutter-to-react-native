// src/services/NotesService.ts

import { db } from './DatabaseService';

class NotesService {
  private notes: Map<string, string> = new Map();

  async loadNotes(): Promise<void> {
    const notesObj = await db.getPreference<Record<string, string>>('control_notes', {});
    this.notes = new Map(Object.entries(notesObj));
  }

  getNote(controlId: string): string {
    const normalized = controlId.toLowerCase();
    return this.notes.get(normalized) || '';
  }

  async saveNote(controlId: string, note: string): Promise<void> {
    const normalized = controlId.toLowerCase();
    if (note.trim()) {
      this.notes.set(normalized, note);
    } else {
      this.notes.delete(normalized);
    }
    await this.persistNotes();
  }

  async deleteNote(controlId: string): Promise<void> {
    this.notes.delete(controlId.toLowerCase());
    await this.persistNotes();
  }

  getControlsWithNotes(): Array<{ controlId: string; note: string }> {
    return Array.from(this.notes.entries()).map(([controlId, note]) => ({
      controlId,
      note,
    }));
  }

  private async persistNotes(): Promise<void> {
    const notesObj = Object.fromEntries(this.notes);
    await db.setPreference('control_notes', notesObj);
  }
}

export const notesService = new NotesService();
