-- Banco do painel de leads da landing R3.
-- Rode uma vez no Supabase: SQL Editor → New query → cole tudo → Run.

-- Cada passo de cada visitante (entrou, abriu o formulário, concluiu etapa, errou campo, fechou...)
create table if not exists eventos (
  id bigint generated always as identity primary key,
  criado_em timestamptz not null default now(),
  visitante_id text not null,
  evento text not null,
  etapa int,
  campo text,
  utm_source text,
  utm_medium text,
  utm_campaign text
);
create index if not exists eventos_criado_em on eventos (criado_em);

-- Um registro por lead, atualizado a cada etapa concluída
create table if not exists leads (
  lead_id text primary key,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  status text not null,
  etapa int,
  nome text,
  whatsapp text,
  concessionaria text,
  cargo text,
  vendedores text,
  faturamento text,
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_content text,
  utm_term text
);
create index if not exists leads_criado_em on leads (criado_em);
-- Campos da copy v2 (faturamento saiu do formulário; a coluna fica para os leads antigos)
alter table leads add column if not exists cidade text;
alter table leads add column if not exists leads_mes text;

-- Quem pode ver o painel. Cadastre aqui o e-mail de cada usuário criado em Authentication → Users:
--   insert into painel_usuarios (email) values ('voce@r3company.com.br');
create table if not exists painel_usuarios (email text primary key);
alter table painel_usuarios enable row level security;

create or replace function pode_ver_painel() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from painel_usuarios where lower(email) = lower(auth.jwt()->>'email'))
$$;

-- Acesso: a landing (anônima) só escreve; só usuários do painel leem.
alter table eventos enable row level security;
alter table leads enable row level security;

drop policy if exists "landing registra eventos" on eventos;
create policy "landing registra eventos" on eventos for insert to anon with check (true);
drop policy if exists "painel le eventos" on eventos;
create policy "painel le eventos" on eventos for select to authenticated using (pode_ver_painel());
drop policy if exists "painel le leads" on leads;
create policy "painel le leads" on leads for select to authenticated using (pode_ver_painel());

-- A landing grava o lead por esta função, sem precisar de permissão de leitura/edição na tabela.
-- Um lead completo nunca volta a ser parcial.
create or replace function salvar_lead(dados jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into leads (lead_id, status, etapa, nome, whatsapp, concessionaria, cidade, cargo, leads_mes, vendedores,
                     utm_source, utm_medium, utm_campaign, utm_content, utm_term)
  values (dados->>'lead_id', dados->>'status', (dados->>'etapa')::int, dados->>'nome', dados->>'whatsapp',
          nullif(dados->>'concessionaria',''), nullif(dados->>'cidade',''), nullif(dados->>'cargo',''),
          nullif(dados->>'leads_mes',''), nullif(dados->>'vendedores',''), dados->>'utm_source', dados->>'utm_medium',
          dados->>'utm_campaign', dados->>'utm_content', dados->>'utm_term')
  on conflict (lead_id) do update set
    status = excluded.status, etapa = excluded.etapa, nome = excluded.nome, whatsapp = excluded.whatsapp,
    concessionaria = excluded.concessionaria, cidade = excluded.cidade, cargo = excluded.cargo,
    leads_mes = excluded.leads_mes, vendedores = excluded.vendedores, atualizado_em = now()
  where leads.status <> 'completo';
end $$;
revoke all on function salvar_lead(jsonb) from public;
grant execute on function salvar_lead(jsonb) to anon, authenticated;

-- Consultas do painel (respeitam o RLS: só funcionam logado)

-- Pessoas únicas por evento/etapa/campo no período
create or replace function painel_eventos(desde timestamptz)
returns table (evento text, etapa int, campo text, pessoas bigint)
language sql stable as $$
  select evento, etapa, campo, count(distinct visitante_id)
  from eventos where criado_em >= desde
  group by evento, etapa, campo
$$;

-- Visitantes e leads completos por dia (horário de Brasília)
create or replace function painel_diario(desde timestamptz)
returns table (dia date, visitantes bigint, leads bigint)
language sql stable as $$
  select (criado_em at time zone 'America/Sao_Paulo')::date,
         count(distinct visitante_id) filter (where evento = 'page_view'),
         count(distinct visitante_id) filter (where evento = 'form_submit')
  from eventos where criado_em >= desde
  group by 1 order by 1
$$;

-- Visitantes e leads completos por origem (utm_source)
create or replace function painel_origens(desde timestamptz)
returns table (origem text, visitantes bigint, leads bigint)
language sql stable as $$
  select coalesce(utm_source, 'direto'),
         count(distinct visitante_id) filter (where evento = 'page_view'),
         count(distinct visitante_id) filter (where evento = 'form_submit')
  from eventos where criado_em >= desde
  group by 1 order by 2 desc
$$;

revoke all on function painel_eventos(timestamptz), painel_diario(timestamptz), painel_origens(timestamptz) from public, anon;
grant execute on function painel_eventos(timestamptz), painel_diario(timestamptz), painel_origens(timestamptz) to authenticated;
