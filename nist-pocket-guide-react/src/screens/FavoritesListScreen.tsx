// src/screens/FavoritesListScreen.tsx

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { favoritesService } from '../services/FavoritesService';
import { controlDataService } from '../services/ControlDataService';
import { Control } from '../models/Control';
import { ControlTile } from '../components/ControlTile';
import './FavoritesListScreen.css';

export const FavoritesListScreen: React.FC = () => {
  const navigate = useNavigate();
  const [favoriteControls, setFavoriteControls] = useState<Control[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadFavorites();
  }, []);

  const loadFavorites = async () => {
    try {
      await favoritesService.loadFavorites();
      const favoriteIds = favoritesService.getFavorites();
      
      const controls = await Promise.all(
        Array.from(favoriteIds).map(id => controlDataService.getControlById(id))
      );
      
      setFavoriteControls(controls.filter((c): c is Control => c !== null));
    } catch (error) {
      console.error('Error loading favorites:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleControlClick = (controlId: string) => {
    navigate(`/controls/detail/${controlId}`);
  };

  const handleFavoriteToggle = () => {
    loadFavorites(); // Reload after toggling
  };

  if (loading) {
    return (
      <div className="favorites-screen">
        <div className="screen-header">
          <button className="back-button" onClick={() => navigate(-1)}>
            <span className="material-icons">arrow_back</span>
          </button>
          <h1>Favorites</h1>
        </div>
        <div className="loading">Loading favorites...</div>
      </div>
    );
  }

  return (
    <div className="favorites-screen">
      <div className="screen-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Favorites</h1>
        <span className="count-badge">{favoriteControls.length}</span>
      </div>

      {favoriteControls.length === 0 ? (
        <div className="empty-state">
          <span className="material-icons">star_outline</span>
          <h2>No Favorites Yet</h2>
          <p>Tap the star icon on any control to add it to your favorites.</p>
        </div>
      ) : (
        <div className="favorites-list">
          {favoriteControls.map(control => (
            <ControlTile
              key={control.id}
              control={control}
              onClick={() => handleControlClick(control.id)}
              onFavoriteToggle={handleFavoriteToggle}
            />
          ))}
        </div>
      )}
    </div>
  );
};
