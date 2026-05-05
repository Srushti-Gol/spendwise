import { useEffect, useState } from 'react';
import api from '../lib/api';

export default function AuditLog() {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [resourceType, setResourceType] = useState('');

  useEffect(() => {
    setLoading(true);
    const params = resourceType ? `?resource_type=${resourceType}` : '';
    api.get(`/audit_logs${params}`).then(r => setLogs(r.data.audit_logs)).finally(() => setLoading(false));
  }, [resourceType]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Audit Log</h1>
          <p className="text-gray-500 text-sm mt-1">Append-only record of all actions. Sub-millisecond page loads via composite indexes.</p>
        </div>
        <select value={resourceType} onChange={e => setResourceType(e.target.value)}
          className="px-3 py-2 rounded-xl border border-gray-200 text-sm bg-white focus:ring-2 focus:ring-indigo-500 outline-none">
          <option value="">All resources</option>
          {['Requisition', 'PurchaseOrder', 'Invoice', 'GoodsReceipt'].map(t => <option key={t} value={t}>{t}</option>)}
        </select>
      </div>
      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-sm overflow-hidden">
        {loading ? <div className="p-8 text-center text-gray-400">Loading...</div> :
         logs.length === 0 ? <div className="p-12 text-center text-gray-400">No audit log entries yet.</div> : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['Time', 'User', 'Action', 'Resource', 'Resource ID', 'IP'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {logs.map(l => (
                <tr key={l.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="px-5 py-3.5 text-xs text-gray-500 whitespace-nowrap">{new Date(l.created_at).toLocaleString()}</td>
                  <td className="px-5 py-3.5 font-medium text-gray-900">{l.user?.name}</td>
                  <td className="px-5 py-3.5">
                    <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-50 text-indigo-700 capitalize">{l.action}</span>
                  </td>
                  <td className="px-5 py-3.5 text-gray-600">{l.auditable_type}</td>
                  <td className="px-5 py-3.5 font-mono text-xs text-gray-400">{l.auditable_id}</td>
                  <td className="px-5 py-3.5 font-mono text-xs text-gray-400">{l.ip_address}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
