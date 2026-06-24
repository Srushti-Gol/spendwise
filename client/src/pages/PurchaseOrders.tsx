import { useEffect, useState } from 'react';
import api from '../lib/api';
import { Plus, Package, TrendingUp } from 'lucide-react';
import toast from 'react-hot-toast';

interface PurchaseOrder {
  id: number; vendor: string; total_amount: number; status: string;
  price_tolerance: number; quantity_tolerance: number; created_at: string;
}

const STATUS_COLORS: Record<string, string> = {
  draft: 'bg-gray-100 text-gray-700',
  sent: 'bg-blue-100 text-blue-700',
  partial: 'bg-yellow-100 text-yellow-700',
  received: 'bg-green-100 text-green-700',
  closed: 'bg-purple-100 text-purple-700',
};

export default function PurchaseOrders() {
  const [pos, setPOs] = useState<PurchaseOrder[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/purchase_orders').then(r => { setPOs(r.data.purchase_orders); setLoading(false); })
         .catch(() => { toast.error('Failed to load purchase orders'); setLoading(false); });
  }, []);

  const totalValue = pos.reduce((sum, po) => sum + Number(po.total_amount), 0);
  const openCount = pos.filter(po => ['sent', 'partial'].includes(po.status)).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Purchase Orders</h1>
          <p className="text-gray-500">Track supplier orders and deliveries</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-xl font-medium hover:bg-indigo-700">
          <Plus className="w-5 h-5" /> New PO
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <Package className="w-5 h-5 text-indigo-500" />
            <span className="text-sm text-gray-500">Total POs</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">{pos.length}</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <TrendingUp className="w-5 h-5 text-green-500" />
            <span className="text-sm text-gray-500">Open Orders</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">{openCount}</p>
        </div>
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-2">
            <Package className="w-5 h-5 text-purple-500" />
            <span className="text-sm text-gray-500">Total Value</span>
          </div>
          <p className="text-2xl font-bold text-gray-900 dark:text-white">${totalValue.toLocaleString()}</p>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-400">Loading...</div>
        ) : pos.length === 0 ? (
          <div className="p-12 text-center">
            <Package className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-400">No purchase orders yet</p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700/50">
              <tr>
                {['Vendor', 'Amount', 'Status', 'Price Tol.', 'Qty Tol.', 'Created'].map(h => (
                  <th key={h} className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
              {pos.map(po => (
                <tr key={po.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/30">
                  <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">{po.vendor}</td>
                  <td className="px-6 py-4 text-gray-700 dark:text-gray-300">${Number(po.total_amount).toLocaleString()}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[po.status] || 'bg-gray-100 text-gray-700'}`}>
                      {po.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-500">{(Number(po.price_tolerance) * 100).toFixed(1)}%</td>
                  <td className="px-6 py-4 text-gray-500">{(Number(po.quantity_tolerance) * 100).toFixed(1)}%</td>
                  <td className="px-6 py-4 text-gray-500">{new Date(po.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
