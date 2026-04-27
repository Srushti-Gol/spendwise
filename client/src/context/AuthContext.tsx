import { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import api from '../lib/api';

interface User { id: number; name: string; email: string; role: string; department?: string; tenant_id: number; }
interface AuthContextType {
  user: User | null; token: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (data: any) => Promise<void>;
  logout: () => void; loading: boolean;
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType);
export const useAuth = () => useContext(AuthContext);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (token) {
      api.get('/auth/me').then(r => setUser(r.data)).catch(() => logout()).finally(() => setLoading(false));
    } else { setLoading(false); }
  }, [token]);

  const login = async (email: string, password: string) => {
    const { data } = await api.post('/auth/login', { email, password });
    localStorage.setItem('token', data.token);
    setToken(data.token); setUser(data.user);
  };

  const register = async (formData: any) => {
    const { data } = await api.post('/auth/register', formData);
    localStorage.setItem('token', data.token);
    setToken(data.token); setUser(data.user);
  };

  const logout = () => {
    localStorage.removeItem('token');
    setToken(null); setUser(null);
  };

  return <AuthContext.Provider value={{ user, token, login, register, logout, loading }}>{children}</AuthContext.Provider>;
}
