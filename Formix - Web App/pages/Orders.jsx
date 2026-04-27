/* global React, Icon, Chip, StatusChip, Button, Drawer, Tabs, AllergenChips, useToast,
   ORDERS, TERMINALS, PREP_AREAS, recipe, prepAreaName, recipeAllergens, recipeCost, fmt */

const { useState: useSO, useMemo: useMO } = React;

function OrdersPage() {
  const [tab, setTab] = useSO('all');
  const [area, setArea] = useSO('all');
  const [query, setQuery] = useSO('');
  const [selected, setSelected] = useSO(null);
  const [newOpen, setNewOpen] = useSO(false);
  const toast = useToast();

  const counts = {
    all: ORDERS.length,
    scheduled: ORDERS.filter(o => o.status === 'scheduled').length,
    'in-progress': ORDERS.filter(o => o.status === 'in-progress').length,
    'on-hold': ORDERS.filter(o => o.status === 'on-hold').length,
    complete: ORDERS.filter(o => o.status === 'complete').length,
  };

  const filtered = useMO(() => ORDERS.filter(o => {
    if (tab !== 'all' && o.status !== tab) return false;
    if (area !== 'all' && o.area !== area) return false;
    if (query && !(String(o.num).includes(query) || recipe(o.recipe).name.toLowerCase().includes(query.toLowerCase()))) return false;
    return true;
  }), [tab, area, query]);

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Orders</div>
          <div className="page__desc">Create orders from recipes. Mix sizes are calculated from order quantity and pushed to terminals filtered by prep area.</div>
        </div>
        <div className="page__actions">
          <Button icon="calendar">Schedule view</Button>
          <Button variant="primary" icon="plus" onClick={() => setNewOpen(true)}>New order</Button>
        </div>
      </div>

      <Tabs active={tab} onChange={setTab} tabs={[
        { id: 'all', label: 'All', count: counts.all },
        { id: 'scheduled', label: 'Scheduled', count: counts.scheduled },
        { id: 'in-progress', label: 'In progress', count: counts['in-progress'] },
        { id: 'on-hold', label: 'On hold', count: counts['on-hold'] },
        { id: 'complete', label: 'Complete', count: counts.complete },
      ]}/>

      <div className="filter-bar" style={{marginTop:16}}>
        <div className="input-group" style={{ flex: '0 1 320px' }}>
          <Icon name="search" size={16} />
          <input className="input" placeholder="Search by number or recipe…" value={query} onChange={e => setQuery(e.target.value)} />
        </div>
        <select className="select" value={area} onChange={e => setArea(e.target.value)} style={{ width: 200 }}>
          <option value="all">All prep areas</option>
          {PREP_AREAS.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
        </select>
        <div style={{ marginLeft: 'auto', fontSize: 13, color: 'var(--hs-fg-3)' }}>{filtered.length} orders</div>
      </div>

      <div className="card" style={{overflow:'hidden'}}>
        <table className="tbl">
          <thead><tr>
            <th style={{width:100}}>Order</th>
            <th>Recipe</th>
            <th style={{width:140}}>Prep area</th>
            <th className="num" style={{width:100}}>Quantity</th>
            <th style={{width:180}}>Mixes</th>
            <th style={{width:140}}>Due</th>
            <th style={{width:110}}>Terminal</th>
            <th style={{width:120}}>Status</th>
          </tr></thead>
          <tbody>
            {filtered.map(o => {
              const r = recipe(o.recipe);
              return (
                <tr key={o.num} onClick={() => setSelected(o.num)}>
                  <td className="mono" style={{fontWeight:700}}>#{o.num}</td>
                  <td>
                    <div style={{fontWeight:600}}>{r.name}</div>
                    <div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{o.recipe} · v{r.version}</div>
                  </td>
                  <td><Chip variant="neutral">{prepAreaName(o.area)}</Chip></td>
                  <td className="num mono"><b>{fmt(o.qty, 0)}</b> {o.unit}</td>
                  <td>
                    <div style={{display:'flex',alignItems:'center',gap:10}}>
                      <div className="progress" style={{flex:1,maxWidth:120}}><div className={`progress__fill ${o.status==='complete'?'progress__fill--success':''}`} style={{width:`${o.progress}%`}}/></div>
                      <div style={{fontSize:12,color:'var(--hs-fg-2)',fontVariantNumeric:'tabular-nums'}}>{o.mixesDone}/{o.mixes}</div>
                    </div>
                  </td>
                  <td className="muted mono">{o.due.split(' ')[1]} · {o.due.split(' ')[0].slice(8)}</td>
                  <td>{o.terminal ? <Chip variant="info" dot>{o.terminal}</Chip> : <span style={{color:'var(--hs-fg-muted)'}}>—</span>}</td>
                  <td><StatusChip status={o.status}/></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <Drawer open={!!selected} onClose={() => setSelected(null)} title={selected ? `Order #${selected}` : ''}
        footer={selected ? <><Button variant="danger">Abandon order</Button><Button icon="printer">Reprint labels</Button><Button variant="primary" icon="check">Authorise</Button></> : null}>
        {selected && <OrderDetail num={selected} />}
      </Drawer>

      <Drawer open={newOpen} onClose={() => setNewOpen(false)} title="Schedule new order" width={520}
        footer={<><Button onClick={() => setNewOpen(false)}>Cancel</Button><Button variant="primary" icon="check" onClick={() => { toast('Order scheduled'); setNewOpen(false); }}>Schedule order</Button></>}>
        <NewOrderForm />
      </Drawer>
    </div>
  );
}

function OrderDetail({ num }) {
  const o = ORDERS.find(x => x.num === num);
  const r = recipe(o.recipe);
  const all = recipeAllergens(o.recipe);
  const mixSize = o.qty / o.mixes;

  return (
    <div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:12,marginBottom:20}}>
        {[
          { l: 'Quantity', v: `${fmt(o.qty,0)} ${o.unit}` },
          { l: 'Mixes', v: `${o.mixes} × ${fmt(mixSize,1)} ${o.unit}` },
          { l: 'Due', v: o.due.split(' ')[1] },
          { l: 'Progress', v: `${o.progress}%` },
        ].map(s => (
          <div key={s.l}>
            <div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-fg-3)',fontWeight:600,marginBottom:2}}>{s.l}</div>
            <div style={{fontSize:18,fontWeight:600,fontVariantNumeric:'tabular-nums'}}>{s.v}</div>
          </div>
        ))}
      </div>

      <div style={{display:'flex',gap:12,alignItems:'center',marginBottom:12}}>
        <StatusChip status={o.status}/>
        {o.terminal && <Chip variant="info" dot>Locked to {o.terminal}</Chip>}
        <div style={{marginLeft:'auto',fontSize:12,color:'var(--hs-fg-3)'}}>Scheduled by Claire Bennett · 14:28</div>
      </div>

      <div className="card card--flat" style={{padding:16,marginBottom:16}}>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <div className="icon-tile icon-tile--purple"><Icon name="book" size={18}/></div>
          <div style={{flex:1}}>
            <div style={{fontWeight:600}}>{r.name}</div>
            <div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{o.recipe} · v{r.version} · {prepAreaName(r.prepArea)}</div>
          </div>
          <div style={{fontSize:13,color:'var(--hs-fg-2)'}}><span className="mono" style={{fontWeight:600}}>£{fmt(recipeCost(o.recipe, o.qty),2)}</span> materials</div>
        </div>
        {all.length > 0 && <div style={{marginTop:10,paddingTop:10,borderTop:'1px solid var(--hs-border)'}}><AllergenChips ids={all}/></div>}
      </div>

      <h4 className="section-title">Mix breakdown</h4>
      <table className="tbl" style={{border:'1px solid var(--hs-border)',borderRadius:10}}>
        <thead><tr>
          <th style={{width:60}}>Mix</th>
          <th className="num" style={{width:120}}>Target</th>
          <th className="num" style={{width:120}}>Actual</th>
          <th>Status</th>
          <th>QA</th>
        </tr></thead>
        <tbody>
          {Array.from({length: o.mixes}, (_, i) => {
            const idx = i + 1;
            const done = i < o.mixesDone;
            const active = i === o.mixesDone && o.status === 'in-progress';
            return (
              <tr key={i} style={{cursor:'default'}}>
                <td className="mono" style={{fontWeight:600}}>#{idx}</td>
                <td className="num mono">{fmt(mixSize,1)} kg</td>
                <td className="num mono">{done ? fmt(mixSize + (Math.random()-0.5)*0.8, 2) + ' kg' : active ? <span style={{color:'var(--hs-purple-700)'}}>weighing…</span> : '—'}</td>
                <td>{done ? <StatusChip status="complete"/> : active ? <StatusChip status="in-progress"/> : <StatusChip status="scheduled"/>}</td>
                <td style={{fontSize:13,color:'var(--hs-fg-2)'}}>{done ? <><Icon name="check" size={14} style={{color:'var(--hs-success)',verticalAlign:'-2px'}}/> 4/4 passed</> : active ? '1/4 pending' : '—'}</td>
              </tr>
            );
          })}
        </tbody>
      </table>

      <h4 className="section-title" style={{marginTop:20}}>Recent transactions</h4>
      <div style={{display:'flex',flexDirection:'column',gap:4}}>
        {[
          { t: '14:32', ing: 'Strong white bread flour', w: '18.04 kg', ok: true, user: 'Joe Mitchell' },
          { t: '14:29', ing: 'Wholemeal bread flour', w: '4.52 kg', ok: true, user: 'Joe Mitchell' },
          { t: '14:26', ing: 'Filtered water', w: '5.38 kg', ok: true, user: 'Joe Mitchell' },
          { t: '14:24', ing: 'Fine sea salt', w: '0.361 kg', ok: true, user: 'Joe Mitchell' },
        ].map((x, i) => (
          <div key={i} style={{display:'flex',gap:10,padding:'8px 0',borderBottom:'1px solid var(--hs-border)',fontSize:13}}>
            <div style={{width:50,color:'var(--hs-fg-3)',fontVariantNumeric:'tabular-nums'}}>{x.t}</div>
            <Icon name="check" size={14} style={{color:x.ok?'var(--hs-success)':'var(--hs-pink-700)',marginTop:3}}/>
            <div style={{flex:1}}>{x.ing}</div>
            <div className="mono" style={{color:'var(--hs-fg-1)',fontWeight:600}}>{x.w}</div>
            <div style={{color:'var(--hs-fg-3)',minWidth:100,textAlign:'right'}}>{x.user}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function NewOrderForm() {
  const [rec, setRec] = useSO('BR-014');
  const [qty, setQty] = useSO(240);
  const r = recipe(rec);
  const mixCount = Math.ceil(qty / 60);
  const mixSize = qty / mixCount;
  const all = recipeAllergens(rec);

  return (
    <div style={{display:'flex',flexDirection:'column',gap:16}}>
      <div className="field">
        <label className="field__label">Recipe</label>
        <select className="select" value={rec} onChange={e => setRec(e.target.value)}>
          {window.RECIPES.filter(r => r.status === 'active').map(r => <option key={r.code} value={r.code}>{r.code} · {r.name}</option>)}
        </select>
        <div className="field__hint">Prep area: <b>{prepAreaName(r.prepArea)}</b> · v{r.version}</div>
      </div>

      <div className="field">
        <label className="field__label">Total quantity (kg)</label>
        <input className="input" type="number" value={qty} onChange={e => setQty(Number(e.target.value))}/>
        <div className="field__hint">System will split into mixes of up to 60 kg max per container.</div>
      </div>

      <div className="field">
        <label className="field__label">Due date &amp; time</label>
        <input className="input" type="datetime-local" defaultValue="2026-04-25T06:00"/>
      </div>

      <div className="field">
        <label className="field__label">Planner notes (optional)</label>
        <textarea className="textarea" placeholder="e.g. prioritise for 8 AM despatch"/>
      </div>

      <div className="card card--flat" style={{padding:16,background:'var(--hs-midnight-50)',border:'1px solid var(--hs-midnight-100)'}}>
        <div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-midnight-700)',fontWeight:600,marginBottom:8}}>Calculated plan</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,fontSize:13}}>
          <div><div style={{color:'var(--hs-fg-3)'}}>Mixes</div><div style={{fontSize:18,fontWeight:600}}>{mixCount} × {fmt(mixSize,1)} kg</div></div>
          <div><div style={{color:'var(--hs-fg-3)'}}>Ingredients</div><div style={{fontSize:18,fontWeight:600}}>{r.lines.length} lines</div></div>
          <div><div style={{color:'var(--hs-fg-3)'}}>Material cost</div><div style={{fontSize:18,fontWeight:600}} className="mono">£{fmt(recipeCost(rec, qty), 2)}</div></div>
          <div><div style={{color:'var(--hs-fg-3)'}}>Eligible terminals</div><div style={{fontSize:18,fontWeight:600}}>3 in {prepAreaName(r.prepArea)}</div></div>
        </div>
        {all.length > 0 && <div style={{marginTop:10}}><AllergenChips ids={all}/></div>}
      </div>
    </div>
  );
}

Object.assign(window, { OrdersPage });
