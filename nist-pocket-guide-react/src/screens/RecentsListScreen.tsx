// src/screens/RecentsListScreen.tsx

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { recentsService } from '../services/RecentsService';
import { controlDataService } from '../services/ControlDataService';
import { Control } from '../models/Control';
import { ControlTile } from '../components/ControlTile';
import './RecentsListScreen.css';

export const RecentsListScreen: React.FC = () => {
  const navigate = useNavigate();
  const [recentControls, setRecentControls] = useState<Control[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRecents();
  }, []);

  const loadRecents = async () => {
    try {
      await recentsService.loadRecents();
      const recentIds = recentsService.getRecents();
      
      const controls = await Promise.all(
        recentIds.map(id => controlDataService.getControlById(id))
      );
      
      setRecentControls(controls.filter((c): c is Control => c !== null));
    } catch (error) {
      console.error('Error loading recents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleControlClick = (controlId: string) => {
    navigate(`/controls/detail/${controlId}`);
  };

  const handleClearRecents = async () => {
    if (window.confirm('Are you sure you want to clear your recent history?')) {
      await recentsService.clearRecents();
      setRecentControls([]);
    }
  };

  if (loading) {
    return (
      <div className="recents-screen">
        <div className="screen-header">
          <button className="back-button" onClick={() => navigate(-1)}>
            <span className="material-icons">arrow_back</span>
          </button>
          <h1>Recent Controls</h1>
        </div>
        <div className="loading">Loading recent controls...</div>
      </div>
    );
  }

  return (
    <div className="recents-screen">
      <div className="screen-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Recent Controls</h1>
        {recentControls.length > 0 && (
          <>
            <span className="count-badge">{recentControls.length}</span>
            <button className="clear-button" onClick={handleClearRecents}>
              <span className="material-icons">delete_outline</span>
              Clear
            </button>
          </>
        )}
      </div>

      {recentControls.length === 0 ? (
        <div className="empty-state">
          <span className="material-icons">history</span>
          <h2>No Recent Controls</h2>
          <p>Controls you view will appear here for quick access.</p>
        </div>
      ) : (
        <div className="recents-list">
          {recentControls.map((control, index) => (
            <div key={`${control.id}-${index}`} className="recent-item">
              <ControlTile
                control={control}
                onClick={() => handleControlClick(control.id)}
              />
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
