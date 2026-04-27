import { Injectable } from '@angular/core';

export interface PrepArea { id: string; name: string; }
export interface Allergen { id: string; name: string; color: string; }
export interface Ingredient { code: string; name: string; unit: string; allergens: string[]; supplier: string; cost: number; stock: number; useBy: number | null; }
export interface RecipeLine { code: string; pct: number; tol: [number, number]; }
export interface Recipe { code: string; name: string; description: string; prepArea: string; status: string; version: number; updated: string; spec: string; lines: RecipeLine[]; }
export interface Order { num: number; recipe: string; qty: number; unit: string; area: string; status: string; terminal: string | null; due: string; mixes: number; mixesDone: number; progress: number; }
export interface Terminal { id: string; label: string; area: string; status: string; user: string | null; version: string; scale: string; printer: string; lastSeen: string; }
export interface User { id: string; name: string; email: string; role: string; active: boolean; last: string; }
export interface RoleMeta { label: string; desc: string; color: string; }
export interface QaCheck { id: string; name: string; trigger: string; type: string; area: string; applies: string | string[]; required: boolean; min?: number; max?: number; }
export interface AllergenRule { id: string; name: string; scope: string[]; policy: string; area: string; cleanMinutes: number; active: boolean; }
export interface AuditEntry { t: string; user: string; action: string; target: string; kind: string; }

export const STATUS_CHIP: Record<string, { label: string; cls: string }> = {
  'scheduled':   { label: 'scheduled',   cls: 'chip--neutral' },
  'in-progress': { label: 'in progress', cls: 'chip--info' },
  'complete':    { label: 'complete',    cls: 'chip--success' },
  'on-hold':     { label: 'on hold',     cls: 'chip--warn' },
  'abandoned':   { label: 'abandoned',   cls: 'chip--danger' },
  'active':      { label: 'active',      cls: 'chip--success' },
  'draft':       { label: 'draft',       cls: 'chip--neutral' },
  'archived':    { label: 'archived',    cls: 'chip--outline' },
  'online':      { label: 'online',      cls: 'chip--success' },
  'offline':     { label: 'offline',     cls: 'chip--danger' },
  'idle':        { label: 'idle',        cls: 'chip--neutral' },
  'updating':    { label: 'updating',    cls: 'chip--info' },
};

export const SEG_COLORS = ['#122559','#4934ad','#d4245c','#1d327b','#6350c4','#e14879','#2d4aa6','#b25b00','#1f8a5a','#6b7597'];

@Injectable({ providedIn: 'root' })
export class DataService {
  readonly prepAreas: PrepArea[] = [
    { id: 'bakery', name: 'Bakery' },
    { id: 'sauces', name: 'Sauces & dressings' },
    { id: 'meat',   name: 'Meat preparation' },
    { id: 'dry',    name: 'Dry goods' },
    { id: 'dairy',  name: 'Dairy' },
  ];

  readonly allergens: Allergen[] = [
    { id: 'gluten',   name: 'Gluten',    color: '#b25b00' },
    { id: 'milk',     name: 'Milk',      color: '#1d327b' },
    { id: 'egg',      name: 'Egg',       color: '#b31a4c' },
    { id: 'soya',     name: 'Soya',      color: '#3a28a0' },
    { id: 'mustard',  name: 'Mustard',   color: '#b25b00' },
    { id: 'sesame',   name: 'Sesame',    color: '#6350c4' },
    { id: 'celery',   name: 'Celery',    color: '#1f8a5a' },
    { id: 'sulphite', name: 'Sulphites', color: '#b25b00' },
    { id: 'nuts',     name: 'Tree nuts', color: '#b31a4c' },
    { id: 'peanut',   name: 'Peanuts',   color: '#b31a4c' },
  ];

  readonly ingredients: Ingredient[] = [
    { code: 'FLR-001', name: 'Strong white bread flour', unit: 'kg', allergens: ['gluten'],         supplier: 'Whitworth Bros.',    cost: 0.62,  stock: 1240, useBy: 180  },
    { code: 'FLR-012', name: 'Wholemeal bread flour',    unit: 'kg', allergens: ['gluten'],         supplier: 'Whitworth Bros.',    cost: 0.68,  stock: 640,  useBy: 180  },
    { code: 'YST-002', name: 'Dried active yeast',       unit: 'kg', allergens: [],                 supplier: 'Lesaffre UK',        cost: 4.10,  stock: 88,   useBy: 365  },
    { code: 'SLT-001', name: 'Fine sea salt',            unit: 'kg', allergens: [],                 supplier: 'British Salt',       cost: 0.42,  stock: 420,  useBy: 1825 },
    { code: 'SUG-003', name: 'Caster sugar',             unit: 'kg', allergens: [],                 supplier: 'Tate & Lyle',        cost: 0.89,  stock: 360,  useBy: 730  },
    { code: 'OIL-004', name: 'Cold-pressed rapeseed oil',unit: 'L',  allergens: [],                 supplier: 'Borderfields',       cost: 3.40,  stock: 180,  useBy: 540  },
    { code: 'EGG-001', name: 'Pasteurised whole egg',    unit: 'L',  allergens: ['egg'],            supplier: 'Stonegate Farmers',  cost: 2.85,  stock: 64,   useBy: 42   },
    { code: 'MLK-002', name: 'Whole milk',               unit: 'L',  allergens: ['milk'],           supplier: 'Arla Foods',         cost: 0.86,  stock: 140,  useBy: 14   },
    { code: 'BUT-001', name: 'Unsalted butter',          unit: 'kg', allergens: ['milk'],           supplier: 'Kerrygold',          cost: 6.20,  stock: 92,   useBy: 120  },
    { code: 'MST-001', name: 'English mustard powder',   unit: 'kg', allergens: ['mustard'],        supplier: "Colman's",           cost: 8.20,  stock: 24,   useBy: 540  },
    { code: 'VIN-001', name: 'White wine vinegar',       unit: 'L',  allergens: ['sulphite'],       supplier: 'Aspall',             cost: 1.90,  stock: 86,   useBy: 730  },
    { code: 'SOY-001', name: 'Light soy sauce',          unit: 'L',  allergens: ['soya','gluten'],  supplier: 'Kikkoman',           cost: 3.60,  stock: 54,   useBy: 540  },
    { code: 'SES-001', name: 'Toasted sesame oil',       unit: 'L',  allergens: ['sesame'],         supplier: 'Meridian',           cost: 7.40,  stock: 18,   useBy: 540  },
    { code: 'HZL-001', name: 'Hazelnut paste',           unit: 'kg', allergens: ['nuts'],           supplier: 'Callebaut',          cost: 14.50, stock: 36,   useBy: 270  },
    { code: 'CCO-001', name: 'Cocoa powder 22/24',       unit: 'kg', allergens: [],                 supplier: 'Barry Callebaut',    cost: 6.80,  stock: 74,   useBy: 540  },
    { code: 'STR-001', name: 'Strawberry purée',         unit: 'kg', allergens: ['sulphite'],       supplier: 'Ravifruit',          cost: 9.10,  stock: 48,   useBy: 60   },
    { code: 'WAT-001', name: 'Filtered water',           unit: 'L',  allergens: [],                 supplier: 'Mains',              cost: 0.002, stock: 9999, useBy: null  },
    { code: 'CEL-001', name: 'Celery salt',              unit: 'kg', allergens: ['celery'],         supplier: 'Schwartz',           cost: 5.20,  stock: 12,   useBy: 540  },
  ];

  readonly recipes: Recipe[] = [
    { code: 'BR-014', name: 'Classic sourdough loaf',    description: 'House sourdough, 24h bulk ferment.', prepArea: 'bakery', status: 'active', version: 7,  updated: '2026-04-18', spec: 'percent',
      lines: [{ code: 'FLR-001', pct: 60, tol:[3,3] },{ code: 'FLR-012', pct:15,tol:[3,3] },{ code:'WAT-001',pct:18,tol:[2,2] },{ code:'SLT-001',pct:1.2,tol:[5,5] },{ code:'YST-002',pct:0.8,tol:[8,8] },{ code:'OIL-004',pct:5,tol:[5,5] }] },
    { code: 'BR-021', name: 'Seeded brown bloomer',      description: 'Wholemeal with mixed seeds.',         prepArea: 'bakery', status: 'active', version: 3,  updated: '2026-04-11', spec: 'percent',
      lines: [{ code:'FLR-012',pct:58,tol:[3,3] },{ code:'FLR-001',pct:12,tol:[3,3] },{ code:'WAT-001',pct:21,tol:[2,2] },{ code:'SLT-001',pct:1.5,tol:[5,5] },{ code:'YST-002',pct:1,tol:[8,8] },{ code:'OIL-004',pct:6.5,tol:[5,5] }] },
    { code: 'SC-008', name: 'Hellenic house mayonnaise', description: 'Mustard-forward mayo, signature line.',prepArea: 'sauces', status: 'active', version: 12, updated: '2026-04-22', spec: 'percent',
      lines: [{ code:'OIL-004',pct:74,tol:[2,2] },{ code:'EGG-001',pct:14,tol:[3,3] },{ code:'VIN-001',pct:6,tol:[4,4] },{ code:'MST-001',pct:2.5,tol:[5,5] },{ code:'SLT-001',pct:1,tol:[6,6] },{ code:'WAT-001',pct:2.5,tol:[5,5] }] },
    { code: 'SC-011', name: 'Sesame soy dressing',       description: 'Asian-style pourable dressing.',      prepArea: 'sauces', status: 'active', version: 2,  updated: '2026-04-03', spec: 'percent',
      lines: [{ code:'SOY-001',pct:42,tol:[3,3] },{ code:'OIL-004',pct:30,tol:[3,3] },{ code:'SES-001',pct:8,tol:[4,4] },{ code:'VIN-001',pct:12,tol:[4,4] },{ code:'SUG-003',pct:7,tol:[5,5] },{ code:'SLT-001',pct:1,tol:[6,6] }] },
    { code: 'DC-003', name: 'Chocolate ganache filling', description: 'Dark couverture ganache.',             prepArea: 'dairy',  status: 'active', version: 5,  updated: '2026-04-09', spec: 'percent',
      lines: [{ code:'CCO-001',pct:48,tol:[2,2] },{ code:'MLK-002',pct:34,tol:[3,3] },{ code:'BUT-001',pct:14,tol:[3,3] },{ code:'SUG-003',pct:4,tol:[4,4] }] },
    { code: 'DC-007', name: 'Hazelnut praline paste',    description: 'Roasted hazelnut base.',              prepArea: 'dairy',  status: 'draft',  version: 1,  updated: '2026-04-23', spec: 'percent',
      lines: [{ code:'HZL-001',pct:58,tol:[2,2] },{ code:'SUG-003',pct:40,tol:[3,3] },{ code:'SLT-001',pct:2,tol:[5,5] }] },
  ];

  readonly orders: Order[] = [
    { num:200482, recipe:'BR-014', qty:240, unit:'kg', area:'bakery', status:'in-progress', terminal:'T-04',  due:'2026-04-24 14:00', mixes:4, mixesDone:2, progress:62  },
    { num:200483, recipe:'SC-008', qty:180, unit:'kg', area:'sauces', status:'in-progress', terminal:'T-11',  due:'2026-04-24 15:30', mixes:3, mixesDone:1, progress:38  },
    { num:200484, recipe:'BR-021', qty:120, unit:'kg', area:'bakery', status:'scheduled',   terminal:null,    due:'2026-04-24 16:00', mixes:2, mixesDone:0, progress:0   },
    { num:200485, recipe:'DC-003', qty:60,  unit:'kg', area:'dairy',  status:'scheduled',   terminal:null,    due:'2026-04-24 17:00', mixes:2, mixesDone:0, progress:0   },
    { num:200486, recipe:'SC-011', qty:90,  unit:'kg', area:'sauces', status:'scheduled',   terminal:null,    due:'2026-04-25 09:00', mixes:2, mixesDone:0, progress:0   },
    { num:200478, recipe:'BR-014', qty:240, unit:'kg', area:'bakery', status:'complete',    terminal:'T-04',  due:'2026-04-24 10:00', mixes:4, mixesDone:4, progress:100 },
    { num:200477, recipe:'SC-008', qty:120, unit:'kg', area:'sauces', status:'complete',    terminal:'T-11',  due:'2026-04-24 09:30', mixes:2, mixesDone:2, progress:100 },
    { num:200479, recipe:'DC-003', qty:40,  unit:'kg', area:'dairy',  status:'on-hold',     terminal:'T-09',  due:'2026-04-24 11:30', mixes:2, mixesDone:1, progress:50  },
    { num:200480, recipe:'BR-021', qty:80,  unit:'kg', area:'bakery', status:'complete',    terminal:'T-02',  due:'2026-04-24 08:00', mixes:2, mixesDone:2, progress:100 },
    { num:200487, recipe:'BR-014', qty:360, unit:'kg', area:'bakery', status:'scheduled',   terminal:null,    due:'2026-04-25 06:00', mixes:6, mixesDone:0, progress:0   },
    { num:200488, recipe:'SC-008', qty:240, unit:'kg', area:'sauces', status:'scheduled',   terminal:null,    due:'2026-04-25 10:00', mixes:4, mixesDone:0, progress:0   },
  ];

  readonly terminals: Terminal[] = [
    { id:'T-01', label:'Bakery #1',      area:'bakery', status:'online',   user:'Alex Doyle',    version:'1.2.3',       scale:'CSW-410',        printer:'Zebra ZD421',       lastSeen:'12s ago' },
    { id:'T-02', label:'Bakery #2',      area:'bakery', status:'online',   user:'Priya Shah',    version:'1.2.3',       scale:'CSW-410',        printer:'Zebra ZD421',       lastSeen:'3s ago'  },
    { id:'T-04', label:'Bakery #3',      area:'bakery', status:'online',   user:'Joe Mitchell',  version:'1.2.3',       scale:'Mettler BBA242', printer:'Honeywell PM43',    lastSeen:'6s ago'  },
    { id:'T-09', label:'Dairy weighing', area:'dairy',  status:'offline',  user:'Sam Okafor',    version:'1.2.3',       scale:'Rinstrun R420',  printer:'Zebra ZD421',       lastSeen:'4m ago'  },
    { id:'T-11', label:'Sauces #1',      area:'sauces', status:'online',   user:'Mei Chen',      version:'1.2.2',       scale:'CSW-410',        printer:'Zebra ZD421',       lastSeen:'2s ago'  },
    { id:'T-12', label:'Sauces #2',      area:'sauces', status:'idle',     user:null,            version:'1.2.3',       scale:'CSW-410',        printer:'Zebra ZD421',       lastSeen:'1m ago'  },
    { id:'T-15', label:'Meat prep',      area:'meat',   status:'online',   user:'Tom Walsh',     version:'1.2.3',       scale:'Mettler BBA242', printer:'Honeywell PM43',    lastSeen:'14s ago' },
    { id:'T-18', label:'Dry goods',      area:'dry',    status:'online',   user:'Hana Kowalski', version:'1.2.3',       scale:'CSW-410',        printer:'Zebra ZD421',       lastSeen:'8s ago'  },
    { id:'T-22', label:'QA bench',       area:'dairy',  status:'updating', user:null,            version:'1.2.2→1.2.3', scale:'Rinstrun R420',  printer:'Zebra ZD421',       lastSeen:'updating'},
  ];

  readonly users: User[] = [
    { id:'u1',  name:'Claire Bennett',  email:'claire.bennett@applebyfoods.co.uk',  role:'planner',  active:true,  last:'2m ago'  },
    { id:'u2',  name:'Dev Patel',       email:'dev.patel@applebyfoods.co.uk',       role:'manager',  active:true,  last:'1h ago'  },
    { id:'u3',  name:'Alex Doyle',      email:'alex.doyle@applebyfoods.co.uk',      role:'operator', active:true,  last:'now'     },
    { id:'u4',  name:'Priya Shah',      email:'priya.shah@applebyfoods.co.uk',      role:'operator', active:true,  last:'now'     },
    { id:'u5',  name:'Joe Mitchell',    email:'joe.mitchell@applebyfoods.co.uk',    role:'operator', active:true,  last:'now'     },
    { id:'u6',  name:'Sam Okafor',      email:'sam.okafor@applebyfoods.co.uk',      role:'operator', active:true,  last:'4m ago'  },
    { id:'u7',  name:'Mei Chen',        email:'mei.chen@applebyfoods.co.uk',        role:'operator', active:true,  last:'now'     },
    { id:'u8',  name:'Tom Walsh',       email:'tom.walsh@applebyfoods.co.uk',       role:'operator', active:true,  last:'now'     },
    { id:'u9',  name:'Hana Kowalski',   email:'hana.kowalski@applebyfoods.co.uk',   role:'operator', active:true,  last:'now'     },
    { id:'u10', name:'Raj Singh',       email:'raj.singh@applebyfoods.co.uk',       role:'qa',       active:true,  last:'22m ago' },
    { id:'u11', name:'Ellie Foster',    email:'ellie.foster@applebyfoods.co.uk',    role:'qa',       active:true,  last:'3h ago'  },
    { id:'u12', name:'Harriet Cole',    email:'harriet.cole@applebyfoods.co.uk',    role:'manager',  active:false, last:'12d ago' },
  ];

  readonly roleMeta: Record<string, RoleMeta> = {
    operator: { label:'Operator', desc:'Performs weighing at terminals.',        color:'neutral' },
    planner:  { label:'Planner',  desc:'Schedules orders & edits recipes.',      color:'info'    },
    qa:       { label:'QA',       desc:'Configures quality checks & allergens.', color:'success' },
    manager:  { label:'Manager',  desc:'Authorisations & fleet management.',     color:'warn'    },
  };

  readonly qaChecks: QaCheck[] = [
    { id:'q1', name:'Ingredient temperature within range', trigger:'per-ingredient', type:'numeric',  area:'dairy',  applies:['MLK-002','BUT-001'], required:true,  min:0,   max:6   },
    { id:'q2', name:'Allergen segregation confirmed',      trigger:'per-ingredient', type:'confirm',  area:'all',    applies:'allergen',            required:true  },
    { id:'q3', name:'No visible contamination',            trigger:'per-ingredient', type:'confirm',  area:'all',    applies:'all',                 required:true  },
    { id:'q4', name:'Mixer clean-down signed off',         trigger:'end-of-mix',     type:'initials', area:'sauces', applies:'',                    required:true  },
    { id:'q5', name:'pH reading within spec',              trigger:'end-of-mix',     type:'numeric',  area:'sauces', applies:'',                    required:true,  min:3.2, max:4.0 },
    { id:'q6', name:'Dough temperature after mix',         trigger:'end-of-mix',     type:'numeric',  area:'bakery', applies:'',                    required:true,  min:22,  max:26  },
    { id:'q7', name:'Visual check — colour & texture',     trigger:'end-of-mix',     type:'confirm',  area:'all',    applies:'',                    required:false },
  ];

  readonly allergenRules: AllergenRule[] = [
    { id:'r1', name:'Nuts run last on shared line',         scope:['nuts'],    policy:'run-last',   area:'dairy',  cleanMinutes:45, active:true  },
    { id:'r2', name:'Separate bakery line for gluten-free', scope:['gluten'],  policy:'segregate',  area:'bakery', cleanMinutes:30, active:true  },
    { id:'r3', name:'Sesame → mandatory clean-down',        scope:['sesame'],  policy:'clean-after',area:'sauces', cleanMinutes:30, active:true  },
    { id:'r4', name:'Egg products before dairy-only',       scope:['egg'],     policy:'run-before', area:'sauces', cleanMinutes:15, active:false },
  ];

  readonly audit: AuditEntry[] = [
    { t:'14:32', user:'Joe Mitchell',   action:'Weighing accepted',              target:'Order 200482 · Mix 3 · FLR-001',              kind:'ok'     },
    { t:'14:31', user:'Mei Chen',       action:'QA check passed',               target:'Order 200483 · Mix 1 · pH 3.6',               kind:'ok'     },
    { t:'14:28', user:'Claire Bennett', action:'Order scheduled',               target:'Order 200488 · SC-008 · 240 kg',              kind:'info'   },
    { t:'14:19', user:'Sam Okafor',     action:'Terminal offline',              target:'T-09 — Dairy weighing',                       kind:'warn'   },
    { t:'14:12', user:'Raj Singh',      action:'QA check updated',              target:'Dough temperature after mix (22–26°C)',       kind:'info'   },
    { t:'14:04', user:'Priya Shah',     action:'Out-of-tolerance (blocked)',     target:'Order 200482 · BR-014 · YST-002',             kind:'danger' },
    { t:'13:58', user:'Claire Bennett', action:'Recipe published',              target:'SC-008 Hellenic house mayonnaise · v12',      kind:'info'   },
    { t:'13:47', user:'Dev Patel',      action:'Ingredient substitution approved',target:'Order 200478 · OIL-004 → OIL-005',          kind:'warn'   },
  ];

  // ---- helpers ----
  prepAreaName(id: string): string { return this.prepAreas.find(p => p.id === id)?.name ?? id; }
  allergenName(id: string): string { return this.allergens.find(a => a.id === id)?.name ?? id; }

  ingredient(code: string): Ingredient | undefined { return this.ingredients.find(i => i.code === code); }
  recipe(code: string): Recipe | undefined { return this.recipes.find(r => r.code === code); }

  recipeAllergens(code: string): string[] {
    const r = this.recipe(code);
    if (!r) return [];
    const set = new Set<string>();
    r.lines.forEach(l => this.ingredient(l.code)?.allergens.forEach(a => set.add(a)));
    return [...set];
  }

  recipeCost(code: string, qty = 100): number {
    const r = this.recipe(code);
    if (!r) return 0;
    return r.lines.reduce((acc, l) => {
      const ing = this.ingredient(l.code);
      return acc + (ing ? (l.pct / 100) * qty * ing.cost : 0);
    }, 0);
  }

  fmt(n: number, dp = 2): string { return n.toLocaleString('en-GB', { minimumFractionDigits: dp, maximumFractionDigits: dp }); }
  fmt0(n: number): string { return n.toLocaleString('en-GB'); }

  statusChip(status: string): { label: string; cls: string } {
    return STATUS_CHIP[status] ?? { label: status, cls: 'chip--neutral' };
  }
}
