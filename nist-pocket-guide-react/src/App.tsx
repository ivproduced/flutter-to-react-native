// src/App.tsx

import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AppDataProvider, ProjectDataProvider, ModulePreferencesProvider, PurchaseProvider } from './contexts';
import { HomePage } from './screens/HomePage';
import { ControlDashboardScreen } from './screens/ControlDashboardScreen';
import { ControlFamiliesScreen } from './screens/ControlFamiliesScreen';
import { ControlFamilyListScreen } from './screens/ControlFamilyListScreen';
import { AllControlsListScreen } from './screens/AllControlsListScreen';
import { ControlDetailScreen } from './screens/ControlDetailScreen';
import { FavoritesListScreen } from './screens/FavoritesListScreen';
import { NotesListScreen } from './screens/NotesListScreen';
import { RecentsListScreen } from './screens/RecentsListScreen';
import { SearchResultsScreen } from './screens/SearchResultsScreen';
import { db } from './services/DatabaseService';
import './App.css';

// Placeholder components for routes - these will be implemented later
const ControlBaselines = () => <div>Control Baselines (Coming Soon)</div>;
const ControlImplementationLevels = () => <div>Implementation Levels (Coming Soon)</div>;
const CsfFunctions = () => <div>CSF Functions (Coming Soon)</div>;
const Sp800171 = () => <div>SP 800-171 (Coming Soon)</div>;
const Ssdf = () => <div>SSDF (Coming Soon)</div>;
const AiRmf = () => <div>AI RMF (Coming Soon)</div>;
const SspGenerator = () => <div>SSP Generator (Coming Soon)</div>;
const Settings = () => <div>Settings (Coming Soon)</div>;
const About = () => <div>About (Coming Soon)</div>;

// Onboarding placeholder
const Onboarding = ({ onFinish }: { onFinish: () => void }) => {
  return (
    <div className="onboarding-screen">
      <div className="onboarding-content">
        <h1>Welcome to NIST Pocket Guide</h1>
        <p>Your comprehensive mobile reference for NIST security controls and frameworks</p>
        <button onClick={onFinish} className="primary-button">Get Started</button>
      </div>
    </div>
  );
};

function App() {
  const [checkingOnboarding, setCheckingOnboarding] = useState(true);
  const [onboardingCompleted, setOnboardingCompleted] = useState(false);

  useEffect(() => {
    const checkOnboarding = async () => {
      try {
        const welcomeSeen = await db.isWelcomeSeen();
        setOnboardingCompleted(welcomeSeen);
      } catch (error) {
        console.error('Error checking onboarding status:', error);
        setOnboardingCompleted(false);
      } finally {
        setCheckingOnboarding(false);
      }
    };

    checkOnboarding();
  }, []);

  const handleOnboardingFinish = async () => {
    await db.setWelcomeSeen();
    setOnboardingCompleted(true);
  };

  if (checkingOnboarding) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  if (!onboardingCompleted) {
    return <Onboarding onFinish={handleOnboardingFinish} />;
  }

  return (
    <AppDataProvider>
      <PurchaseProvider>
        <ProjectDataProvider>
          <ModulePreferencesProvider>
            <Router>
              <Routes>
                <Route path="/" element={<HomePage />} />
                
                {/* 800-53 Control Routes */}
                <Route path="/dashboard" element={<ControlDashboardScreen />} />
                <Route path="/controls/families" element={<ControlFamiliesScreen />} />
                <Route path="/controls/family/:familyId" element={<ControlFamilyListScreen />} />
                <Route path="/controls/baselines" element={<ControlBaselines />} />
                <Route path="/controls/implementation-levels" element={<ControlImplementationLevels />} />
                <Route path="/controls/all" element={<AllControlsListScreen />} />
                <Route path="/controls/detail/:controlId" element={<ControlDetailScreen />} />
                <Route path="/controls/favorites" element={<FavoritesListScreen />} />
                <Route path="/controls/notes" element={<NotesListScreen />} />
                <Route path="/controls/recent" element={<RecentsListScreen />} />
                <Route path="/controls/search" element={<SearchResultsScreen />} />
                
                {/* Other Module Routes */}
                <Route path="/csf-functions" element={<CsfFunctions />} />
                <Route path="/sp800-171" element={<Sp800171 />} />
                <Route path="/ssdf" element={<Ssdf />} />
                <Route path="/ai-rmf" element={<AiRmf />} />
                <Route path="/ssp-generator" element={<SspGenerator />} />
                <Route path="/settings" element={<Settings />} />
                <Route path="/about" element={<About />} />
                
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </Router>
          </ModulePreferencesProvider>
        </ProjectDataProvider>
      </PurchaseProvider>
    </AppDataProvider>
  );
}

export default App;
