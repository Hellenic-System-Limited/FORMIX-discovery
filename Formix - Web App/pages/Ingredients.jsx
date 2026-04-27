/* global React, Icon, Chip, StatusChip, Button, Drawer, Tabs, AllergenChips, useToast,
   INGREDIENTS, ING, ALLERGENS, PREP_AREAS, allergenName, fmt */

const { useState: useSI, useMemo: useMI } = React;

function IngredientsPage() {
  const [query, setQuery] = useSI('');
  const [allergenF, setAllergenF] = useSI('all');
  const [selected, setSelected] = useSI(null);

  const filtered = useMI(() => INGREDIENTS.filter(i => {
    if (query && !(i.name.toLowerCase().includes(query.toLowerCase()) || i.code.toLowerCase().includes(query.toLowerCase()))) return false;
    if (allergenF === 'any' && i.allergens.length === 0) return false;
    if (allergenF === 'none' && i.allergens.length > 0) return false;
    if (allergenF !== 'all' && allergenF !== 'any' && allergenF !== 'none' && !i.allergens.includes(allergenF)) return false;
    return true;
  }), [query, allergenF]);

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Ingredients</div>
          <div className="page__desc">Master data. Allergens flow through to labels, QA checks and sequencing rules.</div>
        </div>
        <div className="page__actions">
          <Button icon="upload">Import CSV</Button>
          <Button variant="primary" icon="plus">New ingredient</Button>
        </div>
      </div>

      <div className="filter-bar">
        <div className="input-group" style={{flex:'0 1 360px'}}>
          <Icon name="search" size={16}/>
          <input className="input" placeholder="Search ingredients…" value={query} onChange={e => setQuery(e.target.value)}/>
        </div>
        <select className="select" value={allergenF} onChange={e => setAllergenF(e.target.value)} style={{width:200}}>
          <option value="all">Any allergen status</option>
          <option value="any">Contains allergens</option>
          <option value="none">No allergens</option>
          <optgroup label="Specific allergen">
            {ALLERGENS.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
          </optgroup>
        </select>
        <div style={{marginLeft:'auto',fontSize:13,color:'var(--hs-fg-3)'}}>{filtered.length} of {INGREDIENTS.length}</div>
      </div>

      <div className="card" style={{overflow:'hidden'}}>
        <table className="tbl">
          <thead><tr>
            <th style={{width:100}}>Code</th>
            <th>Name</th>
            <th style={{width:160}}>Supplier</th>
            <th>Allergens</th>
            <th className="num" style={{width:80}}>Unit</th>
            <th className="num" style={{width:100}}>Cost</th>
            <th className="num" style={{width:100}}>Stock</th>
            <th className="num" style={{width:90}}>Use-by</th>
          </tr></thead>
          <tbody>
            {filtered.map(i => (
              <tr key={i.code} onClick={() => setSelected(i.code)}>
                <td className="mono" style={{fontWeight:600}}>{i.code}</td>
                <td style={{fontWeight:600}}>{i.name}</td>
                <td className="muted">{i.supplier}</td>
                <td><AllergenChips ids={i.allergens} small/></td>
                <td className="num mono">{i.unit}</td>
                <td className="num mono">£{fmt(i.cost,2)}</td>
                <td className="num mono">{fmt(i.stock,0)}</td>
                <td className="num mono muted">{i.useBy ? `${i.useBy} d` : '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Drawer open={!!selected} onClose={() => setSelected(null)} title={selected ? `${selected} · ${ING[selected].name}` : ''}
        footer={selected ? <><Button variant="danger" icon="trash">Archive</Button><Button variant="primary" icon="check">Save</Button></> : null}>
        {selected && <IngredientEditor code={selected}/>}
      </Drawer>
    </div>
  );
}

function IngredientEditor({ code }) {
  const ing = ING[code];
  return (
    <div style={{display:'flex',flexDirection:'column',gap:16}}>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
        <div className="field"><label className="field__label">Code</label><input className="input mono" defaultValue={ing.code}/></div>
        <div className="field"><label className="field__label">Unit of measure</label>
          <select className="select" defaultValue={ing.unit}><option>kg</option><option>L</option><option>g</option><option>ml</option><option>units</option></select>
        </div>
      </div>
      <div className="field"><label className="field__label">Name</label><input className="input" defaultValue={ing.name}/></div>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
        <div className="field"><label className="field__label">Supplier</label><input className="input" defaultValue={ing.supplier}/></div>
        <div className="field"><label className="field__label">Cost per {ing.unit}</label>
          <input className="input mono" defaultValue={ing.cost}/>
        </div>
      </div>
      <div className="field"><label className="field__label">Use-by specification (days from receipt)</label>
        <input className="input mono" defaultValue={ing.useBy || ''}/>
        <div className="field__hint">Used during weighing to validate source barcode dates.</div>
      </div>
      <div>
        <div className="field__label" style={{marginBottom:10}}>Allergens</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
          {ALLERGENS.map(a => {
            const checked = ing.allergens.includes(a.id);
            return (
              <label key={a.id} style={{display:'flex',alignItems:'center',gap:8,padding:'8px 10px',border:`1px solid ${checked?'var(--hs-warning)':'var(--hs-border)'}`,background:checked?'var(--hs-warning-bg)':'white',borderRadius:8,cursor:'pointer',fontSize:13,fontWeight:checked?600:400}}>
                <input type="checkbox" defaultChecked={checked} style={{accentColor:'var(--hs-warning)'}}/>
                {a.name}
              </label>
            );
          })}
        </div>
        <div style={{fontSize:12,color:'var(--hs-fg-3)',marginTop:8}}>
          <Icon name="alert" size={12} style={{verticalAlign:'-1px',color:'var(--hs-warning)'}}/> {' '}
          Allergen words will appear in <b>BOLD UPPERCASE</b> on labels — legally required (Food Information Regs 2014).
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { IngredientsPage });
