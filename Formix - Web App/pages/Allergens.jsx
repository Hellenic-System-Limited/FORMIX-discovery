/* global React, Icon, Chip, StatusChip, Button, Drawer, Tabs, AllergenChips, useToast,
   ALLERGENS, ALLERGEN_RULES, QA_CHECKS, PREP_AREAS, ING, INGREDIENTS, allergenName, prepAreaName */

const { useState: useSA } = React;

function AllergensPage() {
  const [tab, setTab] = useSA('register');
  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Allergen management</div>
          <div className="page__desc">Allergen register, sequencing rules and QA checks. Labels render allergens in <b>BOLD UPPERCASE</b> — a legal requirement.</div>
        </div>
        <div className="page__actions"><Button variant="primary" icon="plus">New rule</Button></div>
      </div>
      <Tabs active={tab} onChange={setTab} tabs={[
        { id:'register', label:'Register', count: ALLERGENS.length },
        { id:'rules',    label:'Sequencing rules', count: ALLERGEN_RULES.length },
        { id:'matrix',   label:'Ingredient matrix' },
      ]}/>
      <div style={{marginTop:16}}>
        {tab === 'register' && <AllergenRegister/>}
        {tab === 'rules' && <SequencingRules/>}
        {tab === 'matrix' && <AllergenMatrix/>}
      </div>
    </div>
  );
}

function AllergenRegister() {
  return (
    <div className="grid" style={{gridTemplateColumns:'repeat(auto-fill, minmax(260px, 1fr))'}}>
      {ALLERGENS.map(a => {
        const used = INGREDIENTS.filter(i => i.allergens.includes(a.id));
        return (
          <div key={a.id} className="card card--flat" style={{padding:16}}>
            <div style={{display:'flex',alignItems:'center',gap:12,marginBottom:10}}>
              <div className="icon-tile icon-tile--warn"><Icon name="alert" size={18}/></div>
              <div style={{flex:1}}>
                <div style={{fontWeight:600,fontSize:15}}>{a.name}</div>
                <div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{used.length} ingredients</div>
              </div>
            </div>
            <div style={{fontSize:12,color:'var(--hs-fg-2)',marginBottom:6}}>Label word</div>
            <div className="allergen-bold" style={{fontSize:14,background:'var(--hs-midnight-700)',color:'white',padding:'6px 10px',borderRadius:6,fontFamily:'var(--hs-font-mono)'}}>
              {a.name.toUpperCase()}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function SequencingRules() {
  return (
    <div className="stack">
      <div className="card" style={{padding:16,background:'var(--hs-info-bg)',border:'1px solid var(--hs-purple-100)'}}>
        <div style={{display:'flex',gap:12,alignItems:'flex-start'}}>
          <Icon name="help" size={20} style={{color:'var(--hs-purple-700)',marginTop:2}}/>
          <div style={{fontSize:13,color:'var(--hs-fg-2)'}}>
            Sequencing rules govern production order on shared lines. Terminals enforce them synchronously — when offline, best-effort using local production history.
          </div>
        </div>
      </div>
      <div className="card" style={{overflow:'hidden'}}>
        <table className="tbl">
          <thead><tr>
            <th>Rule</th>
            <th style={{width:160}}>Scope</th>
            <th style={{width:140}}>Policy</th>
            <th style={{width:120}}>Prep area</th>
            <th className="num" style={{width:120}}>Clean-down</th>
            <th style={{width:90}}>Status</th>
            <th style={{width:36}}></th>
          </tr></thead>
          <tbody>
            {ALLERGEN_RULES.map(r => (
              <tr key={r.id}>
                <td style={{fontWeight:600}}>{r.name}</td>
                <td><AllergenChips ids={r.scope} small/></td>
                <td><Chip variant="info">{r.policy}</Chip></td>
                <td className="muted">{prepAreaName(r.area)}</td>
                <td className="num mono">{r.cleanMinutes} min</td>
                <td><Chip variant={r.active?'success':'neutral'} dot>{r.active?'active':'paused'}</Chip></td>
                <td><button className="btn btn--ghost btn--icon btn--sm"><Icon name="edit" size={14}/></button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function AllergenMatrix() {
  const shown = INGREDIENTS.filter(i => i.allergens.length > 0);
  return (
    <div className="card" style={{overflow:'auto'}}>
      <table className="tbl">
        <thead><tr>
          <th style={{width:260}}>Ingredient</th>
          {ALLERGENS.map(a => <th key={a.id} className="num" style={{width:60,writingMode:'vertical-rl',transform:'rotate(180deg)',padding:'16px 4px'}}>{a.name}</th>)}
        </tr></thead>
        <tbody>
          {shown.map(i => (
            <tr key={i.code} style={{cursor:'default'}}>
              <td>
                <div style={{fontWeight:600}}>{i.name}</div>
                <div className="mono" style={{fontSize:11,color:'var(--hs-fg-3)'}}>{i.code}</div>
              </td>
              {ALLERGENS.map(a => (
                <td key={a.id} className="num" style={{textAlign:'center'}}>
                  {i.allergens.includes(a.id) ? <div style={{width:20,height:20,borderRadius:4,background:'var(--hs-warning)',color:'white',display:'inline-grid',placeItems:'center',fontSize:12,fontWeight:700}}>✓</div> : <span style={{color:'var(--hs-border-strong)'}}>·</span>}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ===== QA page =====
function QAPage() {
  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">QA checks</div>
          <div className="page__desc">Per-ingredient and end-of-mix checks. Operators cannot bypass required checks.</div>
        </div>
        <div className="page__actions"><Button variant="primary" icon="plus">New QA check</Button></div>
      </div>

      <div className="stack">
        {['per-ingredient', 'end-of-mix'].map(trig => (
          <div key={trig} className="card">
            <div className="card__header">
              <div className="icon-tile icon-tile--success"><Icon name="shield" size={18}/></div>
              <div>
                <div className="card__title">{trig === 'per-ingredient' ? 'Per-ingredient checks' : 'End-of-mix checks'}</div>
                <div className="card__desc">{trig === 'per-ingredient' ? 'Triggered during weighing of each ingredient.' : 'Triggered when the operator signs off the mix.'}</div>
              </div>
            </div>
            <table className="tbl">
              <thead><tr>
                <th>Check</th><th style={{width:130}}>Type</th><th style={{width:160}}>Applies to</th><th style={{width:140}}>Prep area</th><th className="num" style={{width:120}}>Required</th><th style={{width:36}}></th>
              </tr></thead>
              <tbody>
                {QA_CHECKS.filter(c => c.trigger === trig).map(c => (
                  <tr key={c.id} style={{cursor:'default'}}>
                    <td>
                      <div style={{fontWeight:600}}>{c.name}</div>
                      {c.type === 'numeric' && <div style={{fontSize:12,color:'var(--hs-fg-3)'}} className="mono">Range: {c.min} – {c.max}</div>}
                    </td>
                    <td><Chip variant="info">{c.type}</Chip></td>
                    <td className="muted">{c.applies === 'allergen' ? 'Allergen ingredients' : c.applies === 'all' ? 'All' : Array.isArray(c.applies) ? `${c.applies.length} ingredients` : '—'}</td>
                    <td className="muted">{c.area === 'all' ? 'All' : prepAreaName(c.area)}</td>
                    <td className="num">{c.required ? <Chip variant="success" dot>required</Chip> : <Chip variant="neutral">optional</Chip>}</td>
                    <td><button className="btn btn--ghost btn--icon btn--sm"><Icon name="edit" size={14}/></button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { AllergensPage, QAPage });
