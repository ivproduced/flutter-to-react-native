// src/screens/HomePage.tsx

import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppData, useModulePreferences } from '../contexts';
import './HomePage.css';

interface ModuleCardProps {
  title: string;
  subtitle: string;
  icon: string;
  color: string;
  onTap: () => void;
}

const ModuleCard: React.FC<ModuleCardProps> = ({ title, subtitle, icon, color, onTap }) => {
  return (
    <div className="module-card" onClick={onTap}>
      <div className="module-card-leading" style={{ backgroundColor: `${color}20` }}>
        <span className="material-icons" style={{ color }}>
          {icon}
        </span>
      </div>
      <div className="module-card-content">
        <h3 className="module-card-title">{title}</h3>
        <p className="module-card-subtitle">{subtitle}</p>
      </div>
      <span className="material-icons module-card-trailing">chevron_right</span>
    </div>
  );
};

const SectionHeader: React.FC<{ title: string }> = ({ title }) => {
  return (
    <div className="section-header">
      <h2>{title}</h2>
    </div>
  );
};

export const HomePage: React.FC = () => {
  const navigate = useNavigate();
  const { isInitialized } = useAppData();
  const modulePrefs = useModulePreferences();

  if (!isInitialized) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="home-page">
      <header className="app-bar">
        <h1>NIST Pocket Guide</h1>
      </header>
      
      <div className="content-container">
        <SectionHeader title="MODULES" />
        
        {modulePrefs.showNist80053Module && (
          <ModuleCard
            title="800-53 Pocket Guide"
            subtitle="Browse NIST 800-53 controls and guidance"
            icon="menu_book"
            color="#2196F3"
            onTap={() => {
              navigate('/dashboard');
            }}
          />
        )}

        {modulePrefs.showCsf20Module && (
          <ModuleCard
            title="NIST CSF 2.0"
            subtitle="Browse the Cybersecurity Framework v2.0"
            icon="security"
            color="#9C27B0"
            onTap={() => navigate('/csf-functions')}
          />
        )}

        {modulePrefs.showSp800171Module && (
          <ModuleCard
            title="SP 800-171 Rev 3"
            subtitle="Browse SP 800-171 Rev 3 controls"
            icon="shield"
            color="#009688"
            onTap={() => navigate('/sp800-171')}
          />
        )}

        {modulePrefs.showSsdfModule && (
          <ModuleCard
            title="SSDF"
            subtitle="Secure Software Development Framework"
            icon="code"
            color="#FF9800"
            onTap={() => navigate('/ssdf')}
          />
        )}

        {modulePrefs.showAiRmfModule && (
          <ModuleCard
            title="AI RMF Playbook"
            subtitle="NIST AI Risk Management Framework"
            icon="psychology"
            color="#E91E63"
            onTap={() => navigate('/ai-rmf')}
          />
        )}

        {modulePrefs.showSspGeneratorModule && (
          <ModuleCard
            title="SSP Generator"
            subtitle="Generate System Security Plans"
            icon="description"
            color="#4CAF50"
            onTap={() => navigate('/ssp-generator')}
          />
        )}

        <SectionHeader title="TOOLS & RESOURCES" />
        
        <ModuleCard
          title="Settings"
          subtitle="Configure app preferences and modules"
          icon="settings"
          color="#607D8B"
          onTap={() => navigate('/settings')}
        />

        <ModuleCard
          title="About"
          subtitle="App information and credits"
          icon="info"
          color="#795548"
          onTap={() => navigate('/about')}
        />
      </div>
    </div>
  );
};
