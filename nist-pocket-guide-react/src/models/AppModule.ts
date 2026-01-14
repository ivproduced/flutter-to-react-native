// src/models/AppModule.ts

/**
 * Defines the available modules in the NIST Pocket Guide app.
 * 
 * This model ensures that the settings screen module visibility list
 * stays in sync with what's actually implemented in the app.
 */

export interface AppModule {
  id: string;
  title: string;
  description: string;
  icon: string; // Icon name/class
  preferenceKey: string;
  defaultVisible: boolean;
  isAvailable?: () => boolean;
}

export const allModules: AppModule[] = [
  {
    id: 'nist_800_53',
    title: '800-53 Pocket Guide',
    description: 'Show NIST 800-53 controls and guidance module',
    icon: 'menu_book_outlined',
    preferenceKey: 'show_nist_800_53_module',
    defaultVisible: true,
  },
  {
    id: 'ai_rmf',
    title: 'AI RMF Playbook',
    description: 'Show NIST AI Risk Management Framework module',
    icon: 'psychology_alt_outlined',
    preferenceKey: 'show_ai_rmf_module',
    defaultVisible: true,
  },
  {
    id: 'ssp_generator',
    title: 'SSP Generator',
    description: 'Generate System Security Plans',
    icon: 'description_outlined',
    preferenceKey: 'show_ssp_generator_module',
    defaultVisible: true,
  },
  {
    id: 'csf_20',
    title: 'NIST CSF 2.0',
    description: 'Browse the Cybersecurity Framework v2.0',
    icon: 'security_outlined',
    preferenceKey: 'show_csf_20_module',
    defaultVisible: true,
  },
  {
    id: 'sp800_171',
    title: 'SP 800-171 Rev 3',
    description: 'Show SP 800-171 Rev 3 controls',
    icon: 'shield_outlined',
    preferenceKey: 'show_sp800_171_module',
    defaultVisible: true,
  },
  {
    id: 'ssdf',
    title: 'SSDF',
    description: 'Secure Software Development Framework',
    icon: 'code_outlined',
    preferenceKey: 'show_ssdf_module',
    defaultVisible: true,
  },
];
