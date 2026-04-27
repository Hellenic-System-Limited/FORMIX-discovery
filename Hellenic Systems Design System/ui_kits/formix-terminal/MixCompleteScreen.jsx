function MixCompleteScreen({ onDone, onBack }) {
  const [qa, setQa] = React.useState([false, false, false]);
  const allOk = qa.every(Boolean);
  return (
    <div style={{ padding: '20px 28px', height: '100%', display: 'flex', flexDirection: 'column', gap: 14 }}>
      <div>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase', color: '#1f8a5a' }}>Mix complete</div>
        <div style={{ fontSize: 24, fontWeight: 600, letterSpacing: '-0.01em', marginTop: 4 }}>Mix 2 of 4 weighed. Run the QA checks.</div>
      </div>
      <div style={{ background: '#fff', border: '1px solid #dde1ec', borderRadius: 10, padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
        {[
          'Temperature within 2–5 °C',
          'No cross-contamination visible',
          'Allergen sequencing respected (no gluten → gluten-free)',
        ].map((q, i) => (
          <label key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: 10, borderRadius: 8, cursor: 'pointer', background: qa[i] ? '#e4f4ec' : '#f6f7fb' }}>
            <input type="checkbox" checked={qa[i]} onChange={e => { const n = [...qa]; n[i] = e.target.checked; setQa(n); }}
                   style={{ width: 20, height: 20, accentColor: '#1f8a5a' }} />
            <span style={{ fontSize: 15, color: '#122559', fontWeight: 500 }}>{q}</span>
          </label>
        ))}
      </div>
      <div style={{
        background: allOk ? 'linear-gradient(135deg,#122559,#4934ad)' : '#eef0f7',
        color: allOk ? '#fff' : '#3a4468',
        borderRadius: 10, padding: 14, fontSize: 14,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <span>{allOk ? 'All QA passed. Ready to print the mix label.' : 'Complete every QA check before printing.'}</span>
      </div>
      <div style={{ marginTop: 'auto', display: 'flex', gap: 10 }}>
        <Button variant="outline" onClick={onBack}>← Back</Button>
        <div style={{ flex: 1 }} />
        <Button variant="cta" disabled={!allOk} onClick={onDone} size="lg">Print mix label</Button>
      </div>
    </div>
  );
}

window.MixCompleteScreen = MixCompleteScreen;
