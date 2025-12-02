use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_crea_op_ind')
drop proc sp_crea_op_ind
go

create proc sp_crea_op_ind
(

@s_user        login         = 'asecha',
@s_term        varchar(30)   = 'term1',
@s_date        datetime      = null,
@s_ofi         smallint      = 1101,
@i_num_prestamos int           = 1,
@i_fecha_valor datetime      = NULL,
@i_mostrar_op  char(1)       = 'S'
)
as

declare 
@w_contador int,
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
@w_cliente            int,
@w_oficial            int,
@w_fecha_proceso      datetime,
@w_cuenta_aho         cuenta,
@w_ofi_func           int,
@w_fecha_pro_orig     datetime,
@w_fecha_cie_orig     datetime,
@w_ingresos           int,
@w_pais               int,
@w_integrantes        int,
@w_banco              varchar(64),
@w_nombre_cliente     varchar(100),
@w_fecha              datetime,
@w_return             int,
@w_commit             char(1)
SELECT @w_fecha_proceso = fc_fecha_cierre  FROM cobis..ba_fecha_cierre WHERE fc_producto = 7

select 
@w_sp_name = 'sp_crea_op_ind',
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
create table #operaciones(cliente int,operacion int, banco cuenta)

/*
if @@trancount = 0 begin
   begin tran
   select @w_commit = 'S'
end
*/
select * into #ente     from cobis..cl_ente      where 1=2
select * into #dire     from cobis..cl_direccion where 1=2
select * into #ente_aux from cobis..cl_ente_aux     where 1=2
select * into #ref      from cobis..cl_ref_personal where 1=2


select @w_ingresos = cl_catalogo.codigo
from cobis..cl_catalogo, cobis..cl_tabla
where cl_catalogo.valor       = '8.001 A 10.000'
and cl_catalogo.tabla        = cl_tabla.codigo
and cl_tabla.tabla           = 'cl_ingresos'

select @w_pais= pa_pais from cobis..cl_pais
where pa_descripcion= 'MEXICO'

SELECT @w_fecha_pro_orig = fp_fecha FROM cobis..ba_fecha_proceso
SELECT @w_fecha_cie_orig = fc_fecha_cierre  FROM cobis..ba_fecha_cierre WHERE fc_producto = 7

UPDATE cobis..ba_fecha_proceso SET fp_fecha = @i_fecha_valor WHERE fp_fecha IS NOT NULL
UPDATE cobis..ba_fecha_cierre SET fc_fecha_cierre = @i_fecha_valor WHERE fc_producto = 7

while @w_contador < @i_num_prestamos begin

   exec cobis..sp_cseqnos
   @t_from       = @w_sp_name,
   @i_tabla      = 'cl_ente',
   @o_siguiente  = @w_cliente out
   
   truncate table #ente
   truncate table #dire
   truncate table #ente_aux
   truncate table #ref
   
   insert into #ente select top 1 * from cobis..cl_ente
   insert into #ente_aux select top 1 * from cobis..cl_ente_aux
   
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'RE'
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'AE'
   insert into #dire select top 1 * from cobis..cl_direccion where di_tipo = 'CE'

   insert into #ref select top 1 * from cobis..cl_ref_personal where rp_referencia = 1
   insert into #ref select top 1 * from cobis..cl_ref_personal where rp_referencia = 2
   
   update #dire set di_direccion = 1, di_ente = @w_cliente where di_tipo = 'RE'
   update #dire set di_direccion = 2, di_ente = @w_cliente where di_tipo = 'AE'
   update #dire set di_direccion = 3, di_ente = @w_cliente where di_tipo = 'CE'
   
   select @w_nombre_cliente = 'CLIENTE ' + convert(varchar, @w_cliente)

   update #ente set
   en_ente         = @w_cliente,
   p_sexo          = 'F',
   en_nombre       = 'CLIENTE ' + convert(varchar, @w_cliente),
   p_p_apellido    = 'OP INDIVIDUAL' ,
   p_s_nombre      = '',
   en_nomlar       = @w_nombre_cliente,
   en_ced_ruc      = convert(varchar,@w_cliente),
   en_oficina      = @w_ofi_func,
   en_ingre        = @w_ingresos,
   en_nacionalidad = @w_pais,
   en_pais         = @w_pais
   
   if @@error <> 0 goto ERROR

   select @w_cuenta_aho =  convert(varchar, round(rand()*100000,0)) + convert(varchar, round(rand()*100000,0)) + convert(varchar, round(rand()*10000,0))
   
   update #ente_aux set 
   ea_ente = @w_cliente,
   ea_cta_banco = @w_cuenta_aho
   
   update #ref set rp_persona    = @w_cliente,  rp_parentesco = 'PA' where rp_referencia = 1
   update #ref set rp_persona    = @w_cliente,  rp_parentesco = 'MA' where rp_referencia = 2

   
   insert into cobis..cl_ente         select * from #ente
   if @@error <> 0 goto ERROR
   
   insert into cobis..cl_direccion    select * from #dire
   if @@error <> 0 goto ERROR
   
   insert into cobis..cl_ente_aux     select * from #ente_aux
   if @@error <> 0 goto ERROR
   
   insert into cobis..cl_ref_personal select * from #ref
   if @@error <> 0 goto ERROR

   
   
   ---CREACIÓN DE OPERACION

   select  @s_ssn = max(secuencial) + 1 from cob_credito..ts_tramite
   select @s_ssn = isnull(@s_ssn,1) 


   /********************** AQUI COLOCAR LOS PARAMETROS DE ENTRADA *************************************************************************/
      select @w_monto  =  4000 + round(rand()*10,0) * 500,   -- Aqui colocar el monto del prestamo
             @w_toperacion = 'INDIVIDUAL' -- Aqui colocar el tipo de operacion (GRUPAL, INDIVIDUAL, INTERCICLO)
   /***************************************************************************************************************************************/

   select @w_fecha = @i_fecha_valor
   
   select @s_ssn = @s_ssn + 1000
       
   ---
   print '*******************************1*********************************'
   exec @w_error = cob_cartera..sp_crear_oper_sol_wf 
   @i_tipo           = 'O',
   @i_tramite        = 0,
   @i_cliente        = @w_cliente,
   @i_codeudor       = 0,
   @i_sector         = '2',
   @i_toperacion     = 'INDIVIDUAL',
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
   @i_grupal         = 'N',
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
   
   update cob_credito..cr_tramite
   set tr_grupal = null
   where tr_tramite = @w_tramite
   
   print '*******************************2*********************************'
   exec @w_error = cob_workflow..sp_inicia_proceso_wf 
   @i_login          =@s_user, 
   @i_id_proceso     =0, 
   @i_nombre_proceso ='PROCESO6', 
   @i_campo_1        =@w_cliente, 
   @i_campo_3        =@w_tramite, 
   @i_ruteo          ='A',
   @i_id_empresa     =1,
   @i_campo_5        =0,
   @i_campo_6        =0.0,
   @i_campo_7        ='S',
   @t_trn            =73506,
   @s_srv            ='CTSSRV',
   @s_user=@s_user,
   @s_term=@s_term, 
   @s_ofi=@s_ofi,
   @s_rol=3,
   @s_ssn=8032508, 
   @s_lsrv='CTSSRV',
   @s_date=@s_date,
   @o_siguiente = @w_inst_proceso out 
   
   if @w_error <> 0 goto ERROR
   
   
   --FIN REGLA
   
   select @s_ssn = @s_ssn + 1000999
   
   print '*******************************3*********************************'
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
   
   
   select @w_operacion = op_operacion, @w_banco = op_banco
   from cob_credito..cr_tramite, cob_cartera..ca_operacion
   where tr_tramite = @w_tramite
   and tr_numero_op = op_operacion
   
   
   ---

   insert into #operaciones values (@w_cliente,@w_operacion, @w_banco)
   /*
   update  cob_cartera..ca_operacion 
   set op_clase = '9' 
   where op_banco = @w_banco_generado
   
   */
   if @@error <> 0 goto ERROR
   select @w_contador = @w_contador + 1
end

UPDATE cobis..cl_seqnos
SET siguiente = @w_cliente + 1
WHERE tabla = 'cl_ente'
AND bdatos = 'cobis'


UPDATE cobis..ba_fecha_proceso SET fp_fecha = @w_fecha_pro_orig WHERE fp_fecha IS NOT NULL
UPDATE cobis..ba_fecha_cierre SET fc_fecha_cierre = @w_fecha_cie_orig WHERE fc_producto = 7

if @w_commit = 'S' begin
   commit tran
   select @w_commit = 'N'
end
select * from #operaciones

return 0

ERROR:
if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

print '@w_error: '+ convert(varchar, @w_error)
--print '@w_return: '+ convert(varchar, @w_return)
exec cobis..sp_cerror
@t_debug = 'N',    
@t_file  = null,
@t_from  = @w_sp_name,   
@i_num   = @w_error

return @w_error

go
