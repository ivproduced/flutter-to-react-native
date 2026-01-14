// src/screens/ControlDetailScreen.tsx

import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Control, Part } from '../models/Control';
import { controlDataService } from '../services/ControlDataService';
import { recentsService } from '../services/RecentsService';
import { notesService } from '../services/NotesService';
import { isEnhancement, isWithdrawn } from '../models/Control';
import { FavoriteButton } from '../components/FavoriteButton';
import { BottomNavBar } from '../components/BottomNavBar';
import './ControlDetailScreen.css';

// Helper function to extract assessment objectives from control parts
const extractAssessmentObjectives = (control: Control): Part[] => {
  const objectives: Part[] = [];
  
  const findObjectivesRecursive = (part: Part, depth: number = 0): void => {
    if (depth > 15) return; // Prevent infinite recursion
    
    // Check if this part is an assessment-objective with prose
    if (part.name.toLowerCase() === 'assessment-objective') {
      if (part.id && part.prose && part.prose.trim().length > 0) {
        objectives.push(part);
        return; // Don't recurse into children of a prose-containing objective
      }
    }
    
    // Recurse into subparts
    if (part.parts && part.parts.length > 0) {
      part.parts.forEach(subpart => findObjectivesRecursive(subpart, depth + 1));
    }
  };
  
  // Search through all top-level parts
  control.parts.forEach(part => findObjectivesRecursive(part, 0));
  
  // Remove duplicates by ID
  const seen = new Set<string>();
  return objectives.filter(obj => {
    if (obj.id && !seen.has(obj.id)) {
      seen.add(obj.id);
      return true;
    }
    return false;
  });
};

export const ControlDetailScreen: React.FC = () => {
  const navigate = useNavigate();
  const { controlId } = useParams<{ controlId: string }>();
  const [control, setControl] = useState<Control | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [note, setNote] = useState('');
  const [isEditingNote, setIsEditingNote] = useState(false);
  const [showAssessment, setShowAssessment] = useState(false);
  const [assessmentObjectives, setAssessmentObjectives] = useState<Part[]>([]);

  useEffect(() => {
    const loadControl = async () => {
      if (!controlId) return;

      await controlDataService.loadCatalog();
      const foundControl = controlDataService.getControlById(controlId);
      
      if (foundControl) {
        // Track this as a recent control
        await recentsService.addRecent(foundControl.id);
        
        // Load note if exists
        await notesService.loadNotes();
        setNote(notesService.getNote(foundControl.id));
        
        // Extract assessment objectives
        const objectives = extractAssessmentObjectives(foundControl);
        setAssessmentObjectives(objectives);
      }
      
      setControl(foundControl || null);
      setIsLoading(false);
    };

    loadControl();
  }, [controlId]);

  if (isLoading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
      </div>
    );
  }

  if (!control) {
    return (
      <div className="control-detail-screen">
        <header className="app-bar">
          <button className="back-button" onClick={() => navigate(-1)}>
            <span className="material-icons">arrow_back</span>
          </button>
          <h1>Control Not Found</h1>
        </header>
        <div className="error-state">
          <span className="material-icons">error_outline</span>
          <h3>Control Not Found</h3>
          <p>The control with ID "{controlId}" could not be found.</p>
        </div>
      </div>
    );
  }

  const withdrawn = isWithdrawn(control);
  const enhancement = isEnhancement(control);
  const statement = control.parts.find(p => p.name === 'statement');
  const guidance = control.parts.find(p => p.name === 'guidance');

  const getBaselineText = () => {
    const baselines: string[] = [];
    if (control.baselines.LOW) baselines.push('Low');
    if (control.baselines.MODERATE) baselines.push('Moderate');
    if (control.baselines.HIGH) baselines.push('High');
    if (control.baselines.PRIVACY) baselines.push('Privacy');
    return baselines.length > 0 ? baselines.join(', ') : 'Not in any baseline';
  };

  const handleSaveNote = async () => {
    await notesService.saveNote(control.id, note);
    setIsEditingNote(false);
  };

  const handleDeleteNote = async () => {
    if (window.confirm('Delete this note?')) {
      await notesService.deleteNote(control.id);
      setNote('');
      setIsEditingNote(false);
    }
  };

  return (
    <div className="control-detail-screen">
      <header className="app-bar">
        <button className="back-button" onClick={() => navigate(-1)}>
          <span className="material-icons">arrow_back</span>
        </button>
        <h1>{control.id.toUpperCase()}</h1>
        <div className="header-actions">
          <FavoriteButton controlId={control.id} />
        </div>
      </header>

      <div className="control-detail-content">
        {/* View Toggle */}
        <div className="view-toggle">
          <button
            className={`toggle-button ${!showAssessment ? 'active' : ''}`}
            onClick={() => setShowAssessment(false)}
          >
            <span className="material-icons">description</span>
            Control Statement
          </button>
          <button
            className={`toggle-button ${showAssessment ? 'active' : ''}`}
            onClick={() => setShowAssessment(true)}
          >
            <span className="material-icons">assignment</span>
            Assessment Objectives
          </button>
        </div>

        {/* Control Header */}
        <div className="control-detail-header">
          <div className="control-id-large">
            {control.id.toUpperCase()}
          </div>
          <div className="control-header-info">
            <h2 className="control-detail-title">
              {control.title}
              {withdrawn && <span className="withdrawn-badge-large">WITHDRAWN</span>}
            </h2>
            {enhancement && (
              <span className="enhancement-badge-large">Enhancement</span>
            )}
            <div className="baseline-badges-large">
              {control.baselines.LOW && <span className="baseline-badge-lg low">LOW</span>}
              {control.baselines.MODERATE && <span className="baseline-badge-lg moderate">MODERATE</span>}
              {control.baselines.HIGH && <span className="baseline-badge-lg high">HIGH</span>}
              {control.baselines.PRIVACY && <span className="baseline-badge-lg privacy">PRIVACY</span>}
            </div>
          </div>
        </div>

        {!showAssessment ? (
          <>
            {/* Control Statement */}
            {statement && statement.prose && (
              <div className="detail-section">
                <h3 className="section-title">
                  <span className="material-icons">description</span>
                  Control Statement
                </h3>
                <div className="section-content">
                  <p className="prose-text">{statement.prose}</p>
                </div>
              </div>
            )}

            {/* Guidance */}
            {guidance && guidance.prose && (
              <div className="detail-section">
                <h3 className="section-title">
                  <span className="material-icons">help_outline</span>
                  Implementation Guidance
                </h3>
                <div className="section-content">
                  <p className="prose-text">{guidance.prose}</p>
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="detail-section">
            <h3 className="section-title">
              <span className="material-icons">assignment</span>
              Assessment Objectives (800-53A)
            </h3>
            <div className="section-content">
              {assessmentObjectives.length > 0 ? (
                <div className="assessment-objectives-list">
                  {assessmentObjectives.map((objective, index) => (
                    <div key={objective.id || index} className="assessment-objective-item">
                      <div className="objective-header">
                        <span className="objective-id">{objective.id?.toUpperCase()}</span>
                        {objective.title && (
                          <span className="objective-title">{objective.title}</span>
                        )}
                      </div>
                      {objective.prose && (
                        <div className="objective-prose">
                          {objective.prose}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <div className="empty-note">
                  <span className="material-icons">info</span>
                  <p>No assessment objectives found for this control.</p>
                  <p className="help-text">Assessment objectives may not be available for all controls in the OSCAL catalog.</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Notes Section */}
        <div className="detail-section">
          <h3 className="section-title">
            <span className="material-icons">note</span>
            Notes
            <button
              className="edit-note-button"
              onClick={() => setIsEditingNote(!isEditingNote)}
            >
              <span className="material-icons">
                {isEditingNote ? 'close' : 'edit'}
              </span>
            </button>
          </h3>
          <div className="section-content">
            {isEditingNote ? (
              <div className="note-editor">
                <textarea
                  className="note-textarea"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="Add implementation notes, reminders, or documentation..."
                  rows={8}
                />
                <div className="note-actions">
                  <button className="save-button" onClick={handleSaveNote}>
                    <span className="material-icons">save</span>
                    Save Note
                  </button>
                  {note && (
                    <button className="delete-button" onClick={handleDeleteNote}>
                      <span className="material-icons">delete</span>
                      Delete
                    </button>
                  )}
                </div>
              </div>
            ) : note ? (
              <div className="note-display">
                <p>{note}</p>
              </div>
            ) : (
              <p className="empty-note">No notes yet. Click edit to add a note.</p>
            )}
          </div>
        </div>

        {/* Related Information */}
        <div className="detail-section">
          <h3 className="section-title">
            <span className="material-icons">info</span>
            Control Information
          </h3>
          <div className="section-content">
            <div className="info-row">
              <span className="info-label">Control ID:</span>
              <span className="info-value">{control.id.toUpperCase()}</span>
            </div>
            <div className="info-row">
              <span className="info-label">Class:</span>
              <span className="info-value">{control.controlClass || 'N/A'}</span>
            </div>
            <div className="info-row">
              <span className="info-label">Type:</span>
              <span className="info-value">{enhancement ? 'Enhancement' : 'Base Control'}</span>
            </div>
          </div>
        </div>

        {/* Enhancements */}
        {!enhancement && control.enhancements.length > 0 && (
          <div className="detail-section">
            <h3 className="section-title">
              <span className="material-icons">add_circle_outline</span>
              Enhancements ({control.enhancements.length})
            </h3>
            <div className="enhancements-list">
              {control.enhancements.map((enh) => (
                <div
                  key={enh.id}
                  className="enhancement-item"
                  onClick={() => navigate(`/controls/detail/${enh.id}`)}
                >
                  <div className="enhancement-id">
                    {enh.id.toUpperCase()}
                  </div>
                  <div className="enhancement-title">
                    {enh.title}
                  </div>
                  <span className="material-icons">chevron_right</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <BottomNavBar />
    </div>
  );
};
