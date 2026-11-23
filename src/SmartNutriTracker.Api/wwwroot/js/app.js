// SOPORTE SIMULADO – Aplicación mínima para la versión de prueba del Equipo 4.
// Solo carga la vista del Equipo 4 (vistas/registro.js). En el sistema integrado se usa el app.js del Equipo 1.
import { api, sesion } from './api.js';
import { estado } from './estado.js';
import { cargando, errorHtml, esc, iniciales } from './ui.js';

import * as registro from './vistas/registro.js';

const TODOS = ['Admin', 'Docente', 'Nutricionista', 'Estudiante'];

const RUTAS = [
  { ruta: 'registro', titulo: 'Registro diario', tituloEst: 'Mi registro diario', icono: 'bi-journal-check', roles: TODOS, vista: registro, seccion: 'Equipo 4 · Hábitos' }
];

const vista = document.getElementById('vista');
const titulo = document.getElementById('titulo');

async function iniciar() {
  if (!sesion.valida()) { window.location.replace('index.html'); return; }
  vista.innerHTML = cargando('Preparando tu espacio...');
  try {
    estado.usuario = await api.get('/api/auth/perfil');
    estado.catalogos = await api.get('/api/catalogos');
  } catch (e) {
    vista.innerHTML = errorHtml(e.message);
    return;
  }

  document.getElementById('nombre-usuario').textContent = estado.usuario.nombre;
  document.getElementById('rol-usuario').textContent = estado.usuario.rol;
  document.getElementById('avatar').textContent = iniciales(estado.usuario.nombre);
  construirMenu();

  document.getElementById('btn-salir').addEventListener('click', (ev) => {
    ev.preventDefault();
    sesion.cerrar();
    sessionStorage.clear();
    window.location.replace('index.html');
  });
  document.getElementById('btn-menu').addEventListener('click', () => document.getElementById('sidebar').classList.toggle('abierto'));

  window.addEventListener('hashchange', navegar);
  await navegar();
}

function rutasPermitidas() {
  return RUTAS.filter(r => r.roles.includes(estado.usuario.rol));
}

function construirMenu() {
  const esEst = estado.usuario.rol === 'Estudiante';
  let html = '';
  let seccionActual = null;
  rutasPermitidas().forEach(r => {
    if (r.seccion !== seccionActual) { html += `<div class="seccion">${esc(r.seccion)}</div>`; seccionActual = r.seccion; }
    html += `<a class="item" href="#/${r.ruta}" data-ruta="${r.ruta}"><i class="bi ${r.icono}"></i>${esc(esEst && r.tituloEst ? r.tituloEst : r.titulo)}</a>`;
  });
  document.getElementById('menu').innerHTML = html;
}

async function navegar() {
  const hash = location.hash.replace(/^#\/?/, '') || 'registro';
  const [camino, consulta] = hash.split('?');
  const [nombre, id] = camino.split('/');
  const params = new URLSearchParams(consulta || '');
  const def = rutasPermitidas().find(r => r.ruta === nombre);

  document.getElementById('sidebar').classList.remove('abierto');
  document.querySelectorAll('#menu a.item').forEach(a => a.classList.toggle('activo', a.dataset.ruta === nombre));

  if (!def) {
    titulo.textContent = 'No encontrado';
    vista.innerHTML = errorHtml('En la versión de prueba solo está disponible el Registro diario (Equipo 4).');
    return;
  }
  const esEst = estado.usuario.rol === 'Estudiante';
  titulo.textContent = esEst && def.tituloEst ? def.tituloEst : def.titulo;
  document.title = `${titulo.textContent} · SmartNutriTracker`;
  vista.innerHTML = cargando();
  try {
    await def.vista.render({ el: vista, id: id ? parseInt(id, 10) : null, params, titulo: (t) => { titulo.textContent = t; } });
  } catch (e) {
    console.error(e);
    vista.innerHTML = errorHtml(e.message || 'Ocurrió un error al cargar la vista.');
  }
}

iniciar();
