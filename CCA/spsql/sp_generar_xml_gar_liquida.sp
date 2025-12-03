/*************************************************************************/
/*   Archivo:            sp_genera_xml_gar_liquida.sp                    */
/*   Stored procedure:   sp_genera_xml_gar_liquida                       */
/*   Base de datos:      cob_cartera                                     */
/*   Producto:           Cartera                                         */
/*   Disenado por:       SRojas                                          */
/*   Fecha de escritura: 09/08/2017                                      */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   "MACOSA", representantes exclusivos para el Ecuador de NCR          */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier acion o agregado hecho por alguno de sus                  */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/
/*                                  PROPOSITO                            */
/*   Genera archivo xml con informacion para el pago de la garantia      */
/*   liquida                                                             */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA               AUTOR                       RAZON               */
/*   09-08-2017          SRojas                Emision Inicial           */
/*   21-11-2018          SRojas                Referencias numéricas     */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/*************************************************************************/

use cob_cartera
go

if object_id ('sp_genera_xml_gar_liquida') is not null
   drop procedure sp_genera_xml_gar_liquida
go

create procedure sp_genera_xml_gar_liquida
(
   @i_tramite           int, --Tramite (desde tabla de notificaciones de garantÃ­as lÃ­quidas)
   @i_opcion            char(1) = 'I',
   @i_vista_previa      char(1) = 'S',
   @o_gar_pendiente     char(1) = 'S' output

)
as
declare 
@w_grupo                int,
@w_grupal               char(1),
@w_monto_gar_liquida    money,
@w_porcentaje_monto     float,
@w_fecha_pro_orig       datetime,
@w_referencia           varchar(30),
@w_fecha_proceso        datetime,
@w_fecha_ini_credito    datetime,
@w_moneda               tinyint,
@w_oficina              smallint,
@w_ruta_xml             varchar(255),
@w_error                int,
@w_sql_bcp              varchar(5000),
@w_sql                  varchar(5000),
@w_mensaje_bcp          varchar(150),
@w_param_ISSUER         varchar(30),
@w_sp_name              varchar(30),
@w_nombre_grupo         varchar(64),
@w_corresponsal         varchar(20), 
@w_id_corresp           varchar(10),
@w_sp_corresponsal      varchar(50),
@w_descripcion_corresp  varchar(30),
@w_fail_tran            char(1),
@w_convenio             varchar(30)


declare @resultadobcp table (linea varchar(max))

select @w_sp_name = 'sp_genera_xml_gar_liquida'

IF(@i_opcion='F') begin
   select 
   grupo_id      = in_grupo_id,   
   nombre_grupo  = in_nombre_grupo, 
   fecha_proceso = in_fecha_proceso,
   fecha_liq     = in_fecha_liq,    
   fecha_venc    = in_fecha_venc,   
   moneda        = in_moneda,       
   num_pago      = in_num_pago,     
   monto         = in_monto,        
   dest_nombre1  = in_dest_nombre1, 
   dest_cargo1   = in_dest_cargo1 , 
   dest_email1   = in_dest_email1 , 
   dest_nombre2  = in_dest_nombre2, 
   dest_cargo2   = in_dest_cargo2 , 
   dest_email2   = in_dest_email2 , 
   dest_nombre3  = in_dest_nombre3, 
   dest_cargo3   = in_dest_cargo3 , 
   dest_email3   = in_dest_email3 , 
   of_nombre 
   from cob_cartera..ca_infogaragrupo, cobis..cl_oficina 
   where in_oficina_id = of_oficina 
   and in_tramite = @i_tramite
        
   select 
   institucion    = ind_institucion, 
   referencia     = ind_referencia, 
   convenio       = ind_convenio, 
   grupo_id       = ind_grupo_id
   from cob_cartera..ca_infogaragrupo_det, cob_cartera..ca_infogaragrupo
   where  ind_grupo_id = in_grupo_id
   and in_tramite = @i_tramite
   
   delete from ca_infogaragrupo_det
   where ind_institucion >= 0

   delete from ca_infogaragrupo
   where in_grupo_id >= 0
        
   RETURN 0
END

--Parametro porcentaje para el calculo de la garantia
select @w_porcentaje_monto = pa_float
  from cobis..cl_parametro 
 where pa_nemonico = 'PGARGR' 
   and pa_producto = 'CCA'

--Parametro referencia del corresponsal
select @w_param_ISSUER = pa_char
  from cobis..cl_parametro 
 where pa_nemonico = 'ISSUER' 
   and pa_producto = 'CCA'

if (@@error != 0 or @@rowcount != 1)
begin
    select @w_error = 724629
    goto ERROR
end


--Ruta del archivo xml
select @w_ruta_xml = ba_path_destino
  from cobis..ba_batch 
 where ba_batch = 7076

if (@@error != 0 or @@rowcount != 1 or isnull(@w_ruta_xml, '') = '')
begin
    select @w_error = 724636
    goto ERROR
end


--Fecha proceso y cálculo de fecha de vencimiento del pago
select @w_fecha_proceso = fp_fecha
  from cobis..ba_fecha_proceso

select @w_fecha_proceso  = convert(datetime,convert(varchar(10), @w_fecha_proceso,101) + ' ' + convert(varchar(12),getdate(),114))
select @w_fecha_pro_orig = dateadd(hour,36,@w_fecha_proceso)

select @w_grupal            = tr_grupal,
       @w_fecha_ini_credito = tr_fecha_apr,
       @w_moneda            = tr_moneda,
       @w_oficina           = tr_oficina,
       @w_grupo             = tr_cliente
  from cob_credito..cr_tramite
 where tr_tramite = @i_tramite

if (@@rowcount = 0)
begin
    select @w_error = 724637
    goto ERROR
end

if @w_grupal <> 'S'
begin
    select @w_error = 724672
	goto ERROR
end

create table #garantialiq_tmp(
   id                int identity,
   tramite           int,
   cliente           int,
   fecha_vencimiento datetime,
   pag_estado        char(2) null,  --cambio realizado por problemas en dev y test en sust no da inconvenientes
   dev_estado        char(2) null,  --cambio realizado por problemas en dev y test en sust no da inconvenientes
   monto_individual  money,
   monto_garantia    money,
   monto_pagado      money
)
      
insert into #garantialiq_tmp
(tramite,       cliente,      monto_individual, 
monto_garantia, monto_pagado, fecha_vencimiento)
select 
@i_tramite,                            tg_cliente,  tg_monto, 
(tg_monto * @w_porcentaje_monto/100), 0,          @w_fecha_pro_orig
from cob_credito..cr_tramite_grupal
where tg_tramite = @i_tramite

--select * from #garantialiq_tmp
update #garantialiq_tmp
set 
monto_pagado = isnull(gl_pag_valor,0)
from cob_cartera..ca_garantia_liquida 
where tramite = gl_tramite
and cliente = gl_cliente

insert into #garantialiq_tmp
(tramite,          cliente,           monto_individual, 
monto_garantia,    fecha_vencimiento, monto_pagado)
select
@i_tramite,        gl_cliente,        0,
0,                 @w_fecha_pro_orig, isnull(gl_pag_valor, 0)
from cob_cartera..ca_garantia_liquida
where gl_tramite = @i_tramite
and gl_cliente not in (select tg_cliente from cob_credito..cr_tramite_grupal where tg_tramite = @i_tramite)

--select * from #garantialiq_tmp

update #garantialiq_tmp set
pag_estado = 'PC',
dev_estado = NULL
where monto_garantia > monto_pagado

update #garantialiq_tmp set
pag_estado = 'CB',
dev_estado = 'PD'
where monto_garantia < monto_pagado

update #garantialiq_tmp set
pag_estado = 'CB',
dev_estado = NULL
where monto_garantia = monto_pagado
      
select @w_monto_gar_liquida = sum(isnull(monto_garantia, 0) - isnull(monto_pagado,0))
from #garantialiq_tmp
where pag_estado = 'PC'

--Borrar tabla temporal
delete from ca_infogaragrupo_det
where ind_institucion >= 0

delete from ca_infogaragrupo
where in_grupo_id >= 0

--Obtiene y actualiza en la temporal los correos de presidente, tesorero y secretario 
select
grupo  = cg_grupo, 
correo = di_descripcion, 
rol    = cg_rol, 
ente   = di_ente, 
nombre = en_nomlar, 
cargo  = b.valor
into #TablaRefGrupos
from cobis..cl_direccion, cobis..cl_cliente_grupo, cobis..cl_ente,
cobis..cl_tabla a, cobis..cl_catalogo b
where di_ente = cg_ente
and di_ente   = en_ente
and cg_grupo  = @w_grupo
and di_tipo   = 'CE'
and cg_rol   in ('P', 'T', 'S')
and cg_rol    = b.codigo
and a.codigo  = b.tabla
and a.tabla   = 'cl_rol_grupo'


if @w_monto_gar_liquida > 0 begin
   begin tran
   insert into ca_infogaragrupo  (in_grupo_id, in_nombre_grupo , in_fecha_proceso, in_fecha_liq    ,                                                                                                                                                                                                               
                                  in_fecha_venc   , in_moneda       , in_oficina_id   , in_num_pago     , in_monto        ,
                                  in_dest_nombre1 , in_dest_cargo1  , in_dest_email1  ,      
                                  in_dest_nombre2 , in_dest_cargo2  , in_dest_email2  , in_dest_nombre3 , in_dest_cargo3  ,      
                                  in_dest_email3  , in_tramite    )
   select 
   in_grupo_id      = @w_grupo,
   in_nombre_grupo  = convert(varchar(64),null),
   in_fecha_proceso = @w_fecha_proceso,
   in_fecha_liq     = @w_fecha_ini_credito,
   in_fecha_venc    = @w_fecha_pro_orig,
   in_moneda        = @w_moneda,
   in_oficina_id    = @w_oficina,
   in_num_pago      = convert(tinyint,1),
   in_monto         = @w_monto_gar_liquida,
   in_dest_nombre1  = convert(varchar(64), ''),
   in_dest_cargo1   = convert(varchar(100), ''),
   in_dest_email1   = convert(varchar(255), ''),
   in_dest_nombre2  = convert(varchar(64), ''),
   in_dest_cargo2   = convert(varchar(100), ''),
   in_dest_email2   = convert(varchar(255), ''),
   in_dest_nombre3  = convert(varchar(64), ''),
   in_dest_cargo3   = convert(varchar(100), ''),
   in_dest_email3   = convert(varchar(255), ''),
   in_tramite       = @i_tramite

   --Inicio Generar referencia por corresponsal
   select @w_id_corresp = 0
   

   while 1 = 1 begin
   
      select top 1
      @w_id_corresp          = co_id,   
      @w_corresponsal        = co_nombre,
      @w_descripcion_corresp = co_descripcion,
      @w_sp_corresponsal     = co_sp_generacion_ref,
      @w_convenio            = co_convenio
      from  ca_corresponsal 
      where co_id            > @w_id_corresp
      and   co_estado        = 'A'
      order by co_id asc
	  
      if @@rowcount = 0 break
	  
      exec @w_error     = @w_sp_corresponsal
      @i_tipo_tran      = 'GL',
      @i_id_referencia  = @w_grupo,
      @i_monto          = @w_monto_gar_liquida,
      @i_monto_desde    = null,
      @i_monto_hasta    = null,
      @i_fecha_lim_pago = @w_fecha_pro_orig,	  
      @o_referencia     = @w_referencia out
      
      
      if @w_error <> 0 begin
       select 
         @w_error = 70207, @w_fail_tran = 'S'
         GOTO ERROR
      end
      
      insert into ca_infogaragrupo_det 
      (ind_grupo_id, ind_corresponsal, ind_institucion,        ind_referencia, ind_convenio)
      values
      (@w_grupo,     @w_corresponsal,  @w_descripcion_corresp, @w_referencia, @w_convenio)
      
   end --Fin Generar referencia por corresponsal

   select @w_nombre_grupo = upper(gr_nombre) from cobis..cl_grupo where gr_grupo = @w_grupo
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Á','A')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'É','E')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Í','I')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Ó','O')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Ú','U')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Ñ‘','N')
   select @w_nombre_grupo = replace(@w_nombre_grupo,'Ü','U')
   
   update ca_infogaragrupo 
   set in_nombre_grupo = @w_nombre_grupo
   where in_grupo_id = @w_grupo
   
   
   --print 'actualiza data xml grupo: ' + convert(varchar, @w_grupo) + ' tramite: ' + convert(varchar, @i_tramite) + ' referencia: ' + @w_referencia
   
   update ca_infogaragrupo set 
   in_dest_nombre1 = b.nombre, 
   in_dest_cargo1  = b.cargo, 
   in_dest_email1  = b.correo 
   from #TablaRefGrupos b 
   where in_grupo_id = b.grupo
   and   b.rol       = 'P'
   
   update ca_infogaragrupo set
   in_dest_nombre2 = b.nombre, 
   in_dest_cargo2  = b.cargo, 
   in_dest_email2  = b.correo 
   from #TablaRefGrupos b 
   where in_grupo_id = b.grupo
   and b.rol    = 'T'
   
   update ca_infogaragrupo set
   in_dest_nombre3 = b.nombre, 
   in_dest_cargo3  = b.cargo, 
   in_dest_email3  = b.correo 
   from #TablaRefGrupos b 
   where in_grupo_id = b.grupo
   and   b.rol       = 'S'    
   
   commit tran   
end

	  
if @i_opcion = 'Q'
begin
   --insertar en tabla temporal para consultar datos

   if @w_monto_gar_liquida > 0
	  select @o_gar_pendiente = 'S'
   else 
   begin
	  select @o_gar_pendiente = 'N'
   end
	  
   if @i_vista_previa = 'S'
   begin
      if @w_monto_gar_liquida <= 0
      begin
		   select @w_error = 70173
		   goto ERROR
	  end
	  else begin 
		  
         select
         grupo_id      = in_grupo_id, 
         nombre_grupo  = in_nombre_grupo, 
         fecha_proceso = in_fecha_proceso,
         fecha_liq     = in_fecha_liq,    
         fecha_venc    = in_fecha_venc,  
         moneda        = in_moneda,      
         num_pago      = in_num_pago,    
         monto         = in_monto,        
         dest_nombre1  = in_dest_nombre1,
         dest_cargo1   = in_dest_cargo1 , 
         dest_email1   = in_dest_email1 ,  
         dest_nombre2  = in_dest_nombre2,  
         dest_cargo2   = in_dest_cargo2 , 
         dest_email2   = in_dest_email2 ,
         dest_nombre3  = in_dest_nombre3, 
         dest_cargo3   = in_dest_cargo3 , 
         dest_email3   = in_dest_email3 ,  
         of_nombre
         from cob_cartera..ca_infogaragrupo, cobis..cl_oficina
         where in_oficina_id = of_oficina
         and in_tramite = @i_tramite
	
	    select 
        institucion    = ind_institucion, 
        referencia     = ind_referencia, 
        convenio       = ind_convenio, 
        grupo_id       = ind_grupo_id
        from cob_cartera..ca_infogaragrupo_det, cob_cartera..ca_infogaragrupo
        where ind_grupo_id = in_grupo_id
        and in_tramite = @i_tramite
		   
	   end
	       
       
	end
	
    return 0
end

if @i_opcion = 'I'
begin

	update cob_cartera..ca_garantia_liquida set
	gl_fecha_vencimiento = fecha_vencimiento,
	gl_monto_garantia    = monto_garantia,
	gl_monto_individual  = monto_individual,
	gl_pag_estado        = pag_estado,
	gl_dev_estado        = dev_estado
	from #garantialiq_tmp
    where gl_tramite = @i_tramite
	and gl_cliente   = cliente
	    
    print 'rowcount' + convert(varchar,@@rowcount)
    if (@@error != 0)
    begin
       select @w_error = 708154
       goto ERROR
    end
	
    insert into ca_garantia_liquida (
    gl_grupo,            gl_cliente,        gl_tramite,
	gl_monto_individual, gl_monto_garantia, gl_fecha_vencimiento,
	gl_pag_estado)
	select 
	@w_grupo,         cliente,        @i_tramite,
	monto_individual, monto_garantia, fecha_vencimiento,
	pag_estado
	from #garantialiq_tmp
	where cliente not in (select gl_cliente from cob_cartera..ca_garantia_liquida where gl_tramite = @i_tramite)
		
	if (@@error != 0)
    begin
        select @w_error = 708154
        goto ERROR
    end

	--print '@w_monto_gar_liquida' + convert(varchar,@w_monto_gar_liquida)
	 if @w_monto_gar_liquida <= 0
	begin
        delete from ca_infogaragrupo_det
        where ind_institucion >= 0

        delete from ca_infogaragrupo
        where in_grupo_id >= 0

    end
		   
end

return 0

ERROR:
set transaction isolation level read uncommitted
if @w_fail_tran = 'S' begin
	rollback tran
end

exec cobis..sp_cerror 
@t_from = @w_sp_name, 
@i_num = @w_error
return @w_error
go
