// src/screens/ControlDashboardScreen.tsx

import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { usePurchase } from '../contexts';
import { controlDataService } from '../services/ControlDataService';
import './ControlDashboardScreen.css';

interface NavOption {
  label: string;
  icon: string;
  color: string;
  route: string;
}

export const ControlDashboardScreen: React.FC = () => {
  const navigate = useNavigate();
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadData = async () => {
      await controlDataService.loadCatalog();
      setIsLoading(false);
    };
    loadData();
  }, []);

  const navOptions: NavOption[] = [
    {
      label: 'Controls by Family',
      icon: 'folder_special',
      color: '#2196F3',
      route: '/controls/families',
    },
    {
      label: 'Controls by Baseline',
      icon: 'security',
      color: '#4CAF50',
      route: '/controls/baselines',
    },
    {
      label: 'Controls by Implementation Level',
      icon: 'label_important',
      color: '#FF9800',
      route: '/controls/implementation-levels',
    },
    {
      label: 'All Controls List',
      icon: 'list_alt',
      color: '#9C27B0',
      route: '/controls/all',
    },
  ];

  if (isLoading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="control-dashboard">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate('/')}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Explore Controls</h1>
      </header>

      <div className="dashboard-content">
        <div className="dashboard-header">
          <h2 className="dashboard-title">Explore Controls</h2>
        </div>

        <div className="nav-options">
          {navOptions.map((option, index) => (
            <div
              key={index}
              className="nav-option-card"
              onClick={() => navigate(option.route)}
            >
              <div
                className="nav-option-icon"
                style={{ backgroundColor: `${option.color}26` }}
              >
                <span
                  className="material-icons"
                  style={{ color: option.color }}
                >
                  {option.icon}
                </span>
              </div>
              <div className="nav-option-content">
                <h3 className="nav-option-label">{option.label}</h3>
              </div>
              <span className="material-icons nav-option-arrow">
                arrow_forward_ios
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
