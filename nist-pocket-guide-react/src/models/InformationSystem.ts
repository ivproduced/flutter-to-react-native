// src/models/InformationSystem.ts

export interface ControlImplementation {
  controlId: string;
  implementationStatus: string;
  responsibleRole: string;
  implementationStatement: string;
  evidenceLinks: string[];
}

export interface InformationSystem {
  id: string;
  name: string;
  description: string;
  owner: string;
  classification: string;
  createdAt: Date;
  updatedAt: Date;
  baselineProfile?: string;
  controlImplementations: ControlImplementation[];
  customFields?: Record<string, any>;
}
