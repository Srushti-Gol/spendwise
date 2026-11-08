import { Menu, LogOut, User } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function Header({ onMenuClick }: { onMenuClick: () => void }) {
  const { user, logout } = useAuth();
  return (
    <header className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-6 py-4 flex items-center justify-between">
      <button onClick={onMenuClick} className="lg:hidden text-gray-500 hover:text-gray-700"><Menu className="w-6 h-6" /></button>
      <div className="flex-1" />
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
          <User className="w-4 h-4" />
          <span>{user?.name}</span>
          <span className="px-2 py-0.5 bg-indigo-100 dark:bg-indigo-900/40 text-indigo-700 dark:text-indigo-300 rounded-full text-xs font-medium capitalize">{user?.role}</span>
        </div>
        <button onClick={logout} className="flex items-center gap-1 text-sm text-gray-500 hover:text-red-600 transition-colors">
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
}
