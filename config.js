// Configuração compartilhada pela landing (index.html) e pelo painel (painel.html).

// Supabase: Project Settings → API. A chave "anon" é pública por natureza; o acesso é controlado pelo supabase/schema.sql.
window.R3_CONFIG = {
  SUPABASE_URL: "",       // ex.: "https://abcdefgh.supabase.co"
  SUPABASE_ANON_KEY: "",  // ex.: "eyJhbGciOi..."

  // Opcionais: ferramentas externas. Deixe vazio para não carregar.
  GA4_ID: "",             // ex.: "G-XXXXXXXXXX"
  META_PIXEL_ID: "",      // ex.: "123456789012345"
  CLARITY_ID: ""          // ex.: "abcd1234ef"
};
