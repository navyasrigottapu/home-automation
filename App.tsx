import { useEffect, useState } from 'react';
import { AuthProvider, useAuth } from '@/context/AuthContext';
import { ThemeProvider } from '@/context/ThemeContext';
import AuthPage from '@/pages/AuthPage';
import Sidebar, { type Page } from '@/components/Sidebar';
import TopBar from '@/components/TopBar';
import NotificationsPanel from '@/components/NotificationsPanel';
import DashboardPage from '@/pages/DashboardPage';
import DevicePage from '@/pages/DevicePage';
import CamerasPage from '@/pages/CamerasPage';
import SensorsPage from '@/pages/SensorsPage';
import EnergyPage from '@/pages/EnergyPage';
import AutomationPage from '@/pages/AutomationPage';
import SecurityPage from '@/pages/SecurityPage';
import SettingsPage from '@/pages/SettingsPage';
import { useNotifications } from '@/hooks/useData';
import { useVoiceControl, useVoiceCommands } from '@/hooks/useVoice';
import { Loader2 } from 'lucide-react';
import { seedSampleData } from '@/lib/seed';

const TITLES: Record<Page, string> = {
  dashboard: 'Dashboard',
  lights: 'Lights',
  fans: 'Fans',
  ac: 'Air Conditioner',
  door: 'Smart Door Lock',
  cameras: 'CCTV Cameras',
  sensors: 'Sensors',
  energy: 'Energy Consumption',
  automation: 'Automation Rules',
  security: 'Security',
  settings: 'Settings',
};

function Shell() {
  const { user, loading } = useAuth();
  const [page, setPage] = useState<Page>('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const { notifications } = useNotifications();
  const voiceCommands = useVoiceCommands();
  const voice = useVoiceControl((text) => {
    const result = voiceCommands(text);
    setToast(result);
    setTimeout(() => setToast(null), 3000);
  });

  useEffect(() => {
    if (user) seedSampleData(user.id);
  }, [user]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50 dark:bg-slate-900">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (!user) return <AuthPage />;

  const unread = notifications.filter((n) => !n.read).length;

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-slate-100 via-blue-50 to-cyan-50 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950">
      <Sidebar current={page} onNavigate={setPage} open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex-1 flex flex-col min-w-0">
        <TopBar
          onMenu={() => setSidebarOpen(true)}
          title={TITLES[page]}
          onVoice={voice.start}
          listening={voice.listening}
          notificationCount={unread}
          onBell={() => setNotifOpen(true)}
        />
        <main className="flex-1 p-4 sm:p-6 overflow-y-auto">
          {page === 'dashboard' && <DashboardPage />}
          {page === 'lights' && <DevicePage type="light" title="Light" />}
          {page === 'fans' && <DevicePage type="fan" title="Fan" />}
          {page === 'ac' && <DevicePage type="ac" title="Air Conditioner" />}
          {page === 'door' && <DevicePage type="door" title="Door Lock" />}
          {page === 'cameras' && <CamerasPage />}
          {page === 'sensors' && <SensorsPage />}
          {page === 'energy' && <EnergyPage />}
          {page === 'automation' && <AutomationPage />}
          {page === 'security' && <SecurityPage />}
          {page === 'settings' && <SettingsPage />}
        </main>
      </div>

      <NotificationsPanel open={notifOpen} onClose={() => setNotifOpen(false)} />

      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[60] px-5 py-3 rounded-xl bg-slate-800 dark:bg-blue-600 text-white text-sm font-medium shadow-2xl animate-[fadeIn_0.2s_ease]">
          {toast}
        </div>
      )}
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <ThemeProvider>
        <Shell />
      </ThemeProvider>
    </AuthProvider>
  );
}
