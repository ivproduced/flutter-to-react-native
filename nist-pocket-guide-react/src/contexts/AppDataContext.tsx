// src/contexts/AppDataContext.tsx

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import localforage from 'localforage';

export type ThemeMode = 'light' | 'dark' | 'system';

interface AppDataContextType {
  isInitialized: boolean;
  currentThemeMode: ThemeMode;
  setThemeMode: (mode: ThemeMode) => void;
}

const AppDataContext = createContext<AppDataContextType | undefined>(undefined);

export const useAppData = () => {
  const context = useContext(AppDataContext);
  if (!context) {
    throw new Error('useAppData must be used within AppDataProvider');
  }
  return context;
};

interface AppDataProviderProps {
  children: ReactNode;
}

export const AppDataProvider: React.FC<AppDataProviderProps> = ({ children }) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [currentThemeMode, setCurrentThemeMode] = useState<ThemeMode>('light');

  useEffect(() => {
    const initialize = async () => {
      try {
        // Load theme preference from storage
        const savedTheme = await localforage.getItem<ThemeMode>('theme_mode');
        if (savedTheme) {
          setCurrentThemeMode(savedTheme);
        }
        setIsInitialized(true);
      } catch (error) {
        console.error('Error initializing AppData:', error);
        setIsInitialized(true);
      }
    };

    initialize();
  }, []);

  const setThemeMode = async (mode: ThemeMode) => {
    try {
      await localforage.setItem('theme_mode', mode);
      setCurrentThemeMode(mode);
    } catch (error) {
      console.error('Error saving theme mode:', error);
    }
  };

  return (
    <AppDataContext.Provider
      value={{
        isInitialized,
        currentThemeMode,
        setThemeMode,
      }}
    >
      {children}
    </AppDataContext.Provider>
  );
};
