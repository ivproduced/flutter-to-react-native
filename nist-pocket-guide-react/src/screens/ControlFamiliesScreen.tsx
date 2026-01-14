// src/screens/ControlFamiliesScreen.tsx

import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { controlDataService } from '../services/ControlDataService';
import './ControlFamiliesScreen.css';

export const ControlFamiliesScreen: React.FC = () => {
  const navigate = useNavigate();
  const [familyPrefixes, setFamilyPrefixes] = useState<string[]>([]);
  const [familyTitles, setFamilyTitles] = useState<Record<string, string>>({});
  const [isGridView, setIsGridView] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    const loadData = async () => {
      await controlDataService.loadCatalog();
      setFamilyPrefixes(controlDataService.getFamilyPrefixes());
      setFamilyTitles(controlDataService.getFamilyTitles());
    };
    loadData();
  }, []);

  const handleSearch = () => {
    if (searchQuery.trim()) {
      navigate(`/controls/search?q=${encodeURIComponent(searchQuery)}`);
    }
  };

  const handleFamilyClick = (prefix: string) => {
    navigate(`/controls/family/${prefix.toLowerCase()}`);
  };

  return (
    <div className="control-families">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate('/dashboard')}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Controls by Family</h1>
      </header>

      <div className="families-content">
        {/* Search Bar */}
        <div className="search-bar">
          <span className="material-icons search-icon">search</span>
          <input
            type="text"
            placeholder="Search controls..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          />
        </div>

        {/* View Toggle */}
        <div className="families-header">
          <h2 className="section-title">Explore by Family</h2>
          <button
            className="view-toggle"
            onClick={() => setIsGridView(!isGridView)}
            title="Toggle view"
          >
            <span className="material-icons">
              {isGridView ? 'list' : 'grid_view'}
            </span>
          </button>
        </div>

        {/* Family List/Grid */}
        <div className={isGridView ? 'families-grid' : 'families-list'}>
          {familyPrefixes.map((prefix) => {
            const title = familyTitles[prefix] || '';
            const controlCount = controlDataService.getControlsForFamily(prefix).length;

            return isGridView ? (
              <div
                key={prefix}
                className="family-grid-card"
                onClick={() => handleFamilyClick(prefix)}
              >
                <div className="family-grid-badge">
                  <span className="family-prefix">{prefix}</span>
                </div>
                <h3 className="family-grid-title">{title}</h3>
                <p className="family-grid-count">{controlCount} controls</p>
              </div>
            ) : (
              <div
                key={prefix}
                className="family-list-card"
                onClick={() => handleFamilyClick(prefix)}
              >
                <div className="family-list-badge">
                  <span className="family-prefix">{prefix}</span>
                </div>
                <div className="family-list-content">
                  <h3 className="family-list-title">{title}</h3>
                  <p className="family-list-count">{controlCount} controls</p>
                </div>
                <span className="material-icons">chevron_right</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
