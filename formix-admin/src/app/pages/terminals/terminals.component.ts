import { Component, inject, signal, computed } from '@angular/core';
import { NgClass } from '@angular/common';
import { DataService } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { DrawerComponent } from '../../shared/drawer/drawer.component';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-terminals',
  standalone: true,
  imports: [NgClass, DrawerComponent, IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Terminal fleet</div>
          <div class="page__desc">Industrial touchscreen terminals on the shop floor. Managed rollout with rollback to one previous version.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--secondary" (click)="toast.push('Update pushed to all terminals')"><app-icon name="sync" [size]="16"/>Push update</button>
          <button class="btn btn--primary" (click)="toast.push('Terminal registered')"><app-icon name="plus" [size]="16"/>Register terminal</button>
        </div>
      </div>

      <div class="grid grid--kpi" style="margin-bottom:20px">
        <div class="stat">
          <div class="stat__label">Online</div>
          <div class="stat__value" style="color:var(--hs-success)">{{ onlineCount }}</div>
        </div>
        <div class="stat">
          <div class="stat__label">Offline</div>
          <div class="stat__value" style="color:var(--hs-pink-700)">{{ offlineCount }}</div>
        </div>
        <div class="stat">
          <div class="stat__label">Updating</div>
          <div class="stat__value" style="color:var(--hs-purple-700)">{{ updatingCount }}</div>
        </div>
        <div class="stat">
          <div class="stat__label">Current version</div>
          <div class="stat__value mono">1.2.3</div>
        </div>
      </div>

      <div class="grid" style="grid-template-columns:repeat(auto-fill,minmax(300px,1fr))">
        @for (t of data.terminals; track t.id) {
          <div class="terminal-card" (click)="selected.set(t.id)">
            <div [class]="iconTileClass(t.status)"><app-icon name="terminal" [size]="18"/></div>
            <div style="flex:1;min-width:0">
              <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px">
                <div style="font-weight:700;font-size:15px">{{ t.id }}</div>
                <span class="chip chip--dot" [ngClass]="data.statusChip(t.status).cls">{{ data.statusChip(t.status).label }}</span>
              </div>
              <div style="font-size:13px;color:var(--hs-fg-2);margin-bottom:8px">{{ t.label }} · {{ data.prepAreaName(t.area) }}</div>
              <div style="font-size:12px;color:var(--hs-fg-3);display:flex;flex-direction:column;gap:2px">
                <div><app-icon name="scale" [size]="12" style="vertical-align:-2px"/> {{ t.scale }}</div>
                <div><app-icon name="printer" [size]="12" style="vertical-align:-2px"/> {{ t.printer }}</div>
                <div style="margin-top:4px;display:flex;gap:8px;align-items:center">
                  <span class="mono">v{{ t.version }}</span>
                  <span>·</span>
                  <span>{{ t.user || 'idle' }}</span>
                  <span style="margin-left:auto;font-size:11px">{{ t.lastSeen }}</span>
                </div>
              </div>
            </div>
          </div>
        }
      </div>

      <!-- Terminal detail drawer -->
      <app-drawer [open]="!!selected()" [title]="drawerTitle()" [hasFooter]="true" (close)="selected.set(null)">
        @if (selectedTerminal()) {
          @let t = selectedTerminal()!;
          <div style="display:flex;flex-direction:column;gap:16px">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
              <div>
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-fg-3);font-weight:600">Status</div>
                <span class="chip chip--dot" [ngClass]="data.statusChip(t.status).cls">{{ data.statusChip(t.status).label }}</span>
              </div>
              <div>
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-fg-3);font-weight:600">Prep area</div>
                <span class="chip chip--neutral">{{ data.prepAreaName(t.area) }}</span>
              </div>
              <div>
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-fg-3);font-weight:600">Current operator</div>
                <div style="font-weight:600">{{ t.user || 'idle' }}</div>
              </div>
              <div>
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--hs-fg-3);font-weight:600">App version</div>
                <div class="mono" style="font-weight:600">{{ t.version }}</div>
              </div>
            </div>

            <div class="card card--flat" style="padding:14px">
              <div style="font-weight:600;margin-bottom:10px">Hardware</div>
              <div style="display:flex;gap:10px;align-items:center;margin-bottom:8px">
                <app-icon name="scale" [size]="16" style="color:var(--hs-fg-2)"/>
                <div style="flex:1">{{ t.scale }}</div>
                <span class="chip chip--success chip--dot">connected</span>
              </div>
              <div style="display:flex;gap:10px;align-items:center;margin-bottom:8px">
                <app-icon name="printer" [size]="16" style="color:var(--hs-fg-2)"/>
                <div style="flex:1">{{ t.printer }}</div>
                <span class="chip chip--success chip--dot">connected</span>
              </div>
              <div style="display:flex;gap:10px;align-items:center">
                <app-icon name="barcode" [size]="16" style="color:var(--hs-fg-2)"/>
                <div style="flex:1">Keyboard wedge scanner</div>
                <span class="chip chip--success chip--dot">connected</span>
              </div>
            </div>

            <div class="card card--flat" style="padding:14px">
              <div style="font-weight:600;margin-bottom:10px">Recent events</div>
              @for (e of recentEvents; track e.t; let i = $index) {
                <div [style]="'display:flex;gap:10px;padding:6px 0;border-top:' + (i ? '1px solid var(--hs-border)' : 'none') + ';font-size:13px'">
                  <span style="width:44px;color:var(--hs-fg-3)" class="mono">{{ e.t }}</span>
                  <span style="flex:1;font-weight:600">{{ e.e }}</span>
                  <span style="color:var(--hs-fg-3)">{{ e.d }}</span>
                </div>
              }
            </div>
          </div>
        }
        <ng-container slot="footer">
          <button class="btn btn--danger">Deregister</button>
          <button class="btn btn--secondary" (click)="toast.push('Sync forced')"><app-icon name="sync" [size]="16"/>Force sync</button>
          <button class="btn btn--primary" (click)="toast.push('Update pushed')"><app-icon name="upload" [size]="16"/>Push update</button>
        </ng-container>
      </app-drawer>
    </div>
  `,
})
export class TerminalsComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  selected = signal<string | null>(null);

  selectedTerminal = computed(() => this.selected() ? this.data.terminals.find(t => t.id === this.selected()) : undefined);
  drawerTitle = computed(() => {
    const t = this.selectedTerminal();
    return t ? `${t.id} · ${t.label}` : '';
  });

  get onlineCount() { return this.data.terminals.filter(t => t.status === 'online').length; }
  get offlineCount() { return this.data.terminals.filter(t => t.status === 'offline').length; }
  get updatingCount() { return this.data.terminals.filter(t => t.status === 'updating').length; }

  iconTileClass(status: string): string {
    if (status === 'offline') return 'icon-tile icon-tile--pink';
    if (status === 'updating') return 'icon-tile icon-tile--purple';
    return 'icon-tile icon-tile--success';
  }

  readonly recentEvents = [
    { t: '14:32', e: 'Weighing accepted',  d: '#200482 · FLR-001 · 18.04kg' },
    { t: '14:28', e: 'Mix complete',        d: '#200482 · Mix 2' },
    { t: '13:47', e: 'Sync with server',   d: '43 transactions · 2 orders' },
  ];
}
