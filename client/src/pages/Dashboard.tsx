import { useEffect, useState } from 'react';
import api from '../lib/api';
import { FileText, ShoppingCart, Receipt, AlertTriangle, TrendingUp, Clock } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

export default function Dashboard() {
  const [stats, setStats] = useState<any>(null);

  useEffect(() => {
    api.get('/dashboard/stats').then(r => setStats(r.data)).catch(console.error);
  }, []);

  const kpis = stats ? [
    { label: 'My Approval Inbox', value: stats.requisitions?.my_inbox ?? 0, icon: Clock, color: 'bg-amber-50 text-amber-600', border: 'border-amber-100' },
    { label: 'Open Purchase Orders', value: stats.purchase_orders?.open ?? 0, icon: ShoppingCart, color: 'bg-blue-50 text-blue-600', border: 'border-blue-100' },
    { label: 'Matched Invoices', value: stats.invoices?.matched ?? 0, icon: Receipt, color: 'bg-green-50 text-green-600', border: 'border-green-100' },
    { label: 'Invoice Exceptions', value: stats.invoices?.exceptions ?? 0, icon: AlertTriangle, color: 'bg-red-50 text-red-600', border: 'border-red-100' },
    { label: 'Total Spend (Approved)', value: `$${((stats.purchase_orders?.total_value ?? 0) / 1000).toFixed(0)}k`, icon: TrendingUp, color: 'bg-indigo-50 text-indigo-600', border: 'border-indigo-100' },
    { label: 'Total Requisitions', value: stats.requisitions?.total ?? 0, icon: FileText, color: 'bg-purple-50 text-purple-600', border: 'border-purple-100' },
  ] : [];

  const chartData = (stats?.spend_by_month || []).map((d: any) => ({
    month: new Date(d.month).toLocaleString('default', { month: 'short', year: '2-digit' }),
    spend: parseFloat(d.total),
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
        <p className="text-gray-500 dark:text-gray-400 text-sm mt-1">Procure-to-pay overview</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {kpis.map(({ label, value, icon: Icon, color, border }) => (
          <div key={label} className={`bg-white dark:bg-gray-800 rounded-2xl p-5 border ${border} dark:border-gray-700 shadow-sm`}>
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${color} mb-3`}>
              <Icon className="w-5 h-5" />
            </div>
            <p className="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{label}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-100 dark:border-gray-700 shadow-sm">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Monthly Invoice Spend</h3>
        {chartData.length === 0 ? (
          <p className="text-gray-400 text-center py-8">No spend data yet</p>
        ) : (
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} tickFormatter={v => `$${(v/1000).toFixed(0)}k`} />
              <Tooltip formatter={(v: any) => [`$${v.toLocaleString()}`, 'Spend']} />
              <Legend />
              <Bar dataKey="spend" fill="#6366f1" radius={[6, 6, 0, 0]} name="Spend" />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}
