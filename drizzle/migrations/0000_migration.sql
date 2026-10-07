
-- ===== ENUMS =====
create type public.app_role as enum ('admin','operador','funcionario');
create type public.status_operacao as enum ('EM_OPERACAO','DEVOLVIDO','DEVOLUCAO_PARCIAL','CANCELADO');
create type public.tipo_movimentacao as enum ('ENTRADA','RETIRADA','DEVOLUCAO','AJUSTE','CANCELAMENTO');

-- ===== PROFILES & ROLES =====
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null default '',
  email text,
  created_at timestamptz not null default now()
);
grant select, update on public.profiles to authenticated;
grant all on public.profiles to service_role;
alter table public.profiles enable row level security;

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  role app_role not null,
  unique (user_id, role)
);
grant select, insert, delete on public.user_roles to authenticated;
grant all on public.user_roles to service_role;
alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role)
$$;

create or replace function public.is_staff(_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role in ('admin','operador'))
$$;

create policy "own or admin read profiles" on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff(auth.uid()));
create policy "own update profile" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "read own roles or admin" on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.has_role(auth.uid(),'admin'));
create policy "admin insert roles" on public.user_roles for insert to authenticated
  with check (public.has_role(auth.uid(),'admin'));
create policy "admin delete roles" on public.user_roles for delete to authenticated
  using (public.has_role(auth.uid(),'admin'));

-- first user becomes admin, others operador
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)), new.email);
  if not exists (select 1 from public.user_roles where role = 'admin') then
    insert into public.user_roles (user_id, role) values (new.id, 'admin');
  else
    insert into public.user_roles (user_id, role) values (new.id, 'operador');
  end if;
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== CATEGORIAS =====
create table public.categorias (
  id uuid primary key default gen_random_uuid(),
  nome text not null unique,
  created_at timestamptz not null default now()
);
grant select, insert, update, delete on public.categorias to authenticated;
grant all on public.categorias to service_role;
alter table public.categorias enable row level security;
create policy "auth read categorias" on public.categorias for select to authenticated using (true);
create policy "admin write categorias" on public.categorias for all to authenticated
  using (public.has_role(auth.uid(),'admin')) with check (public.has_role(auth.uid(),'admin'));

-- ===== FUNCIONARIOS =====
create table public.funcionarios (
  id uuid primary key default gen_random_uuid(),
  gh text not null default '',
  nome text not null,
  matricula text not null unique,
  cpf text,
  telefone text,
  cargo text,
  status text not null default 'ATIVO' check (status in ('ATIVO','INATIVO')),
  user_id uuid,
  created_at timestamptz not null default now()
);
grant select, insert, update on public.funcionarios to authenticated;
grant all on public.funcionarios to service_role;
alter table public.funcionarios enable row level security;
create policy "staff or self read funcionarios" on public.funcionarios for select to authenticated
  using (public.is_staff(auth.uid()) or user_id = auth.uid());
create policy "admin insert funcionarios" on public.funcionarios for insert to authenticated
  with check (public.has_role(auth.uid(),'admin'));
create policy "admin update funcionarios" on public.funcionarios for update to authenticated
  using (public.has_role(auth.uid(),'admin')) with check (public.has_role(auth.uid(),'admin'));

-- ===== MATERIAIS =====
create table public.materiais (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  codigo text not null default '',
  categoria text not null default 'Outros',
  unidade text not null default 'un',
  estoque_inicial integer not null default 0 check (estoque_inicial >= 0),
  estoque_minimo integer not null default 0 check (estoque_minimo >= 0),
  estoque_atual integer not null default 0 check (estoque_atual >= 0),
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);
grant select on public.materiais to authenticated;
grant insert (nome, codigo, categoria, unidade, estoque_inicial, estoque_minimo, ativo) on public.materiais to authenticated;
grant update (nome, codigo, categoria, unidade, estoque_inicial, estoque_minimo, ativo) on public.materiais to authenticated;
grant all on public.materiais to service_role;
alter table public.materiais enable row level security;
create policy "auth read materiais" on public.materiais for select to authenticated using (true);
create policy "admin insert materiais" on public.materiais for insert to authenticated
  with check (public.has_role(auth.uid(),'admin'));
create policy "admin update materiais" on public.materiais for update to authenticated
  using (public.has_role(auth.uid(),'admin')) with check (public.has_role(auth.uid(),'admin'));

-- ===== OPERACOES =====
create table public.operacoes (
  id uuid primary key default gen_random_uuid(),
  numero_operacao bigserial unique,
  funcionario_id uuid not null references public.funcionarios(id),
  data_retirada timestamptz not null default now(),
  data_devolucao timestamptz,
  status status_operacao not null default 'EM_OPERACAO',
  observacao text,
  observacao_devolucao text,
  assinatura_retirada text,
  assinatura_devolucao text,
  usuario_retirada uuid,
  usuario_devolucao uuid,
  created_at timestamptz not null default now()
);
grant select on public.operacoes to authenticated;
grant update (observacao, observacao_devolucao) on public.operacoes to authenticated;
grant all on public.operacoes to service_role;
alter table public.operacoes enable row level security;
create policy "staff or own read operacoes" on public.operacoes for select to authenticated
  using (public.is_staff(auth.uid()) or exists (select 1 from public.funcionarios f where f.id = funcionario_id and f.user_id = auth.uid()));
create policy "admin edit operacoes" on public.operacoes for update to authenticated
  using (public.has_role(auth.uid(),'admin')) with check (public.has_role(auth.uid(),'admin'));

create table public.itens_operacao (
  id uuid primary key default gen_random_uuid(),
  operacao_id uuid not null references public.operacoes(id) on delete cascade,
  material_id uuid not null references public.materiais(id),
  quantidade_retirada integer not null check (quantidade_retirada > 0),
  quantidade_devolvida integer not null default 0 check (quantidade_devolvida >= 0),
  quantidade_pendente integer generated always as (quantidade_retirada - quantidade_devolvida) stored,
  check (quantidade_devolvida <= quantidade_retirada)
);
grant select on public.itens_operacao to authenticated;
grant all on public.itens_operacao to service_role;
alter table public.itens_operacao enable row level security;
create policy "staff or own read itens" on public.itens_operacao for select to authenticated
  using (exists (select 1 from public.operacoes o where o.id = operacao_id));

-- ===== MOVIMENTACOES =====
create table public.movimentacoes (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references public.materiais(id),
  operacao_id uuid references public.operacoes(id),
  tipo tipo_movimentacao not null,
  quantidade integer not null,
  created_at timestamptz not null default now(),
  usuario_id uuid,
  observacao text
);
grant select on public.movimentacoes to authenticated;
grant all on public.movimentacoes to service_role;
alter table public.movimentacoes enable row level security;
create policy "staff read movimentacoes" on public.movimentacoes for select to authenticated
  using (public.is_staff(auth.uid()));

-- ===== STOCK TRIGGERS ON MATERIAL =====
create or replace function public.materiais_before_insert()
returns trigger language plpgsql as $$
begin
  new.estoque_atual := new.estoque_inicial;
  return new;
end; $$;
create trigger trg_materiais_bi before insert on public.materiais
  for each row execute function public.materiais_before_insert();

create or replace function public.materiais_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.estoque_inicial > 0 then
    insert into public.movimentacoes (material_id, tipo, quantidade, usuario_id, observacao)
    values (new.id, 'ENTRADA', new.estoque_inicial, auth.uid(), 'Estoque inicial');
  end if;
  return new;
end; $$;
create trigger trg_materiais_ai after insert on public.materiais
  for each row execute function public.materiais_after_insert();

create or replace function public.materiais_before_update()
returns trigger language plpgsql security definer set search_path = public as $$
declare delta integer;
begin
  if new.estoque_inicial <> old.estoque_inicial then
    delta := new.estoque_inicial - old.estoque_inicial;
    new.estoque_atual := old.estoque_atual + delta;
    if new.estoque_atual < 0 then
      raise exception 'Alteração deixaria o estoque negativo';
    end if;
    insert into public.movimentacoes (material_id, tipo, quantidade, usuario_id, observacao)
    values (new.id, 'AJUSTE', delta, auth.uid(), 'Alteração do estoque inicial: ' || old.estoque_inicial || ' → ' || new.estoque_inicial);
  end if;
  return new;
end; $$;
create trigger trg_materiais_bu before update on public.materiais
  for each row execute function public.materiais_before_update();

-- ===== CORE: RETIRADA =====
create or replace function public._retirada_core(p_funcionario uuid, p_itens jsonb, p_assinatura text, p_obs text, p_usuario uuid, p_data timestamptz)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_op uuid; v_item jsonb; v_mat public.materiais; v_qtd integer; v_func public.funcionarios;
begin
  select * into v_func from public.funcionarios where id = p_funcionario;
  if v_func.id is null then raise exception 'Funcionário não encontrado'; end if;
  if v_func.status <> 'ATIVO' then raise exception 'Funcionário inativo'; end if;
  if p_itens is null or jsonb_array_length(p_itens) = 0 then raise exception 'Informe ao menos um material'; end if;

  insert into public.operacoes (funcionario_id, data_retirada, observacao, assinatura_retirada, usuario_retirada)
  values (p_funcionario, p_data, p_obs, p_assinatura, p_usuario) returning id into v_op;

  for v_item in select * from jsonb_array_elements(p_itens) loop
    v_qtd := (v_item->>'quantidade')::integer;
    if v_qtd is null or v_qtd <= 0 then raise exception 'Quantidade inválida'; end if;
    select * into v_mat from public.materiais where id = (v_item->>'material_id')::uuid for update;
    if v_mat.id is null then raise exception 'Material não encontrado'; end if;
    if v_mat.estoque_atual < v_qtd then
      raise exception 'Estoque insuficiente para %: disponível %, solicitado %', v_mat.nome, v_mat.estoque_atual, v_qtd;
    end if;
    update public.materiais set estoque_atual = estoque_atual - v_qtd where id = v_mat.id;
    insert into public.itens_operacao (operacao_id, material_id, quantidade_retirada) values (v_op, v_mat.id, v_qtd);
    insert into public.movimentacoes (material_id, operacao_id, tipo, quantidade, usuario_id, observacao, created_at)
    values (v_mat.id, v_op, 'RETIRADA', v_qtd, p_usuario, p_obs, p_data);
  end loop;
  return v_op;
end; $$;
revoke execute on function public._retirada_core from public, anon, authenticated;

create or replace function public.registrar_retirada(p_funcionario uuid, p_itens jsonb, p_assinatura text, p_obs text default null)
returns uuid language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff(auth.uid()) then raise exception 'Sem permissão'; end if;
  if p_assinatura is null or length(p_assinatura) < 50 then raise exception 'Assinatura obrigatória'; end if;
  return public._retirada_core(p_funcionario, p_itens, p_assinatura, p_obs, auth.uid(), now());
end; $$;
grant execute on function public.registrar_retirada to authenticated;

-- ===== CORE: DEVOLUCAO =====
create or replace function public._devolucao_core(p_operacao uuid, p_itens jsonb, p_assinatura text, p_obs text, p_usuario uuid, p_data timestamptz)
returns public.status_operacao language plpgsql security definer set search_path = public as $$
declare v_op public.operacoes; v_item jsonb; v_it public.itens_operacao; v_qtd integer; v_pend integer; v_status public.status_operacao;
begin
  select * into v_op from public.operacoes where id = p_operacao for update;
  if v_op.id is null then raise exception 'Operação não encontrada'; end if;
  if v_op.status not in ('EM_OPERACAO','DEVOLUCAO_PARCIAL') then raise exception 'Operação não está em aberto'; end if;

  for v_item in select * from jsonb_array_elements(p_itens) loop
    v_qtd := coalesce((v_item->>'quantidade')::integer, 0);
    if v_qtd < 0 then raise exception 'Quantidade negativa não permitida'; end if;
    select * into v_it from public.itens_operacao where id = (v_item->>'item_id')::uuid and operacao_id = p_operacao for update;
    if v_it.id is null then raise exception 'Item não pertence à operação'; end if;
    if v_qtd > v_it.quantidade_pendente then raise exception 'Devolução maior que a quantidade pendente'; end if;
    if v_qtd > 0 then
      update public.itens_operacao set quantidade_devolvida = quantidade_devolvida + v_qtd where id = v_it.id;
      update public.materiais set estoque_atual = estoque_atual + v_qtd where id = v_it.material_id;
      insert into public.movimentacoes (material_id, operacao_id, tipo, quantidade, usuario_id, observacao, created_at)
      values (v_it.material_id, p_operacao, 'DEVOLUCAO', v_qtd, p_usuario, p_obs, p_data);
    end if;
  end loop;

  select coalesce(sum(quantidade_pendente),0) into v_pend from public.itens_operacao where operacao_id = p_operacao;
  if v_pend = 0 then
    v_status := 'DEVOLVIDO';
  else
    if p_obs is null or btrim(p_obs) = '' then raise exception 'Observação obrigatória quando há divergência na devolução'; end if;
    v_status := 'DEVOLUCAO_PARCIAL';
  end if;

  update public.operacoes set status = v_status, data_devolucao = p_data, assinatura_devolucao = p_assinatura,
    usuario_devolucao = p_usuario,
    observacao_devolucao = case when p_obs is null or btrim(p_obs)='' then observacao_devolucao else coalesce(observacao_devolucao || E'\n','') || p_obs end
  where id = p_operacao;
  return v_status;
end; $$;
revoke execute on function public._devolucao_core from public, anon, authenticated;

create or replace function public.registrar_devolucao(p_operacao uuid, p_itens jsonb, p_assinatura text, p_obs text default null)
returns public.status_operacao language plpgsql security definer set search_path = public as $$
begin
  if not public.is_staff(auth.uid()) then raise exception 'Sem permissão'; end if;
  if p_assinatura is null or length(p_assinatura) < 50 then raise exception 'Assinatura obrigatória'; end if;
  return public._devolucao_core(p_operacao, p_itens, p_assinatura, p_obs, auth.uid(), now());
end; $$;
grant execute on function public.registrar_devolucao to authenticated;

-- ===== ADMIN: AJUSTE & CANCELAMENTO =====
create or replace function public.ajustar_estoque(p_material uuid, p_delta integer, p_obs text)
returns void language plpgsql security definer set search_path = public as $$
declare v_mat public.materiais;
begin
  if not public.has_role(auth.uid(),'admin') then raise exception 'Somente administradores'; end if;
  if p_obs is null or btrim(p_obs) = '' then raise exception 'Informe o motivo do ajuste'; end if;
  if p_delta = 0 then raise exception 'Ajuste deve ser diferente de zero'; end if;
  select * into v_mat from public.materiais where id = p_material for update;
  if v_mat.estoque_atual + p_delta < 0 then raise exception 'Ajuste deixaria o estoque negativo'; end if;
  update public.materiais set estoque_atual = estoque_atual + p_delta where id = p_material;
  insert into public.movimentacoes (material_id, tipo, quantidade, usuario_id, observacao)
  values (p_material, case when p_delta > 0 then 'ENTRADA'::tipo_movimentacao else 'AJUSTE'::tipo_movimentacao end, p_delta, auth.uid(), p_obs);
end; $$;
grant execute on function public.ajustar_estoque to authenticated;

create or replace function public.cancelar_operacao(p_operacao uuid, p_motivo text)
returns void language plpgsql security definer set search_path = public as $$
declare v_op public.operacoes; v_it record;
begin
  if not public.has_role(auth.uid(),'admin') then raise exception 'Somente administradores'; end if;
  if p_motivo is null or btrim(p_motivo) = '' then raise exception 'Informe o motivo'; end if;
  select * into v_op from public.operacoes where id = p_operacao for update;
  if v_op.status = 'CANCELADO' then raise exception 'Operação já cancelada'; end if;
  for v_it in select * from public.itens_operacao where operacao_id = p_operacao and quantidade_pendente > 0 loop
    update public.materiais set estoque_atual = estoque_atual + v_it.quantidade_pendente where id = v_it.material_id;
    insert into public.movimentacoes (material_id, operacao_id, tipo, quantidade, usuario_id, observacao)
    values (v_it.material_id, p_operacao, 'CANCELAMENTO', v_it.quantidade_pendente, auth.uid(), p_motivo);
  end loop;
  update public.operacoes set status = 'CANCELADO',
    observacao = coalesce(observacao || E'\n','') || 'CANCELADO: ' || p_motivo
  where id = p_operacao;
end; $$;
grant execute on function public.cancelar_operacao to authenticated;

-- admin: list users with roles
create or replace function public.listar_usuarios()
returns table (id uuid, nome text, email text, roles text[])
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.has_role(auth.uid(),'admin') then raise exception 'Somente administradores'; end if;
  return query select p.id, p.nome, p.email, coalesce(array_agg(r.role::text) filter (where r.role is not null), '{}')
  from public.profiles p left join public.user_roles r on r.user_id = p.id group by p.id order by p.created_at;
end; $$;
grant execute on function public.listar_usuarios to authenticated;

-- ===== DEMO DATA =====
insert into public.categorias (nome) values
('Arma de porte'),('Carregador de arma de porte'),('Arma portátil'),('Carregador de arma portátil'),
('Munição .40'),('Munição .556'),('Colete'),('Câmera'),('LTE'),('Outros');

insert into public.materiais (nome, codigo, categoria, unidade, estoque_inicial, estoque_minimo) values
('GLOCK','201','Arma de porte','un',20,5),
('Carregador GLOCK','202','Carregador de arma de porte','un',60,15),
('ARAD','1540','Arma portátil','un',10,3),
('Carregador ARAD','1541','Carregador de arma portátil','un',30,8),
('Munição .40','2140','Munição .40','un',1000,300),
('Munição .556','240','Munição .556','un',400,250),
('Colete','417','Colete','un',15,4),
('Câmera corporal','310','Câmera','un',8,3),
('LTE','273','LTE','un',6,2),
('Lanterna tática','900','Outros','un',2,2);

insert into public.funcionarios (gh, nome, matricula, telefone, cargo) values
('CB','MORAES','527639','(11) 98888-1001','Cabo'),
('SD','SILVA','531204','(11) 98888-1002','Soldado'),
('SGT','OLIVEIRA','498812','(11) 98888-1003','Sargento'),
('SD','COSTA','540033','(11) 98888-1004','Soldado'),
('CB','ALMEIDA','522918','(11) 98888-1005','Cabo'),
('TEN','PEREIRA','470021','(11) 98888-1006','Tenente'),
('SD','SOUZA','545670','(11) 98888-1007','Soldado'),
('CB','RIBEIRO','519377','(11) 98888-1008','Cabo');

do $$
declare
  m jsonb := (select jsonb_object_agg(codigo, id) from public.materiais);
  f jsonb := (select jsonb_object_agg(matricula, id) from public.funcionarios);
  v_op uuid; it record; sig text := 'demo';
begin
  -- devolvidas (histórico)
  for i in 1..6 loop
    v_op := public._retirada_core((f->>(array['531204','498812','540033','522918','470021','545670'])[i])::uuid,
      jsonb_build_array(jsonb_build_object('material_id', m->>'201','quantidade',1),
                        jsonb_build_object('material_id', m->>'202','quantidade',3),
                        jsonb_build_object('material_id', m->>'2140','quantidade',45),
                        jsonb_build_object('material_id', m->>'417','quantidade',1)),
      sig, null, null, now() - ((8 - i) || ' days')::interval - interval '6 hours');
    select jsonb_agg(jsonb_build_object('item_id', id, 'quantidade', quantidade_retirada)) into it
      from public.itens_operacao where operacao_id = v_op;
    perform public._devolucao_core(v_op, (select jsonb_agg(jsonb_build_object('item_id', id, 'quantidade', quantidade_retirada)) from public.itens_operacao where operacao_id = v_op),
      sig, null, null, now() - ((8 - i) || ' days')::interval + interval '4 hours');
  end loop;

  -- MORAES em operação (exemplo completo)
  perform public._retirada_core((f->>'527639')::uuid,
    jsonb_build_array(
      jsonb_build_object('material_id', m->>'201','quantidade',1),
      jsonb_build_object('material_id', m->>'202','quantidade',3),
      jsonb_build_object('material_id', m->>'1540','quantidade',1),
      jsonb_build_object('material_id', m->>'1541','quantidade',1),
      jsonb_build_object('material_id', m->>'2140','quantidade',45),
      jsonb_build_object('material_id', m->>'240','quantidade',30),
      jsonb_build_object('material_id', m->>'417','quantidade',1),
      jsonb_build_object('material_id', m->>'273','quantidade',1)),
    sig, 'Operação de patrulhamento', null, now() - interval '3 hours');

  -- RIBEIRO em operação
  perform public._retirada_core((f->>'519377')::uuid,
    jsonb_build_array(jsonb_build_object('material_id', m->>'1540','quantidade',1),
                      jsonb_build_object('material_id', m->>'240','quantidade',120),
                      jsonb_build_object('material_id', m->>'310','quantidade',1)),
    sig, null, null, now() - interval '1 day');

  -- SOUZA devolução parcial
  v_op := public._retirada_core((f->>'545670')::uuid,
    jsonb_build_array(jsonb_build_object('material_id', m->>'201','quantidade',1),
                      jsonb_build_object('material_id', m->>'2140','quantidade',45)),
    sig, null, null, now() - interval '2 days');
  perform public._devolucao_core(v_op,
    (select jsonb_agg(jsonb_build_object('item_id', id, 'quantidade', case when quantidade_retirada = 45 then 40 else quantidade_retirada end)) from public.itens_operacao where operacao_id = v_op),
    sig, '5 munições utilizadas em treinamento — aguardando laudo', null, now() - interval '1 day 20 hours');

  -- Lanterna zerada
  perform public._retirada_core((f->>'498812')::uuid,
    jsonb_build_array(jsonb_build_object('material_id', m->>'900','quantidade',2)), sig, null, null, now() - interval '5 hours');
end $$;
