import { Component, inject } from '@angular/core';
import { NgClass } from '@angular/common';
import { DataService } from '../../core/data.service';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [IconComponent, NgClass],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Today · Thursday 24 April 2026</div>
          <div class="page__desc">Appleby Foods · Worcester site · 9 terminals · 27 active orders this week</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--secondary">
            <app-icon name="download" [size]="16"/>Export
          </button>
          <button class="btn btn--primary">
            <app-icon name="plus" [size]="16"/>Schedule order
          </button>
        </div>
      </div>

      <div class="grid grid--kpi" style="margin-bottom:20px">
        <div class="stat">
          <div class="stat__label">Orders in progress</div>
          <div class="stat__value">{{ inProg }}</div>
          <div class="stat__delta stat__delta--up">+2 vs. yesterday</div>
        </div>
        <div class="stat">
          <div class="stat__label">Completed today</div>
          <div class="stat__value">{{ complete }}</div>
          <div class="stat__delta stat__delta--up">on track</div>
        </div>
        <div class="stat">
          <div class="stat__label">Out-of-tolerance</div>
          <div class="stat__value">3</div>
          <div class="stat__delta stat__delta--down">blocked</div>
        </div>
        <div class="stat">
          <div class="stat__label">Terminals online</div>
          <div class="stat__value">{{ onlineTerminals }}/{{ data.terminals.length }}</div>
          <div class="stat__delta stat__delta--down">T-09 offline 4m</div>
        </div>
      </div>

      <div class="grid grid--sidebar" style="align-items:start">
        <div class="stack">
          <!-- Production schedule -->
          <div class="card">
            <div class="card__header">
              <div>
                <div class="card__title">Production schedule — today</div>
                <div class="card__desc">{{ ordersToday.length }} orders · grouped by prep area</div>
              </div>
              <div style="margin-left:auto">
                <button class="btn btn--ghost btn--sm">
                  <app-icon name="calendar" [size]="14"/>Week view
                </button>
              </div>
            </div>
            <div class="card__body" style="padding:0">
              <div style="padding:8px 20px 20px">
                <div style="display:grid;grid-template-columns:140px 1fr;gap:0;position:relative">
                  <div></div>
                  <div style="display:grid;grid-template-columns:repeat(12,1fr);border-bottom:1px solid var(--hs-border);padding-bottom:6px">
                    @for (h of hours; track h) {
                      <div style="font-size:11px;color:var(--hs-fg-3);font-variant-numeric:tabular-nums">
                        {{ padHour(h) }}:00
                      </div>
                    }
                  </div>
                  @for (area of scheduleAreas; track area.id) {
                    <div style="padding:10px 0;font-size:13px;font-weight:600;color:var(--hs-fg-2);border-bottom:1px solid var(--hs-border)">{{ area.name }}</div>
                    <div style="position:relative;min-height:44px;border-bottom:1px solid var(--hs-border)">
                      @for (o of ordersForArea(area.id); track o.num) {
                        <div [style]="orderBlockStyle(o)"
                             [title]="data.recipe(o.recipe)?.name + ' · ' + o.qty + o.unit + ' · #' + o.num">
                          <div style="font-weight:700">#{{ o.num }}</div>
                          <div style="text-overflow:ellipsis;overflow:hidden">{{ data.recipe(o.recipe)?.name }}</div>
                        </div>
                      }
                    </div>
                  }
                  <div></div>
                  <div style="position:absolute;top:24px;bottom:0;width:2px;background:var(--hs-pink-600);pointer-events:none"
                       [style.left]="nowLineLeft">
                    <div style="position:absolute;top:-8px;left:-20px;background:var(--hs-pink-600);color:white;font-size:10px;font-weight:700;padding:1px 6px;border-radius:3px">NOW</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Active mixes -->
          <div class="card">
            <div class="card__header">
              <div class="card__title">Active mixes</div>
              <div style="margin-left:auto"><button class="btn btn--ghost btn--sm">View all</button></div>
            </div>
            <div class="card__body" style="padding:0">
              <table class="tbl">
                <thead><tr>
                  <th>Order</th><th>Recipe</th><th>Terminal</th><th>Operator</th>
                  <th style="width:200px">Progress</th><th style="width:110px">Status</th>
                </tr></thead>
                <tbody>
                  @for (o of activeMixes; track o.num) {
                    <tr>
                      <td class="mono"><b>#{{ o.num }}</b></td>
                      <td>
                        <div style="font-weight:600">{{ data.recipe(o.recipe)?.name }}</div>
                        <div style="font-size:12px;color:var(--hs-fg-3)">{{ o.recipe }} · {{ o.qty }} {{ o.unit }}</div>
                      </td>
                      <td><span class="chip chip--info chip--dot">{{ o.terminal }}</span></td>
                      <td>{{ terminalUser(o.terminal) }}</td>
                      <td>
                        <div style="display:flex;align-items:center;gap:10px">
                          <div class="progress" style="flex:1">
                            <div class="progress__fill" [style.width.%]="o.progress"></div>
                          </div>
                          <div style="font-size:12px;font-variant-numeric:tabular-nums;color:var(--hs-fg-2)">
                            {{ o.mixesDone }}/{{ o.mixes }}
                          </div>
                        </div>
                      </td>
                      <td><span class="chip chip--dot" [ngClass]="statusChip(o.status).cls">{{ statusChip(o.status).label }}</span></td>
                    </tr>
                  }
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div class="stack">
          <!-- Terminal fleet -->
          <div class="card">
            <div class="card__header"><div class="card__title">Terminal fleet</div></div>
            <div class="card__body" style="display:flex;flex-direction:column;gap:8px">
              @for (t of data.terminals.slice(0, 6); track t.id) {
                <div style="display:flex;align-items:center;gap:10px">
                  <app-icon [name]="t.status === 'offline' ? 'wifiOff' : 'wifi'" [size]="16"
                    [style.color]="t.status === 'offline' ? 'var(--hs-pink-700)' : t.status === 'updating' ? 'var(--hs-purple-600)' : 'var(--hs-success)'"/>
                  <div style="flex:1;min-width:0">
                    <div style="font-weight:600;font-size:13px">{{ t.id }} · {{ t.label }}</div>
                    <div style="font-size:11px;color:var(--hs-fg-3)">{{ t.user || 'idle' }} · {{ t.lastSeen }}</div>
                  </div>
                  <span class="chip chip--dot" [ngClass]="statusChip(t.status).cls">{{ statusChip(t.status).label }}</span>
                </div>
              }
              <button class="btn btn--ghost btn--sm">See all terminals →</button>
            </div>
          </div>

          <!-- Recent activity -->
          <div class="card">
            <div class="card__header"><div class="card__title">Recent activity</div></div>
            <div class="card__body" style="display:flex;flex-direction:column;gap:12px">
              @for (a of data.audit.slice(0, 7); track $index) {
                <div style="display:flex;gap:10px">
                  <div style="width:8px;height:8px;border-radius:999px;margin-top:7px;flex-shrink:0"
                       [style.background]="auditColor(a.kind)"></div>
                  <div style="flex:1;min-width:0">
                    <div style="font-size:13px;font-weight:600">{{ a.action }}</div>
                    <div style="font-size:12px;color:var(--hs-fg-3)">{{ a.target }}</div>
                    <div style="font-size:11px;color:var(--hs-fg-muted);margin-top:2px">{{ a.user }} · {{ a.t }}</div>
                  </div>
                </div>
              }
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
})
export class DashboardComponent {
  data = inject(DataService);

  get ordersToday() { return this.data.orders.filter(o => o.due.startsWith('2026-04-24')); }
  get inProg() { return this.data.orders.filter(o => o.status === 'in-progress').length; }
  get complete() { return this.data.orders.filter(o => o.status === 'complete').length; }
  get onlineTerminals() { return this.data.terminals.filter(t => t.status === 'online' || t.status === 'idle').length; }
  get activeMixes() { return this.data.orders.filter(o => o.status === 'in-progress' || o.status === 'on-hold'); }

  readonly hours = [6,7,8,9,10,11,12,13,14,15,16,17];
  readonly nowHour = 14.53;
  readonly nowLineLeft = `calc(140px + ${((this.nowHour - 6) / 12) * 100}% - ${((this.nowHour - 6) / 12) * 140}px)`;

  get scheduleAreas() {
    const today = this.ordersToday;
    return this.data.prepAreas.filter(a => today.some(o => o.area === a.id));
  }

  ordersForArea(areaId: string) {
    return this.ordersToday.filter(o => o.area === areaId);
  }

  orderBlockStyle(o: any): string {
    const hr = parseFloat(o.due.split(' ')[1].split(':')[0]) + parseFloat(o.due.split(' ')[1].split(':')[1]) / 60;
    const start = hr - 1.5;
    const left = ((start - 6) / 12) * 100;
    const width = (1.5 / 12) * 100;
    const bgMap: Record<string, string> = { complete: 'var(--hs-success-bg)', 'in-progress': 'var(--hs-info-bg)', 'on-hold': 'var(--hs-warning-bg)' };
    const bdMap: Record<string, string> = { complete: 'var(--hs-success)', 'in-progress': 'var(--hs-purple-600)', 'on-hold': 'var(--hs-warning)' };
    const fgMap: Record<string, string> = { complete: 'var(--hs-success)', 'in-progress': 'var(--hs-purple-700)', 'on-hold': 'var(--hs-warning)' };
    const bg = bgMap[o.status] ?? 'var(--hs-bg-sunken)';
    const bd = bdMap[o.status] ?? 'var(--hs-border-strong)';
    const fg = fgMap[o.status] ?? 'var(--hs-fg-2)';
    return `position:absolute;top:6px;bottom:6px;left:${left}%;width:${width}%;background:${bg};border:1px solid ${bd};border-radius:6px;padding:4px 8px;font-size:11px;color:${fg};overflow:hidden;white-space:nowrap`;
  }

  terminalUser(termId: string | null): string {
    return this.data.terminals.find(t => t.id === termId)?.user ?? '—';
  }

  statusChip(s: string) { return this.data.statusChip(s); }

  padHour(h: number): string { return String(h).padStart(2, '0'); }

  auditColor(kind: string): string {
    const m: Record<string, string> = { ok: 'var(--hs-success)', warn: 'var(--hs-warning)', danger: 'var(--hs-pink-700)', info: 'var(--hs-purple-600)' };
    return m[kind] ?? 'var(--hs-fg-3)';
  }
}
