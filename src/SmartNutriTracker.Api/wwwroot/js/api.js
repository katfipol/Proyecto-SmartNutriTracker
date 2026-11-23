// Cliente HTTP de la API con manejo del token JWT
const CLAVE = 'snt_sesion';

export const sesion = {
  obtener() {
    try { return JSON.parse(localStorage.getItem(CLAVE)); } catch { return null; }
  },
  guardar(datos) { localStorage.setItem(CLAVE, JSON.stringify(datos)); },
  cerrar() { localStorage.removeItem(CLAVE); },
  valida() {
    const s = this.obtener();
    return !!(s && s.token && new Date(s.expiraEn) > new Date());
  }
};

export class ApiError extends Error {
  constructor(mensaje, status, detalles) {
    super(mensaje);
    this.status = status;
    this.detalles = detalles;
  }
}

async function solicitud(metodo, url, cuerpo) {
  const s = sesion.obtener();
  const headers = { 'Accept': 'application/json' };
  if (cuerpo !== undefined) headers['Content-Type'] = 'application/json';
  if (s?.token) headers['Authorization'] = `Bearer ${s.token}`;

  let resp;
  try {
    resp = await fetch(url, { method: metodo, headers, body: cuerpo !== undefined ? JSON.stringify(cuerpo) : undefined });
  } catch {
    throw new ApiError('No se pudo conectar con el servidor. Verifique que la API esté en ejecución.', 0);
  }

  if (resp.status === 401 && !url.endsWith('/api/auth/login')) {
    sesion.cerrar();
    window.location.href = 'index.html?expirada=1';
    throw new ApiError('La sesión expiró. Inicie sesión nuevamente.', 401);
  }

  if (resp.status === 204) return null;
  const texto = await resp.text();
  let datos = null;
  if (texto) { try { datos = JSON.parse(texto); } catch { datos = texto; } }

  if (!resp.ok) {
    let mensaje = datos?.detail || datos?.title || `Error ${resp.status}`;
    if (resp.status === 403 && !datos?.detail) mensaje = 'No tiene permisos para realizar esta acción.';
    if (resp.status === 429) mensaje = 'Demasiados intentos. Espere un minuto e inténtelo de nuevo.';
    if (datos?.errors) {
      const lista = Object.values(datos.errors).flat();
      if (lista.length) mensaje = lista.join(' ');
    }
    throw new ApiError(mensaje, resp.status, datos);
  }
  return datos;
}

export const api = {
  get: (url) => solicitud('GET', url),
  post: (url, cuerpo = {}) => solicitud('POST', url, cuerpo),
  put: (url, cuerpo = {}) => solicitud('PUT', url, cuerpo),
  patch: (url, cuerpo = {}) => solicitud('PATCH', url, cuerpo),
  del: (url) => solicitud('DELETE', url)
};

/** Construye una URL con parámetros de consulta, omitiendo los vacíos. */
export function conParametros(url, params = {}) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== '') q.append(k, v); });
  const s = q.toString();
  return s ? `${url}?${s}` : url;
}
