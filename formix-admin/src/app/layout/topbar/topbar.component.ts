import { Component, signal, inject } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { IconComponent } from '../../shared/icon/icon.component';

const CRUMBS: Record<string, string[]> = {
  dashboard:   ['Operations', 'Dashboard'],
  orders:      ['Operations', 'Orders'],
  recipes:     ['Master data', 'Recipes'],
  ingredients: ['Master data', 'Ingredients'],
  allergens:   ['Master data', 'Allergens'],
  qa:          ['Master data', 'QA checks'],
  terminals:   ['Fleet', 'Terminals'],
  users:       ['Fleet', 'Users & roles'],
};

function segFromUrl(url: string): string {
  return url.split('/').filter(Boolean)[0] ?? 'dashboard';
}

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="topbar">
      <div class="topbar__crumbs">
        <span>Appleby Foods</span>
        @for (crumb of crumbs(); track $index; let last = $last) {
          <span class="sep">/</span>
          <span [style.color]="last ? 'var(--hs-fg-1)' : 'var(--hs-fg-3)'"
                [style.font-weight]="last ? '600' : '400'">{{ crumb }}</span>
        }
      </div>
      <div class="topbar__actions">
        <div class="input-group cmdk">
          <app-icon name="search" [size]="14"/>
          <input class="input" placeholder="Search orders, recipes, users…"
                 style="padding-left:32px;font-size:13px;height:36px"/>
          <span style="position:absolute;right:8px;top:50%;transform:translateY(-50%)" class="kbd">⌘K</span>
        </div>
        <button class="btn btn--ghost btn--icon" title="Notifications">
          <app-icon name="bell" [size]="16"/>
        </button>
        <button class="btn btn--ghost btn--icon" title="Help">
          <app-icon name="help" [size]="16"/>
        </button>
      </div>
    </div>
  `,
})
export class TopbarComponent {
  private router = inject(Router);
  crumbs = signal<string[]>(CRUMBS[segFromUrl(this.router.url)] ?? []);

  constructor() {
    this.router.events.subscribe(e => {
      if (e instanceof NavigationEnd) {
        this.crumbs.set(CRUMBS[segFromUrl(e.urlAfterRedirects)] ?? []);
      }
    });
  }
}
