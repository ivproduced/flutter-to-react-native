// src/models/Control.ts

export interface Prop {
  name: string;
  value: string;
  ns?: string;
  clazz?: string;
}

export interface Link {
  href: string;
  rel?: string;
}

export interface Select {
  howMany?: string;
  choice: string[];
}

export interface Parameter {
  id: string;
  props: Prop[];
  label?: string;
  values: string[];
  select?: Select;
}

export interface Part {
  id?: string;
  name: string;
  prose?: string;
  title?: string;
  props: Prop[];
  parts: Part[]; // subparts
  links: Link[];
}

export interface Control {
  id: string;
  title: string;
  controlClass: string;
  props: Prop[];
  links: Link[];
  params: Parameter[];
  parts: Part[];
  enhancements: Control[]; // nested controls (enhancements)
  baselines: {
    LOW: boolean;
    MODERATE: boolean;
    HIGH: boolean;
    PRIVACY: boolean;
  };
  inCustomBaseline: boolean;
}

export interface Group {
  id: string;
  title: string;
  controls: Control[];
  props: Prop[];
  parts: Part[];
  links: Link[];
}

export interface Catalog {
  uuid: string;
  metadata: {
    title: string;
    version: string;
    oscalVersion: string;
    lastModified?: string;
  };
  groups: Group[];
  controls: Control[];
}

// Helper functions
export const isEnhancement = (control: Control): boolean => {
  return control.id.includes('.');
};

export const isWithdrawn = (control: Control): boolean => {
  return control.props.some(
    p => p.name === 'status' && p.value.toLowerCase() === 'withdrawn'
  ) || control.title.toLowerCase().includes('withdrawn');
};

export const getEnhancementDisplay = (controlId: string): string => {
  const parts = controlId.split('.');
  if (parts.length === 2) {
    const base = parts[0].toUpperCase();
    const enh = parts[1];
    return `${base}(${enh})`;
  }
  return controlId.toUpperCase();
};

export const getFamilyPrefix = (controlId: string): string => {
  return controlId.split('-')[0].toUpperCase();
};

export const getControlsForFamily = (
  controls: Control[],
  familyPrefix: string
): Control[] => {
  return controls.filter(
    c => c.id.toUpperCase().startsWith(familyPrefix.toUpperCase() + '-')
  );
};

export const getBaselineControls = (
  controls: Control[],
  baseline: 'LOW' | 'MODERATE' | 'HIGH' | 'PRIVACY'
): Control[] => {
  return controls.filter(c => c.baselines[baseline]);
};
