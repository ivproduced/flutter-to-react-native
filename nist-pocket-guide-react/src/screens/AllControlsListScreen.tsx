// src/screens/AllControlsListScreen.tsx

import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Control } from '../models/Control';
import { controlDataService } from '../services/ControlDataService';
import { ControlTile } from '../components/ControlTile';
import './AllControlsListScreen.css';

export const AllControlsListScreen: React.FC = () => {
  const navigate = useNavigate();
  const [controls, setControls] = useState<Control[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadControls = async () => {
      await controlDataService.loadCatalog();
      const allControls = controlDataService.getAllControls();
      setControls(allControls);
      setIsLoading(false);
    };

    loadControls();
  }, []);

  if (isLoading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="all-controls-screen">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate('/dashboard')}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>All Controls</h1>
      </header>

      <div className="all-controls-content">
        <div className="controls-stats">
          <span className="material-icons">list_alt</span>
          <span>{controls.length} total controls</span>
        </div>

        <div className="controls-list">
          {controls.map((control) => (
            <ControlTile key={control.id} control={control} />
          ))}
        </div>
      </div>
    </div>
  );
};
