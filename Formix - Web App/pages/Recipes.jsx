/* global React, Icon, Chip, StatusChip, Button, Drawer, Tabs, CompositionBar, AllergenChips, SEG_COLORS, useToast,
   RECIPES, REC, ING, PREP_AREAS, ALLERGENS, recipe, ingredient, allergenName, prepAreaName,
   recipeAllergens, recipeCost, fmt */

const { useState: useSR, useMemo: useMR } = React;

function RecipesPage() {
  const [query, setQuery] = useSR('');
  const [area, setArea] = useSR('all');
  const [status, setStatus] = useSR('all');
  const [selected, setSelected] = useSR(null);
  const toast = useToast();

  const filtered = useMR(() => RECIPES.filter(r => {
    if (query && !(r.name.toLowerCase().includes(query.toLowerCase()) || r.code.toLowerCase().includes(query.toLowerCase()))) return false;
    if (area !== 'all' && r.prepArea !== area) return false;
    if (status !== 'all' && r.status !== status) return false;
    return true;
  }), [query, area, status]);

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Recipes</div>
          <div className="page__desc">Define ingredient proportions, tolerances and QA checks. Recipes flow down to every terminal on next sync.</div>
        </div>
        <div className="page__actions">
          <Button icon="upload">Import</Button>
          <Button variant="primary" icon="plus" onClick={() => toast('New recipe draft created')}>New recipe</Button>
        </div>
      </div>

      <div className="filter-bar">
        <div className="input-group" style={{ flex: '0 1 360px' }}>
          <Icon name="search" size={16} />
          <input className="input" placeholder="Search by name or code…" value={query} onChange={e => setQuery(e.target.value)} />
        </div>
        <select className="select" value={area} onChange={e => setArea(e.target.value)} style={{ width: 200 }}>
          <option value="all">All prep areas</option>
          {PREP_AREAS.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <select className="select" value={status} onChange={e => setStatus(e.target.value)} style={{ width: 160 }}>
          <option value="all">Any status</option>
          <option value="active">Active</option>
          <option value="draft">Draft</option>
        </select>
        <div style={{ marginLeft: 'auto', fontSize: 13, color: 'var(--hs-fg-3)' }}>{filtered.length} of {RECIPES.length}</div>
      </div>

      <div className="card" style={{ overflow: 'hidden' }}>
        <table className="tbl">
          <thead><tr>
            <th style={{width:110}}>Code</th>
            <th>Name</th>
            <th style={{width:140}}>Prep area</th>
            <th>Allergens</th>
            <th style={{width:120}}>Composition</th>
            <th style={{width:90}} className="num">Cost / kg</th>
            <th style={{width:80}}>Ver.</th>
            <th style={{width:110}}>Status</th>
          </tr></thead>
          <tbody>
            {filtered.map(r => {
              const all = recipeAllergens(r.code);
              return (
                <tr key={r.code} onClick={() => setSelected(r.code)}>
                  <td className="mono" style={{fontWeight:600}}>{r.code}</td>
                  <td>
                    <div style={{fontWeight:600}}>{r.name}</div>
                    <div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{r.description}</div>
                  </td>
                  <td><Chip variant="neutral">{prepAreaName(r.prepArea)}</Chip></td>
                  <td><AllergenChips ids={all} small /></td>
                  <td><div style={{width:110}}><CompositionBar lines={r.lines}/></div></td>
                  <td className="num mono">£{fmt(recipeCost(r.code, 1))}</td>
                  <td className="mono">v{r.version}</td>
                  <td><StatusChip status={r.status}/></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <Drawer open={!!selected} onClose={() => setSelected(null)} title={selected ? `${selected} · ${recipe(selected).name}` : ''}
        footer={selected ? <><Button variant="danger" icon="trash">Archive</Button><Button icon="copy">Duplicate</Button><Button variant="primary" icon="check" onClick={() => { toast('Recipe saved'); setSelected(null); }}>Save changes</Button></> : null}>
        {selected && <RecipeEditor code={selected} />}
      </Drawer>
    </div>
  );
}

function RecipeEditor({ code }) {
  const r = recipe(code);
  const [tab, setTab] = useSR('composition');
  const [mixSize, setMixSize] = useSR(60);
  const all = recipeAllergens(code);

  const total = r.lines.reduce((a, l) => a + l.pct, 0);

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: 200 }}>
          <div style={{ fontSize: 11, color: 'var(--hs-fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600, marginBottom: 4 }}>Prep area</div>
          <div style={{ fontSize: 15, fontWeight: 600 }}>{prepAreaName(r.prepArea)}</div>
        </div>
        <div style={{ flex: 1, minWidth: 200 }}>
          <div style={{ fontSize: 11, color: 'var(--hs-fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600, marginBottom: 4 }}>Spec</div>
          <div style={{ fontSize: 15, fontWeight: 600 }}>Percentage{r.spec !== 'percent' ? ' + volume' : ''}</div>
        </div>
        <div style={{ flex: 1, minWidth: 200 }}>
          <div style={{ fontSize: 11, color: 'var(--hs-fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em', fontWeight: 600, marginBottom: 4 }}>Version</div>
          <div style={{ fontSize: 15, fontWeight: 600 }}>v{r.version} · updated {r.updated}</div>
        </div>
      </div>

      {all.length > 0 && (
        <div style={{ background: 'var(--hs-warning-bg)', borderRadius: 10, padding: '12px 16px', marginBottom: 16, display: 'flex', gap: 12, alignItems: 'flex-start' }}>
          <Icon name="alert" size={18} style={{ color: 'var(--hs-warning)', flexShrink: 0, marginTop: 2 }} />
          <div style={{ flex: 1 }}>
            <div style={{ fontWeight: 600, fontSize: 13, color: 'var(--hs-warning)', marginBottom: 4 }}>Contains declarable allergens</div>
            <AllergenChips ids={all} />
            <div style={{ fontSize: 12, color: 'var(--hs-fg-2)', marginTop: 6 }}>These words will appear in <b>BOLD UPPERCASE</b> on every mix and ingredient label (Food Information Regs 2014).</div>
          </div>
        </div>
      )}

      <Tabs active={tab} onChange={setTab} tabs={[
        { id: 'composition', label: 'Composition', count: r.lines.length },
        { id: 'qa',          label: 'QA checks',   count: 3 },
        { id: 'process',     label: 'Process steps' },
        { id: 'history',     label: 'Version history' },
      ]} />

      <div style={{ marginTop: 16 }}>
        {tab === 'composition' && (
          <div>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 12 }}>
              <label className="field" style={{ flex: '0 0 auto' }}>
                <span className="field__label">Preview mix size</span>
              </label>
              <input type="number" className="input" style={{ width: 120 }} value={mixSize} onChange={e => setMixSize(Number(e.target.value))}/>
              <span style={{ color: 'var(--hs-fg-3)', fontSize: 13 }}>kg</span>
              <div style={{ marginLeft: 'auto', fontSize: 13, color: total === 100 ? 'var(--hs-success)' : 'var(--hs-pink-700)', fontWeight: 600 }}>
                <Icon name={total === 100 ? 'check' : 'alert'} size={14}/> Total: {fmt(total)}%
              </div>
            </div>

            <CompositionBar lines={r.lines} />
            <div className="legend" style={{ margin: '8px 0 16px' }}>
              {r.lines.map((l, i) => (
                <div key={l.code}><span className="legend__dot" style={{background: SEG_COLORS[i % SEG_COLORS.length]}}/> {ingredient(l.code)?.name} {l.pct}%</div>
              ))}
            </div>

            <table className="tbl" style={{ border: '1px solid var(--hs-border)', borderRadius: 10 }}>
              <thead><tr>
                <th style={{width:32}}>#</th>
                <th>Ingredient</th>
                <th>Allergens</th>
                <th className="num" style={{width:70}}>%</th>
                <th className="num" style={{width:110}}>Qty / {mixSize}kg</th>
                <th style={{width:150}}>Tolerance</th>
                <th style={{width:36}}></th>
              </tr></thead>
              <tbody>
                {r.lines.map((l, i) => {
                  const ing = ingredient(l.code);
                  const qty = (l.pct / 100) * mixSize;
                  return (
                    <tr key={l.code} style={{cursor:'default'}}>
                      <td className="mono" style={{color:'var(--hs-fg-3)'}}>{i + 1}</td>
                      <td>
                        <div style={{fontWeight:600}}>{ing?.name}</div>
                        <div style={{fontSize:11,color:'var(--hs-fg-3)'}} className="mono">{l.code}</div>
                      </td>
                      <td><AllergenChips ids={ing?.allergens || []} small/></td>
                      <td className="num mono">{fmt(l.pct)}</td>
                      <td className="num mono">{fmt(qty)} {ing?.unit}</td>
                      <td className="mono" style={{fontSize:13, color:'var(--hs-fg-2)'}}>±{l.tol[0]}% <span style={{color:'var(--hs-fg-muted)'}}>/</span> ±{l.tol[1]}%</td>
                      <td><button className="btn btn--ghost btn--icon btn--sm" title="Edit"><Icon name="edit" size={14}/></button></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <Button variant="ghost" size="sm" icon="plus" style={{ marginTop: 10 }}>Add ingredient line</Button>
          </div>
        )}
        {tab === 'qa' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {[
              { n: 'Ingredient temperature within range', trig: 'Per ingredient', a: ['MLK-002'], t: 'numeric 0–6°C' },
              { n: 'No visible contamination', trig: 'Per ingredient', a: 'all', t: 'confirm' },
              { n: 'Visual check — colour & texture',    trig: 'End of mix', a: 'all', t: 'confirm' },
            ].map((c, i) => (
              <div key={i} className="card card--flat" style={{padding:14}}>
                <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>
                  <div className="icon-tile icon-tile--success"><Icon name="shield" size={18}/></div>
                  <div style={{flex:1}}>
                    <div style={{fontWeight:600}}>{c.n}</div>
                    <div style={{fontSize:12,color:'var(--hs-fg-3)',marginTop:2}}>{c.trig} · applies to {Array.isArray(c.a) ? c.a.join(', ') : c.a} · {c.t}</div>
                  </div>
                  <Button variant="ghost" size="sm">Configure</Button>
                </div>
              </div>
            ))}
          </div>
        )}
        {tab === 'process' && (
          <div className="empty">
            <div className="empty__icon"><Icon name="clock" size={32}/></div>
            <div className="empty__title">No process steps</div>
            <div>Add non-weighing steps (e.g. "stir for 3 minutes") with terminal lock. Enterprise tier.</div>
            <div style={{marginTop:12}}><Button variant="secondary" icon="plus">Add process step</Button></div>
          </div>
        )}
        {tab === 'history' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { v: r.version,     date: r.updated,    by: 'Claire Bennett',  note: 'Adjusted yeast to 0.8% for summer ambient temps.' },
              { v: r.version - 1, date: '2026-03-22', by: 'Claire Bennett',  note: 'Tightened salt tolerance to ±5%.' },
              { v: r.version - 2, date: '2026-02-14', by: 'Raj Singh',       note: 'Added "dough temperature" end-of-mix QA check.' },
            ].filter(v => v.v > 0).map(v => (
              <div key={v.v} style={{ display: 'flex', gap: 12, padding: 12, border: '1px solid var(--hs-border)', borderRadius: 8 }}>
                <Chip variant="info">v{v.v}</Chip>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{v.note}</div>
                  <div style={{ fontSize: 12, color: 'var(--hs-fg-3)', marginTop: 2 }}>{v.date} · {v.by}</div>
                </div>
                <Button variant="ghost" size="sm">Restore</Button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { RecipesPage });
