// src/screens/NotesListScreen.tsx

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { notesService } from '../services/NotesService';
import { controlDataService } from '../services/ControlDataService';
import { Control } from '../models/Control';
import { ControlTile } from '../components/ControlTile';
import './NotesListScreen.css';

export const NotesListScreen: React.FC = () => {
  const navigate = useNavigate();
  const [controlsWithNotes, setControlsWithNotes] = useState<Control[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadNotes();
  }, []);

  const loadNotes = async () => {
    try {
      await notesService.loadNotes();
      const notesData = notesService.getControlsWithNotes();
      
      const controls = await Promise.all(
        notesData.map(({ controlId }) => controlDataService.getControlById(controlId))
      );
      
      setControlsWithNotes(controls.filter((c): c is Control => c !== null));
    } catch (error) {
      console.error('Error loading notes:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleControlClick = (controlId: string) => {
    navigate(`/controls/detail/${controlId}`);
  };

  if (loading) {
    return (
      <div className="notes-screen">
        <div className="screen-header">
          <button className="back-button" onClick={() => navigate(-1)}>
            <span className="material-icons">arrow_back</span>
          </button>
          <h1>Notes</h1>
        </div>
        <div className="loading">Loading notes...</div>
      </div>
    );
  }

  return (
    <div className="notes-screen">
      <div className="screen-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Notes</h1>
        <span className="count-badge">{controlsWithNotes.length}</span>
      </div>

      {controlsWithNotes.length === 0 ? (
        <div className="empty-state">
          <span className="material-icons">note</span>
          <h2>No Notes Yet</h2>
          <p>Add notes to controls to keep track of implementation details and reminders.</p>
        </div>
      ) : (
        <div className="notes-list">
          {controlsWithNotes.map(control => {
            const note = notesService.getNote(control.id);
            return (
              <div key={control.id} className="note-item">
                <ControlTile
                  control={control}
                  onClick={() => handleControlClick(control.id)}
                />
                {note && (
                  <div className="note-preview">
                    <span className="material-icons">note</span>
                    <p>{note.length > 150 ? `${note.substring(0, 150)}...` : note}</p>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
