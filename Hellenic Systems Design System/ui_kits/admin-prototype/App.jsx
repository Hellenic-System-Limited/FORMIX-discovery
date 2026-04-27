import { AdminShell } from './Shell.jsx';
import { AdminNav } from './Nav.jsx';
import { RecipeAdmin } from './RecipeAdmin.jsx';
import { OrderAdmin } from './OrderAdmin.jsx';
import { IngredientAdmin } from './IngredientAdmin.jsx';
import { UserAdmin } from './UserAdmin.jsx';
import { AuditAdmin } from './AuditAdmin.jsx';

function App() {
  const [section, setSection] = React.useState('recipes');
  return (
    <AdminShell>
      <AdminNav section={section} onSection={setSection} />
      <div style={{ flex: 1, padding: 32, overflow: 'auto' }}>
        {section === 'recipes' && <RecipeAdmin />}
        {section === 'orders' && <OrderAdmin />}
        {section === 'ingredients' && <IngredientAdmin />}
        {section === 'users' && <UserAdmin />}
        {section === 'audit' && <AuditAdmin />}
      </div>
    </AdminShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);