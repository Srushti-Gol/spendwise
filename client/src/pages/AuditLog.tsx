import { useEffect, useState } from 'react';
import api from '../lib/api';
import { Shield, Filter } from 'lucide-react';

interface AuditEntry {
  id: number; action: string; auditable_type: string; auditable_id: number;
  user: { id: number; name: string }; ip_address: string; created_at: string;
}

const ACTION_COLORS: Record<string, string> = {
  create: 'bg-green-100 text-green-700',
  update: 'bg-blue-100 text-blue-700',
  approve: 'bg-indigo-100 text-indigo-700',
  reject: 'bg-red-100 text-red-700',
  submit: 'bg-yellow-100 text-yellow-700',
  delete: 'bg-gray-100 text-gray-700',
};

export default function AuditLog() {
  const [logs, setLogs] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [resourceFilter, setResourceFilter] = useState('');

  useEffect(() => {
    const params = resourceFilter ? `?resource_type=${resourceFilter}` : '';
    api.get(`/audit_logs${params}`)
         .then(r => { setLogs(r.data.audit_logs); setLoading(false); })
         .catch(() => setLoading(false));
  }, [resourceFilter]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Audit Log</h1>
        <p className="text-gray-500">Append-only record of every action in the system</p>
      </div>

      <div className="flex items-center gap-3">
        <Filter className="w-5 h-5 text-gray-400" />
        <select value={resourceFilter} onChange={e => setResourceFilter(e.target.value)}
          className="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white text-sm">
          <option value="">All resources</option>
          <option value="Requisition">Requisitions</option>
          <option value="PurchaseOrder">Purchase Orders</option>
          <option value="Invoice">Invoices</option>
          <option value="GoodsReceipt">Goods Receipts</option>
        </select>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-400">Loading audit trail...</div>
        ) : logs.length === 0 ? (
          <div className="p-12 text-center">
            <Shield className="w-12 h-12 text-gray-300 mx-auto mb-3" />
            <p className="text-gray-400">No audit events yet</p>
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700/50">
              <tr>
                {['Action', 'Resource', 'Actor', 'IP Address', 'Timestamp'].map(h => (
                  <th key={h} className="px-6 py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
              {logs.map(log => (
                <tr key={log.id} className="hover:bg-gray-50 dark:hover:bg-gray-700/30">
                  <td className="px-6 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium ${ACTION_COLORS[log.action] || 'bg-gray-100 text-gray-700'}`}>
                      {log.action}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-600 dark:text-gray-300">
                    {log.auditable_type} #{log.auditable_id}
                  </td>
                  <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">{log.user?.name}</td>
                  <td className="px-6 py-4 text-gray-500 font-mono text-sm">{log.ip_address || '—'}</td>
                  <td className="px-6 py-4 text-gray-500 text-sm">{new Date(log.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
