// src/components/ControlTile.tsx

import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Control, isEnhancement, isWithdrawn, getEnhancementDisplay } from '../models/Control';
import { FavoriteButton } from './FavoriteButton';
import './ControlTile.css';

interface ControlTileProps {
  control: Control;
  onClick?: () => void;
  onFavoriteToggle?: () => void;
  showFavorite?: boolean;
}

export const ControlTile: React.FC<ControlTileProps> = ({ 
  control, 
  onClick, 
  onFavoriteToggle, 
  showFavorite = true 
}) => {
  const navigate = useNavigate();
  const withdrawn = isWithdrawn(control);
  const enhancement = isEnhancement(control);

  const handleClick = () => {
    if (onClick) {
      onClick();
    } else {
      navigate(`/controls/detail/${control.id}`);
    }
  };

  const getBaselineIndicators = () => {
    const activeBaselines: string[] = [];
    if (control.baselines.LOW) activeBaselines.push('L');
    if (control.baselines.MODERATE) activeBaselines.push('M');
    if (control.baselines.HIGH) activeBaselines.push('H');
    if (control.baselines.PRIVACY) activeBaselines.push('P');
    return activeBaselines;
  };

  const baselineIndicators = getBaselineIndicators();

  return (
    <div
      className={`control-tile ${withdrawn ? 'withdrawn' : ''}`}
      onClick={handleClick}
    >
      <div className="control-tile-header">
        <div className="control-id-badge">
          <span className="control-id">
            {enhancement ? getEnhancementDisplay(control.id) : control.id.toUpperCase()}
          </span>
        </div>
        <div className="control-tile-content">
          <h3 className="control-title">
            {control.title}
            {withdrawn && <span className="withdrawn-badge">WITHDRAWN</span>}
          </h3>
          <div className="control-meta">
            {baselineIndicators.length > 0 && (
              <div className="baseline-badges">
                {baselineIndicators.map((baseline) => (
                  <span key={baseline} className={`baseline-badge baseline-${baseline.toLowerCase()}`}>
                    {baseline}
                  </span>
                ))}
              </div>
            )}
            {enhancement && (
              <span className="enhancement-badge">Enhancement</span>
            )}
          </div>
        </div>
        {showFavorite && (
          <FavoriteButton 
            controlId={control.id} 
            onToggle={onFavoriteToggle}
          />
        )}
        <span className="material-icons control-arrow">chevron_right</span>
      </div>
    </div>
  );
};
