import { Component, inject } from '@angular/core';
import { DataService } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-qa',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">QA checks</div>
          <div class="page__desc">Per-ingredient and end-of-mix checks. Operators cannot bypass required checks.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--primary" (click)="toast.push('New QA check created')"><app-icon name="plus" [size]="16"/>New QA check</button>
        </div>
      </div>

      <div class="stack">
        @for (trig of triggers; track trig.id) {
          <div class="card">
            <div class="card__header">
              <div class="icon-tile icon-tile--success"><app-icon name="shield" [size]="18"/></div>
              <div>
                <div class="card__title">{{ trig.title }}</div>
                <div class="card__desc">{{ trig.desc }}</div>
              </div>
            </div>
            <table class="tbl">
              <thead><tr>
                <th>Check</th>
                <th style="width:130px">Type</th>
                <th style="width:160px">Applies to</th>
                <th style="width:140px">Prep area</th>
                <th class="num" style="width:120px">Required</th>
                <th style="width:36px"></th>
              </tr></thead>
              <tbody>
                @for (c of checksFor(trig.id); track c.id) {
                  <tr style="cursor:default">
                    <td>
                      <div style="font-weight:600">{{ c.name }}</div>
                      @if (c.type === 'numeric') {
                        <div style="font-size:12px;color:var(--hs-fg-3)" class="mono">Range: {{ c.min }} – {{ c.max }}</div>
                      }
                    </td>
                    <td><span class="chip chip--info">{{ c.type }}</span></td>
                    <td class="muted">{{ appliesLabel(c.applies) }}</td>
                    <td class="muted">{{ c.area === 'all' ? 'All' : data.prepAreaName(c.area) }}</td>
                    <td class="num">
                      @if (c.required) {
                        <span class="chip chip--success chip--dot">required</span>
                      } @else {
                        <span class="chip chip--neutral">optional</span>
                      }
                    </td>
                    <td><button class="btn btn--ghost btn--icon btn--sm"><app-icon name="edit" [size]="14"/></button></td>
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
export class QaComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  readonly triggers = [
    { id: 'per-ingredient', title: 'Per-ingredient checks', desc: 'Triggered during weighing of each ingredient.' },
    { id: 'end-of-mix',     title: 'End-of-mix checks',     desc: 'Triggered when the operator signs off the mix.' },
  ];

  checksFor(trigger: string) {
    return this.data.qaChecks.filter(c => c.trigger === trigger);
  }

  appliesLabel(applies: string | string[]): string {
    if (applies === 'allergen') return 'Allergen ingredients';
    if (applies === 'all') return 'All';
    if (Array.isArray(applies)) return `${applies.length} ingredients`;
    return '—';
  }
}
