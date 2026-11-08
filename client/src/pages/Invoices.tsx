import { useEffect, useState } from 'react';
import api from '../lib/api';
import { Zap, CheckCircle, AlertTriangle, Clock, Copy } from 'lucide-react';
import toast from 'react-hot-toast';

const statusConfig: Record<string, { label: string; color: string; icon: any }> = {
  pending:    { label: 'Pending',    color: 'bg-gray-100 text-gray-700',   icon: Clock },
  processing: { label: 'Processing', color: 'bg-blue-100 text-blue-700',   icon: Zap },
  matched:    { label: 'Matched',    color: 'bg-green-100 text-green-700', icon: CheckCircle },
  exception:  { label: 'Exception',  color: 'bg-red-100 text-red-700',     icon: AlertTriangle },
  approved:   { label: 'Approved',   color: 'bg-indigo-100 text-indigo-700', icon: CheckCircle },
  paid:       { label: 'Paid',       color: 'bg-purple-100 text-purple-700', icon: CheckCircle },
};

export default function Invoices() {
  const [invoices, setInvoices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetch = () => {
    setLoading(true);
    api.get('/invoices').then(r => setInvoices(r.data.invoices)).finally(() => setLoading(false));
  };
  useEffect(() => { fetch(); }, []);

  const processInvoice = async (id: number) => {
    await api.post(`/invoices/${id}/process_invoice`);
    toast.success('Processing queued — AI extraction running');
    setTimeout(fetch, 3000);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Invoices</h1>
          <p className="text-gray-500 text-sm mt-1">AI-powered invoice extraction and 3-way matching</p>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-sm overflow-x-auto">
        {loading ? <div className="p-8 text-center text-gray-400">Loading...</div> :
         invoices.length === 0 ? <div className="p-12 text-center text-gray-400">No invoices yet.</div> : (
          <table className="w-full text-sm min-w-[800px]">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['Invoice #', 'Vendor', 'Amount', 'Status', 'Price Match', 'Qty Match', 'Duplicate', 'Processed', 'Actions'].map(h => (
                  <th key={h} className="px-4 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {invoices.map(inv => {
                const cfg = statusConfig[inv.status] || statusConfig.pending;
                const Icon = cfg.icon;
                return (
                  <tr key={inv.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="px-4 py-4 font-mono text-xs text-gray-600">{inv.invoice_number || `#${inv.id}`}</td>
                    <td className="px-4 py-4 font-medium text-gray-900">{inv.vendor}</td>
                    <td className="px-4 py-4 font-semibold">${parseFloat(inv.total_amount).toLocaleString()}</td>
                    <td className="px-4 py-4">
                      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${cfg.color}`}>
                        <Icon className="w-3.5 h-3.5" />{cfg.label}
                      </span>
                    </td>
                    <td className="px-4 py-4">{inv.price_match === null ? '—' : inv.price_match ? <span className="text-green-600 font-medium">✓</span> : <span className="text-red-600 font-medium">✗ {inv.price_variance ? `(${(inv.price_variance * 100).toFixed(1)}%)` : ''}</span>}</td>
                    <td className="px-4 py-4">{inv.quantity_match === null ? '—' : inv.quantity_match ? <span className="text-green-600 font-medium">✓</span> : <span className="text-red-600 font-medium">✗</span>}</td>
                    <td className="px-4 py-4">{inv.is_duplicate ? <span className="inline-flex items-center gap-1 text-orange-600 text-xs font-medium"><Copy className="w-3.5 h-3.5" />Duplicate</span> : <span className="text-gray-400">—</span>}</td>
                    <td className="px-4 py-4 text-xs text-gray-400">{inv.processed_at ? new Date(inv.processed_at).toLocaleDateString() : '—'}</td>
                    <td className="px-4 py-4">
                      {inv.status === 'pending' && (
                        <button onClick={() => processInvoice(inv.id)} className="flex items-center gap-1 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-medium transition-colors">
                          <Zap className="w-3.5 h-3.5" /> Process
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
