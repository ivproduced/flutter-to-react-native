// src/contexts/ProjectDataContext.tsx

import React, { createContext, useContext, useState, useEffect, ReactNode, useCallback } from 'react';
import { InformationSystem } from '../models/InformationSystem';
import { db } from '../services/DatabaseService';

interface ProjectDataContextType {
  systems: InformationSystem[];
  isLoading: boolean;
  errorMessage: string | null;
  loadSystems: () => Promise<boolean>;
  addSystem: (system: InformationSystem) => Promise<boolean>;
  updateSystem: (system: InformationSystem) => Promise<boolean>;
  deleteSystem: (id: string) => Promise<boolean>;
  getSystemById: (id: string) => InformationSystem | undefined;
}

const ProjectDataContext = createContext<ProjectDataContextType | undefined>(undefined);

export const useProjectData = () => {
  const context = useContext(ProjectDataContext);
  if (!context) {
    throw new Error('useProjectData must be used within ProjectDataProvider');
  }
  return context;
};

interface ProjectDataProviderProps {
  children: ReactNode;
}

export const ProjectDataProvider: React.FC<ProjectDataProviderProps> = ({ children }) => {
  const [systems, setSystems] = useState<InformationSystem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const loadSystems = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setErrorMessage(null);
    
    try {
      const loadedSystems = await db.getAllInformationSystems();
      loadedSystems.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
      setSystems(loadedSystems);
      setIsLoading(false);
      return true;
    } catch (error) {
      console.error('Error loading systems:', error);
      setErrorMessage('Failed to load systems.');
      setIsLoading(false);
      setSystems([]);
      return false;
    }
  }, []);

  const addSystem = useCallback(async (system: InformationSystem): Promise<boolean> => {
    setIsLoading(true);
    setErrorMessage(null);
    
    try {
      await db.createInformationSystem(system);
      await loadSystems();
      return true;
    } catch (error) {
      console.error('Error adding system:', error);
      setErrorMessage(`Failed to add system '${system.name}'.`);
      setIsLoading(false);
      return false;
    }
  }, [loadSystems]);

  const updateSystem = useCallback(async (system: InformationSystem): Promise<boolean> => {
    setIsLoading(true);
    setErrorMessage(null);
    
    try {
      await db.updateInformationSystem(system);
      setSystems(prev => {
        const updated = prev.map(s => s.id === system.id ? system : s);
        return updated.sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
      });
      setIsLoading(false);
      return true;
    } catch (error) {
      console.error('Error updating system:', error);
      setErrorMessage(`Failed to update system '${system.name}'.`);
      setIsLoading(false);
      return false;
    }
  }, []);

  const deleteSystem = useCallback(async (id: string): Promise<boolean> => {
    setIsLoading(true);
    setErrorMessage(null);
    
    try {
      await db.deleteInformationSystem(id);
      setSystems(prev => prev.filter(s => s.id !== id));
      setIsLoading(false);
      return true;
    } catch (error) {
      console.error('Error deleting system:', error);
      setErrorMessage('Failed to delete system.');
      setIsLoading(false);
      return false;
    }
  }, []);

  const getSystemById = useCallback((id: string): InformationSystem | undefined => {
    return systems.find(s => s.id === id);
  }, [systems]);

  useEffect(() => {
    loadSystems();
  }, [loadSystems]);

  return (
    <ProjectDataContext.Provider
      value={{
        systems,
        isLoading,
        errorMessage,
        loadSystems,
        addSystem,
        updateSystem,
        deleteSystem,
        getSystemById,
      }}
    >
      {children}
    </ProjectDataContext.Provider>
  );
};
