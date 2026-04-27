import { Component, inject, signal, computed } from '@angular/core';
import { NgClass } from '@angular/common';
import { DataService } from '../../core/data.service';
import { ToastService } from '../../shared/toast.service';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [NgClass, IconComponent],
  template: `
    <div class="page">
      <div class="page__header">
        <div>
          <div class="page__title">Users &amp; roles</div>
          <div class="page__desc">Role-based access control. Microsoft Identity handles authentication; roles control what each person can do.</div>
        </div>
        <div class="page__actions">
          <button class="btn btn--primary" (click)="toast.push('Invitation sent')"><app-icon name="plus" [size]="16"/>Invite user</button>
        </div>
      </div>

      <div class="grid grid--kpi" style="margin-bottom:20px;grid-template-columns:repeat(4,1fr)">
        @for (entry of roleSummary(); track entry.key) {
          <div class="stat" style="cursor:pointer" (click)="roleFilter.set(entry.key)">
            <div class="stat__label">{{ entry.meta.label }}s</div>
            <div class="stat__value">{{ entry.count }}</div>
            <div style="font-size:12px;color:var(--hs-fg-3)">{{ entry.meta.desc }}</div>
          </div>
        }
      </div>

      <div class="filter-bar">
        <div style="display:flex;gap:4px">
          <button class="tab" [class.tab--active]="roleFilter() === 'all'"
                  style="border-radius:6px;border-bottom:none"
                  (click)="roleFilter.set('all')">All roles</button>
          @for (entry of roleSummary(); track entry.key) {
            <button class="tab" [class.tab--active]="roleFilter() === entry.key"
                    style="border-radius:6px;border-bottom:none"
                    (click)="roleFilter.set(entry.key)">{{ entry.meta.label }}</button>
          }
        </div>
        <div style="margin-left:auto;font-size:13px;color:var(--hs-fg-3)">{{ filtered().length }} users</div>
      </div>

      <div class="card" style="overflow:hidden">
        <table class="tbl">
          <thead><tr>
            <th>Name</th>
            <th style="width:280px">Email</th>
            <th style="width:140px">Role</th>
            <th style="width:140px">Last active</th>
            <th style="width:100px">Status</th>
          </tr></thead>
          <tbody>
            @for (u of filtered(); track u.id) {
              @let meta = data.roleMeta[u.role];
              <tr>
                <td>
                  <div style="display:flex;align-items:center;gap:10px">
                    <div class="avatar" style="width:28px;height:28px;font-size:11px">{{ initials(u.name) }}</div>
                    <div style="font-weight:600">{{ u.name }}</div>
                  </div>
                </td>
                <td class="muted">{{ u.email }}</td>
                <td>
                  <span class="chip chip--dot" [ngClass]="roleChipClass(meta?.color)">{{ meta?.label }}</span>
                </td>
                <td class="muted">{{ u.last }}</td>
                <td>
                  @if (u.active) {
                    <span class="chip chip--success chip--dot">active</span>
                  } @else {
                    <span class="chip chip--neutral">inactive</span>
                  }
                </td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    </div>
  `,
})
export class UsersComponent {
  data = inject(DataService);
  toast = inject(ToastService);

  roleFilter = signal('all');

  filtered = computed(() => {
    const role = this.roleFilter();
    return this.data.users.filter(u => role === 'all' || u.role === role);
  });

  roleSummary = computed(() =>
    Object.entries(this.data.roleMeta).map(([key, meta]) => ({
      key,
      meta,
      count: this.data.users.filter(u => u.role === key && u.active).length,
    }))
  );

  initials(name: string): string {
    return name.split(' ').map(n => n[0]).slice(0, 2).join('');
  }

  roleChipClass(color: string | undefined): string {
    const map: Record<string, string> = {
      neutral: 'chip--neutral',
      info:    'chip--info',
      success: 'chip--success',
      warn:    'chip--warn',
    };
    return map[color ?? ''] ?? 'chip--neutral';
  }
}
