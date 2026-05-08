import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Requisitions from './pages/Requisitions';
import PurchaseOrders from './pages/PurchaseOrders';
import GoodsReceipts from './pages/GoodsReceipts';
import Invoices from './pages/Invoices';
import AuditLog from './pages/AuditLog';

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Toaster position="top-right" toastOptions={{ style: { borderRadius: '12px', fontSize: '14px' } }} />
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route path="/" element={<Dashboard />} />
              <Route path="/requisitions" element={<Requisitions />} />
              <Route path="/purchase-orders" element={<PurchaseOrders />} />
              <Route path="/goods-receipts" element={<GoodsReceipts />} />
              <Route path="/invoices" element={<Invoices />} />
              <Route path="/audit-log" element={<AuditLog />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
