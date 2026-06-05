async function webAuthnRegister(username) {
  if (!window.PublicKeyCredential) return false;
  const challenge = crypto.getRandomValues(new Uint8Array(32));
  const cred = await navigator.credentials.create({ publicKey: {
    challenge,
    rp: { name: 'ClubConnect', id: location.hostname },
    user: {
      id: new TextEncoder().encode(username),
      name: username,
      displayName: username,
    },
    pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
    authenticatorSelection: {
      userVerification: 'preferred',
    },
    timeout: 60000,
  }});
  localStorage.setItem('webauthn_id', btoa(String.fromCharCode(...new Uint8Array(cred.rawId))));
  localStorage.setItem('webauthn_user', username);
  return true;
}

async function webAuthnAuthenticate() {
  if (!window.PublicKeyCredential) return null;
  const id = localStorage.getItem('webauthn_id');
  if (!id) return null;
  const rawId = Uint8Array.from(atob(id), c => c.charCodeAt(0));
  const challenge = crypto.getRandomValues(new Uint8Array(32));
  await navigator.credentials.get({ publicKey: {
    challenge,
    allowCredentials: [{ id: rawId, type: 'public-key' }],
    userVerification: 'required',
    timeout: 60000,
  }});
  return localStorage.getItem('webauthn_user');
}
