// Configuração da landing (index.html).
window.R3_CONFIG = {
  // Opcionais: ferramentas externas. Deixe vazio para não carregar.
  GA4_ID: "",             // ex.: "G-XXXXXXXXXX"
  META_PIXEL_ID: "1755248785773446",      // ex.: "123456789012345"
  CLARITY_ID: "",         // ex.: "abcd1234ef"

  // ZappZen (CRM de WhatsApp): cada envio do formulário vira contato lá. É o destino principal dos leads. Formulários > chave do formulário.
  ZAPPZEN_DOMINIO: "https://zappzen.atendimentoautomatizado.com.br",
  ZAPPZEN_CHAVE: "zzf_9jPkKFkuFPs9vAWZsb4AmRT6",
  // true = envia também na etapa 1 (nome + WhatsApp), para recuperar quem desiste no meio.
  // O ZappZen junta a etapa 1 e o formulário completo da mesma pessoa numa resposta só.
  ZAPPZEN_PARCIAL: true
};
