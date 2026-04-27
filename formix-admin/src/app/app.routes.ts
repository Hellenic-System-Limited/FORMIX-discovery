import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard',   loadComponent: () => import('./pages/dashboard/dashboard.component').then(m => m.DashboardComponent) },
  { path: 'orders',      loadComponent: () => import('./pages/orders/orders.component').then(m => m.OrdersComponent) },
  { path: 'recipes',     loadComponent: () => import('./pages/recipes/recipes.component').then(m => m.RecipesComponent) },
  { path: 'ingredients', loadComponent: () => import('./pages/ingredients/ingredients.component').then(m => m.IngredientsComponent) },
  { path: 'allergens',   loadComponent: () => import('./pages/allergens/allergens.component').then(m => m.AllergensComponent) },
  { path: 'qa',          loadComponent: () => import('./pages/qa/qa.component').then(m => m.QaComponent) },
  { path: 'terminals',   loadComponent: () => import('./pages/terminals/terminals.component').then(m => m.TerminalsComponent) },
  { path: 'users',       loadComponent: () => import('./pages/users/users.component').then(m => m.UsersComponent) },
];
