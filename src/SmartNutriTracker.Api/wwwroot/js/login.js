import { api, sesion } from './api.js';

if (sesion.valida()) window.location.replace('app.html');

const form = document.getElementById('form-login');
const error = document.getElementById('error');
const spinner = document.getElementById('spinner');
const boton = document.getElementById('btn-ingresar');
const correo = document.getElementById('correo');
const password = document.getElementById('password');

if (new URLSearchParams(location.search).has('expirada')) {
  mostrarError('Tu sesión expiró. Vuelve a iniciar sesión.');
}

function mostrarError(texto) {
  error.textContent = texto;
  error.classList.remove('d-none');
}

document.getElementById('ver-password').addEventListener('click', () => {
  password.type = password.type === 'password' ? 'text' : 'password';
});

document.querySelectorAll('[data-correo]').forEach(b => b.addEventListener('click', () => {
  correo.value = b.dataset.correo;
  password.value = 'Innovare2026!';
  password.focus();
}));

form.addEventListener('submit', async (ev) => {
  ev.preventDefault();
  error.classList.add('d-none');
  if (!correo.value.trim() || !password.value) { mostrarError('Ingrese su correo y contraseña.'); return; }

  boton.disabled = true;
  spinner.classList.remove('d-none');
  try {
    const r = await api.post('/api/auth/login', { correo: correo.value.trim(), password: password.value });
    sesion.guardar({ token: r.token, expiraEn: r.expiraEn, usuario: r.usuario });
    window.location.replace('app.html');
  } catch (e) {
    mostrarError(e.message);
  } finally {
    boton.disabled = false;
    spinner.classList.add('d-none');
  }
});
