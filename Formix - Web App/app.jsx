/* global React, ReactDOM, ToastProvider, Icon, Button,
   DashboardPage, RecipesPage, OrdersPage, IngredientsPage, AllergensPage, QAPage, TerminalsPage, UsersPage, ORDERS */

const { useState } = React;

const NAV = [
  { id: 'dashboard',   label: 'Dashboard',   icon: 'home',       group: 'Operations' },
  { id: 'orders',      label: 'Orders',      icon: 'clipboard',  group: 'Operations', badge: ORDERS.filter(o=>o.status==='in-progress').length },
  { id: 'recipes',     label: 'Recipes',     icon: 'book',       group: 'Master data' },
  { id: 'ingredients', label: 'Ingredients', icon: 'package',    group: 'Master data' },
  { id: 'allergens',   label: 'Allergens',   icon: 'alert',      group: 'Master data' },
  { id: 'qa',          label: 'QA checks',   icon: 'shield',     group: 'Master data' },
  { id: 'terminals',   label: 'Terminals',   icon: 'terminal',   group: 'Fleet' },
  { id: 'users',       label: 'Users & roles', icon: 'users',    group: 'Fleet' },
];

const CRUMBS = {
  dashboard:   ['Operations', 'Dashboard'],
  orders:      ['Operations', 'Orders'],
  recipes:     ['Master data', 'Recipes'],
  ingredients: ['Master data', 'Ingredients'],
  allergens:   ['Master data', 'Allergens'],
  qa:          ['Master data', 'QA checks'],
  terminals:   ['Fleet', 'Terminals'],
  users:       ['Fleet', 'Users & roles'],
};

function Sidebar({ page, setPage }) {
  const groups = [...new Set(NAV.map(n => n.group))];
  return (
    <aside className="sidebar">
      <div className="sidebar__brand">
        <img src="assets/hellenic-mark.png" alt="Hellenic"/>
        <div className="sidebar__brand-text">
          <div className="sidebar__brand-title">Formix</div>
          <div className="sidebar__brand-sub">Recipe system</div>
        </div>
      </div>

      {groups.map(g => (
        <React.Fragment key={g}>
          <div className="nav-section">{g}</div>
          {NAV.filter(n => n.group === g).map(n => (
            <button key={n.id} className={`nav-item ${page===n.id?'nav-item--active':''}`} onClick={() => setPage(n.id)}>
              <Icon name={n.icon} size={18}/>
              <span>{n.label}</span>
              {n.badge ? <span className="nav-item__badge">{n.badge}</span> : null}
            </button>
          ))}
        </React.Fragment>
      ))}

      <div className="sidebar__footer">
        <div className="sidebar__user">
          <div className="avatar">CB</div>
          <div style={{flex:1,minWidth:0}}>
            <div className="sidebar__user-name">Claire Bennett</div>
            <div className="sidebar__user-role">Planner · Appleby Foods</div>
          </div>
          <Icon name="chevronDown" size={14} style={{opacity:0.5}}/>
        </div>
      </div>
    </aside>
  );
}

function Topbar({ page }) {
  const crumbs = CRUMBS[page] || [];
  return (
    <div className="topbar">
      <div className="topbar__crumbs">
        <span>Appleby Foods</span>
        <span className="sep">/</span>
        {crumbs.map((c, i) => (
          <React.Fragment key={i}>
            <span style={{color: i === crumbs.length - 1 ? 'var(--hs-fg-1)' : 'var(--hs-fg-3)', fontWeight: i === crumbs.length - 1 ? 600 : 400}}>{c}</span>
            {i < crumbs.length - 1 && <span className="sep">/</span>}
          </React.Fragment>
        ))}
      </div>
      <div className="topbar__actions">
        <div className="input-group cmdk">
          <Icon name="search" size={14}/>
          <input className="input" placeholder="Search orders, recipes, users…" style={{paddingLeft: 32, fontSize: 13, height: 36}}/>
          <span style={{position:'absolute',right:8,top:'50%',transform:'translateY(-50%)'}} className="kbd">⌘K</span>
        </div>
        <button className="btn btn--ghost btn--icon" title="Notifications"><Icon name="bell" size={16}/></button>
        <button className="btn btn--ghost btn--icon" title="Help"><Icon name="help" size={16}/></button>
      </div>
    </div>
  );
}

function App() {
  // Support ?page=recipes etc. for standalone per-page URLs
  const urlPage = new URLSearchParams(location.search).get('page');
  const initial = ['dashboard','orders','recipes','ingredients','allergens','qa','terminals','users'].includes(urlPage) ? urlPage : 'dashboard';
  const [page, setPage] = useState(initial);
  const pages = {
    dashboard: DashboardPage,
    orders: OrdersPage,
    recipes: RecipesPage,
    ingredients: IngredientsPage,
    allergens: AllergensPage,
    qa: QAPage,
    terminals: TerminalsPage,
    users: UsersPage,
  };
  const Page = pages[page];

  return (
    <ToastProvider>
      <div className="app" data-screen-label={page}>
        <Sidebar page={page} setPage={setPage}/>
        <main className="main">
          <Topbar page={page}/>
          <Page/>
        </main>
      </div>
    </ToastProvider>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
