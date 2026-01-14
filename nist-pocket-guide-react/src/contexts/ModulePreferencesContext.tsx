// src/contexts/ModulePreferencesContext.tsx

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { db } from '../services/DatabaseService';
import { allModules } from '../models/AppModule';

interface ModulePreferencesContextType {
  showNist80053Module: boolean;
  showCsf20Module: boolean;
  showSp800171Module: boolean;
  showSsdfModule: boolean;
  showAiRmfModule: boolean;
  showSspGeneratorModule: boolean;
  toggleModuleVisibility: (preferenceKey: string) => Promise<void>;
  isModuleVisible: (preferenceKey: string) => boolean;
}

const ModulePreferencesContext = createContext<ModulePreferencesContextType | undefined>(undefined);

export const useModulePreferences = () => {
  const context = useContext(ModulePreferencesContext);
  if (!context) {
    throw new Error('useModulePreferences must be used within ModulePreferencesProvider');
  }
  return context;
};

interface ModulePreferencesProviderProps {
  children: ReactNode;
}

export const ModulePreferencesProvider: React.FC<ModulePreferencesProviderProps> = ({ children }) => {
  const [preferences, setPreferences] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const loadPreferences = async () => {
      const prefs: Record<string, boolean> = {};
      
      for (const module of allModules) {
        const value = await db.getPreference(module.preferenceKey, module.defaultVisible);
        prefs[module.preferenceKey] = value;
      }
      
      setPreferences(prefs);
    };

    loadPreferences();
  }, []);

  const toggleModuleVisibility = async (preferenceKey: string) => {
    const currentValue = preferences[preferenceKey] ?? true;
    const newValue = !currentValue;
    
    await db.setPreference(preferenceKey, newValue);
    setPreferences(prev => ({ ...prev, [preferenceKey]: newValue }));
  };

  const isModuleVisible = (preferenceKey: string): boolean => {
    return preferences[preferenceKey] ?? true;
  };

  return (
    <ModulePreferencesContext.Provider
      value={{
        showNist80053Module: preferences['show_nist_800_53_module'] ?? true,
        showCsf20Module: preferences['show_csf_20_module'] ?? true,
        showSp800171Module: preferences['show_sp800_171_module'] ?? true,
        showSsdfModule: preferences['show_ssdf_module'] ?? true,
        showAiRmfModule: preferences['show_ai_rmf_module'] ?? true,
        showSspGeneratorModule: preferences['show_ssp_generator_module'] ?? true,
        toggleModuleVisibility,
        isModuleVisible,
      }}
    >
      {children}
    </ModulePreferencesContext.Provider>
  );
};
