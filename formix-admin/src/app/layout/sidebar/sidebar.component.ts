import { Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { DataService } from '../../core/data.service';
import { IconComponent } from '../../shared/icon/icon.component';

interface NavItem { id: string; label: string; icon: string; group: string; badge?: number; }

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, IconComponent],
  template: `
    <aside class="sidebar">
      <div class="sidebar__brand">
        <img src="/assets/hellenic-mark.png" alt="Hellenic"/>
        <div class="sidebar__brand-text">
          <div class="sidebar__brand-title">Formix</div>
          <div class="sidebar__brand-sub">Recipe system</div>
        </div>
      </div>

      @for (group of groups; track group) {
        <div class="nav-section">{{ group }}</div>
        @for (item of navByGroup(group); track item.id) {
          <a class="nav-item" [routerLink]="item.id" routerLinkActive="active">
            <app-icon [name]="item.icon" [size]="18"/>
            <span>{{ item.label }}</span>
            @if (item.badge) {
              <span class="nav-item__badge">{{ item.badge }}</span>
            }
          </a>
        }
      }

      <div class="sidebar__footer">
        <div class="sidebar__user">
          <div class="avatar">CB</div>
          <div style="flex:1;min-width:0">
            <div class="sidebar__user-name">Claire Bennett</div>
            <div class="sidebar__user-role">Planner · Appleby Foods</div>
          </div>
          <app-icon name="chevronDown" [size]="14" style="opacity:0.5"/>
        </div>
      </div>
    </aside>
  `,
})
export class SidebarComponent {
  private data = inject(DataService);

  readonly nav: NavItem[] = [
    { id: 'dashboard',   label: 'Dashboard',     icon: 'home',      group: 'Operations' },
    { id: 'orders',      label: 'Orders',        icon: 'clipboard', group: 'Operations', badge: this.data.orders.filter(o => o.status === 'in-progress').length },
    { id: 'recipes',     label: 'Recipes',       icon: 'book',      group: 'Master data' },
    { id: 'ingredients', label: 'Ingredients',   icon: 'package',   group: 'Master data' },
    { id: 'allergens',   label: 'Allergens',     icon: 'alert',     group: 'Master data' },
    { id: 'qa',          label: 'QA checks',     icon: 'shield',    group: 'Master data' },
    { id: 'terminals',   label: 'Terminals',     icon: 'terminal',  group: 'Fleet' },
    { id: 'users',       label: 'Users & roles', icon: 'users',     group: 'Fleet' },
  ];

  readonly groups = [...new Set(this.nav.map(n => n.group))];

  navByGroup(g: string): NavItem[] { return this.nav.filter(n => n.group === g); }
}
