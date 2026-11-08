import { useEffect, useState } from 'react';
import api from '../lib/api';

export default function GoodsReceipts() {
  const [receipts, setReceipts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    api.get('/goods_receipts').then(r => setReceipts(r.data.goods_receipts)).finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Goods Receipts</h1>
        <p className="text-gray-500 text-sm mt-1">Record and track delivery confirmations</p>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-sm overflow-hidden">
        {loading ? <div className="p-8 text-center text-gray-400">Loading...</div> :
         receipts.length === 0 ? <div className="p-12 text-center text-gray-400">No goods receipts yet.</div> : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['ID', 'PO ID', 'Received By', 'Received At', 'Created'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {receipts.map(r => (
                <tr key={r.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-5 py-4 font-mono text-xs text-gray-500">GR-{r.id}</td>
                  <td className="px-5 py-4 text-gray-600">PO-{r.purchase_order_id}</td>
                  <td className="px-5 py-4 font-medium text-gray-900">{r.received_by}</td>
                  <td className="px-5 py-4 text-gray-500">{r.received_at ? new Date(r.received_at).toLocaleDateString() : '—'}</td>
                  <td className="px-5 py-4 text-gray-400 text-xs">{new Date(r.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
