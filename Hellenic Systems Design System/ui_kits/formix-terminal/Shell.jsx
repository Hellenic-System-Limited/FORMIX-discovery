const { useState: useStateShell, useEffect: useEffectShell } = React;

function Shell({ terminal, operator, children, onLogout }) {
  const [clock, setClock] = useStateShell(() => new Date());
  useEffectShell(() => {
    const t = setInterval(() => setClock(new Date()), 1000);
    return () => clearInterval(t);
  }, []);
  const hhmm = clock.toTimeString().slice(0, 5);
  const date = clock.toLocaleDateString('en-GB', { weekday: 'short', day: '2-digit', month: 'short' });

  return (
    <div style={{
      width: 800, height: 600, background: '#f6f7fb',
      display: 'flex', flexDirection: 'column',
      border: '1px solid #dde1ec', borderRadius: 14,
      overflow: 'hidden', boxShadow: '0 20px 45px rgba(18,37,89,.14), 0 4px 10px rgba(18,37,89,.06)',
      fontFamily: 'Figtree, sans-serif', color: '#122559',
    }}>
      {/* Header */}
      <div style={{
        height: 52, padding: '0 18px', background: '#122559', color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <img src="../../assets/hellenic-mark.png" style={{ width: 28, height: 28 }} />
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Formix</div>
            <div style={{ fontSize: 11, opacity: 0.7, marginTop: -2 }}>Recipe System · v8.0.3</div>
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, fontSize: 12 }}>
          <span style={{ opacity: 0.7 }}>Terminal</span>
          <span style={{ fontWeight: 600 }}>{terminal}</span>
          {operator && (<>
            <span style={{ opacity: 0.4 }}>·</span>
            <span style={{ opacity: 0.7 }}>Operator</span>
            <span style={{ fontWeight: 600 }}>{operator}</span>
            <Button variant="ghost" size="sm" onClick={onLogout}
              style={{ color: '#fff', padding: '4px 10px' }}>Log out</Button>
          </>)}
          <span style={{ opacity: 0.4 }}>·</span>
          <span style={{ fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>{hhmm}</span>
          <span style={{ opacity: 0.6 }}>{date}</span>
        </div>
      </div>
      {/* Content */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {children}
      </div>
    </div>
  );
}

window.Shell = Shell;
