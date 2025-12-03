use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ingresa_gr_ope')
drop proc sp_ingresa_gr_ope
go

create proc sp_ingresa_gr_ope
(

@s_user        login         = 'asecha',
@s_term        varchar(30)   = 'term1',
@s_date        datetime      = null,
@s_ofi         smallint      = 1101,
@i_integrantes int           = 7,
@i_fecha_valor datetime      = NULL,
@i_mostrar_tra char(1)     = 'S',
@o_tramite     int        output
)
as

declare 
@w_contador int,
@w_ente     int,
@w_genero  char(1),
@w_nombre   varchar(20),
@w_apellido   varchar(20),
@w_sp_name   varchar(20),
@w_letra char(1),
@s_ssn                integer,
@w_error             integer,
@w_tramite          int,
@w_operacion        int,
@w_op_banco_0         cuenta,
@w_monto              money,
@w_toperacion         catalogo,
@w_tasa               float,
@w_banco_generado     cuenta,
@w_resultado          smallint,
@w_io_id_inst_proc    int,
@w_num_cliente        int,
@w_monto_individual   money,
@w_inst_proceso       int,
@w_grupo              INT,
@w_cliente            int,
@w_oficial            int,
@w_fecha_proceso      datetime,
@w_cuenta_aho         cuenta,
@w_ofi_func           int,
@w_fecha_pro_orig     datetime,
@w_fecha_cie_orig     datetime,
@w_ingresos           int,
@w_pais               int

SELECT @w_fecha_proceso = fc_fecha_cierre  FROM cobis..ba_fecha_cierre WHERE fc_producto = 7


select 
@w_sp_name = 'sp_ingresa_gr_ope',
@w_contador = 0,
@s_date        = isnull(@s_date, @w_fecha_proceso),
@i_fecha_valor = isnull( @i_fecha_valor, @w_fecha_proceso)

select 
@w_oficial  = oc_oficial,
@w_ofi_func = fu_oficina
from cobis..cc_oficial, cobis..cl_funcionario
where oc_funcionario = fu_funcionario
and fu_login = @s_user


create table #montos (ente int, cuenta cuenta, monto money)
select * into #ente     from cobis..cl_ente      where 1=2
select * into #dire     from cobis..cl_direccion where 1=2
select * into #grup     from cobis..cl_grupo     where 1=2
select * into #ente_aux from cobis..cl_ente_aux     where 1=2
select * into #ref      from cobis..cl_ref_personal where 1=2


SELECT @w_grupo = isnull(max(gr_grupo), 0) + 1 FROM cobis..cl_grupo

select @w_ingresos = cl_catalogo.codigo
from cobis..cl_catalogo, cobis..cl_tabla
where cl_catalogo.valor       = '8.001 A 10.000'
and cl_catalogo.tabla        = cl_tabla.codigo
and cl_tabla.tabla           = 'cl_ingresos'

select @w_pais= pa_pais from cobis..cl_pais
where pa_descripcion= 'MEXICO'

while @w_contador < @i_integrantes begin

   exec cobis..sp_cseqnos
   @t_from       = @w_sp_name,
   @i_tabla      = 'cl_ente',
   @o_siguiente  = @w_ente out
   
   truncate table #ente
   truncate table #dire
   truncate table #grup
   truncate table #ente_aux
   truncate table #ref
   
   insert into #ente select top 1 * from cobis..cl_ente
   insert into #ente_aux select top 1 * from cobis..cl_ente_aux
   
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'RE'
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'AE'
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'CE'

   insert into #ref select top 1 * from cobis..cl_ref_personal where rp_referencia = 1
   insert into #ref select top 1 * from cobis..cl_ref_personal where rp_referencia = 2
   
   update #dire set di_direccion = 1, di_ente = @w_ente where di_tipo = 'RE'
   update #dire set di_direccion = 2, di_ente = @w_ente where di_tipo = 'AE'
   update #dire set di_direccion = 3, di_ente = @w_ente where di_tipo = 'CE'
   

   update #ente set
   en_ente         = @w_ente,
   p_sexo          = 'F',
   en_nombre       = 'DEL GRUPO ' + convert(varchar, @w_grupo),
   p_p_apellido    = 'CLIENTE ' + convert(varchar, @w_ente),     
   p_s_nombre      = '',
   en_nomlar       = 'CLIENTE ' + convert(varchar, @w_ente) + ' DEL GRUPO ' + convert(varchar, @w_grupo),
   en_ced_ruc      = convert(varchar,@w_ente),
   en_oficina      = @w_ofi_func,
   en_ingre        = @w_ingresos,
   en_nacionalidad = @w_pais,
   en_pais         = @w_pais

   select @w_cuenta_aho =  convert(varchar, round(rand()*100000,0)) + convert(varchar, round(rand()*100000,0)) + convert(varchar, round(rand()*10000,0))
   
   update #ente_aux set 
   ea_ente = @w_ente,
   ea_cta_banco = @w_cuenta_aho
   
   update #ref set rp_persona    = @w_ente,  rp_parentesco = 'PA' where rp_referencia = 1
   update #ref set rp_persona    = @w_ente,  rp_parentesco = 'MA' where rp_referencia = 2

   
   insert into cobis..cl_ente         select * from #ente
   insert into cobis..cl_direccion    select * from #dire
   insert into cobis..cl_ente_aux     select * from #ente_aux
   insert into cobis..cl_ref_personal select * from #ref

   insert into #montos values(@w_ente, @w_cuenta_aho, 4000 + round(rand()*10,0) * 500)
   
   
   INSERT INTO cobis..cl_cliente_grupo (
   cg_ente,                cg_grupo,               cg_usuario, 
   cg_terminal,            cg_oficial,             cg_fecha_reg, 
   cg_rol,                 
   cg_estado,              cg_calif_interna,       cg_fecha_desasociacion, 
   cg_tipo_relacion,       cg_ahorro_voluntario,   cg_lugar_reunion,       
   cg_nro_ciclo)
   values( 
   @w_ente,                @w_grupo,                @s_user, 
   'TERM1',                @w_oficial,              @w_fecha_proceso, 
   case @w_contador when 0 then 'P' when 1 then 'T' when 2 then 'S' else 'M' end,
   'V',                   'A',                       NULL,                   
   NULL,                   0,                        NULL,                   
   1)

   if @@ERROR <> 0 goto ERROR
   
   if @w_contador = 0 begin
   
      
	  insert into #grup select top 1 * from cobis..cl_grupo 
      
      update #grup set
      gr_grupo          = @w_grupo, 
      gr_nombre         = 'GRUPO '+ convert(varchar, @w_grupo),
      gr_representante  = @w_ente,
      gr_oficial        = @w_oficial,
      gr_estado         = 'V',
      gr_num_ciclo      = 1
         
      insert into cobis..cl_grupo select * from #grup
	  if @@ERROR <> 0 goto ERROR
   
   end

   select @w_contador = @w_contador +1
   
end

select 'grupo '+convert(varchar, @w_grupo)

UPDATE cobis..cl_seqnos
SET siguiente = @w_ente + 1
WHERE tabla = 'cl_ente'
AND bdatos = 'cobis'

UPDATE cobis..cl_seqnos
SET siguiente = @w_grupo + 1
WHERE tabla = 'cl_grupo'
AND bdatos = 'cobis'

 
SELECT @w_fecha_pro_orig = fp_fecha FROM cobis..ba_fecha_proceso
SELECT @w_fecha_cie_orig = fc_fecha_cierre  FROM cobis..ba_fecha_cierre WHERE fc_producto = 7

UPDATE cobis..ba_fecha_proceso SET fp_fecha = @i_fecha_valor WHERE fp_fecha IS NOT NULL
UPDATE cobis..ba_fecha_cierre SET fc_fecha_cierre = @i_fecha_valor WHERE fc_producto = 7

select  @s_ssn = max(secuencial) + 1 from cob_credito..ts_tramite

select @s_ssn = isnull(@s_ssn,1) 

select @w_tramite = max(tr_tramite) +1 from cob_credito..cr_tramite 
select @w_tramite = isnull(@w_tramite,1)

update cobis..cl_seqnos set siguiente = @w_tramite where tabla = 'cr_tramite'

select @w_monto  =  sum(monto) from #montos
select @s_ssn    = @s_ssn + 1000
select @s_ssn    = isnull(@s_ssn,0)

--PRIMER GUARDAR
exec @w_error = cob_cartera..sp_crear_oper_sol_wf 
@i_tipo           = 'O',
@i_tramite        = 0,
@i_cliente        = @w_grupo,
@i_codeudor       = 0,
@i_sector         = '2',
@i_toperacion     = 'GRUPAL',
@i_oficina        = @w_ofi_func,
@i_moneda         = 0,
@i_comentario     = 'Operacion creada por be',
@i_oficial        = @w_oficial,
@i_fecha_ini      = @i_fecha_valor,
@i_monto          = @w_monto,
@i_monto_aprobado = @w_monto,
@i_ciudad         = 1,
@i_formato_fecha  = 0,
@i_clase_cartera  = '9',
@i_numero_reest   = 0,
@i_num_renovacion = 0,
@i_grupal         = 'S',
@i_banca          = '1',
@i_promocion      = 'N',
@i_acepta_ren     = 'S',
@i_no_acepta      = '',
@i_emprendimiento = 'N',
@i_garantia       = 12.0,
@i_destino        = '1',
@t_trn            = 77100,
@o_operacion      = @w_operacion out,
@o_tramite        = @w_tramite out,
@s_srv            = 'CTSSRV',
@s_user           = @s_user,
@s_term           = '192.168.56.53',
@s_ofi            = @s_ofi,
@s_rol            = 3,
@s_ssn            = @s_ssn,
@s_lsrv           = 'CTSSRV',
@s_date           = @s_date, 
@s_sesn           = @s_ssn

if @w_error <> 0 goto ERROR

update cob_credito..cr_tramite_grupal set 
tg_monto          = monto,
tg_monto_aprobado = monto,
tg_cuenta         = cuenta
from #montos
where tg_tramite = @w_tramite
and tg_cliente = ente
and tg_grupo   = @w_grupo 

if @@ERROR<> 0 goto ERROR

exec @w_error = cob_workflow..sp_inicia_proceso_wf 
@i_login          =@s_user, 
@i_id_proceso     =0, 
@i_nombre_proceso ='PROCESO4', 
@i_campo_1        =@w_grupo, 
@i_campo_3        =@w_tramite, 
@i_ruteo          ='A',
@i_id_empresa     =1,
@i_campo_5=0,
@i_campo_6=0.0,
@i_campo_7='S',
@t_trn=73506,
@s_srv='CTSSRV',
@s_user=@s_user,
@s_term=@s_term, 
@s_ofi=@s_ofi,
@s_rol=3,
@s_ssn=8032508, 
@s_lsrv='CTSSRV',
@s_date=@s_date,
@o_siguiente = @w_inst_proceso out 

if @w_error <> 0 goto ERROR


select @s_ssn = @s_ssn + 1000999


exec @w_error= cob_workflow..sp_pasa_cartera_wf
@s_srv            = 'CTSSRV',
@s_user           = @s_user,
@s_term           = '192.168.56.82',
@s_ofi            = @s_ofi,
@s_rol            = 3,
@s_ssn            = @s_ssn,
@s_lsrv           = 'CTSSRV',
@s_date           = @s_date,
@s_sesn           = @s_ssn,
@i_id_inst_proc   = @w_inst_proceso,
@i_id_inst_act    = 0,
@i_id_empresa     = 1,
@i_etapa_flujo    = 'IMP',
@o_id_resultado   = @w_resultado out

if @w_error <> 0 goto ERROR

select @s_ssn = @s_ssn + 1000999

exec @w_error = cob_workflow..sp_pasa_cartera_wf
@s_srv            = 'CTSSRV',
@s_user           = @s_user,
@s_term           = '192.168.56.82',
@s_ofi            = @s_ofi,
@s_rol            = 3,
@s_ssn            = @s_ssn,
@s_lsrv           = 'CTSSRV',
@s_date           = @s_date,
@s_sesn           = @s_ssn,
@i_id_inst_proc   = @w_inst_proceso,
@i_id_inst_act    = 0,
@i_id_empresa     = 1,
@o_id_resultado   = @w_resultado out

if @w_error <> 0 goto ERROR

UPDATE cobis..ba_fecha_proceso SET fp_fecha = @w_fecha_pro_orig WHERE fp_fecha IS NOT NULL
UPDATE cobis..ba_fecha_cierre SET fc_fecha_cierre = @w_fecha_cie_orig WHERE fc_producto = 7

if @i_mostrar_tra = 'S'
begin
   select * from cob_credito..cr_tramite_grupal
   where tg_tramite = @w_tramite
end
insert into cob_cartera..ca_en_fecha_valor (bi_operacion,bi_banco,bi_fecha_valor, bi_user)
select tg_operacion, tg_prestamo, @i_fecha_valor, @s_user
from cob_credito..cr_tramite_grupal
where tg_tramite = @w_tramite

select @o_tramite = @w_tramite

return 0

ERROR:

UPDATE cobis..ba_fecha_proceso SET fp_fecha = @w_fecha_pro_orig WHERE fp_fecha IS NOT NULL
UPDATE cobis..ba_fecha_cierre SET fc_fecha_cierre = @w_fecha_cie_orig WHERE fc_producto = 7

exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,   
@i_num   = @w_error

return @w_error

go
