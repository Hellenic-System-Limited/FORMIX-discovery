/* global React */
// Shared UI primitives for Formix admin

const { useState, useEffect, useMemo, useRef } = React;

// ---------- Icon (lucide via data URI style — inline SVG) ----------
function Icon({ name, size = 20, stroke = 1.75, style }) {
  const s = size;
  const common = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: stroke, strokeLinecap: 'round', strokeLinejoin: 'round', style };
  const paths = {
    home:    (<><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2h-4v-7H9v7H5a2 2 0 0 1-2-2Z"/></>),
    book:    (<><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20V2H6.5A2.5 2.5 0 0 0 4 4.5Z"/><path d="M4 19.5V22h16"/></>),
    clipboard: (<><rect x="8" y="2" width="8" height="4" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/></>),
    package: (<><path d="m7.5 4.27 9 5.15"/><path d="M21 8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16Z"/><path d="M3.3 7 12 12l8.7-5"/><path d="M12 22V12"/></>),
    users:   (<><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></>),
    shield:  (<><path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.5 3.8 17 5 19 5a1 1 0 0 1 1 1Z"/><path d="m9 12 2 2 4-4"/></>),
    alert:   (<><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4"/><path d="M12 17h.01"/></>),
    scale:   (<><path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/></>),
    terminal:(<><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8"/><path d="M12 17v4"/><path d="m7 9 3 3-3 3"/><path d="M13 15h4"/></>),
    gauge:   (<><path d="m12 14 4-4"/><path d="M3.34 19a10 10 0 1 1 17.32 0"/></>),
    search:  (<><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></>),
    plus:    (<><path d="M5 12h14"/><path d="M12 5v14"/></>),
    chevron: (<><path d="m9 18 6-6-6-6"/></>),
    chevronDown: (<><path d="m6 9 6 6 6-6"/></>),
    close:   (<><path d="M18 6 6 18"/><path d="m6 6 12 12"/></>),
    more:    (<><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/></>),
    filter:  (<><path d="M3 6h18"/><path d="M7 12h10"/><path d="M10 18h4"/></>),
    calendar:(<><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4"/><path d="M8 2v4"/><path d="M3 10h18"/></>),
    check:   (<><path d="M20 6 9 17l-5-5"/></>),
    edit:    (<><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"/></>),
    trash:   (<><path d="M3 6h18"/><path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"/></>),
    copy:    (<><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></>),
    arrowUp:(<><path d="m5 12 7-7 7 7"/><path d="M12 19V5"/></>),
    arrowDown:(<><path d="M12 5v14"/><path d="m19 12-7 7-7-7"/></>),
    bell:    (<><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></>),
    wifi:    (<><path d="M5 13a10 10 0 0 1 14 0"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M2 8.82a15 15 0 0 1 20 0"/><path d="M12 20h.01"/></>),
    wifiOff: (<><path d="M12 20h.01"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="m2 2 20 20"/><path d="M8.56 8.56A10 10 0 0 0 5 13"/><path d="M2 8.82a15 15 0 0 1 4.17-2.65"/><path d="M10.66 5c4.01-.36 8.14.9 11.34 3.82"/><path d="m16.85 11.25 2.15 1.75"/></>),
    barcode: (<><path d="M3 5v14"/><path d="M8 5v14"/><path d="M12 5v14"/><path d="M17 5v14"/><path d="M21 5v14"/></>),
    flask:   (<><path d="M9 2v6l-4.5 8a2 2 0 0 0 1.76 3h11.48a2 2 0 0 0 1.76-3L15 8V2"/><path d="M8 2h8"/><path d="M7.5 14h9"/></>),
    beaker:  (<><path d="M4.5 3h15"/><path d="M6 3v14a4 4 0 0 0 4 4h4a4 4 0 0 0 4-4V3"/><path d="M6 8h12"/></>),
    tag:     (<><path d="M20.59 13.41 13.42 20.58a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82Z"/><circle cx="7" cy="7" r="1"/></>),
    sync:    (<><path d="M21 12a9 9 0 0 0-15-6.7L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 15 6.7L21 16"/><path d="M21 21v-5h-5"/></>),
    logOut:  (<><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="m16 17 5-5-5-5"/><path d="M21 12H9"/></>),
    settings:(<><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2Z"/><circle cx="12" cy="12" r="3"/></>),
    download:(<><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m7 10 5 5 5-5"/><path d="M12 15V3"/></>),
    upload:  (<><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="m17 8-5-5-5 5"/><path d="M12 3v12"/></>),
    printer: (<><path d="M6 9V2h12v7"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></>),
    layers:  (<><path d="m12.83 2.18 8 4a2 2 0 0 1 0 3.64l-8 4a2 2 0 0 1-1.66 0l-8-4a2 2 0 0 1 0-3.64l8-4a2 2 0 0 1 1.66 0Z"/><path d="m2.58 13 9.25 4.62a2 2 0 0 0 1.84 0L22.92 13"/><path d="m2.58 17 9.25 4.62a2 2 0 0 0 1.84 0L22.92 17"/></>),
    clock:   (<><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></>),
    refresh: (<><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M8 16H3v5"/></>),
    at:      (<><circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8"/></>),
    dot:     (<><circle cx="12" cy="12" r="3" fill="currentColor"/></>),
    sliders: (<><path d="M4 21v-7"/><path d="M4 10V3"/><path d="M12 21v-9"/><path d="M12 8V3"/><path d="M20 21v-5"/><path d="M20 12V3"/><path d="M1 14h6"/><path d="M9 8h6"/><path d="M17 16h6"/></>),
    mapPin:  (<><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></>),
    command: (<><path d="M18 3a3 3 0 0 0-3 3v12a3 3 0 0 0 3 3 3 3 0 0 0 3-3 3 3 0 0 0-3-3H6a3 3 0 0 0-3 3 3 3 0 0 0 3 3 3 3 0 0 0 3-3V6a3 3 0 0 0-3-3 3 3 0 0 0-3 3 3 3 0 0 0 3 3h12a3 3 0 0 0 3-3 3 3 0 0 0-3-3Z"/></>),
    help:    (<><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/></>),
  };
  return <svg {...common} aria-hidden="true">{paths[name] || null}</svg>;
}

// ---------- Chip ----------
function Chip({ children, variant = 'neutral', dot = false, style }) {
  const cls = `chip chip--${variant} ${dot ? 'chip--dot' : ''}`;
  return <span className={cls} style={style}>{children}</span>;
}

function StatusChip({ status }) {
  const s = STATUS_CHIP[status] || { label: status, cls: 'chip--neutral' };
  return <span className={`chip ${s.cls} chip--dot`}>{s.label}</span>;
}

// ---------- Button ----------
function Button({ variant = 'secondary', size, icon, children, onClick, disabled, style, title, type = 'button' }) {
  const cls = `btn btn--${variant}${size ? ' btn--' + size : ''}${!children ? ' btn--icon' : ''}`;
  return (
    <button type={type} className={cls} onClick={onClick} disabled={disabled} style={style} title={title}>
      {icon && <Icon name={icon} size={size === 'sm' ? 14 : 16} />}
      {children}
    </button>
  );
}

// ---------- Tabs ----------
function Tabs({ tabs, active, onChange }) {
  return (
    <div className="tabs">
      {tabs.map(t => (
        <button key={t.id} className={`tab ${active === t.id ? 'tab--active' : ''}`} onClick={() => onChange(t.id)}>
          {t.label}
          {t.count != null && <span style={{ marginLeft: 8, fontSize: 12, color: 'var(--hs-fg-3)' }}>{t.count}</span>}
        </button>
      ))}
    </div>
  );
}

// ---------- Drawer ----------
function Drawer({ open, onClose, title, width, children, footer }) {
  useEffect(() => {
    if (!open) return;
    const h = (e) => { if (e.key === 'Escape') onClose?.(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [open, onClose]);
  if (!open) return null;
  return (
    <>
      <div className="drawer-backdrop" onClick={onClose} />
      <div className="drawer" style={width ? { width } : {}}>
        <div className="drawer__header">
          <div className="drawer__title">{title}</div>
          <button className="btn btn--ghost btn--icon drawer__close" onClick={onClose} title="Close"><Icon name="close" size={18}/></button>
        </div>
        <div className="drawer__body">{children}</div>
        {footer && <div className="drawer__footer">{footer}</div>}
      </div>
    </>
  );
}

// ---------- Toasts ----------
const ToastCtx = React.createContext(() => {});
function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const push = (msg) => {
    const id = Math.random().toString(36).slice(2);
    setToasts(t => [...t, { id, msg }]);
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 2800);
  };
  return (
    <ToastCtx.Provider value={push}>
      {children}
      <div className="toast-stack">
        {toasts.map(t => <div key={t.id} className="toast"><Icon name="check" size={16}/>{t.msg}</div>)}
      </div>
    </ToastCtx.Provider>
  );
}
const useToast = () => React.useContext(ToastCtx);

// ---------- Allergen chips ----------
function AllergenChips({ ids, small }) {
  if (!ids?.length) return <span style={{ color: 'var(--hs-fg-muted)', fontSize: 12 }}>none</span>;
  return (
    <div style={{ display: 'inline-flex', flexWrap: 'wrap', gap: 4 }}>
      {ids.map(id => (
        <span key={id} className="chip chip--allergen" style={small ? { fontSize: 10, padding: '2px 7px' } : {}}>{allergenName(id)}</span>
      ))}
    </div>
  );
}

// ---------- Composition bar (recipe % segments) ----------
const SEG_COLORS = ['#122559', '#4934ad', '#d4245c', '#1d327b', '#6350c4', '#e14879', '#2d4aa6', '#b25b00', '#1f8a5a', '#6b7597'];
function CompositionBar({ lines }) {
  return (
    <div className="comp-bar" title="Recipe composition">
      {lines.map((l, i) => (
        <div key={l.code} className="comp-bar__seg" style={{ width: `${l.pct}%`, background: SEG_COLORS[i % SEG_COLORS.length] }} title={`${ingredient(l.code)?.name} — ${l.pct}%`} />
      ))}
    </div>
  );
}

// ---------- Stat card ----------
function Stat({ label, value, delta, deltaDir, children }) {
  return (
    <div className="stat">
      <div className="stat__label">{label}</div>
      <div className="stat__value">{value}</div>
      {delta && <div className={`stat__delta stat__delta--${deltaDir || 'up'}`}>{delta}</div>}
      {children}
    </div>
  );
}

Object.assign(window, { Icon, Chip, StatusChip, Button, Tabs, Drawer, ToastProvider, ToastCtx, useToast, AllergenChips, CompositionBar, Stat, SEG_COLORS });
