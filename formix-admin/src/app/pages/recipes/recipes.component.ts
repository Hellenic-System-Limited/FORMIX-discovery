import { Component, inject, signal, computed } from '@angular/core';
import { NgClass } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { DataService, SEG_COLORS } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { DrawerComponent } from '../../shared/drawer/drawer.component';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-recipes',
  standalone: true,
  imports: [NgClass, FormsModule, DrawerComponent, IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Recipes</div>
          <div class="page__desc">Define ingredient proportions, tolerances and QA checks. Recipes flow down to every terminal on next sync.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--secondary"><app-icon name="upload" [size]="16"/>Import</button>
          <button class="btn btn--primary" (click)="toast.push('New recipe draft created')"><app-icon name="plus" [size]="16"/>New recipe</button>
        </div>
      </div>

      <div class="filter-bar">
        <div class="input-group" style="flex:0 1 360px">
          <app-icon name="search" [size]="16"/>
          <input class="input" placeholder="Search by name or code…" [(ngModel)]="query"/>
        </div>
        <select class="select" style="width:200px" [(ngModel)]="areaFilter">
          <option value="all">All prep areas</option>
          @for (p of data.prepAreas; track p.id) {
            <option [value]="p.id">{{ p.name }}</option>
          }
        </select>
        <select class="select" style="width:160px" [(ngModel)]="statusFilter">
          <option value="all">Any status</option>
          <option value="active">Active</option>
          <option value="draft">Draft</option>
        </select>
        <div style="margin-left:auto;font-size:13px;color:var(--hs-fg-3)">{{ filtered().length }} of {{ data.recipes.length }}</div>
      </div>

      <div class="card" style="overflow:hidden">
        <table class="tbl">
          <thead><tr>
            <th style="width:110px">Code</th>
            <th>Name</th>
            <th style="width:140px">Prep area</th>
            <th>Allergens</th>
            <th style="width:120px">Composition</th>
            <th class="num" style="width:90px">Cost / kg</th>
            <th style="width:80px">Ver.</th>
            <th style="width:110px">Status</th>
          </tr></thead>
          <tbody>
            @for (r of filtered(); track r.code) {
              <tr (click)="selected.set(r.code)">
                <td class="mono" style="font-weight:600">{{ r.code }}</td>
                <td>
                  <div style="font-weight:600">{{ r.name }}</div>
                  <div style="font-size:12px;color:var(--hs-fg-3)">{{ r.description }}</div>
                </td>
                <td><span class="chip chip--neutral">{{ data.prepAreaName(r.prepArea) }}</span></td>
                <td>
                  @if (data.recipeAllergens(r.code).length) {
                    @for (id of data.recipeAllergens(r.code); track id) {
                      <span class="chip chip--allergen" style="margin-right:3px;font-size:10px;padding:2px 7px">{{ data.allergenName(id) }}</span>
                    }
                  } @else {
                    <span style="color:var(--hs-fg-muted);font-size:12px">none</span>
                  }
                </td>
                <td>
                  <div class="comp-bar" style="width:110px">
                    @for (l of r.lines; track l.code; let i = $index) {
                      <div class="comp-bar__seg" [style.width.%]="l.pct" [style.background]="segColor(i)"></div>
                    }
                  </div>
                </td>
                <td class="num mono">£{{ data.fmt(data.recipeCost(r.code, 1)) }}</td>
                <td class="mono">v{{ r.version }}</td>
                <td><span class="chip chip--dot" [ngClass]="data.statusChip(r.status).cls">{{ data.statusChip(r.status).label }}</span></td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      <!-- Recipe editor drawer -->
      <app-drawer [open]="!!selected()" [title]="selected() ? selected() + ' · ' + data.recipe(selected()!)?.name : ''" [hasFooter]="true" (close)="selected.set(null)">
        @if (selected()) {
          <div>
            <!-- Meta row -->
            <div style="display:flex;gap:12px;margin-bottom:16px;flex-wrap:wrap">
              @for (m of recipeMeta(); track m.label) {
                <div style="flex:1;min-width:200px">
                  <div style="font-size:11px;color:var(--hs-fg-3);text-transform:uppercase;letter-spacing:.06em;font-weight:600;margin-bottom:4px">{{ m.label }}</div>
                  <div style="font-size:15px;font-weight:600">{{ m.value }}</div>
                </div>
              }
            </div>
            <!-- Allergen warning -->
            @if (selectedAllergens().length) {
              <div style="background:var(--hs-warning-bg);border-radius:10px;padding:12px 16px;margin-bottom:16px;display:flex;gap:12px;align-items:flex-start">
                <app-icon name="alert" [size]="18" style="color:var(--hs-warning);flex-shrink:0;margin-top:2px"/>
                <div style="flex:1">
                  <div style="font-weight:600;font-size:13px;color:var(--hs-warning);margin-bottom:4px">Contains declarable allergens</div>
                  @for (id of selectedAllergens(); track id) {
                    <span class="chip chip--allergen" style="margin-right:4px">{{ data.allergenName(id) }}</span>
                  }
                  <div style="font-size:12px;color:var(--hs-fg-2);margin-top:6px">These words will appear in <b>BOLD UPPERCASE</b> on every mix and ingredient label.</div>
                </div>
              </div>
            }
            <!-- Tabs -->
            <div class="tabs">
              @for (t of editorTabs; track t.id) {
                <button class="tab" [class.tab--active]="editorTab() === t.id" (click)="editorTab.set(t.id)">{{ t.label }}</button>
              }
            </div>
            <div style="margin-top:16px">
              @if (editorTab() === 'composition') {
                <div>
                  <div style="display:flex;gap:12px;align-items:center;margin-bottom:12px">
                    <label class="field" style="flex:0 0 auto">
                      <span class="field__label">Preview mix size</span>
                    </label>
                    <input type="number" class="input" style="width:120px" [(ngModel)]="mixSize"/>
                    <span style="color:var(--hs-fg-3);font-size:13px">kg</span>
                    <div style="margin-left:auto;font-size:13px;font-weight:600" [style.color]="linesTotal() === 100 ? 'var(--hs-success)' : 'var(--hs-pink-700)'">
                      <app-icon [name]="linesTotal() === 100 ? 'check' : 'alert'" [size]="14"/>
                      Total: {{ data.fmt(linesTotal()) }}%
                    </div>
                  </div>
                  <div class="comp-bar">
                    @for (l of data.recipe(selected()!)!.lines; track l.code; let i = $index) {
                      <div class="comp-bar__seg" [style.width.%]="l.pct" [style.background]="segColor(i)"
                           [title]="data.ingredient(l.code)?.name + ' — ' + l.pct + '%'"></div>
                    }
                  </div>
                  <div class="legend" style="margin:8px 0 16px">
                    @for (l of data.recipe(selected()!)!.lines; track l.code; let i = $index) {
                      <div>
                        <span class="legend__dot" [style.background]="segColor(i)"></span>
                        {{ data.ingredient(l.code)?.name }} {{ l.pct }}%
                      </div>
                    }
                  </div>
                  <table class="tbl" style="border:1px solid var(--hs-border);border-radius:10px">
                    <thead><tr>
                      <th style="width:32px">#</th>
                      <th>Ingredient</th>
                      <th>Allergens</th>
                      <th class="num" style="width:70px">%</th>
                      <th class="num" style="width:110px">Qty / {{ mixSize }}kg</th>
                      <th style="width:150px">Tolerance</th>
                      <th style="width:36px"></th>
                    </tr></thead>
                    <tbody>
                      @for (l of data.recipe(selected()!)!.lines; track l.code; let i = $index) {
                        <tr style="cursor:default">
                          <td class="mono" style="color:var(--hs-fg-3)">{{ i + 1 }}</td>
                          <td>
                            <div style="font-weight:600">{{ data.ingredient(l.code)?.name }}</div>
                            <div style="font-size:11px;color:var(--hs-fg-3)" class="mono">{{ l.code }}</div>
                          </td>
                          <td>
                            @if (data.ingredient(l.code)?.allergens?.length) {
                              @for (a of data.ingredient(l.code)!.allergens; track a) {
                                <span class="chip chip--allergen" style="font-size:10px;padding:2px 7px;margin-right:3px">{{ data.allergenName(a) }}</span>
                              }
                            } @else {
                              <span style="color:var(--hs-fg-muted);font-size:12px">none</span>
                            }
                          </td>
                          <td class="num mono">{{ data.fmt(l.pct) }}</td>
                          <td class="num mono">{{ data.fmt((l.pct / 100) * mixSize) }} {{ data.ingredient(l.code)?.unit }}</td>
                          <td class="mono" style="font-size:13px;color:var(--hs-fg-2)">±{{ l.tol[0] }}% / ±{{ l.tol[1] }}%</td>
                          <td><button class="btn btn--ghost btn--icon btn--sm"><app-icon name="edit" [size]="14"/></button></td>
                        </tr>
                      }
                    </tbody>
                  </table>
                  <button class="btn btn--ghost btn--sm" style="margin-top:10px"><app-icon name="plus" [size]="14"/>Add ingredient line</button>
                </div>
              }
              @if (editorTab() === 'history') {
                <div style="display:flex;flex-direction:column;gap:8px">
                  @for (v of versionHistory(); track v.v) {
                    <div style="display:flex;gap:12px;padding:12px;border:1px solid var(--hs-border);border-radius:8px">
                      <span class="chip chip--info">v{{ v.v }}</span>
                      <div style="flex:1">
                        <div style="font-size:13px;font-weight:600">{{ v.note }}</div>
                        <div style="font-size:12px;color:var(--hs-fg-3);margin-top:2px">{{ v.date }} · {{ v.by }}</div>
                      </div>
                      <button class="btn btn--ghost btn--sm">Restore</button>
                    </div>
                  }
                </div>
              }
              @if (editorTab() === 'process') {
                <div class="empty">
                  <div class="empty__icon"><app-icon name="clock" [size]="32"/></div>
                  <div class="empty__title">No process steps</div>
                  <div>Add non-weighing steps (e.g. "stir for 3 minutes") with terminal lock. Enterprise tier.</div>
                  <div style="margin-top:12px"><button class="btn btn--secondary"><app-icon name="plus" [size]="14"/>Add process step</button></div>
                </div>
              }
            </div>
          </div>
        }
        <ng-container slot="footer">
          <button class="btn btn--danger"><app-icon name="trash" [size]="16"/>Archive</button>
          <button class="btn btn--secondary"><app-icon name="copy" [size]="16"/>Duplicate</button>
          <button class="btn btn--primary" (click)="save()"><app-icon name="check" [size]="16"/>Save changes</button>
        </ng-container>
      </app-drawer>
    </div>
  `,
})
export class RecipesComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  query = '';
  areaFilter = 'all';
  statusFilter = 'all';
  selected = signal<string | null>(null);
  editorTab = signal('composition');
  mixSize = 60;

  readonly editorTabs = [
    { id: 'composition', label: 'Composition' },
    { id: 'history', label: 'Version history' },
    { id: 'process', label: 'Process steps' },
  ];

  filtered = computed(() => this.data.recipes.filter(r => {
    const q = this.query.toLowerCase();
    if (q && !r.name.toLowerCase().includes(q) && !r.code.toLowerCase().includes(q)) return false;
    if (this.areaFilter !== 'all' && r.prepArea !== this.areaFilter) return false;
    if (this.statusFilter !== 'all' && r.status !== this.statusFilter) return false;
    return true;
  }));

  selectedAllergens = computed(() => this.selected() ? this.data.recipeAllergens(this.selected()!) : []);

  recipeMeta = computed(() => {
    const r = this.data.recipe(this.selected() ?? '');
    if (!r) return [];
    return [
      { label: 'Prep area', value: this.data.prepAreaName(r.prepArea) },
      { label: 'Spec', value: 'Percentage' },
      { label: 'Version', value: `v${r.version} · updated ${r.updated}` },
    ];
  });

  linesTotal = computed(() => {
    const r = this.data.recipe(this.selected() ?? '');
    return r ? r.lines.reduce((a, l) => a + l.pct, 0) : 0;
  });

  versionHistory = computed(() => {
    const r = this.data.recipe(this.selected() ?? '');
    if (!r) return [];
    return [
      { v: r.version,     date: r.updated,    by: 'Claire Bennett', note: 'Adjusted yeast to 0.8% for summer ambient temps.' },
      { v: r.version - 1, date: '2026-03-22', by: 'Claire Bennett', note: 'Tightened salt tolerance to ±5%.' },
      { v: r.version - 2, date: '2026-02-14', by: 'Raj Singh',      note: 'Added "dough temperature" end-of-mix QA check.' },
    ].filter(v => v.v > 0);
  });

  segColor(i: number): string { return SEG_COLORS[i % SEG_COLORS.length]; }

  save() { this.toast.push('Recipe saved'); this.selected.set(null); }
}
