// HU-19 consumo real · HU-20 hábitos · HU-21 historial · HU-22 corregir registros
import { api, conParametros } from '../api.js';
import { estado, cargarEstudiantes, estudianteSeleccionado, htmlSelectorEstudiante, engancharSelector } from '../estado.js';
import { esc, num, fecha, hoyIso, sumarDias, vacio, abrirModal, opciones, toast, on, confirmar, htmlComidas, htmlResumen, leerFormulario } from '../ui.js';

let fechaSel = null;
let alimentosCache = null;

export async function render(ctx) {
  const { el, params } = ctx;
  await cargarEstudiantes();
  const id = estudianteSeleccionado(params);
  if (!id) { el.innerHTML = vacio('No hay estudiantes disponibles.', 'bi-people'); return; }
  const hoy = hoyIso();
  if (!fechaSel || fechaSel > hoy) fechaSel = hoy;
  alimentosCache ??= await api.get('/api/alimentos');

  const [dia, historial] = await Promise.all([
    api.get(conParametros(`/api/consumos/estudiante/${id}`, { fecha: fechaSel })),
    api.get(conParametros(`/api/habitos/estudiante/${id}/historial`, { desde: sumarDias(hoy, -29), hasta: hoy }))
  ]);
  const editable = fechaSel >= sumarDias(hoy, -7);
  const h = dia.habitos;

  el.innerHTML = `
    <div class="d-flex flex-wrap gap-3 align-items-center mb-3">
      ${htmlSelectorEstudiante(id)}
      <div class="d-flex align-items-center gap-1 ms-auto">
        <button class="btn btn-sm btn-light" data-accion="dia" data-delta="-1" title="Día anterior"><i class="bi bi-chevron-left"></i></button>
        <input type="date" class="form-control form-control-sm" id="f-fecha" value="${fechaSel}" max="${hoy}" style="width:160px">
        <button class="btn btn-sm btn-light" data-accion="dia" data-delta="1" ${fechaSel >= hoy ? 'disabled' : ''} title="Día siguiente"><i class="bi bi-chevron-right"></i></button>
        <button class="btn btn-sm btn-outline-primary" data-accion="hoy">Hoy</button>
      </div>
    </div>
    ${editable ? '' : '<div class="alert alert-warning py-2 small"><i class="bi bi-lock me-1"></i>Solo se pueden registrar o corregir los últimos 7 días. Este día es de solo lectura.</div>'}

    <div class="row g-3">
      <div class="col-xl-7">
        <div class="tarjeta h-100"><div class="cabecera"><i class="bi bi-egg-fried" style="color:var(--snt-700)"></i><h3>Comidas del ${fecha(fechaSel, true)}</h3>
          ${editable ? '<button class="btn btn-primary btn-sm ms-auto" data-accion="agregar"><i class="bi bi-plus-lg me-1"></i>Agregar alimento</button>' : ''}</div>
          <div class="cuerpo" id="comidas">${htmlComidas(dia.comidas, { acciones: editable })}</div></div>
      </div>
      <div class="col-xl-5">
        <div class="tarjeta mb-3"><div class="cabecera"><i class="bi bi-speedometer2" style="color:var(--snt-700)"></i><h3>Total del día</h3></div>
          <div class="cuerpo">${htmlResumen(dia.totales, dia.caloriasObjetivo)}
            <div class="d-flex justify-content-between small mt-3"><span>Azúcares</span><strong class="${dia.azucares > 50 ? 'text-danger' : ''}">${num(dia.azucares, 1)} g</strong></div>
            <div class="d-flex justify-content-between small"><span>Sodio</span><strong class="${dia.sodioMg > 2300 ? 'text-danger' : ''}">${num(dia.sodioMg)} mg</strong></div>
          </div></div>

        <div class="tarjeta"><div class="cabecera"><i class="bi bi-heart-pulse" style="color:var(--snt-700)"></i><h3>Hábitos del día</h3>
          ${h ? '<span class="badge b-verde ms-auto">Registrado</span>' : '<span class="badge b-ambar ms-auto">Pendiente</span>'}</div>
          <div class="cuerpo"><form id="form-habitos" novalidate><fieldset ${editable ? '' : 'disabled'}>
            <div class="row g-2">
              <div class="col-4"><label class="form-label"><i class="bi bi-moon-stars"></i> Sueño (h)</label>
                <input type="number" class="form-control" name="horasSueno" data-tipo="num" step="0.5" min="0" max="24" required value="${h?.horasSueno ?? ''}"></div>
              <div class="col-4"><label class="form-label"><i class="bi bi-droplet"></i> Agua (ml)</label>
                <input type="number" class="form-control" name="aguaMl" data-tipo="int" step="50" min="0" max="10000" required value="${h?.aguaMl ?? ''}"></div>
              <div class="col-4"><label class="form-label"><i class="bi bi-bicycle"></i> Actividad (min)</label>
                <input type="number" class="form-control" name="minutosActividad" data-tipo="int" step="5" min="0" max="1440" required value="${h?.minutosActividad ?? ''}"></div>
              <div class="col-12"><label class="form-label">Observaciones</label>
                <input class="form-control" name="observaciones" maxlength="300" data-nulo value="${esc(h?.observaciones ?? '')}" placeholder="¿Cómo te sentiste hoy?"></div>
            </div>
            <div class="d-flex gap-2 mt-3">
              <button class="btn btn-success" type="submit"><i class="bi bi-check2 me-1"></i>${h ? 'Actualizar hábitos' : 'Guardar hábitos'}</button>
              ${h ? `<button class="btn btn-light text-danger" type="button" data-accion="borrar-habitos" data-id="${h.id}"><i class="bi bi-trash"></i></button>` : ''}
            </div>
          </fieldset></form></div></div>
      </div>
    </div>

    <div class="tarjeta mt-3"><div class="cabecera"><i class="bi bi-clock-history" style="color:var(--snt-700)"></i><h3>Historial (últimos 30 días)</h3></div>
      <div class="cuerpo p-0">${historial.length ? `<div class="table-responsive"><table class="table table-hover">
        <thead><tr><th>Fecha</th><th class="text-end">Calorías</th><th class="text-end">Prot.</th><th class="text-end">Carb.</th><th class="text-end">Grasas</th>
          <th class="text-end">Sueño</th><th class="text-end">Agua</th><th class="text-end">Actividad</th><th></th></tr></thead>
        <tbody>${historial.map(d => `<tr>
          <td class="fw-semibold">${fecha(d.fecha, true)}</td>
          <td class="text-end">${d.registrosConsumo ? `${num(d.calorias)} kcal` : '<span class="muted">—</span>'}</td>
          <td class="text-end">${d.registrosConsumo ? num(d.proteinas, 1) + ' g' : '—'}</td>
          <td class="text-end">${d.registrosConsumo ? num(d.carbohidratos, 1) + ' g' : '—'}</td>
          <td class="text-end">${d.registrosConsumo ? num(d.grasas, 1) + ' g' : '—'}</td>
          <td class="text-end">${d.habitos ? num(d.habitos.horasSueno, 1) + ' h' : '—'}</td>
          <td class="text-end">${d.habitos ? num(d.habitos.aguaMl) + ' ml' : '—'}</td>
          <td class="text-end">${d.habitos ? d.habitos.minutosActividad + ' min' : '—'}</td>
          <td class="text-end"><button class="btn btn-sm btn-light" data-accion="ir" data-fecha="${d.fecha}">Ver</button></td></tr>`).join('')}
        </tbody></table></div>` : vacio('Aún no hay registros.', 'bi-journal')}</div></div>`;

  const recargar = () => render(ctx);
  engancharSelector(el, () => recargar());
  el.querySelector('#f-fecha').addEventListener('change', (ev) => { if (ev.target.value) { fechaSel = ev.target.value; recargar(); } });
  on(el, 'click', '[data-accion=dia]', (_, b) => { fechaSel = sumarDias(fechaSel, parseInt(b.dataset.delta, 10)); recargar(); });
  on(el, 'click', '[data-accion=hoy]', () => { fechaSel = hoyIso(); recargar(); });
  on(el, 'click', '[data-accion=ir]', (_, b) => { fechaSel = b.dataset.fecha; recargar(); window.scrollTo({ top: 0, behavior: 'smooth' }); });
  on(el, 'click', '[data-accion=agregar]', () => modalConsumo(id, null, recargar));
  on(el, 'click', '[data-accion=editar-item]', (_, b) => {
    const itemId = parseInt(b.dataset.id, 10);
    const comida = dia.comidas.find(c => c.items.some(i => i.id === itemId));
    const item = comida.items.find(i => i.id === itemId);
    modalConsumo(id, { id: itemId, tipoComidaId: comida.tipoComidaId, alimentoId: item.alimentoId, porciones: item.porciones }, recargar);
  });
  on(el, 'click', '[data-accion=borrar-item]', async (_, b) => {
    if (!await confirmar('¿Eliminar este alimento del registro?', 'Eliminar')) return;
    try { await api.del(`/api/consumos/${b.dataset.id}`); toast('Registro eliminado.'); recargar(); }
    catch (e) { toast(e.message, 'error'); }
  });
  on(el, 'click', '[data-accion=borrar-habitos]', async (_, b) => {
    if (!await confirmar('¿Eliminar los hábitos registrados de este día?', 'Eliminar')) return;
    try { await api.del(`/api/habitos/${b.dataset.id}`); toast('Hábitos eliminados.'); recargar(); }
    catch (e) { toast(e.message, 'error'); }
  });
  el.querySelector('#form-habitos').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const form = ev.target;
    if (!form.checkValidity()) { form.classList.add('was-validated'); return; }
    try {
      await api.put('/api/habitos', { estudianteId: id, fecha: fechaSel, ...leerFormulario(form) });
      toast('Hábitos guardados.');
      window.dispatchEvent(new Event('snt:notificaciones'));
      recargar();
    } catch (e) { toast(e.message, 'error'); }
  });
}

function modalConsumo(estudianteId, item, recargar) {
  const tipos = estado.catalogos.tiposComida;
  const horaActual = new Date().getHours();
  const tipoSugerido = item?.tipoComidaId ?? (horaActual < 10 ? tipos[0] : horaActual < 12 ? tipos[1] : horaActual < 15 ? tipos[2] : horaActual < 18 ? tipos[3] : tipos[4])?.id;
  const contenido = abrirModal({
    titulo: item ? 'Editar alimento consumido' : 'Registrar alimento consumido',
    cuerpo: `<div class="row g-3">
      <div class="col-12"><label class="form-label">Tiempo de comida</label><select class="form-select" name="tipoComidaId" data-tipo="int">${opciones(tipos, tipoSugerido)}</select></div>
      <div class="col-12"><label class="form-label">Alimento</label>
        <input class="form-control form-control-sm mb-1" placeholder="Buscar..." id="buscar-alimento">
        <select class="form-select" name="alimentoId" data-tipo="int" size="7" required id="sel-alimento">${opciones(alimentosCache.map(a => ({ id: a.id, nombre: `${a.nombre} — ${a.porcionDescripcion} · ${Math.round(a.calorias)} kcal` })), item?.alimentoId ?? alimentosCache[0]?.id)}</select></div>
      <div class="col-6"><label class="form-label">Porciones</label><input type="number" class="form-control" name="porciones" data-tipo="num" step="0.25" min="0.25" max="10" required value="${item?.porciones ?? 1}"></div>
      <div class="col-6 d-flex align-items-end"><div class="small muted" id="kcal-estimadas"></div></div>
    </div>`,
    alGuardar: async (form) => {
      const datos = leerFormulario(form);
      if (item) await api.put(`/api/consumos/${item.id}`, datos);
      else await api.post('/api/consumos', { estudianteId, fecha: fechaSel, ...datos });
      toast(item ? 'Registro actualizado.' : 'Alimento registrado.');
      window.dispatchEvent(new Event('snt:notificaciones'));
      recargar();
    }
  });
  const sel = contenido.querySelector('#sel-alimento');
  const porciones = contenido.querySelector('[name=porciones]');
  const estimar = () => {
    const a = alimentosCache.find(x => String(x.id) === sel.value);
    contenido.querySelector('#kcal-estimadas').textContent = a ? `≈ ${num(a.calorias * (parseFloat(porciones.value) || 0))} kcal` : '';
  };
  contenido.querySelector('#buscar-alimento').addEventListener('input', (ev) => {
    const t = ev.target.value.toLowerCase();
    [...sel.options].forEach(o => { o.hidden = !o.text.toLowerCase().includes(t); });
    const primero = [...sel.options].find(o => !o.hidden);
    if (primero) { sel.value = primero.value; estimar(); }
  });
  sel.addEventListener('change', estimar);
  porciones.addEventListener('input', estimar);
  estimar();
}
