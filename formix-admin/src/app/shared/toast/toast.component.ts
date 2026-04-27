import { Component, inject } from '@angular/core';
import { ToastService } from '../toast.service';
import { IconComponent } from '../icon/icon.component';

@Component({
  selector: 'app-toast-stack',
  standalone: true,
  imports: [IconComponent],
  template: `
    <div class="toast-stack">
      @for (t of toast.toasts(); track t.id) {
        <div class="toast">
          <app-icon name="check" [size]="16"/>
          {{ t.msg }}
        </div>
      }
    </div>
  `,
})
export class ToastStackComponent {
  toast = inject(ToastService);
}
