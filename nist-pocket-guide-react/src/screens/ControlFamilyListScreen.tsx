// src/screens/ControlFamilyListScreen.tsx

import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Control } from '../models/Control';
import { controlDataService } from '../services/ControlDataService';
import { ControlTile } from '../components/ControlTile';
import './ControlFamilyListScreen.css';

export const ControlFamilyListScreen: React.FC = () => {
  const navigate = useNavigate();
  const { familyId } = useParams<{ familyId: string }>();
  const [controls, setControls] = useState<Control[]>([]);
  const [familyTitle, setFamilyTitle] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadControls = async () => {
      if (!familyId) return;

      await controlDataService.loadCatalog();
      const familyControls = controlDataService.getControlsForFamily(familyId.toUpperCase());
      const titles = controlDataService.getFamilyTitles();
      
      setControls(familyControls);
      setFamilyTitle(titles[familyId.toUpperCase()] || familyId.toUpperCase());
      setIsLoading(false);
    };

    loadControls();
  }, [familyId]);

  if (isLoading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="family-list-screen">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate('/controls/families')}>
          <span className="material-icons">arrow_back</span>
        </button>
        <div className="app-bar-title">
          <h1>{familyId?.toUpperCase()}</h1>
          <p className="app-bar-subtitle">{familyTitle}</p>
        </div>
      </header>

      <div className="family-list-content">
        <div className="controls-stats">
          <span className="material-icons">info</span>
          <span>{controls.length} controls in this family</span>
        </div>

        <div className="controls-list">
          {controls.length > 0 ? (
            controls.map((control) => (
              <ControlTile key={control.id} control={control} />
            ))
          ) : (
            <div className="empty-state">
              <span className="material-icons">folder_open</span>
              <h3>No Controls Found</h3>
              <p>This family doesn't contain any controls yet.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
