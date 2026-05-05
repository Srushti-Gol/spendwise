import { useEffect, useState } from 'react';
import api from '../lib/api';

const STATUS_COLORS: Record<string, string> = {
  draft: 'bg-gray-100 text-gray-700',
  sent: 'bg-blue-100 text-blue-700',
  partial: 'bg-amber-100 text-amber-700',
  received: 'bg-green-100 text-green-700',
  closed: 'bg-gray-100 text-gray-500',
};

export default function PurchaseOrders() {
  const [pos, setPos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get('/purchase_orders').then(r => setPos(r.data.purchase_orders)).finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Purchase Orders</h1>
        <p className="text-gray-500 text-sm mt-1">Track ordered vs received quantities with configurable tolerances</p>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-sm overflow-hidden">
        {loading ? <div className="p-8 text-center text-gray-400">Loading...</div> :
         pos.length === 0 ? <div className="p-12 text-center text-gray-400">No purchase orders yet.</div> : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['ID', 'Vendor', 'Amount', 'Status', 'Price Tolerance', 'Qty Tolerance', 'Created'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {pos.map(po => (
                <tr key={po.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-5 py-4 font-mono text-xs text-gray-500">PO-{po.id}</td>
                  <td className="px-5 py-4 font-medium text-gray-900 dark:text-white">{po.vendor}</td>
                  <td className="px-5 py-4 font-semibold">${parseFloat(po.total_amount).toLocaleString()}</td>
                  <td className="px-5 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium capitalize ${STATUS_COLORS[po.status] || ''}`}>{po.status}</span>
                  </td>
                  <td className="px-5 py-4 text-gray-500">{(parseFloat(po.price_tolerance) * 100).toFixed(0)}%</td>
                  <td className="px-5 py-4 text-gray-500">{(parseFloat(po.quantity_tolerance) * 100).toFixed(0)}%</td>
                  <td className="px-5 py-4 text-gray-400 text-xs">{new Date(po.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
