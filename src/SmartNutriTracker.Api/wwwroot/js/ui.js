// Utilidades de interfaz: escape HTML, formatos, toasts, modales, gráficos
/* global bootstrap, Chart */

export const PALETA = ['#2d6a4f', '#52b788', '#a7c957', '#95d5b2', '#1b4332', '#74c69d', '#e9c46a', '#e76f51'];

/** Escapa texto para insertarlo en HTML (previene XSS). */
export function esc(valor) {
  if (valor === null || valor === undefined) return '';
  return String(valor)
    .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;').replaceAll("'", '&#39;');
}

export const num = (v, dec = 0) => (v === null || v === undefined || v === '') ? '—'
  : Number(v).toLocaleString('es-BO', { minimumFractionDigits: dec, maximumFractionDigits: dec });

export function hoyIso() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
export function sumarDias(iso, dias) {
  const [y, m, d] = iso.split('-').map(Number);
  const f = new Date(y, m - 1, d + dias);
  return `${f.getFullYear()}-${String(f.getMonth() + 1).padStart(2, '0')}-${String(f.getDate()).padStart(2, '0')}`;
}

/** Fecha 'yyyy-MM-dd' → 'lun 06/11/2026' */
export function fecha(iso, conDia = false) {
  if (!iso) return '—';
  const [y, m, d] = iso.substring(0, 10).split('-').map(Number);
  const f = new Date(y, m - 1, d);
  const base = f.toLocaleDateString('es-BO', { day: '2-digit', month: '2-digit', year: 'numeric' });
  return conDia ? `${f.toLocaleDateString('es-BO', { weekday: 'short' })} ${base}` : base;
}
export function fechaCorta(iso) {
  const [y, m, d] = iso.substring(0, 10).split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('es-BO', { weekday: 'short', day: '2-digit' });
}
/** Fecha y hora local (citas). */
export function fechaHora(valor) {
  if (!valor) return '—';
  return new Date(valor).toLocaleString('es-BO', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}
/** Fecha y hora guardada en UTC por el servidor (auditoría, notificaciones). */
export function fechaHoraUtc(valor) {
  if (!valor) return '—';
  const s = /[zZ]|[+-]\d\d:\d\d$/.test(valor) ? valor : `${valor}Z`;
  return fechaHora(s);
}
export function haceCuanto(valorUtc) {
  const s = /[zZ]|[+-]\d\d:\d\d$/.test(valorUtc) ? valorUtc : `${valorUtc}Z`;
  const min = Math.round((Date.now() - new Date(s).getTime()) / 60000);
  if (min < 1) return 'ahora';
  if (min < 60) return `hace ${min} min`;
  const h = Math.round(min / 60);
  if (h < 24) return `hace ${h} h`;
  return `hace ${Math.round(h / 24)} d`;
}

export function iniciales(nombre) {
  return (nombre || '?').split(' ').filter(p => p && !p.endsWith('.')).slice(0, 2).map(p => p[0].toUpperCase()).join('');
}

// ---------------- Badges ----------------
export function badgeImc(categoria) {
  const c = { 'Bajo peso': 'b-ambar', 'Normal': 'b-verde', 'Sobrepeso': 'b-ambar', 'Obesidad': 'b-coral' }[categoria] || 'b-gris';
  return `<span class="badge ${c}">${esc(categoria)}</span>`;
}
export function badgeNivel(nivel) {
  const c = { 'Alta': 'b-coral', 'Media': 'b-ambar', 'Baja': 'b-lima' }[nivel] || 'b-gris';
  return `<span class="badge ${c}">${esc(nivel)}</span>`;
}
export function badgeEstado(estado) {
  const c = {
    'Generada': 'b-gris', 'Aceptada': 'b-verde', 'Rechazada': 'b-coral',
    'Programada': 'b-lima', 'Completada': 'b-verde', 'Cancelada': 'b-gris'
  }[estado] || 'b-gris';
  return `<span class="badge ${c}">${esc(estado)}</span>`;
}

// ---------------- Estados de carga ----------------
export const cargando = (texto = 'Cargando...') =>
  `<div class="cargando"><div class="spinner-border mb-2" role="status"></div><div>${esc(texto)}</div></div>`;
export const vacio = (texto, icono = 'bi-inbox') => `<div class="vacio"><i class="bi ${icono}"></i>${esc(texto)}</div>`;
export const errorHtml = (texto) =>
  `<div class="alert alert-danger d-flex gap-2"><i class="bi bi-exclamation-triangle"></i><div>${esc(texto)}</div></div>`;

export function barra(valor, maximo) {
  const pct = maximo > 0 ? Math.round(valor / maximo * 100) : 0;
  return `<div class="progreso ${pct > 110 ? 'excedido' : ''}"><div style="width:${Math.min(pct, 100)}%"></div></div>`;
}

// ---------------- Toasts ----------------
export function toast(mensaje, tipo = 'exito') {
  const iconos = { exito: 'bi-check-circle-fill', error: 'bi-x-circle-fill', info: 'bi-info-circle-fill' };
  const colores = { exito: 'var(--snt-800)', error: 'var(--snt-rojo)', info: 'var(--snt-700)' };
  const el = document.createElement('div');
  el.className = 'toast align-items-center text-white border-0';
  el.style.background = colores[tipo];
  el.innerHTML = `<div class="d-flex"><div class="toast-body"><i class="bi ${iconos[tipo]} me-2"></i>${esc(mensaje)}</div>
    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>`;
  document.getElementById('toasts').appendChild(el);
  const t = new bootstrap.Toast(el, { delay: tipo === 'error' ? 6000 : 3500 });
  el.addEventListener('hidden.bs.toast', () => el.remove());
  t.show();
}

// ---------------- Modal genérico ----------------
let modalBs = null;
function modalEl() { return document.getElementById('modal'); }

/**
 * Abre un modal. `cuerpo` es HTML; `alGuardar(form)` puede lanzar errores (se muestran en el modal).
 * Devuelve el elemento del modal para enganchar eventos extra.
 */
export function abrirModal({ titulo, cuerpo, textoGuardar = 'Guardar', alGuardar = null, tamano = '' }) {
  const el = modalEl();
  el.querySelector('.modal-dialog').className = `modal-dialog modal-dialog-scrollable ${tamano}`;
  // Se reemplaza el contenido por un nodo nuevo para no acumular listeners entre aperturas
  const anterior = el.querySelector('.modal-content');
  const contenido = anterior.cloneNode(false);
  anterior.replaceWith(contenido);
  contenido.innerHTML = `
    <form novalidate>
      <div class="modal-header"><h5 class="modal-title">${esc(titulo)}</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
      <div class="modal-body"><div class="alert alert-danger d-none" data-error></div>${cuerpo}</div>
      <div class="modal-footer">
        <button type="button" class="btn btn-light" data-bs-dismiss="modal">${alGuardar ? 'Cancelar' : 'Cerrar'}</button>
        ${alGuardar ? `<button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm d-none me-1"></span>${esc(textoGuardar)}</button>` : ''}
      </div>
    </form>`;
  const form = contenido.querySelector('form');
  form.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    if (!alGuardar) return;
    const alerta = form.querySelector('[data-error]');
    const boton = form.querySelector('button[type=submit]');
    alerta.classList.add('d-none');
    if (!form.checkValidity()) { form.classList.add('was-validated'); return; }
    boton.disabled = true;
    boton.querySelector('.spinner-border').classList.remove('d-none');
    try {
      await alGuardar(form);
      cerrarModal();
    } catch (e) {
      alerta.textContent = e.message;
      alerta.classList.remove('d-none');
    } finally {
      boton.disabled = false;
      boton.querySelector('.spinner-border').classList.add('d-none');
    }
  });
  modalBs = bootstrap.Modal.getOrCreateInstance(el);
  modalBs.show();
  return contenido;
}
export function cerrarModal() { modalBs?.hide(); }

export function confirmar(mensaje, textoBoton = 'Confirmar') {
  return new Promise(resolve => {
    let resuelto = false;
    const el = abrirModal({
      titulo: 'Confirmar', cuerpo: `<p class="mb-0">${esc(mensaje)}</p>`, textoGuardar: textoBoton,
      alGuardar: async () => { resuelto = true; resolve(true); }
    });
    document.getElementById('modal').addEventListener('hidden.bs.modal', () => { if (!resuelto) resolve(false); }, { once: true });
  });
}

/** Lee los campos con atributo name de un formulario. data-tipo="num|int|bool" convierte el valor. */
export function leerFormulario(form) {
  const datos = {};
  form.querySelectorAll('[name]').forEach(c => {
    const tipo = c.dataset.tipo;
    let v;
    if (c.type === 'checkbox') v = c.checked;
    else if (c.multiple) v = [...c.selectedOptions].map(o => tipo === 'int' ? parseInt(o.value, 10) : o.value);
    else v = c.value.trim();
    if (!c.multiple && c.type !== 'checkbox') {
      if (tipo === 'num') v = v === '' ? null : parseFloat(v);
      if (tipo === 'int') v = v === '' ? null : parseInt(v, 10);
      if (v === '' && c.dataset.nulo !== undefined) v = null;
    }
    datos[c.name] = v;
  });
  return datos;
}

export const opciones = (lista, seleccionado, { valor = 'id', texto = 'nombre', vacioTexto = null } = {}) =>
  (vacioTexto !== null ? `<option value="">${esc(vacioTexto)}</option>` : '') +
  lista.map(o => `<option value="${esc(o[valor])}" ${String(o[valor]) === String(seleccionado) ? 'selected' : ''}>${esc(o[texto])}</option>`).join('');

/** Delegación de eventos: on(contenedor, 'click', '[data-accion=x]', fn) */
export function on(raiz, evento, selector, fn) {
  raiz.addEventListener(evento, (ev) => {
    const objetivo = ev.target.closest(selector);
    if (objetivo && raiz.contains(objetivo)) fn(ev, objetivo);
  });
}

// ---------------- Gráficos ----------------
const graficos = new Map();
export function grafico(canvas, config) {
  if (!canvas) return null;
  graficos.get(canvas)?.destroy();
  Chart.defaults.font.family = getComputedStyle(document.body).fontFamily;
  Chart.defaults.color = '#4c5d53';
  const g = new Chart(canvas, {
    ...config,
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { labels: { usePointStyle: true, boxWidth: 8 } }, ...(config.options?.plugins || {}) },
      ...config.options
    }
  });
  graficos.set(canvas, g);
  return g;
}
export function destruirGraficos() { graficos.forEach(g => g.destroy()); graficos.clear(); }

/** Tarjeta KPI */
export const kpi = (icono, color, valor, etiqueta) => `
  <div class="tarjeta kpi"><div class="icono ${color}"><i class="bi ${icono}"></i></div>
  <div><div class="valor">${valor}</div><div class="etiqueta">${esc(etiqueta)}</div></div></div>`;

/** Lista de comidas (DTO ComidaDto[]) */
export function htmlComidas(comidas, { acciones = false } = {}) {
  if (!comidas?.length) return vacio('No hay alimentos registrados.', 'bi-egg');
  return comidas.map(c => `
    <div class="comida">
      <div class="titulo"><span><i class="bi bi-clock me-1 muted"></i>${esc(c.tipoComida)}</span>
        <span class="badge b-verde">${num(c.calorias)} kcal</span></div>
      ${c.items.map(i => `
        <div class="item">
          <div><div class="fw-semibold">${esc(i.alimento)}</div>
            <div class="small muted">${num(i.porciones, 1)} × ${esc(i.porcion)} · P ${num(i.proteinas, 1)} g · C ${num(i.carbohidratos, 1)} g · G ${num(i.grasas, 1)} g</div></div>
          <div class="d-flex align-items-center gap-2 text-nowrap">
            <span class="small fw-semibold">${num(i.calorias)} kcal</span>
            ${acciones ? `<button class="btn btn-sm btn-light" data-accion="editar-item" data-id="${i.id}" title="Editar"><i class="bi bi-pencil"></i></button>
            <button class="btn btn-sm btn-light text-danger" data-accion="borrar-item" data-id="${i.id}" title="Eliminar"><i class="bi bi-trash"></i></button>` : ''}
          </div>
        </div>`).join('')}
    </div>`).join('');
}

/** Resumen nutricional (ResumenNutricionalDto) */
export function htmlResumen(r, objetivoKcal = null) {
  const ok = r.evaluacion?.startsWith('Saludable');
  return `
    <div class="d-flex justify-content-between align-items-end mb-1">
      <div><div class="muted small">Calorías</div><div class="fs-4 fw-bold" style="color:var(--snt-900)">${num(r.calorias)}
        ${objetivoKcal ? `<span class="fs-6 muted fw-normal">/ ${num(objetivoKcal)} kcal</span>` : 'kcal'}</div></div>
      ${objetivoKcal ? `<span class="badge b-verde">${num(r.calorias / objetivoKcal * 100)}%</span>` : ''}
    </div>
    ${objetivoKcal ? barra(r.calorias, objetivoKcal) : ''}
    <div class="row text-center mt-3 g-2">
      <div class="col"><div class="small muted">Proteínas</div><div class="fw-bold">${num(r.proteinas, 1)} g</div><div class="small muted">${num(r.pctProteina, 0)}%</div></div>
      <div class="col"><div class="small muted">Carbohidratos</div><div class="fw-bold">${num(r.carbohidratos, 1)} g</div><div class="small muted">${num(r.pctCarbohidratos, 0)}%</div></div>
      <div class="col"><div class="small muted">Grasas</div><div class="fw-bold">${num(r.grasas, 1)} g</div><div class="small muted">${num(r.pctGrasas, 0)}%</div></div>
    </div>
    <div class="observacion ${ok ? '' : 'alerta'} mt-3 mb-0"><i class="bi ${ok ? 'bi-check2-circle' : 'bi-exclamation-circle'} me-1"></i>${esc(r.evaluacion)}</div>`;
}
