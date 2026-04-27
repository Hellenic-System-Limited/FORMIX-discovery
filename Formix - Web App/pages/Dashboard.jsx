/* global React, Icon, Chip, StatusChip, Button, Stat, CompositionBar, AllergenChips, SEG_COLORS,
   RECIPES, ORDERS, TERMINALS, USERS, ING, REC, PREP_AREAS, ALLERGENS, QA_CHECKS, ALLERGEN_RULES, AUDIT,
   recipe, ingredient, allergenName, prepAreaName, recipeAllergens, recipeCost, fmt, fmt0, ROLE_META */

const { useState: useS, useMemo: useM } = React;

/* ========== DASHBOARD ========== */
function DashboardPage() {
  const ordersToday = ORDERS.filter(o => o.due.startsWith('2026-04-24'));
  const inProg = ORDERS.filter(o => o.status === 'in-progress').length;
  const complete = ORDERS.filter(o => o.status === 'complete').length;
  const onHold   = ORDERS.filter(o => o.status === 'on-hold').length;
  const onlineTerminals = TERMINALS.filter(t => t.status === 'online' || t.status === 'idle').length;

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Today · Thursday 24 April 2026</div>
          <div className="page__desc">Appleby Foods · Worcester site · 9 terminals · 27 active orders this week</div>
        </div>
        <div className="page__actions">
          <Button icon="download">Export</Button>
          <Button variant="primary" icon="plus">Schedule order</Button>
        </div>
      </div>

      <div className="grid grid--kpi" style={{ marginBottom: 20 }}>
        <Stat label="Orders in progress"   value={inProg}   delta="+2 vs. yesterday" deltaDir="up"/>
        <Stat label="Completed today"      value={complete} delta="on track"           deltaDir="up"/>
        <Stat label="Out-of-tolerance"     value={3}        delta="blocked" deltaDir="down"/>
        <Stat label="Terminals online"     value={`${onlineTerminals}/${TERMINALS.length}`} delta="T-09 offline 4m" deltaDir="down"/>
      </div>

      <div className="grid grid--sidebar" style={{ alignItems: 'start' }}>
        <div className="stack">
          <div className="card">
            <div className="card__header">
              <div>
                <div className="card__title">Production schedule — today</div>
                <div className="card__desc">{ordersToday.length} orders · grouped by prep area</div>
              </div>
              <div style={{ marginLeft: 'auto' }}><Button size="sm" variant="ghost" icon="calendar">Week view</Button></div>
            </div>
            <div className="card__body" style={{ padding: 0 }}>
              <ScheduleTimeline orders={ordersToday} />
            </div>
          </div>

          <div className="card">
            <div className="card__header">
              <div className="card__title">Active mixes</div>
              <div style={{ marginLeft: 'auto' }}><Button size="sm" variant="ghost">View all</Button></div>
            </div>
            <div className="card__body" style={{ padding: 0 }}>
              <table className="tbl">
                <thead><tr>
                  <th>Order</th><th>Recipe</th><th>Terminal</th><th>Operator</th><th style={{width:200}}>Progress</th><th style={{width:110}}>Status</th>
                </tr></thead>
                <tbody>
                  {ORDERS.filter(o => o.status === 'in-progress' || o.status === 'on-hold').map(o => {
                    const r = recipe(o.recipe);
                    const term = TERMINALS.find(t => t.id === o.terminal);
                    return (
                      <tr key={o.num}>
                        <td className="mono"><b>#{o.num}</b></td>
                        <td><div style={{fontWeight:600}}>{r.name}</div><div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{o.recipe} · {o.qty} {o.unit}</div></td>
                        <td><Chip variant="info" dot>{o.terminal}</Chip></td>
                        <td>{term?.user || '—'}</td>
                        <td>
                          <div style={{display:'flex',alignItems:'center',gap:10}}>
                            <div className="progress" style={{flex:1}}><div className="progress__fill" style={{width:`${o.progress}%`}}/></div>
                            <div style={{fontSize:12,fontVariantNumeric:'tabular-nums',color:'var(--hs-fg-2)'}}>{o.mixesDone}/{o.mixes}</div>
                          </div>
                        </td>
                        <td><StatusChip status={o.status}/></td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <div className="stack">
          <div className="card">
            <div className="card__header"><div className="card__title">Terminal fleet</div></div>
            <div className="card__body" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {TERMINALS.slice(0, 6).map(t => (
                <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <Icon name={t.status === 'offline' ? 'wifiOff' : 'wifi'} size={16} style={{ color: t.status === 'offline' ? 'var(--hs-pink-700)' : t.status === 'updating' ? 'var(--hs-purple-600)' : 'var(--hs-success)' }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 13 }}>{t.id} · {t.label}</div>
                    <div style={{ fontSize: 11, color: 'var(--hs-fg-3)' }}>{t.user || 'idle'} · {t.lastSeen}</div>
                  </div>
                  <StatusChip status={t.status} />
                </div>
              ))}
              <Button variant="ghost" size="sm">See all terminals →</Button>
            </div>
          </div>

          <div className="card">
            <div className="card__header"><div className="card__title">Recent activity</div></div>
            <div className="card__body" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {AUDIT.slice(0, 7).map((a, i) => {
                const colors = { ok: 'var(--hs-success)', warn: 'var(--hs-warning)', danger: 'var(--hs-pink-700)', info: 'var(--hs-purple-600)' };
                return (
                  <div key={i} style={{ display: 'flex', gap: 10 }}>
                    <div style={{ width: 8, height: 8, borderRadius: 999, background: colors[a.kind], marginTop: 7, flexShrink: 0 }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 13, fontWeight: 600 }}>{a.action}</div>
                      <div style={{ fontSize: 12, color: 'var(--hs-fg-3)' }}>{a.target}</div>
                      <div style={{ fontSize: 11, color: 'var(--hs-fg-muted)', marginTop: 2 }}>{a.user} · {a.t}</div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ScheduleTimeline({ orders }) {
  const areas = PREP_AREAS.filter(a => orders.some(o => o.area === a.id));
  const HOURS = [6,7,8,9,10,11,12,13,14,15,16,17,18];
  const nowHour = 14.53;
  return (
    <div style={{ padding: '8px 20px 20px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '140px 1fr', gap: 0, position: 'relative' }}>
        <div></div>
        <div style={{ display: 'grid', gridTemplateColumns: `repeat(${HOURS.length - 1}, 1fr)`, borderBottom: '1px solid var(--hs-border)', paddingBottom: 6 }}>
          {HOURS.slice(0, -1).map(h => (
            <div key={h} style={{ fontSize: 11, color: 'var(--hs-fg-3)', fontVariantNumeric: 'tabular-nums' }}>{String(h).padStart(2,'0')}:00</div>
          ))}
        </div>
        {areas.map(a => {
          const rows = orders.filter(o => o.area === a.id);
          return (
            <React.Fragment key={a.id}>
              <div style={{ padding: '10px 0', fontSize: 13, fontWeight: 600, color: 'var(--hs-fg-2)', borderBottom: '1px solid var(--hs-border)' }}>{a.name}</div>
              <div style={{ position: 'relative', minHeight: 44, borderBottom: '1px solid var(--hs-border)' }}>
                {rows.map(o => {
                  const hr = parseFloat(o.due.split(' ')[1].split(':')[0]) + parseFloat(o.due.split(' ')[1].split(':')[1]) / 60;
                  const start = hr - 1.5; // assume 1.5 hr duration
                  const left = ((start - 6) / 12) * 100;
                  const width = (1.5 / 12) * 100;
                  const r = recipe(o.recipe);
                  const bg = o.status === 'complete' ? 'var(--hs-success-bg)' : o.status === 'in-progress' ? 'var(--hs-info-bg)' : o.status === 'on-hold' ? 'var(--hs-warning-bg)' : 'var(--hs-bg-sunken)';
                  const bd = o.status === 'complete' ? 'var(--hs-success)' : o.status === 'in-progress' ? 'var(--hs-purple-600)' : o.status === 'on-hold' ? 'var(--hs-warning)' : 'var(--hs-border-strong)';
                  const fg = o.status === 'complete' ? 'var(--hs-success)' : o.status === 'in-progress' ? 'var(--hs-purple-700)' : o.status === 'on-hold' ? 'var(--hs-warning)' : 'var(--hs-fg-2)';
                  return (
                    <div key={o.num} style={{
                      position: 'absolute', top: 6, bottom: 6, left: `${left}%`, width: `${width}%`,
                      background: bg, border: `1px solid ${bd}`, borderRadius: 6, padding: '4px 8px',
                      fontSize: 11, color: fg, overflow: 'hidden', whiteSpace: 'nowrap',
                    }} title={`${r.name} · ${o.qty}${o.unit} · #${o.num}`}>
                      <div style={{ fontWeight: 700 }}>#{o.num}</div>
                      <div style={{ textOverflow: 'ellipsis', overflow: 'hidden' }}>{r.name}</div>
                    </div>
                  );
                })}
              </div>
            </React.Fragment>
          );
        })}
        {/* Now line */}
        <div></div>
        <div style={{ position: 'absolute', top: 24, bottom: 0, left: `calc(140px + ${((nowHour-6)/12)*100}% - ${((nowHour-6)/12)*140}px)`, width: 2, background: 'var(--hs-pink-600)', pointerEvents: 'none' }}>
          <div style={{ position: 'absolute', top: -8, left: -20, background: 'var(--hs-pink-600)', color: 'white', fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 3 }}>NOW</div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { DashboardPage });
