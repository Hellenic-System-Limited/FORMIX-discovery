import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { TopbarComponent } from '../topbar/topbar.component';
import { ToastStackComponent } from '../../shared/toast/toast.component';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterOutlet, SidebarComponent, TopbarComponent, ToastStackComponent],
  template: `
    <div class="app">
      <app-sidebar/>
      <main class="main">
        <app-topbar/>
        <router-outlet/>
      </main>
    </div>
    <app-toast-stack/>
  `,
})
export class ShellComponent {}
