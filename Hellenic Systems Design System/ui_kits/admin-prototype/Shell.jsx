export function AdminShell({ children }) {
  return (
    <div style={{
      width: 1000, minHeight: 700, margin: '40px auto', background: '#fff', borderRadius: 18, boxShadow: '0 8px 32px rgba(18,37,89,.10)', display: 'flex', flexDirection: 'column', overflow: 'hidden', border: '1px solid #e3e6f0'
    }}>
      <header style={{ background: 'linear-gradient(90deg, #4934ad 0%, #d4245c 100%)', color: '#fff', padding: '18px 32px', fontSize: 28, fontWeight: 700, letterSpacing: '-0.01em', display: 'flex', alignItems: 'center', gap: 18 }}>
        <img src="../assets/logo.svg" alt="Hellenic logo" style={{ height: 38, marginRight: 18 }} />
        Hellenic Recipe Admin
      </header>
      <div style={{ display: 'flex', flex: 1, minHeight: 0 }}>
        {children}
      </div>
    </div>
  );
}
