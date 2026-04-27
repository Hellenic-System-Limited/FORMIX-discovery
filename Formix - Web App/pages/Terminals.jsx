/* global React, Icon, Chip, StatusChip, Button, Drawer, Tabs, useToast,
   TERMINALS, USERS, ROLE_META, PREP_AREAS, prepAreaName */

const { useState: useST } = React;

function TerminalsPage() {
  const [selected, setSelected] = useST(null);
  const online = TERMINALS.filter(t => t.status === 'online').length;
  const offline = TERMINALS.filter(t => t.status === 'offline').length;
  const updating = TERMINALS.filter(t => t.status === 'updating').length;

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Terminal fleet</div>
          <div className="page__desc">Industrial touchscreen terminals on the shop floor. Managed rollout with rollback to one previous version.</div>
        </div>
        <div className="page__actions">
          <Button icon="sync">Push update</Button>
          <Button variant="primary" icon="plus">Register terminal</Button>
        </div>
      </div>

      <div className="grid grid--kpi" style={{marginBottom:20}}>
        <div className="stat"><div className="stat__label">Online</div><div className="stat__value" style={{color:'var(--hs-success)'}}>{online}</div></div>
        <div className="stat"><div className="stat__label">Offline</div><div className="stat__value" style={{color:'var(--hs-pink-700)'}}>{offline}</div></div>
        <div className="stat"><div className="stat__label">Updating</div><div className="stat__value" style={{color:'var(--hs-purple-700)'}}>{updating}</div></div>
        <div className="stat"><div className="stat__label">Current version</div><div className="stat__value mono">1.2.3</div></div>
      </div>

      <div className="grid" style={{gridTemplateColumns:'repeat(auto-fill, minmax(300px, 1fr))'}}>
        {TERMINALS.map(t => (
          <div key={t.id} className="terminal-card" onClick={() => setSelected(t.id)}>
            <div className={`icon-tile ${t.status==='offline'?'icon-tile--pink':t.status==='updating'?'icon-tile--purple':'icon-tile--success'}`}><Icon name="terminal" size={18}/></div>
            <div style={{flex:1,minWidth:0}}>
              <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:4}}>
                <div style={{fontWeight:700,fontSize:15}}>{t.id}</div>
                <StatusChip status={t.status}/>
              </div>
              <div style={{fontSize:13,color:'var(--hs-fg-2)',marginBottom:8}}>{t.label} · {prepAreaName(t.area)}</div>
              <div style={{fontSize:12,color:'var(--hs-fg-3)',display:'flex',flexDirection:'column',gap:2}}>
                <div><Icon name="scale" size={12} style={{verticalAlign:'-2px'}}/> {t.scale}</div>
                <div><Icon name="printer" size={12} style={{verticalAlign:'-2px'}}/> {t.printer}</div>
                <div style={{marginTop:4,display:'flex',gap:8,alignItems:'center'}}>
                  <span className="mono">v{t.version}</span>
                  <span>·</span>
                  <span>{t.user || 'idle'}</span>
                  <span style={{marginLeft:'auto',fontSize:11}}>{t.lastSeen}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <Drawer open={!!selected} onClose={() => setSelected(null)} title={selected ? `${selected} · ${TERMINALS.find(t=>t.id===selected).label}` : ''}
        footer={selected ? <><Button variant="danger">Deregister</Button><Button icon="sync">Force sync</Button><Button variant="primary" icon="upload">Push update</Button></> : null}>
        {selected && <TerminalDetail id={selected}/>}
      </Drawer>
    </div>
  );
}

function TerminalDetail({ id }) {
  const t = TERMINALS.find(x => x.id === id);
  return (
    <div style={{display:'flex',flexDirection:'column',gap:16}}>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
        <div><div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-fg-3)',fontWeight:600}}>Status</div><StatusChip status={t.status}/></div>
        <div><div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-fg-3)',fontWeight:600}}>Prep area</div><Chip variant="neutral">{prepAreaName(t.area)}</Chip></div>
        <div><div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-fg-3)',fontWeight:600}}>Current operator</div><div style={{fontWeight:600}}>{t.user || 'idle'}</div></div>
        <div><div style={{fontSize:11,textTransform:'uppercase',letterSpacing:'.06em',color:'var(--hs-fg-3)',fontWeight:600}}>App version</div><div className="mono" style={{fontWeight:600}}>{t.version}</div></div>
      </div>

      <div className="card card--flat" style={{padding:14}}>
        <div style={{fontWeight:600,marginBottom:10}}>Hardware</div>
        <div style={{display:'flex',gap:10,alignItems:'center',marginBottom:8}}>
          <Icon name="scale" size={16} style={{color:'var(--hs-fg-2)'}}/>
          <div style={{flex:1}}>{t.scale}</div>
          <Chip variant="success" dot>connected</Chip>
        </div>
        <div style={{display:'flex',gap:10,alignItems:'center',marginBottom:8}}>
          <Icon name="printer" size={16} style={{color:'var(--hs-fg-2)'}}/>
          <div style={{flex:1}}>{t.printer}</div>
          <Chip variant="success" dot>connected</Chip>
        </div>
        <div style={{display:'flex',gap:10,alignItems:'center'}}>
          <Icon name="barcode" size={16} style={{color:'var(--hs-fg-2)'}}/>
          <div style={{flex:1}}>Keyboard wedge scanner</div>
          <Chip variant="success" dot>connected</Chip>
        </div>
      </div>

      <div className="card card--flat" style={{padding:14}}>
        <div style={{fontWeight:600,marginBottom:10}}>Recent events</div>
        {[
          {t:'14:32', e:'Weighing accepted', d:'#200482 · FLR-001 · 18.04kg'},
          {t:'14:28', e:'Mix complete',      d:'#200482 · Mix 2'},
          {t:'13:47', e:'Sync with server',  d:'43 transactions · 2 orders'},
        ].map((x,i) => (
          <div key={i} style={{display:'flex',gap:10,padding:'6px 0',borderTop:i?'1px solid var(--hs-border)':'none',fontSize:13}}>
            <span style={{width:44,color:'var(--hs-fg-3)'}} className="mono">{x.t}</span>
            <span style={{flex:1,fontWeight:600}}>{x.e}</span>
            <span style={{color:'var(--hs-fg-3)'}}>{x.d}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ===== Users page =====
function UsersPage() {
  const [selected, setSelected] = useST(null);
  const [role, setRole] = useST('all');

  const filtered = USERS.filter(u => role === 'all' || u.role === role);

  return (
    <div className="page">
      <div className="page__header">
        <div>
          <div className="page__title">Users &amp; roles</div>
          <div className="page__desc">Role-based access control. Microsoft Identity handles authentication; roles control what each person can do.</div>
        </div>
        <div className="page__actions"><Button variant="primary" icon="plus">Invite user</Button></div>
      </div>

      <div className="grid grid--kpi" style={{marginBottom:20,gridTemplateColumns:'repeat(4,1fr)'}}>
        {Object.entries(ROLE_META).map(([key, meta]) => {
          const count = USERS.filter(u => u.role === key && u.active).length;
          return (
            <div key={key} className="stat" style={{cursor:'pointer'}} onClick={() => setRole(key)}>
              <div className="stat__label">{meta.label}s</div>
              <div className="stat__value">{count}</div>
              <div style={{fontSize:12,color:'var(--hs-fg-3)'}}>{meta.desc}</div>
            </div>
          );
        })}
      </div>

      <div className="filter-bar">
        <div style={{display:'flex',gap:4}}>
          {['all', ...Object.keys(ROLE_META)].map(k => (
            <button key={k} className={`tab ${role===k?'tab--active':''}`} style={{borderRadius:6,borderBottom:'none',background:role===k?'var(--hs-midnight-50)':'transparent'}} onClick={() => setRole(k)}>
              {k === 'all' ? 'All roles' : ROLE_META[k].label}
            </button>
          ))}
        </div>
        <div style={{marginLeft:'auto',fontSize:13,color:'var(--hs-fg-3)'}}>{filtered.length} users</div>
      </div>

      <div className="card" style={{overflow:'hidden'}}>
        <table className="tbl">
          <thead><tr>
            <th>Name</th>
            <th style={{width:280}}>Email</th>
            <th style={{width:140}}>Role</th>
            <th style={{width:140}}>Last active</th>
            <th style={{width:100}}>Status</th>
          </tr></thead>
          <tbody>
            {filtered.map(u => {
              const meta = ROLE_META[u.role];
              const initials = u.name.split(' ').map(n => n[0]).slice(0,2).join('');
              return (
                <tr key={u.id} onClick={() => setSelected(u.id)}>
                  <td>
                    <div style={{display:'flex',alignItems:'center',gap:10}}>
                      <div className="avatar" style={{width:28,height:28,fontSize:11}}>{initials}</div>
                      <div style={{fontWeight:600}}>{u.name}</div>
                    </div>
                  </td>
                  <td className="muted">{u.email}</td>
                  <td><Chip variant={meta.color} dot>{meta.label}</Chip></td>
                  <td className="muted">{u.last}</td>
                  <td>{u.active ? <Chip variant="success" dot>active</Chip> : <Chip variant="neutral">inactive</Chip>}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

Object.assign(window, { TerminalsPage, UsersPage });
