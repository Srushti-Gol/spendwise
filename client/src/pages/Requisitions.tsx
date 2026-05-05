import { useEffect, useState } from 'react';
import api from '../lib/api';
import { Plus, CheckCircle, XCircle, Send } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuth } from '../context/AuthContext';

const STATUS_COLORS: Record<string, string> = {
  draft: 'bg-gray-100 text-gray-700',
  pending: 'bg-amber-100 text-amber-700',
  approved: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
  cancelled: 'bg-gray-100 text-gray-500',
  ordered: 'bg-blue-100 text-blue-700',
};

export default function Requisitions() {
  const [reqs, setReqs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  const fetchReqs = () => {
    setLoading(true);
    api.get('/requisitions').then(r => setReqs(r.data.requisitions)).finally(() => setLoading(false));
  };
  useEffect(() => { fetchReqs(); }, []);

  const submit = async (id: number) => {
    await api.post(`/requisitions/${id}/submit`);
    toast.success('Submitted for approval'); fetchReqs();
  };
  const approve = async (id: number) => {
    const comment = prompt('Approval comment (optional):') || undefined;
    await api.post(`/requisitions/${id}/approve`, { comment });
    toast.success('Approved'); fetchReqs();
  };
  const reject = async (id: number) => {
    const comment = prompt('Rejection reason:') || 'Rejected';
    await api.post(`/requisitions/${id}/reject`, { comment });
    toast.success('Rejected'); fetchReqs();
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Requisitions</h1>
          <p className="text-gray-500 text-sm mt-1">Manage purchase requests and approvals</p>
        </div>
        <a href="/requisitions/new" className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-medium text-sm transition-colors">
          <Plus className="w-4 h-4" /> New Requisition
        </a>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-100 dark:border-gray-700 shadow-sm overflow-hidden">
        {loading ? <div className="p-8 text-center text-gray-400">Loading...</div> :
         reqs.length === 0 ? <div className="p-12 text-center text-gray-400">No requisitions yet. Create one to get started.</div> : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 dark:bg-gray-700/50 border-b border-gray-100 dark:border-gray-700">
              <tr>
                {['Title', 'Department', 'Amount', 'Status', 'Requester', 'Current Approver', 'Actions'].map(h => (
                  <th key={h} className="px-5 py-3.5 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
              {reqs.map(r => (
                <tr key={r.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-700/30 transition-colors">
                  <td className="px-5 py-4 font-medium text-gray-900 dark:text-white">{r.title}</td>
                  <td className="px-5 py-4 text-gray-500">{r.department}</td>
                  <td className="px-5 py-4 font-semibold text-gray-900 dark:text-white">${parseFloat(r.total_amount).toLocaleString()}</td>
                  <td className="px-5 py-4">
                    <span className={`px-2.5 py-1 rounded-full text-xs font-medium capitalize ${STATUS_COLORS[r.status] || 'bg-gray-100 text-gray-700'}`}>{r.status}</span>
                  </td>
                  <td className="px-5 py-4 text-gray-500">{r.requester?.name}</td>
                  <td className="px-5 py-4 text-gray-500">{r.current_approver?.name ?? '—'}</td>
                  <td className="px-5 py-4">
                    <div className="flex gap-2">
                      {r.status === 'draft' && r.requester?.id === user?.id && (
                        <button onClick={() => submit(r.id)} className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors" title="Submit">
                          <Send className="w-4 h-4" />
                        </button>
                      )}
                      {r.status === 'pending' && r.current_approver?.id === user?.id && (
                        <>
                          <button onClick={() => approve(r.id)} className="p-1.5 rounded-lg bg-green-50 text-green-600 hover:bg-green-100 transition-colors" title="Approve">
                            <CheckCircle className="w-4 h-4" />
                          </button>
                          <button onClick={() => reject(r.id)} className="p-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors" title="Reject">
                            <XCircle className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
