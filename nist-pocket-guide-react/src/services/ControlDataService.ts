// src/services/ControlDataService.ts

import { Catalog, Control, Group } from '../models/Control';

interface BaselineProfile {
  profile: {
    imports: Array<{
      'include-controls': Array<{
        'with-ids': string[];
      }>;
    }>;
  };
}

/**
 * Service for loading and managing NIST 800-53 control data
 */
class ControlDataService {
  private static instance: ControlDataService;
  private catalog: Catalog | null = null;
  private isLoaded = false;
  private baselineData: Map<string, Set<string>> = new Map();

  private constructor() {}

  static getInstance(): ControlDataService {
    if (!ControlDataService.instance) {
      ControlDataService.instance = new ControlDataService();
    }
    return ControlDataService.instance;
  }

  async loadCatalog(): Promise<void> {
    if (this.isLoaded) return;

    try {
      // Load the main catalog
      const catalogResponse = await fetch('/data/NIST_SP-800-53_rev5_catalog.json');
      const catalogData = await catalogResponse.json();
      
      // Load baseline profiles
      await this.loadBaselines();
      
      // Parse the catalog
      this.catalog = this.parseCatalog(catalogData);
      this.isLoaded = true;
      
      console.log(`Loaded ${this.getAllControls().length} controls from NIST catalog`);
    } catch (error) {
      console.error('Error loading NIST catalog:', error);
      // Fallback to mock data if loading fails
      this.catalog = this.createMockCatalog();
      this.isLoaded = true;
    }
  }

  private async loadBaselines(): Promise<void> {
    const baselines = ['LOW', 'MODERATE', 'HIGH', 'PRIVACY'];
    
    for (const baseline of baselines) {
      try {
        const response = await fetch(`/data/NIST_SP-800-53_rev5_${baseline}-baseline_profile.json`);
        const data: BaselineProfile = await response.json();
        
        const controlIds = new Set<string>();
        data.profile.imports.forEach(imp => {
          imp['include-controls'].forEach(inc => {
            inc['with-ids'].forEach(id => {
              controlIds.add(id.toLowerCase());
            });
          });
        });
        
        this.baselineData.set(baseline, controlIds);
      } catch (error) {
        console.error(`Error loading ${baseline} baseline:`, error);
      }
    }
  }

  private parseCatalog(data: any): Catalog {
    const catalogObj = data.catalog || data;
    
    // Parse groups (control families)
    const groups: Group[] = (catalogObj.groups || []).map((g: any) => ({
      id: g.id,
      title: g.title,
      controls: [],
      props: g.props || [],
      parts: g.parts || [],
      links: g.links || [],
    }));

    // Parse all controls
    const controls: Control[] = [];
    
    groups.forEach(group => {
      const groupData = catalogObj.groups.find((g: any) => g.id === group.id);
      if (groupData && groupData.controls) {
        groupData.controls.forEach((ctrl: any) => {
          const parsedControl = this.parseControl(ctrl);
          if (parsedControl) {
            controls.push(parsedControl);
            
            // Parse control enhancements
            if (ctrl.controls) {
              ctrl.controls.forEach((enhancement: any) => {
                const parsedEnhancement = this.parseControl(enhancement);
                if (parsedEnhancement) {
                  controls.push(parsedEnhancement);
                }
              });
            }
          }
        });
      }
    });

    return {
      uuid: catalogObj.uuid,
      metadata: {
        title: catalogObj.metadata?.title || 'NIST SP 800-53 Rev 5',
        version: catalogObj.metadata?.version || '5.1.1',
        oscalVersion: catalogObj.metadata?.['oscal-version'] || '1.0.4',
        lastModified: catalogObj.metadata?.['last-modified'] || new Date().toISOString(),
      },
      groups,
      controls,
    };
  }

  private parseControl(ctrl: any): Control | null {
    if (!ctrl || !ctrl.id) return null;

    const controlId = ctrl.id.toLowerCase();
    
    return {
      id: controlId,
      title: ctrl.title || '',
      controlClass: ctrl.class || 'SP800-53',
      props: ctrl.props || [],
      links: ctrl.links || [],
      params: ctrl.params || [],
      parts: ctrl.parts || [],
      enhancements: [], // Will be populated separately
      baselines: {
        LOW: this.baselineData.get('LOW')?.has(controlId) || false,
        MODERATE: this.baselineData.get('MODERATE')?.has(controlId) || false,
        HIGH: this.baselineData.get('HIGH')?.has(controlId) || false,
        PRIVACY: this.baselineData.get('PRIVACY')?.has(controlId) || false,
      },
      inCustomBaseline: false,
    };
  }

  getCatalog(): Catalog | null {
    return this.catalog;
  }

  getAllControls(): Control[] {
    return this.catalog?.controls || [];
  }

  getGroups(): Group[] {
    return this.catalog?.groups || [];
  }

  getFamilyPrefixes(): string[] {
    return this.getGroups().map(g => g.id.toUpperCase());
  }

  getFamilyTitles(): Record<string, string> {
    const titles: Record<string, string> = {};
    this.getGroups().forEach(g => {
      titles[g.id.toUpperCase()] = g.title;
    });
    return titles;
  }

  getControlById(id: string): Control | undefined {
    const normalizedId = id.toLowerCase();
    return this.getAllControls().find(c => c.id === normalizedId);
  }

  getControlsForFamily(familyPrefix: string): Control[] {
    const allControls = this.getAllControls();
    const familyControls = allControls.filter(
      c => c.id.toUpperCase().startsWith(familyPrefix.toUpperCase() + '-')
    );
    
    // Build enhancement map
    const baseControls = familyControls.filter(c => !c.id.includes('.'));
    const enhancements = familyControls.filter(c => c.id.includes('.'));
    
    // Attach enhancements to their parent controls
    baseControls.forEach(control => {
      control.enhancements = enhancements.filter(e => 
        e.id.startsWith(control.id + '.')
      );
    });
    
    return baseControls;
  }

  searchControls(query: string): Control[] {
    const lowerQuery = query.toLowerCase();
    const allControls = this.getAllControls();
    
    return allControls.filter(c => {
      // Search in ID
      if (c.id.toLowerCase().includes(lowerQuery)) return true;
      
      // Search in title
      if (c.title.toLowerCase().includes(lowerQuery)) return true;
      
      // Search in statement prose
      const statement = c.parts.find(p => p.name === 'statement');
      if (statement?.prose && statement.prose.toLowerCase().includes(lowerQuery)) {
        return true;
      }
      
      return false;
    });
  }

  getControlsByBaseline(baseline: 'LOW' | 'MODERATE' | 'HIGH' | 'PRIVACY'): Control[] {
    return this.getAllControls().filter(c => c.baselines[baseline]);
  }

  private createMockCatalog(): Catalog {
    // Mock catalog with sample controls for testing
    const families = [
      { id: 'ac', title: 'Access Control' },
      { id: 'au', title: 'Audit and Accountability' },
      { id: 'at', title: 'Awareness and Training' },
      { id: 'cm', title: 'Configuration Management' },
      { id: 'cp', title: 'Contingency Planning' },
      { id: 'ia', title: 'Identification and Authentication' },
      { id: 'ir', title: 'Incident Response' },
      { id: 'ma', title: 'Maintenance' },
      { id: 'mp', title: 'Media Protection' },
      { id: 'pe', title: 'Physical and Environmental Protection' },
      { id: 'pl', title: 'Planning' },
      { id: 'ps', title: 'Personnel Security' },
      { id: 'pt', title: 'PII Processing and Transparency' },
      { id: 'ra', title: 'Risk Assessment' },
      { id: 'ca', title: 'Assessment, Authorization, and Monitoring' },
      { id: 'sc', title: 'System and Communications Protection' },
      { id: 'si', title: 'System and Information Integrity' },
      { id: 'sa', title: 'System and Services Acquisition' },
      { id: 'sr', title: 'Supply Chain Risk Management' },
    ];

    const groups: Group[] = families.map(f => ({
      id: f.id,
      title: f.title,
      controls: [],
      props: [],
      parts: [],
      links: [],
    }));

    // Create sample controls
    const controls: Control[] = [];
    
    families.forEach((family, idx) => {
      // Add 5 sample controls per family
      for (let i = 1; i <= 5; i++) {
        const control: Control = {
          id: `${family.id}-${i}`,
          title: `${family.title} Control ${i}`,
          controlClass: 'SP800-53',
          props: [
            { name: 'label', value: `${family.id.toUpperCase()}-${i}` },
            { name: 'sort-id', value: `${family.id}-${String(i).padStart(2, '0')}` },
          ],
          links: [],
          params: [],
          parts: [
            {
              name: 'statement',
              prose: `This is a sample control statement for ${family.id.toUpperCase()}-${i}. In a production app, this would contain the actual NIST 800-53 control guidance.`,
              props: [],
              parts: [],
              links: [],
            },
          ],
          enhancements: [],
          baselines: {
            LOW: i <= 3,
            MODERATE: i <= 4,
            HIGH: true,
            PRIVACY: idx < 5 && i <= 2,
          },
          inCustomBaseline: false,
        };
        controls.push(control);

        // Add enhancements for first control in each family
        if (i === 1) {
          for (let e = 1; e <= 3; e++) {
            controls.push({
              id: `${family.id}-${i}.${e}`,
              title: `${family.title} Enhancement ${i}.${e}`,
              controlClass: 'SP800-53-enhancement',
              props: [
                { name: 'label', value: `${family.id.toUpperCase()}-${i}(${e})` },
              ],
              links: [],
              params: [],
              parts: [
                {
                  name: 'statement',
                  prose: `Enhancement statement for ${family.id.toUpperCase()}-${i}(${e}).`,
                  props: [],
                  parts: [],
                  links: [],
                },
              ],
              enhancements: [],
              baselines: {
                LOW: false,
                MODERATE: e === 1,
                HIGH: e <= 2,
                PRIVACY: false,
              },
              inCustomBaseline: false,
            });
          }
        }
      }
    });

    return {
      uuid: 'mock-catalog-uuid',
      metadata: {
        title: 'NIST SP 800-53 Rev 5 Security and Privacy Controls',
        version: '5.1.1',
        oscalVersion: '1.0.4',
        lastModified: '2024-01-01',
      },
      groups,
      controls,
    };
  }
}

export const controlDataService = ControlDataService.getInstance();
