import { getSession } from './supabase.js';

const $ = (selector) => document.querySelector(selector);
let initialized = false;
let modal;

function installUserForm(button) {
  if (initialized) return;
  initialized = true;

  button.id = 'addUserButton';
  button.textContent = '＋ Tambah pengguna';

  const guide = button.closest('section')?.querySelector('.team-guide');
  if (guide) {
    guide.innerHTML = '<b>Cara menambah pengguna</b><br>Admin membuat akun dengan email perusahaan dan password sementara. Akun langsung aktif tanpa verifikasi email, dengan peran awal <b>Pengguna</b>.';
  }

  document.head.insertAdjacentHTML('beforeend', `<style>
    #userCreateModal{width:min(560px,calc(100% - 28px));border:0;border-radius:15px;padding:0;box-shadow:0 28px 80px #10243b42}
    #userCreateModal::backdrop{background:#10243b80}
    .user-create-head{display:flex;justify-content:space-between;gap:16px;padding:20px 22px;border-bottom:1px solid #e4eaf0}
    .user-create-head h2,.user-create-head p{margin:0}.user-create-head p{margin-top:5px;color:#718092;font-size:10px}
    .user-create-close{width:38px;height:38px;border:1px solid #d8e0e8;border-radius:9px;background:#fff;font-size:18px}
    .user-create-form{padding:20px 22px}.user-create-grid{display:grid;grid-template-columns:1fr 1fr;gap:13px}
    .user-create-form label{display:block;margin:0 0 13px;font-size:10px;font-weight:800;color:#405164}
    .user-create-form input{display:block;width:100%;height:42px;margin-top:6px;padding:10px 11px;border:1px solid #cbd5df;border-radius:8px;font:inherit}
    .user-create-form input:focus{outline:3px solid #1767d929;border-color:#1767d9}.user-create-wide{grid-column:1/-1}
    .user-create-note{padding:11px 12px;border-radius:9px;background:#fff6df;color:#74531c;font-size:10px;line-height:1.5}
    .user-create-error{min-height:20px;margin-top:10px;color:#b73832;font-size:10px}.user-create-actions{display:flex;justify-content:flex-end;gap:9px;margin-top:12px}
    .user-create-actions button{min-height:42px;padding:9px 15px;border-radius:9px;font-weight:800}.user-create-cancel{border:1px solid #d5dde5;background:#fff}
    .user-create-submit{border:0;background:#1767d9;color:#fff}.user-create-submit:disabled{opacity:.6}
    @media(max-width:620px){.user-create-grid{grid-template-columns:1fr}.user-create-wide{grid-column:auto}}
  </style>`);

  document.body.insertAdjacentHTML('beforeend', `<dialog id="userCreateModal" aria-labelledby="userCreateTitle">
    <div class="user-create-head"><div><h2 id="userCreateTitle">Tambah Pengguna</h2><p>Akun langsung aktif tanpa verifikasi email.</p></div><button type="button" class="user-create-close" aria-label="Tutup">×</button></div>
    <form class="user-create-form" id="userCreateForm">
      <div class="user-create-grid">
        <label>Nama lengkap<input name="full_name" autocomplete="name" required maxlength="120"></label>
        <label>Departemen<input name="department" required maxlength="80" placeholder="Engineering / SHE / GA"></label>
        <label class="user-create-wide">Email perusahaan<input name="email" type="email" autocomplete="off" required placeholder="nama@jambiprimacoal.co.id"></label>
        <label class="user-create-wide">Password sementara<input name="password" type="password" autocomplete="new-password" minlength="10" required></label>
      </div>
      <div class="user-create-note">Peran awal adalah <b>Pengguna</b>. Admin dapat mengubahnya menjadi Verifier, KTT/PTL, atau Admin setelah akun dibuat. Minta pengguna mengganti password sementara setelah login pertama.</div>
      <div class="user-create-error" id="userCreateError" role="alert"></div>
      <div class="user-create-actions"><button type="button" class="user-create-cancel">Batal</button><button type="submit" class="user-create-submit">Buat pengguna</button></div>
    </form>
  </dialog>`);

  modal = $('#userCreateModal');
  const form = $('#userCreateForm');
  const error = $('#userCreateError');
  const submit = form.querySelector('.user-create-submit');
  const close = () => { if (modal.open) modal.close(); error.textContent = ''; };

  modal.querySelector('.user-create-close').addEventListener('click', close);
  modal.querySelector('.user-create-cancel').addEventListener('click', close);
  modal.addEventListener('click', (event) => { if (event.target === modal) close(); });

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    error.textContent = '';
    submit.disabled = true;
    submit.textContent = 'Membuat...';
    const data = new FormData(form);
    const session = getSession();
    try {
      if (!session?.access_token) throw new Error('Sesi Admin tidak tersedia');
      const response = await fetch('/api/admin-create-user', {
        method: 'POST',
        headers: { Authorization: `Bearer ${session.access_token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ full_name: data.get('full_name'), department: data.get('department'), email: data.get('email'), password: data.get('password') })
      });
      const result = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(result.error || 'Pengguna gagal dibuat');
      close();
      $('#refreshTeam')?.click();
      const toast = $('#globalActivityToast');
      if (toast) {
        toast.querySelector('b').textContent = 'Pengguna berhasil dibuat';
        $('#globalActivityText').textContent = `${result.user.full_name} dapat langsung login tanpa verifikasi email.`;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 3500);
      }
    } catch (err) {
      error.textContent = err.message;
    } finally {
      submit.disabled = false;
      submit.textContent = 'Buat pengguna';
    }
  });
}

function ensureInstalled() {
  const button = $('#addUserButton, #copySignup');
  if (button) installUserForm(button);
}

document.addEventListener('click', (event) => {
  const button = event.target.closest?.('#addUserButton, #copySignup');
  if (!button) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  if (!initialized) installUserForm(button);
  const form = $('#userCreateForm');
  form.reset();
  $('#userCreateError').textContent = '';
  if (!modal.open) modal.showModal();
}, true);

ensureInstalled();
if (!initialized) {
  const observer = new MutationObserver(() => {
    ensureInstalled();
    if (initialized) observer.disconnect();
  });
  observer.observe(document.body, { childList: true, subtree: true });
}
