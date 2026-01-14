// src/components/FavoriteButton.tsx

import React, { useState, useEffect } from 'react';
import { favoritesService } from '../services/FavoritesService';
import './FavoriteButton.css';

interface FavoriteButtonProps {
  controlId: string;
  onToggle?: (isFavorite: boolean) => void;
}

export const FavoriteButton: React.FC<FavoriteButtonProps> = ({ controlId, onToggle }) => {
  const [isFavorite, setIsFavorite] = useState(false);

  useEffect(() => {
    const loadFavoriteStatus = async () => {
      await favoritesService.loadFavorites();
      setIsFavorite(favoritesService.isFavorite(controlId));
    };
    loadFavoriteStatus();
  }, [controlId]);

  const handleClick = async (e: React.MouseEvent) => {
    e.stopPropagation();

    const newStatus = await favoritesService.toggleFavorite(controlId);
    setIsFavorite(newStatus);
    onToggle?.(newStatus);
  };

  return (
    <button
      className={`favorite-button ${isFavorite ? 'active' : ''}`}
      onClick={handleClick}
      title={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
    >
      <span className="material-icons">
        {isFavorite ? 'star' : 'star_border'}
      </span>
    </button>
  );
};
