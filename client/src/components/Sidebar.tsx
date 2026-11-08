import { NavLink } from 'react-router-dom';
import { LayoutDashboard, ClipboardList, Package, FileText, Shield, X, TrendingUp } from 'lucide-react';

const NAV_LINKS = [
  { to: '/',               icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/requisitions',   icon: ClipboardList,   label: 'Requisitions' },
  { to: '/purchase-orders',icon: Package,         label: 'Purchase Orders' },
  { to: '/invoices',       icon: FileText,        label: 'Invoices' },
  { to: '/audit-log',      icon: Shield,          label: 'Audit Log' },
];

export default function Sidebar({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <>
      {open && (
        <div className="fixed inset-0 bg-black/50 z-20 lg:hidden" onClick={onClose} />
      )}
      <div className={`fixed lg:static inset-y-0 left-0 z-30 w-64 bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-700/50 transform transition-transform duration-200 ${open ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0 flex flex-col`}>
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100 dark:border-gray-700/50">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg flex items-center justify-center shadow-sm">
              <TrendingUp className="w-4 h-4 text-white" />
            </div>
            <span className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">SpendWise</span>
          </div>
          <button onClick={onClose} className="lg:hidden text-gray-400 hover:text-gray-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
          {NAV_LINKS.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to} to={to} end={to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400'
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-200'
                }`
              }
            >
              <Icon className="w-4.5 h-4.5 flex-shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-gray-100 dark:border-gray-700/50">
          <p className="text-xs text-gray-400 text-center">SpendWise v1.0.0</p>
        </div>
      </div>
    </>
  );
}
