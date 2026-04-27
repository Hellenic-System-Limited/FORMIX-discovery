import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IconComponent } from '../icon/icon.component';

@Component({
  selector: 'app-drawer',
  standalone: true,
  imports: [CommonModule, IconComponent],
  template: `
    @if (open) {
      <div class="drawer-backdrop" (click)="close.emit()"></div>
      <div class="drawer" [style.width]="width || ''">
        <div class="drawer__header">
          <div class="drawer__title">{{ title }}</div>
          <button class="btn btn--ghost btn--icon" (click)="close.emit()" title="Close">
            <app-icon name="close" [size]="18"/>
          </button>
        </div>
        <div class="drawer__body">
          <ng-content></ng-content>
        </div>
        @if (hasFooter) {
          <div class="drawer__footer">
            <ng-content select="[slot=footer]"></ng-content>
          </div>
        }
      </div>
    }
  `,
})
export class DrawerComponent {
  @Input() open = false;
  @Input() title = '';
  @Input() width = '';
  @Input() hasFooter = false;
  @Output() close = new EventEmitter<void>();

  @HostListener('document:keydown.escape')
  onEsc() { if (this.open) this.close.emit(); }
}
