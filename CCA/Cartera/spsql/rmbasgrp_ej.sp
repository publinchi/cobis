/**************************************************************************/
/*      Archivo:                        rmbasgrp_ej.sp                    */
/*      Stored procedure:               sp_rep_mensual_seg_bas_grup_ej    */
/*      Base de Datos:                  cob_cartera                       */
/*      Producto:                       Cartera                           */
/*      Disenado por:                   Edison Cajas                      */
/*      Fecha de Documentacion:         02/Ago/2019                       */
/**************************************************************************/
/*                      IMPORTANTE                                        */
/*   Este programa es parte de los paquetes bancarios propiedad de        */
/*   "Cobiscorp", representantes exclusivos para el Ecuador de la         */
/*   "Cobiscorp CORPORATION".                                             */
/*  Su uso no autorizado queda expresamente prohibido asi como cualquier  */
/*  alteracion o agregado hecho por alguno de sus usuarios sin el debido  */
/*   consentimiento por escrito de la presidencia ejecutiva de Cobiscorp  */
/*   o su representante.                                                  */
/**************************************************************************/
/*                      PROPOSITO                                         */
/*  Reporte de facturación Mensual de seguros Básico Grupal               */
/**************************************************************************/
/*                      MODIFICACIONES                                    */
/*      FECHA           AUTOR                       RAZON                 */
/*   6/AGO/2019     Edison Cajas       Estado inicial                     */
/*  22/01/21          P.Narvaez        optimizado para mysql            */
/**************************************************************************/

use cob_cartera
go

IF OBJECT_ID ('dbo.sp_rep_mensual_seg_bas_grup_ej') IS NOT NULL
	DROP PROCEDURE dbo.sp_rep_mensual_seg_bas_grup_ej
GO

create proc sp_rep_mensual_seg_bas_grup_ej
(
    @t_show_version        int  = 0,
	@i_param1              varchar(255)  = null,
    @i_param2              varchar(255)  = null
)
as

declare 
    @w_cliente         int            ,@w_email           varchar(50)    ,@w_calle           varchar(70)
   ,@w_colonia         varchar(70)    ,@w_estado          varchar(70)    ,@w_ciudad          varchar(70)
   ,@w_delegacion      varchar(70)    ,@w_codigoPostal    varchar(10)    ,@w_telefono1       varchar(10) 
   ,@w_sp_name         varchar(32)    ,@w_retorno         int            ,@w_tabla           varchar(500)
   ,@w_titulo          varchar(100)   ,@w_mensaje         varchar(100)   ,@w_retorno_ej      int
   ,@w_detalle         varchar(500)   ,@w_telefono2       varchar(10) 
   ,@i_fecha_desde     datetime       ,@i_fecha_hasta     datetime       ,@i_sarta           int
   ,@i_batch           int            ,@i_secuencial      int            ,@i_corrida         int
   ,@i_intento         int            ,@w_fec_proceso     datetime
   
select @w_retorno = 0,
       @w_sp_name = 'sp_rep_mensual_seg_bas_grup_ej',
       @w_tabla =   'cob_cartera..ca_factmenssegbasgrp_rep'   
   
if @t_show_version = 1
begin 
   --print 'Stored Procedure=%1! Version=%2!' , @w_sp_name , '4.0.0.0'
   return 0
end


select 
   @i_fecha_desde   = convert(datetime  , rtrim(ltrim(@i_param1)))
  ,@i_fecha_hasta   = convert(datetime  , rtrim(ltrim(@i_param2)))
  

declare @w_operaciones table (
    secuencial      int
   ,tipoPrestamo    catalogo
   ,producto        catalogo
   ,noGrupo         int
   ,nombreGrupo     varchar(70)
   ,credito         cuenta
   ,cliente         int
   ,nombreCliente   varchar(100)
   ,regional        varchar(100)
   ,oficinaSucursal descripcion
   ,diasMora        int
   ,cuota           money
   ,saldo           money
   ,edad            int
   ,sexo            sexo
   ,fechaNacimiento date
   ,calle           varchar(70)
   ,colonia         varchar(70) 
   ,estado          varchar(70)
   ,ciudad          varchar(70)
   ,delegacion      varchar(70)
   ,codigoPostal    varchar(10)
   ,fechaInicial    date
   ,fechaTermino    date
   ,telefono1       varchar(10)
   ,telefono2       varchar(10)
   ,email           varchar(50)
   ,status          varchar(1)
)

select @w_fec_proceso = fp_fecha
from cobis..ba_fecha_proceso

insert @w_operaciones
select 
   ROW_NUMBER() over(order by a.op_operacion),
   a.op_toperacion,
   (SELECT valor FROM cobis..cl_tabla c, cobis..cl_catalogo d
    WHERE c.codigo = d.tabla AND c.tabla = 'ca_toperacion' and d.codigo = a.op_toperacion),
   a.op_grupo
   ,(select gr_nombre from cobis..cl_grupo where gr_grupo = a.op_grupo)
   ,a.op_banco,b.op_cliente
  ,isnull(ente.p_p_apellido,'') + ' ' + isnull(ente.p_s_apellido,'') + ' ' + isnull(ente.en_nombre,'')
  ,(select pv_descripcion from cobis..cl_provincia where pv_provincia = a.op_oficina)
  ,(select of_nombre from cobis..cl_oficina  where of_oficina = a.op_oficial)
  ,0,0  
  ,case when a.op_fecha_ini >= @i_fecha_desde and a.op_fecha_ini <= @i_fecha_hasta 
        then b.op_monto 
		else 
		    round((select do_saldo
               from cob_conta_super..sb_dato_operacion
              where do_banco = a.op_banco
                and do_fecha = (
                    select max(do_fecha)
                      from cob_conta_super..sb_dato_operacion
                     where do_banco = a.op_banco
                       and Month(do_fecha) = Month(@i_fecha_desde) - 1
                       and year(do_fecha) = YEAR(@i_fecha_desde))) * (b.op_monto/a.op_monto),2)
		end
  ,year(getdate()) - year(ente.p_fecha_nac) 
  ,ente.p_sexo,ente.p_fecha_nac 
  ,null,null,null,null,null,null
  ,a.op_fecha_ini,a.op_fecha_fin
  ,null,null,null,' '  
from ca_operacion a,
ca_operacion b,
cobis..cl_ente ente
where (a.op_estado not in (0, 3, 6, 99) or 
(a.op_estado = 3 and a.op_fecha_ult_proceso between @i_fecha_desde  and @i_fecha_hasta))
and a.op_fecha_ini <= @i_fecha_hasta
and a.op_grupal = 'S'
and a.op_ref_grupal is null
AND a.op_banco = b.op_ref_grupal
and b.op_operacion in (select so_operacion from ca_seguros_op where so_tipo_seguro = 'B')
and b.op_cliente = en_ente


DECLARE updateDir CURSOR FOR
 
select distinct cliente
from @w_operaciones

OPEN updateDir  
FETCH NEXT FROM updateDir INTO @w_cliente  

WHILE @@FETCH_STATUS = 0  
BEGIN  

   if exists(select 1 from cobis..cl_direccion where di_ente = @w_cliente and di_tipo = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TDRE'))
   begin
      --Actualizar Direccion
      select top 1 
             @w_calle        = di_calle
            ,@w_colonia      = (select pq_descripcion from cobis..cl_parroquia where pq_parroquia = di_parroquia)
            ,@w_estado       = (select pv_descripcion from cobis..cl_provincia where pv_provincia = di_provincia)
            ,@w_ciudad       = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = di_ciudad)   
            ,@w_codigoPostal = di_codpostal
	        ,@w_delegacion   = (select ba_descripcion from cobis..cl_barrio where ba_barrio = di_barrio)
       from cobis..cl_direccion
      where di_tipo = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TDRE')
        and di_ente = @w_cliente
	
      --Actualiza Telefono 1	  
	  SELECT @w_telefono1 = te_valor FROM (
	     SELECT
		    ROW_NUMBER() OVER (ORDER BY te_ente ASC) AS rownumber
			,te_valor
		 FROM cobis..cl_telefono,
		      cobis..cl_direccion
	    where te_ente = di_ente 
          and te_direccion = di_direccion
	      and di_tipo = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TDRE')
		  and te_ente = @w_cliente
		  
	  ) AS telefono
      WHERE rownumber = 1
	  
	  --Actualiza Telefono 2	  
	  SELECT @w_telefono2 = te_valor FROM (
	     SELECT
		    ROW_NUMBER() OVER (ORDER BY te_ente ASC) AS rownumber
			,te_valor
		 FROM cobis..cl_telefono,
		      cobis..cl_direccion
	    where te_ente = di_ente 
          and te_direccion = di_direccion
		  and di_tipo = (select pa_char from cobis..cl_parametro where pa_nemonico = 'TDRE')
	      and te_ente = @w_cliente
	  ) AS telefono
      WHERE rownumber = 2
		
   end else begin
   
       select top 1 
            @w_calle        = di_calle
           ,@w_colonia      = (select pq_descripcion from cobis..cl_parroquia where pq_parroquia = di_parroquia)
           ,@w_estado       = (select pv_descripcion from cobis..cl_provincia where pv_provincia = di_provincia)
           ,@w_ciudad       = (select ci_descripcion from cobis..cl_ciudad where ci_ciudad = di_ciudad)   
           ,@w_codigoPostal = di_codpostal
	       ,@w_delegacion   = (select ba_descripcion from cobis..cl_barrio where ba_barrio = di_barrio)
         from cobis..cl_direccion
         where di_tipo in (select pa_char from cobis..cl_parametro where pa_nemonico <> 'TDW' and pa_char is not null)
         and di_ente = @w_cliente
		 
		 
		 --Actualiza Telefono 1	  
	  SELECT @w_telefono1 = te_valor FROM (
	     SELECT
		    ROW_NUMBER() OVER (ORDER BY te_ente ASC) AS rownumber
			,te_valor
		 FROM cobis..cl_telefono,
		      cobis..cl_direccion
	    where te_ente = di_ente 
          and te_direccion = di_direccion
	      and di_tipo in (select pa_char from cobis..cl_parametro where pa_nemonico <> 'TDW' and pa_char is not null)
		  and te_ente = @w_cliente
		  
	  ) AS telefono
      WHERE rownumber = 1
	  
	  --Actualiza Telefono 2	  
	  SELECT @w_telefono2 = te_valor FROM (
	     SELECT
		    ROW_NUMBER() OVER (ORDER BY te_ente ASC) AS rownumber
			,te_valor
		 FROM cobis..cl_telefono,
		      cobis..cl_direccion
	    where te_ente = di_ente 
          and te_direccion = di_direccion
		  and di_tipo in (select pa_char from cobis..cl_parametro where pa_nemonico <> 'TDW' and pa_char is not null)
	      and te_ente = @w_cliente
	  ) AS telefono
      WHERE rownumber = 2
   
   end

   --Actualizar el email
   select top 1 @w_email = di_descripcion 
   from cobis..cl_direccion
   where di_tipo = (
      select pa_char 
	  from cobis..cl_parametro 
	  where pa_nemonico = 'TDW')
   and di_ente = @w_cliente


   update @w_operaciones set 
       email          = @w_email
	  ,calle          = @w_calle
	  ,colonia        = @w_colonia
	  ,estado         = @w_estado
	  ,ciudad         = @w_ciudad
	  ,delegacion     = @w_delegacion
	  ,codigoPostal   = @w_codigoPostal
	  ,telefono1      = @w_telefono1
	  ,telefono2      = @w_telefono2
   where cliente  = @w_cliente

   FETCH NEXT FROM updateDir INTO @w_cliente 
END 

CLOSE updateDir  
DEALLOCATE updateDir 

delete cob_cartera..ca_factmenssegbasgrp_rep
where secuencial >= 0

select @w_titulo = 'Reporte de facturación mensual de seguros básicos Crédito Grupal'

insert into cob_cartera..ca_factmenssegbasgrp_rep values
(0,' ',' ',' ',' ',' ',' ',@w_titulo,' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ')


insert into cob_cartera..ca_factmenssegbasgrp_rep values
(0,'Tipo Prestamo','Producto','No Grupo','Nombre Grupo','Credito','Cliente','Nombre Cliente','Regional','Oficina Sucursal','Dias Mora','Cuota',
'Saldo','Edad','Sexo','Fecha Nacimiento','Calle','Colonia','Estado','Ciudad','Delegacion','Codigo Postal','Fecha Inicial',
'Fecha Termino','Telefono1','Telefono2','Email','Status')



insert cob_cartera..ca_factmenssegbasgrp_rep
select 
    secuencial
   ,tipoPrestamo
   ,producto
   ,convert(varchar(10), noGrupo)
   ,nombreGrupo
   ,convert(varchar(24), credito)
   ,convert(varchar(10), cliente)
   ,nombreCliente
   ,regional
   ,oficinaSucursal
   ,convert(varchar(5), diasMora)
   ,convert(varchar(15), cuota)
   ,convert(varchar(15), saldo)
   ,convert(varchar(10), edad)
   ,sexo
   ,convert(varchar(10), fechaNacimiento, 103)
   ,calle
   ,colonia
   ,estado
   ,ciudad
   ,delegacion
   ,codigoPostal
   ,convert(varchar(10), fechaInicial, 103)
   ,convert(varchar(10), fechaTermino, 103)
   ,telefono1
   ,telefono2
   ,email
   ,status
from @w_operaciones
order by secuencial

if @@error != 0 
begin 
   select @w_mensaje = 'Error al insertar en la tabla'+ @w_tabla 
   goto ERROR
end


-----------------------------------------------------------------------
--REPORTE
-----------------------------------------------------------------------
declare 
   @w_parsapp   varchar(64)    ,@w_hora      varchar(8)   ,@w_fecha     varchar(8)
  ,@w_comando   varchar(500)   ,@w_path      varchar(64)  ,@w_archivo   varchar(128)
  ,@w_cmd       varchar(5000)  ,@w_destino   varchar(255) ,@w_errores   varchar(255)


--hora
select @w_hora  = convert(varchar(8), getdate(), 108) --hh:mm:ss
select @w_hora  = substring(@w_hora,1,2) + substring(@w_hora,4,2) --hhmm

--fecha proceso 
select @w_fecha = convert(varchar(8), getdate(), 112) --yyyymmdd
select @w_fecha = substring(@w_fecha,5,2) + substring(@w_fecha,7,2) + substring(@w_fecha,1,4) --mmddyyyy

-- Parametro S_APP
select @w_parsapp = pa_char
  from cobis..cl_parametro
 where pa_nemonico = 'S_APP' 
   and pa_producto ='ADM'

-- Revisa_Path_Archivo
select @w_path = pp_path_destino 
  from cobis..ba_path_pro 
 where pp_producto = 7

if @w_path = '' or @w_path = null
begin
   select @w_mensaje = 'ERROR: No se ha especificado PATH del producto'
   select @w_retorno = 2
   goto ERROR
end

select @w_retorno = 0

select @w_cmd = @w_parsapp + 's_app bcp -auto -login cob_cartera..ca_factmenssegbasgrp_rep out '
select @w_destino = @w_path + 'factmenssegbasgrp' + @w_fecha + '_' + @w_hora + '.txt'
      ,@w_errores = @w_path + 'factmenssegbasgrp' + @w_fecha + '_' + @w_hora + '.err'

select @w_comando = @w_cmd + @w_destino + ' -b5000 -c -T -e ' + @w_errores + ' -t"|" ' + '-config ' + @w_parsapp + 's_app.ini'

print ' CMD: ' + @w_comando

exec @w_retorno = xp_cmdshell @w_comando

if @w_retorno != 0
begin
   select @w_mensaje  = 'ERROR: No se puede cargar archivo'
   select @w_retorno  = 3
   goto ERROR
end

-----------------------------------------------------------------------
--FIN REPORTE
-----------------------------------------------------------------------

return 0

ERROR:
  exec cobis..sp_errorlog 
	@i_fecha        = @w_fec_proceso,
	@i_error        = @w_retorno,
	@i_usuario      = 'usrbatch',
	@i_tran         = 26004,
	@i_descripcion  = @w_mensaje,
	@i_tran_name    = null,
	@i_rollback     = 'S'

 return @w_retorno

GO

