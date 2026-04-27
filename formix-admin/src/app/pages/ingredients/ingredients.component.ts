import { Component, inject, signal, computed } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DataService } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { DrawerComponent } from '../../shared/drawer/drawer.component';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-ingredients',
  standalone: true,
  imports: [FormsModule, DrawerComponent, IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Ingredients</div>
          <div class="page__desc">Master data. Allergens flow through to labels, QA checks and sequencing rules.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--secondary"><app-icon name="upload" [size]="16"/>Import CSV</button>
          <button class="btn btn--primary" (click)="toast.push('New ingredient created')"><app-icon name="plus" [size]="16"/>New ingredient</button>
        </div>
      </div>

      <div class="filter-bar">
        <div class="input-group" style="flex:0 1 360px">
          <app-icon name="search" [size]="16"/>
          <input class="input" placeholder="Search ingredients…" [(ngModel)]="query"/>
        </div>
        <select class="select" style="width:200px" [(ngModel)]="allergenFilter">
          <option value="all">Any allergen status</option>
          <option value="any">Contains allergens</option>
          <option value="none">No allergens</option>
          <optgroup label="Specific allergen">
            @for (a of data.allergens; track a.id) {
              <option [value]="a.id">{{ a.name }}</option>
            }
          </optgroup>
        </select>
        <div style="margin-left:auto;font-size:13px;color:var(--hs-fg-3)">{{ filtered().length }} of {{ data.ingredients.length }}</div>
      </div>

      <div class="card" style="overflow:hidden">
        <table class="tbl">
          <thead><tr>
            <th style="width:100px">Code</th>
            <th>Name</th>
            <th style="width:160px">Supplier</th>
            <th>Allergens</th>
            <th class="num" style="width:80px">Unit</th>
            <th class="num" style="width:100px">Cost</th>
            <th class="num" style="width:100px">Stock</th>
            <th class="num" style="width:90px">Use-by</th>
          </tr></thead>
          <tbody>
            @for (i of filtered(); track i.code) {
              <tr (click)="selected.set(i.code)">
                <td class="mono" style="font-weight:600">{{ i.code }}</td>
                <td style="font-weight:600">{{ i.name }}</td>
                <td class="muted">{{ i.supplier }}</td>
                <td>
                  @if (i.allergens.length) {
                    @for (id of i.allergens; track id) {
                      <span class="chip chip--allergen" style="margin-right:3px;font-size:10px;padding:2px 7px">{{ data.allergenName(id) }}</span>
                    }
                  } @else {
                    <span style="color:var(--hs-fg-muted);font-size:12px">none</span>
                  }
                </td>
                <td class="num mono">{{ i.unit }}</td>
                <td class="num mono">£{{ data.fmt(i.cost, 2) }}</td>
                <td class="num mono">{{ data.fmt0(i.stock) }}</td>
                <td class="num mono muted">{{ i.useBy ? i.useBy + ' d' : '—' }}</td>
              </tr>
            }
          </tbody>
        </table>
      </div>

      <!-- Ingredient editor drawer -->
      <app-drawer [open]="!!selected()" [title]="drawerTitle()" [hasFooter]="true" (close)="selected.set(null)">
        @if (selectedIng()) {
          <div style="display:flex;flex-direction:column;gap:16px">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
              <div class="field">
                <label class="field__label">Code</label>
                <input class="input mono" [value]="selectedIng()!.code" readonly/>
              </div>
              <div class="field">
                <label class="field__label">Unit of measure</label>
                <select class="select" [value]="selectedIng()!.unit">
                  <option>kg</option><option>L</option><option>g</option><option>ml</option><option>units</option>
                </select>
              </div>
            </div>
            <div class="field">
              <label class="field__label">Name</label>
              <input class="input" [value]="selectedIng()!.name"/>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
              <div class="field">
                <label class="field__label">Supplier</label>
                <input class="input" [value]="selectedIng()!.supplier"/>
              </div>
              <div class="field">
                <label class="field__label">Cost per {{ selectedIng()!.unit }}</label>
                <input class="input mono" [value]="selectedIng()!.cost"/>
              </div>
            </div>
            <div class="field">
              <label class="field__label">Use-by specification (days from receipt)</label>
              <input class="input mono" [value]="selectedIng()!.useBy ?? ''"/>
              <div class="field__hint">Used during weighing to validate source barcode dates.</div>
            </div>
            <div>
              <div class="field__label" style="margin-bottom:10px">Allergens</div>
              <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">
                @for (a of data.allergens; track a.id) {
                  @let checked = selectedIng()!.allergens.includes(a.id);
                  <label [style]="allergenLabelStyle(checked)">
                    <input type="checkbox" [checked]="checked" style="accent-color:var(--hs-warning)"/>
                    {{ a.name }}
                  </label>
                }
              </div>
              <div style="font-size:12px;color:var(--hs-fg-3);margin-top:8px">
                <app-icon name="alert" [size]="12" style="vertical-align:-1px;color:var(--hs-warning)"/>
                Allergen words will appear in <b>BOLD UPPERCASE</b> on labels — legally required (Food Information Regs 2014).
              </div>
            </div>
          </div>
        }
        <ng-container slot="footer">
          <button class="btn btn--danger"><app-icon name="trash" [size]="16"/>Archive</button>
          <button class="btn btn--primary" (click)="save()"><app-icon name="check" [size]="16"/>Save</button>
        </ng-container>
      </app-drawer>
    </div>
  `,
})
export class IngredientsComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  query = '';
  allergenFilter = 'all';
  selected = signal<string | null>(null);

  filtered = computed(() => this.data.ingredients.filter(i => {
    const q = this.query.toLowerCase();
    if (q && !i.name.toLowerCase().includes(q) && !i.code.toLowerCase().includes(q)) return false;
    if (this.allergenFilter === 'any' && i.allergens.length === 0) return false;
    if (this.allergenFilter === 'none' && i.allergens.length > 0) return false;
    if (this.allergenFilter !== 'all' && this.allergenFilter !== 'any' && this.allergenFilter !== 'none' && !i.allergens.includes(this.allergenFilter)) return false;
    return true;
  }));

  selectedIng = computed(() => this.selected() ? this.data.ingredient(this.selected()!) : undefined);
  drawerTitle = computed(() => this.selected() ? `${this.selected()} · ${this.selectedIng()?.name ?? ''}` : '');

  allergenLabelStyle(checked: boolean): string {
    return `display:flex;align-items:center;gap:8px;padding:8px 10px;border:1px solid ${checked ? 'var(--hs-warning)' : 'var(--hs-border)'};background:${checked ? 'var(--hs-warning-bg)' : 'white'};border-radius:8px;cursor:pointer;font-size:13px;font-weight:${checked ? 600 : 400}`;
  }

  save() { this.toast.push('Ingredient saved'); this.selected.set(null); }
}
