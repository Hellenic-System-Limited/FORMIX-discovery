function App() {
  const [screen, setScreen] = React.useState('login');
  const [operator, setOperator] = React.useState(null);

  return (
    <Shell terminal="Scale 1" operator={operator} onLogout={() => { setOperator(null); setScreen('login'); }}>
      {screen === 'login' && <LoginScreen onLogin={op => { setOperator(op); setScreen('menu'); }} />}
      {screen === 'menu' && <MainMenuScreen onPick={p => { if (p === 'process') setScreen('process'); }} />}
      {screen === 'process' && <ProcessRecipeScreen onComplete={() => setScreen('mix')} onBack={() => setScreen('menu')} />}
      {screen === 'mix' && <MixCompleteScreen onDone={() => setScreen('menu')} onBack={() => setScreen('process')} />}
    </Shell>
  );
}

window.App = App;
