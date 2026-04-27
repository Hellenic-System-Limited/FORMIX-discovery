export function AdminNav({ section, onSection }) {
  const nav = [
    { key: 'recipes', label: 'Recipes' },
    { key: 'orders', label: 'Orders' },
    { key: 'ingredients', label: 'Ingredients' },
    { key: 'users', label: 'Users' },
    { key: 'audit', label: 'Audit' },
  ];
  return (
    <nav style={{ width: 180, background: '#f7f8fa', borderRight: '1px solid #e3e6f0', padding: '32px 0', display: 'flex', flexDirection: 'column', gap: 8 }}>
      {nav.map(item => (
        <button key={item.key} onClick={() => onSection(item.key)}
          style={{
            background: section === item.key ? 'linear-gradient(90deg, #4934ad 0%, #d4245c 100%)' : 'none',
            color: section === item.key ? '#fff' : '#4934ad',
            fontWeight: 600, fontSize: 18, border: 'none', borderRadius: 8, margin: '0 18px', padding: '12px 18px', cursor: 'pointer', textAlign: 'left', transition: 'all 0.2s'
          }}>{item.label}</button>
      ))}
    </nav>
  );
}
