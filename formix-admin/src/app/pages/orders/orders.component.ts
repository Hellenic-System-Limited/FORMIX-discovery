import { Component, inject, signal, computed } from '@angular/core';
import { NgClass } from '@angular/common';
import { DataService, Order } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { DrawerComponent } from '../../shared/drawer/drawer.component';
import { IconComponent } from '../../shared/icon/icon.component';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-orders',
  standalone: true,
  imports: [NgClass, IconComponent, DrawerComponent, FormsModule],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Orders</div>
          <div class="page__desc">Create orders from recipes. Mix sizes are calculated from order quantity and pushed to terminals filtered by prep area.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--secondary"><app-icon name="calendar" [size]="16"/>Schedule view</button>
          <button class="btn btn--primary" (click)="newOpen.set(true)"><app-icon name="plus" [size]="16"/>New order</button>
        </div>
      </div>

      <!-- Tabs -->
      <div class="tabs">
        @for (t of tabs; track t.id) {
          <button class="tab" [class.tab--active]="activeTab() === t.id" (click)="activeTab.set(t.id)">
            {{ t.label }} <span style="margin-left:8px;font-size:12px;color:var(--hs-fg-3)">{{ countsFor(t.id) }}</span>
          </button>
        }
      </div>

      <div class="filter-bar" style="margin-top:16px">
        <div class="input-group" style="flex:0 1 320px">
          <app-icon name="search" [size]="16"/>
          <input class="input" placeholder="Search by number or recipe…" [(ngModel)]="query"/>
        </div>
        <select class="select" style="width:200px" [(ngModel)]="areaFilter">
          <option value="all">All prep areas</option>
          @for (p of data.prepAreas; track p.id) {
            <option [value]="p.id">{{ p.name }}</option>
          }
        </select>
        <div style="margin-left:auto;font-size:13px;color:var(--hs-fg-3)">{{ filtered().length }} orders</div>
      </div>

      <div class="card" style="overflow:hidden">
        <table class="tbl">
          <thead><tr>
            <th style="width:100px">Order</th>
            <th>Recipe</th>
            <th style="width:140px">Prep area</th>
            <th class="num" style="width:100px">Quantity</th>
            <th style="width:180px">Mixes</th>
            <th style="width:140px">Due</th>
            <th style="width:110px">Terminal</th>
            <th style="width:120px">Status</th>
          </tr></thead>
          <tbody>
            @for (o of filtered(); track o.num) {
              <tr (click)="selected.set(o.num)">
                <td class="mono" style="font-weight:700">#{{ o.num }}</td>
                <td>
                  <div style="font-weight:600">{{ data.recipe(o.recipe)?.name }}</div>
                  <div style="font-size:12px;color:var(--hs-fg-3)">{{ o.recipe }} · v{{ data.recipe(o.recipe)?.version }}</div>
                </td>
                <td><span class="chip chip--neutral">{{ data.prepAreaName(o.area) }}</span></td>
                <td class="num mono"><b>{{ o.qty }}</b> {{ o.unit }}</td>
                <td>
                  <div style="display:flex;align-items:center;gap:10px">
                    <div class="progress" style="flex:1;max-width:120px">
                      <div class="progress__fill" [class.progress__fill--success]="o.status==='complete'" [style.width.%]="o.progress"></div>
                    </div>
                    <div style="font-size:12px;color:var(--hs-fg-2);font-variant-numeric:tabular-nums">{{ o.mixesDone }}/{{ o.mixes }}</div>
                  </div>
                </td>
                <td class="muted mono">{{ o.due.split(' ')[1] }} · {{ o.due.split(' ')[0].slice(8) }}</td>
                <td>
                  @if (o.terminal) {
                    <span class="chip chip--info chip--dot">{{ o.terminal }}</span>
                  } @else {
                    <span style="color:var(--hs-fg-muted)">—</span>
                  }
                </td>
                <td><span class="chip chip--dot" [ngClass]="data.statusChip(o.status).cls">{{ data.statusChip(o.status).label }}</span></td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      <!-- Order detail drawer -->
      <app-drawer [open]="!!selected()" [title]="selected() ? 'Order #' + selected() : ''" [hasFooter]="true" (close)="selected.set(null)">
        @if (selectedOrder()) {
          <div>
            <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px">
              @for (s of orderStats(); track s.l) {
                <div>
                  <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-fg-3);font-weight:600;margin-bottom:2px">{{ s.l }}</div>
                  <div style="font-size:18px;font-weight:600;font-variant-numeric:tabular-nums">{{ s.v }}</div>
                </div>
              }
            </div>
            <div style="display:flex;gap:12px;align-items:center;margin-bottom:12px">
              <span class="chip chip--dot" [ngClass]="data.statusChip(selectedOrder()!.status).cls">{{ data.statusChip(selectedOrder()!.status).label }}</span>
              @if (selectedOrder()!.terminal) {
                <span class="chip chip--info chip--dot">Locked to {{ selectedOrder()!.terminal }}</span>
              }
              <div style="margin-left:auto;font-size:12px;color:var(--hs-fg-3)">Scheduled by Claire Bennett · 14:28</div>
            </div>
            <div class="card card--flat" style="padding:16px;margin-bottom:16px">
              <div style="display:flex;align-items:center;gap:12px">
                <div class="icon-tile icon-tile--purple"><app-icon name="book" [size]="18"/></div>
                <div style="flex:1">
                  <div style="font-weight:600">{{ data.recipe(selectedOrder()!.recipe)?.name }}</div>
                  <div style="font-size:12px;color:var(--hs-fg-3)">{{ selectedOrder()!.recipe }} · v{{ data.recipe(selectedOrder()!.recipe)?.version }} · {{ data.prepAreaName(selectedOrder()!.area) }}</div>
                </div>
                <div style="font-size:13px;color:var(--hs-fg-2)">
                  <span class="mono" style="font-weight:600">£{{ data.fmt(data.recipeCost(selectedOrder()!.recipe, selectedOrder()!.qty), 2) }}</span> materials
                </div>
              </div>
              @if (selectedAllergens().length) {
                <div style="margin-top:10px;padding-top:10px;border-top:1px solid var(--hs-border)">
                  @for (id of selectedAllergens(); track id) {
                    <span class="chip chip--allergen" style="margin-right:4px">{{ data.allergenName(id) }}</span>
                  }
                </div>
              }
            </div>
            <h4 class="section-title">Mix breakdown</h4>
            <table class="tbl" style="border:1px solid var(--hs-border);border-radius:10px">
              <thead><tr>
                <th style="width:60px">Mix</th>
                <th class="num" style="width:120px">Target</th>
                <th class="num" style="width:120px">Actual</th>
                <th>Status</th><th>QA</th>
              </tr></thead>
              <tbody>
                @for (mix of mixRows(); track mix.idx) {
                  <tr style="cursor:default">
                    <td class="mono" style="font-weight:600">#{{ mix.idx }}</td>
                    <td class="num mono">{{ data.fmt(mix.target, 1) }} kg</td>
                    <td class="num mono">
                      @if (mix.done) { {{ data.fmt(mix.target + (Math.random() - 0.5) * 0.8, 2) }} kg }
                      @else if (mix.active) { <span style="color:var(--hs-purple-700)">weighing…</span> }
                      @else { — }
                    </td>
                    <td>
                      @if (mix.done) { <span class="chip chip--success chip--dot">complete</span> }
                      @else if (mix.active) { <span class="chip chip--info chip--dot">in progress</span> }
                      @else { <span class="chip chip--neutral chip--dot">scheduled</span> }
                    </td>
                    <td style="font-size:13px;color:var(--hs-fg-2)">
                      @if (mix.done) { <app-icon name="check" [size]="14" style="color:var(--hs-success);vertical-align:-2px"/> 4/4 passed }
                      @else if (mix.active) { 1/4 pending }
                      @else { — }
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        }
        <ng-container slot="footer">
          <button class="btn btn--danger">Abandon order</button>
          <button class="btn btn--secondary"><app-icon name="printer" [size]="16"/>Reprint labels</button>
          <button class="btn btn--primary"><app-icon name="check" [size]="16"/>Authorise</button>
        </ng-container>
      </app-drawer>

      <!-- New order drawer -->
      <app-drawer [open]="newOpen()" title="Schedule new order" width="520px" [hasFooter]="true" (close)="newOpen.set(false)">
        <div style="display:flex;flex-direction:column;gap:16px">
          <div class="field">
            <label class="field__label">Recipe</label>
            <select class="select" [(ngModel)]="newRecipe">
              @for (r of activeRecipes; track r.code) {
                <option [value]="r.code">{{ r.code }} · {{ r.name }}</option>
              }
            </select>
            <div class="field__hint">Prep area: <b>{{ data.prepAreaName(data.recipe(newRecipe)?.prepArea ?? '') }}</b> · v{{ data.recipe(newRecipe)?.version }}</div>
          </div>
          <div class="field">
            <label class="field__label">Total quantity (kg)</label>
            <input class="input" type="number" [(ngModel)]="newQty"/>
            <div class="field__hint">System will split into mixes of up to 60 kg max per container.</div>
          </div>
          <div class="field">
            <label class="field__label">Due date &amp; time</label>
            <input class="input" type="datetime-local" value="2026-04-25T06:00"/>
          </div>
          <div class="field">
            <label class="field__label">Planner notes (optional)</label>
            <textarea class="textarea" placeholder="e.g. prioritise for 8 AM despatch"></textarea>
          </div>
          <div class="card card--flat" style="padding:16px;background:var(--hs-midnight-50);border:1px solid var(--hs-midnight-100)">
            <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-midnight-700);font-weight:600;margin-bottom:8px">Calculated plan</div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;font-size:13px">
              <div><div style="color:var(--hs-fg-3)">Mixes</div><div style="font-size:18px;font-weight:600">{{ newMixCount }} × {{ data.fmt(newQty / newMixCount, 1) }} kg</div></div>
              <div><div style="color:var(--hs-fg-3)">Ingredients</div><div style="font-size:18px;font-weight:600">{{ data.recipe(newRecipe)?.lines?.length ?? 0 }} lines</div></div>
              <div><div style="color:var(--hs-fg-3)">Material cost</div><div style="font-size:18px;font-weight:600" class="mono">£{{ data.fmt(data.recipeCost(newRecipe, newQty), 2) }}</div></div>
              <div><div style="color:var(--hs-fg-3)">Eligible terminals</div><div style="font-size:18px;font-weight:600">3 in {{ data.prepAreaName(data.recipe(newRecipe)?.prepArea ?? '') }}</div></div>
            </div>
          </div>
        </div>
        <ng-container slot="footer">
          <button class="btn btn--secondary" (click)="newOpen.set(false)">Cancel</button>
          <button class="btn btn--primary" (click)="scheduleOrder()"><app-icon name="check" [size]="16"/>Schedule order</button>
        </ng-container>
      </app-drawer>
    </div>
  `,
})
export class OrdersComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  activeTab = signal('all');
  query = '';
  areaFilter = 'all';
  selected = signal<number | null>(null);
  newOpen = signal(false);
  newRecipe = 'BR-014';
  newQty = 240;
  readonly Math = Math;

  readonly tabs = [
    { id: 'all', label: 'All' },
    { id: 'scheduled', label: 'Scheduled' },
    { id: 'in-progress', label: 'In progress' },
    { id: 'on-hold', label: 'On hold' },
    { id: 'complete', label: 'Complete' },
  ];

  counts = computed((): Record<string, number> => ({
    all: this.data.orders.length,
    scheduled: this.data.orders.filter(o => o.status === 'scheduled').length,
    'in-progress': this.data.orders.filter(o => o.status === 'in-progress').length,
    'on-hold': this.data.orders.filter(o => o.status === 'on-hold').length,
    complete: this.data.orders.filter(o => o.status === 'complete').length,
  }));

  countsFor(id: string): number { return this.counts()[id] ?? 0; }

  filtered = computed(() => this.data.orders.filter(o => {
    if (this.activeTab() !== 'all' && o.status !== this.activeTab()) return false;
    if (this.areaFilter !== 'all' && o.area !== this.areaFilter) return false;
    const q = this.query.toLowerCase();
    if (q && !String(o.num).includes(q) && !(this.data.recipe(o.recipe)?.name.toLowerCase().includes(q))) return false;
    return true;
  }));

  selectedOrder = computed(() => this.selected() ? this.data.orders.find(o => o.num === this.selected()) : null);
  selectedAllergens = computed(() => this.selected() ? this.data.recipeAllergens(this.data.orders.find(o => o.num === this.selected())?.recipe ?? '') : []);

  orderStats = computed(() => {
    const o = this.selectedOrder();
    if (!o) return [];
    const mixSize = o.qty / o.mixes;
    return [
      { l: 'Quantity', v: `${o.qty} ${o.unit}` },
      { l: 'Mixes',    v: `${o.mixes} × ${this.data.fmt(mixSize, 1)} ${o.unit}` },
      { l: 'Due',      v: o.due.split(' ')[1] },
      { l: 'Progress', v: `${o.progress}%` },
    ];
  });

  mixRows = computed(() => {
    const o = this.selectedOrder();
    if (!o) return [];
    const mixSize = o.qty / o.mixes;
    return Array.from({ length: o.mixes }, (_, i) => ({
      idx: i + 1,
      target: mixSize,
      done: i < o.mixesDone,
      active: i === o.mixesDone && o.status === 'in-progress',
    }));
  });

  get activeRecipes() { return this.data.recipes.filter(r => r.status === 'active'); }
  get newMixCount() { return Math.ceil(this.newQty / 60); }

  scheduleOrder() {
    this.toast.push('Order scheduled');
    this.newOpen.set(false);
  }
}
