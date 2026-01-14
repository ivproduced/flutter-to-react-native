// src/components/BottomNavBar.tsx

import React from 'react';
import { useNavigate } from 'react-router-dom';
import './BottomNavBar.css';

interface BottomNavBarProps {
  currentRoute?: string;
}

export const BottomNavBar: React.FC<BottomNavBarProps> = ({ currentRoute }) => {
  const navigate = useNavigate();

  return (
    <div className="bottom-nav-bar">
      <button
        className="nav-item"
        onClick={() => navigate('/controls/favorites')}
      >
        <span className="material-icons">star</span>
        <span className="nav-label">Favorites</span>
      </button>
      
      <button
        className="nav-item"
        onClick={() => navigate('/controls/notes')}
      >
        <span className="material-icons">note</span>
        <span className="nav-label">Notes</span>
      </button>
      
      <button
        className="nav-item"
        onClick={() => navigate('/controls/recent')}
      >
        <span className="material-icons">history</span>
        <span className="nav-label">Recent</span>
      </button>
    </div>
  );
};
