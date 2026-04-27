function MenuTile({ title, sub, count, onClick, accent }) {
  const [hover, setHover] = React.useState(false);
  return (
    <button onClick={onClick}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{
        textAlign: 'left', background: '#fff', border: '1px solid #dde1ec',
        borderRadius: 12, padding: 20, cursor: 'pointer',
        boxShadow: hover ? '0 20px 45px rgba(18,37,89,.14), 0 4px 10px rgba(18,37,89,.06)' : '0 6px 20px rgba(18,37,89,.10), 0 1px 3px rgba(18,37,89,.06)',
        transform: hover ? 'translateY(-2px)' : 'none',
        transition: 'all 200ms cubic-bezier(0.2,0.7,0.2,1)',
        fontFamily: 'inherit', color: '#122559', position: 'relative', overflow: 'hidden',
      }}>
      <div style={{ position: 'absolute', top: 0, right: 0, width: 4, height: '100%', background: accent }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ fontSize: 20, fontWeight: 600, letterSpacing: '-0.01em' }}>{title}</div>
        {count != null && (
          <div style={{ fontSize: 28, fontWeight: 600, color: accent, fontVariantNumeric: 'tabular-nums', lineHeight: 1 }}>{count}</div>
        )}
      </div>
      <div style={{ fontSize: 13, color: '#3a4468', marginTop: 6, lineHeight: 1.4 }}>{sub}</div>
    </button>
  );
}

function MainMenuScreen({ onPick }) {
  return (
    <div style={{ padding: '24px 32px', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase', color: '#4934ad' }}>Main menu</div>
        <div style={{ fontSize: 26, fontWeight: 600, letterSpacing: '-0.01em', marginTop: 4 }}>What are we doing next?</div>
      </div>
      <div style={{
        flex: 1, display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: '1fr 1fr',
        gap: 14, marginTop: 18,
      }}>
        <MenuTile title="Recipe orders" sub="Start a scheduled order. Weigh, QA, print labels."
          count={12} accent="#d4245c" onClick={() => onPick('process')} />
        <MenuTile title="View mix" sub="Review a mix already weighed today."
          count={8} accent="#4934ad" onClick={() => onPick('mix')} />
        <MenuTile title="Transactions" sub="Browse the weighing audit trail for this terminal."
          accent="#122559" onClick={() => onPick('tx')} />
        <MenuTile title="Setup" sub="Scale, printer, and terminal options."
          accent="#6b7597" onClick={() => onPick('setup')} />
      </div>
    </div>
  );
}

window.MainMenuScreen = MainMenuScreen;
