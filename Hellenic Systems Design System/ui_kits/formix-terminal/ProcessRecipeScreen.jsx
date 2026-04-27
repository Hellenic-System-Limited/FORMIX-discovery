const RECIPE = {
  order: '104523', recipeCode: 'SPICE-A',
  description: 'Caribbean jerk seasoning',
  orderWt: 200, mixes: 4, currentMix: 2,
  ingredients: [
    { code: 'SALT-01',   name: 'Sea salt fine',        required: 12.50, tol: 0.25, done: true },
    { code: 'PEPR-05',   name: 'Black pepper cracked', required: 6.25,  tol: 0.20, done: true },
    { code: 'PAPR-02',   name: 'Smoked paprika',       required: 8.00,  tol: 0.20, done: true, allergen: null },
    { code: 'ALSPC-01',  name: 'Allspice ground',      required: 4.00,  tol: 0.15, done: false, current: true },
    { code: 'THYM-03',   name: 'Thyme dried',          required: 3.25,  tol: 0.10, done: false },
    { code: 'GARL-02',   name: 'Garlic granules',      required: 9.00,  tol: 0.20, done: false },
    { code: 'WHEAT-F',   name: 'Wheat flour (carrier)',required: 7.00,  tol: 0.20, done: false, allergen: 'gluten' },
  ],
};

function ProcessRecipeScreen({ onComplete, onBack }) {
  const { useState, useEffect } = React;
  const current = RECIPE.ingredients.find(i => i.current);
  const [weight, setWeight] = useState(0);
  const [tared, setTared] = useState(false);
  const [scanned, setScanned] = useState(false);
  const [lot, setLot] = useState('');

  // Simulated continuous scale reading: oscillate toward target
  useEffect(() => {
    if (!tared) return;
    let raf;
    const target = current.required;
    const jitter = () => {
      setWeight(w => {
        const toward = w + (target + (Math.random() - 0.5) * 0.4 - w) * 0.06;
        return Math.max(0, toward);
      });
      raf = requestAnimationFrame(jitter);
    };
    raf = requestAnimationFrame(jitter);
    return () => cancelAnimationFrame(raf);
  }, [tared, current]);

  const inTol = tared && Math.abs(weight - current.required) <= current.tol;
  const canAccept = tared && scanned && inTol;

  const reset = () => { setWeight(0); setTared(false); setScanned(false); setLot(''); };

  return (
    <div style={{ padding: '16px 20px', height: '100%', display: 'flex', flexDirection: 'column', gap: 12, boxSizing: 'border-box' }}>
      {/* Top: order details + progress */}
      <div style={{
        background: '#fff', border: '1px solid #dde1ec', borderRadius: 10,
        padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase', color: '#4934ad' }}>Order {RECIPE.order} · Recipe {RECIPE.recipeCode}</div>
          <div style={{ fontSize: 18, fontWeight: 600, marginTop: 2, letterSpacing: '-0.01em' }}>{RECIPE.description}</div>
          <div style={{ fontSize: 12, color: '#6b7597', marginTop: 4, display: 'flex', gap: 10 }}>
            <span>Mix <b style={{ color: '#122559' }}>{RECIPE.currentMix}</b> of {RECIPE.mixes}</span>
            <span>·</span>
            <span>Order weight {RECIPE.orderWt}.00 kg</span>
            <span>·</span>
            <span>Prep area Dry</span>
          </div>
        </div>
        <Button variant="outline" size="sm" onClick={onBack}>← Menu</Button>
      </div>

      {/* Middle: two columns */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.1fr 1fr', gap: 12, flex: 1, minHeight: 0 }}>
        {/* Ingredient list */}
        <div style={{ background: '#fff', border: '1px solid #dde1ec', borderRadius: 10, padding: 12, overflow: 'auto' }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#6b7597', letterSpacing: '.04em', textTransform: 'uppercase', margin: '2px 4px 8px' }}>Ingredients</div>
          {RECIPE.ingredients.map(ing => (
            <div key={ing.code} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 10px', borderRadius: 8,
              background: ing.current ? '#eeeafa' : 'transparent',
              border: ing.current ? '1px solid #4934ad' : '1px solid transparent',
              marginBottom: 2,
            }}>
              <span style={{
                width: 18, height: 18, borderRadius: '50%',
                background: ing.done ? '#1f8a5a' : ing.current ? '#4934ad' : '#eef0f7',
                color: '#fff', fontSize: 11, display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700,
              }}>{ing.done ? '✓' : ''}</span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: ing.current ? 600 : 500, color: '#122559' }}>{ing.name}</div>
                <div style={{ fontSize: 11, color: '#6b7597' }}>{ing.code}</div>
              </div>
              {ing.allergen && <span style={{ background: '#122559', color: '#fff', fontSize: 10, padding: '2px 6px', borderRadius: 999, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '.04em' }}>{ing.allergen}</span>}
              <div style={{ fontSize: 13, fontVariantNumeric: 'tabular-nums', color: '#3a4468', fontWeight: 500 }}>{ing.required.toFixed(2)} kg</div>
            </div>
          ))}
        </div>

        {/* Scale & actions */}
        <div style={{ background: '#fff', border: '1px solid #dde1ec', borderRadius: 10, padding: 16, display: 'flex', flexDirection: 'column' }}>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#6b7597', letterSpacing: '.04em', textTransform: 'uppercase' }}>Now weighing</div>
          <div style={{ fontSize: 18, fontWeight: 600, letterSpacing: '-0.01em', marginTop: 2 }}>{current.name}</div>
          <div style={{ fontSize: 12, color: '#6b7597', marginTop: 2 }}>
            Target <b style={{ color: '#122559', fontVariantNumeric: 'tabular-nums' }}>{current.required.toFixed(2)} kg</b>
            <span style={{ margin: '0 6px' }}>·</span>
            Tolerance <b style={{ color: '#122559', fontVariantNumeric: 'tabular-nums' }}>±{current.tol.toFixed(2)} kg</b>
          </div>

          <div style={{ textAlign: 'center', margin: '14px 0 4px' }}>
            <ScaleReadout value={weight} />
          </div>
          <ToleranceBar current={weight} target={current.required} band={current.tol} />

          <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
            {!tared && <Button variant="outline" onClick={() => setTared(true)} size="sm" style={{ flex: 1 }}>1. Tare container</Button>}
            {tared && <Chip tone="success">Tared</Chip>}
            {!scanned && <Button variant="outline" onClick={() => setScanned(true)} size="sm" style={{ flex: 1 }} disabled={!tared}>2. Scan barcode</Button>}
            {scanned && <Chip tone="success">Scanned · SRC-9841</Chip>}
          </div>

          <div style={{ marginTop: 8 }}>
            <Field label="Lot no. (optional)" value={lot} onChange={setLot} placeholder="from supplier container" />
          </div>

          <div style={{ marginTop: 'auto', display: 'flex', gap: 8, paddingTop: 10 }}>
            <Button variant="ghost" size="sm" onClick={reset}>Reset step</Button>
            <div style={{ flex: 1 }} />
            <Button variant="cta" size="md" disabled={!canAccept} onClick={onComplete}>
              Accept & print label
            </Button>
          </div>
        </div>
      </div>

      {/* Footer status */}
      <div style={{
        background: inTol && tared ? '#e4f4ec' : !tared ? '#eef0f7' : '#fbdce6',
        color: inTol && tared ? '#1f8a5a' : !tared ? '#3a4468' : '#d4245c',
        padding: '8px 14px', borderRadius: 8, fontSize: 13, fontWeight: 600,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <span>
          {!tared ? 'Tare the container to start.' :
            !scanned ? 'Scan the source barcode on the ingredient container.' :
            inTol ? 'In tolerance — ready to accept.' :
            'Out of tolerance — adjust the weight before accepting.'}
        </span>
        <span style={{ fontSize: 11, opacity: 0.7 }}>Hard block on out-of-tolerance weighings.</span>
      </div>
    </div>
  );
}

window.ProcessRecipeScreen = ProcessRecipeScreen;
