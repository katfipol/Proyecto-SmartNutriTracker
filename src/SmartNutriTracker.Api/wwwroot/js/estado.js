// Estado compartido de la aplicación
import { api } from './api.js';
import { esc, opciones } from './ui.js';

export const estado = {
  usuario: null,       // { id, nombre, correo, rol, estudianteId }
  catalogos: null,     // CatalogosDto
  estudiantes: null    // EstudianteResumenDto[] (solo personal)
};

export const esRol = (...roles) => roles.includes(estado.usuario?.rol);
export const esPersonal = () => esRol('Admin', 'Docente', 'Nutricionista');
export const esSalud = () => esRol('Admin', 'Nutricionista');

export async function cargarEstudiantes(forzar = false) {
  if (!esPersonal()) return [];
  if (!estado.estudiantes || forzar) estado.estudiantes = await api.get('/api/estudiantes');
  return estado.estudiantes;
}

const CLAVE_SEL = 'snt_estudiante_sel';

/**
 * Devuelve el id de estudiante a usar en la vista:
 * el propio (rol Estudiante) o el seleccionado (personal).
 */
export function estudianteSeleccionado(params) {
  if (estado.usuario.rol === 'Estudiante') return estado.usuario.estudianteId;
  const deRuta = params?.get?.('estudiante');
  if (deRuta) { sessionStorage.setItem(CLAVE_SEL, deRuta); return parseInt(deRuta, 10); }
  const guardado = sessionStorage.getItem(CLAVE_SEL);
  if (guardado && estado.estudiantes?.some(e => String(e.id) === guardado)) return parseInt(guardado, 10);
  return estado.estudiantes?.[0]?.id ?? null;
}

export function recordarEstudiante(id) { sessionStorage.setItem(CLAVE_SEL, String(id)); }

/** HTML del selector de estudiante (solo personal). */
export function htmlSelectorEstudiante(id) {
  if (estado.usuario.rol === 'Estudiante') return '';
  const lista = (estado.estudiantes || []).map(e => ({ id: e.id, nombre: `${e.nombreCompleto} · ${e.curso}` }));
  return `<div class="d-flex align-items-center gap-2">
    <label class="form-label mb-0 text-nowrap" for="sel-estudiante"><i class="bi bi-person"></i> Estudiante</label>
    <select class="form-select form-select-sm" id="sel-estudiante" style="min-width:260px">${opciones(lista, id)}</select></div>`;
}

export function engancharSelector(raiz, alCambiar) {
  const sel = raiz.querySelector('#sel-estudiante');
  sel?.addEventListener('change', () => { recordarEstudiante(sel.value); alCambiar(parseInt(sel.value, 10)); });
}

export const nombreEstudiante = (id) => esc(estado.estudiantes?.find(e => e.id === id)?.nombreCompleto ?? '');
