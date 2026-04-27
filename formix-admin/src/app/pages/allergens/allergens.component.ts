import { Component, inject, signal } from '@angular/core';
import { NgClass } from '@angular/common';
import { DataService } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-allergens',
  standalone: true,
  imports: [NgClass, IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Allergen management</div>
          <div class="page__desc">Allergen register, sequencing rules and QA checks. Labels render allergens in <b>BOLD UPPERCASE</b> — a legal requirement.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--primary" (click)="toast.push('New rule created')"><app-icon name="plus" [size]="16"/>New rule</button>
        </div>
      </div>

      <div class="tabs">
        @for (t of tabs; track t.id) {
          <button class="tab" [class.tab--active]="activeTab() === t.id" (click)="activeTab.set(t.id)">
            {{ t.label }}
            @if (t.count !== undefined) {
              <span style="margin-left:8px;font-size:12px;color:var(--hs-fg-3)">{{ t.count }}</span>
            }
          </button>
        }
      </div>

      <div style="margin-top:16px">
        <!-- Register tab -->
        @if (activeTab() === 'register') {
          <div class="grid" style="grid-template-columns:repeat(auto-fill,minmax(260px,1fr))">
            @for (a of data.allergens; track a.id) {
              @let used = ingWithAllergen(a.id);
              <div class="card card--flat" style="padding:16px">
                <div style="display:flex;align-items:center;gap:12px;margin-bottom:10px">
                  <div class="icon-tile icon-tile--warn"><app-icon name="alert" [size]="18"/></div>
                  <div style="flex:1">
                    <div style="font-weight:600;font-size:15px">{{ a.name }}</div>
                    <div style="font-size:12px;color:var(--hs-fg-3)">{{ used }} ingredient{{ used !== 1 ? 's' : '' }}</div>
                  </div>
                </div>
                <div style="font-size:12px;color:var(--hs-fg-2);margin-bottom:6px">Label word</div>
                <div style="font-size:14px;background:var(--hs-midnight-700);color:white;padding:6px 10px;border-radius:6px;font-family:var(--hs-font-mono)">
                  {{ a.name.toUpperCase() }}
                </div>
              </div>
            }
          </div>
        }

        <!-- Rules tab -->
        @if (activeTab() === 'rules') {
          <div class="stack">
            <div class="card" style="padding:16px;background:var(--hs-info-bg);border:1px solid var(--hs-purple-100)">
              <div style="display:flex;gap:12px;align-items:flex-start">
                <app-icon name="help" [size]="20" style="color:var(--hs-purple-700);margin-top:2px"/>
                <div style="font-size:13px;color:var(--hs-fg-2)">
                  Sequencing rules govern production order on shared lines. Terminals enforce them synchronously — when offline, best-effort using local production history.
                </div>
              </div>
            </div>
            <div class="card" style="overflow:hidden">
              <table class="tbl">
                <thead><tr>
                  <th>Rule</th>
                  <th style="width:160px">Scope</th>
                  <th style="width:140px">Policy</th>
                  <th style="width:120px">Prep area</th>
                  <th class="num" style="width:120px">Clean-down</th>
                  <th style="width:90px">Status</th>
                  <th style="width:36px"></th>
                </tr></thead>
                <tbody>
                  @for (r of data.allergenRules; track r.id) {
                    <tr>
                      <td style="font-weight:600">{{ r.name }}</td>
                      <td>
                        @for (id of r.scope; track id) {
                          <span class="chip chip--allergen" style="margin-right:3px;font-size:10px;padding:2px 7px">{{ data.allergenName(id) }}</span>
                        }
                      </td>
                      <td><span class="chip chip--info">{{ r.policy }}</span></td>
                      <td class="muted">{{ data.prepAreaName(r.area) }}</td>
                      <td class="num mono">{{ r.cleanMinutes }} min</td>
                      <td>
                        <span class="chip chip--dot" [ngClass]="r.active ? 'chip--success' : 'chip--neutral'">{{ r.active ? 'active' : 'paused' }}</span>
                      </td>
                      <td><button class="btn btn--ghost btn--icon btn--sm"><app-icon name="edit" [size]="14"/></button></td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          </div>
        }

        <!-- Matrix tab -->
        @if (activeTab() === 'matrix') {
          <div class="card" style="overflow:auto">
            <table class="tbl">
              <thead><tr>
                <th style="width:260px">Ingredient</th>
                @for (a of data.allergens; track a.id) {
                  <th class="num" style="width:60px;writing-mode:vertical-rl;transform:rotate(180deg);padding:16px 4px">{{ a.name }}</th>
                }
              </tr></thead>
              <tbody>
                @for (i of ingredientsWithAllergens(); track i.code) {
                  <tr style="cursor:default">
                    <td>
                      <div style="font-weight:600">{{ i.name }}</div>
                      <div class="mono" style="font-size:11px;color:var(--hs-fg-3)">{{ i.code }}</div>
                    </td>
                    @for (a of data.allergens; track a.id) {
                      <td class="num" style="text-align:center">
                        @if (i.allergens.includes(a.id)) {
                          <div style="width:20px;height:20px;border-radius:4px;background:var(--hs-warning);color:white;display:inline-grid;place-items:center;font-size:12px;font-weight:700">✓</div>
                        } @else {
                          <span style="color:var(--hs-border-strong)">·</span>
                        }
                      </td>
                    }
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
      </div>
    </div>
  `,
})
export class AllergensComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  activeTab = signal('register');

  readonly tabs = [
    { id: 'register', label: 'Register',          count: 10 },
    { id: 'rules',    label: 'Sequencing rules',   count: 4  },
    { id: 'matrix',   label: 'Ingredient matrix',  count: undefined },
  ];

  ingWithAllergen(id: string): number {
    return this.data.ingredients.filter(i => i.allergens.includes(id)).length;
  }

  ingredientsWithAllergens() {
    return this.data.ingredients.filter(i => i.allergens.length > 0);
  }
}
