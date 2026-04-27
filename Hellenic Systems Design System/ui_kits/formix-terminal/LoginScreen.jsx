function LoginScreen({ onLogin }) {
  const [user, setUser] = React.useState('JSMITH');
  const [pin, setPin] = React.useState('');
  const [err, setErr] = React.useState(false);

  const submit = () => {
    if (pin.length >= 4) onLogin(user);
    else { setErr(true); setTimeout(() => setErr(false), 400); }
  };

  return (
    <div style={{ padding: '28px 48px', height: '100%', display: 'flex', gap: 24 }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase', color: '#4934ad' }}>Sign in</div>
        <div style={{ fontSize: 32, fontWeight: 600, letterSpacing: '-0.01em', margin: '6px 0 4px' }}>Welcome back.</div>
        <div style={{ fontSize: 15, color: '#3a4468', marginBottom: 22, maxWidth: 320 }}>
          Enter your operator ID and PIN to start a shift on this terminal.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, maxWidth: 320 }}>
          <Field label="Operator ID" value={user} onChange={setUser} autoFocus />
          <Field label="PIN" type="password" value={pin} onChange={setPin}
                 hint={err ? 'PIN must be at least 4 digits' : 'Keep it private.'} error={err} />
          <Button onClick={submit} size="lg">Sign in</Button>
        </div>
      </div>
      <div style={{
        width: 260, background: 'linear-gradient(135deg,#122559 0%,#4934ad 60%,#d4245c 100%)',
        borderRadius: 14, padding: 24, color: '#fff', display: 'flex', flexDirection: 'column',
        justifyContent: 'space-between',
      }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '.08em', textTransform: 'uppercase', opacity: 0.8 }}>Today</div>
          <div style={{ fontSize: 56, fontWeight: 600, lineHeight: 1, marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>12</div>
          <div style={{ fontSize: 14, opacity: 0.9, marginTop: 4 }}>orders scheduled<br/>on this terminal</div>
        </div>
        <div style={{ fontSize: 13, opacity: 0.85, lineHeight: 1.45 }}>
          "Built around you."<br/>
          <span style={{ opacity: 0.7 }}>Trusted by 130+ manufacturers.</span>
        </div>
      </div>
    </div>
  );
}

window.LoginScreen = LoginScreen;
