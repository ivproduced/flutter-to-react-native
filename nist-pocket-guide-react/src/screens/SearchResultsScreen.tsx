// src/screens/SearchResultsScreen.tsx

import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { controlDataService } from '../services/ControlDataService';
import { Control } from '../models/Control';
import { ControlTile } from '../components/ControlTile';
import './SearchResultsScreen.css';

export const SearchResultsScreen: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const query = searchParams.get('q') || '';
  
  const [results, setResults] = useState<Control[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const performSearch = async () => {
      setLoading(true);
      await controlDataService.loadCatalog();
      
      if (query.trim()) {
        const searchResults = controlDataService.searchControls(query);
        setResults(searchResults);
      } else {
        setResults([]);
      }
      
      setLoading(false);
    };

    performSearch();
  }, [query]);

  const handleControlClick = (controlId: string) => {
    navigate(`/controls/detail/${controlId}`);
  };

  return (
    <div className="search-results-screen">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate(-1)}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>Search Results</h1>
      </header>

      <div className="search-results-content">
        <div className="search-query-display">
          <span className="material-icons">search</span>
          <p>
            {loading ? 'Searching...' : (
              results.length > 0
                ? `Found ${results.length} result${results.length === 1 ? '' : 's'} for "${query}"`
                : `No results found for "${query}"`
            )}
          </p>
        </div>

        {loading ? (
          <div className="loading">
            <div className="spinner" />
          </div>
        ) : results.length > 0 ? (
          <div className="results-list">
            {results.map(control => (
              <ControlTile
                key={control.id}
                control={control}
                onClick={() => handleControlClick(control.id)}
              />
            ))}
          </div>
        ) : (
          <div className="empty-state">
            <span className="material-icons">search_off</span>
            <h2>No Results Found</h2>
            <p>Try searching with different keywords or control IDs.</p>
          </div>
        )}
      </div>
    </div>
  );
};
