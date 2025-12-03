/***********************************************************************/
/*  Archivo:        tipoiden.sp                                        */
/*  Stored procedure:   sp_tipo_identificacion                         */
/*  Base de datos:      cobis                                          */
/*  Producto:       MIS                                                */
/*  Disenado por:                                                      */
/*  Fecha de escritura: 31/MAY/2004                                    */
/***********************************************************************/
/*                           IMPORTANTE                                */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad      */
/*   de COBIS S.A.                                                     */
/*   Su uso no  autorizado queda  expresamente prohibido asi como      */
/*   cualquier  alteracion  o agregado  hecho por  alguno  de sus      */
/*   usuarios sin el debido consentimiento por escrito de COBIS S.A    */
/*   Este programa esta protegido por la ley de derechos de autor      */
/*   y por las  convenciones  internacionales de  propiedad inte-      */
/*   lectual.  Su uso no  autorizado dara  derecho a  COBIS S.A para   */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir      */
/*   penalmente a los autores de cualquier infraccion.                 */
/***********************************************************************/
/*              PROPOSITO                                              */
/*  Mantenimiento de los tipos de identificacion                       */
/***********************************************************************/
/*AUTOR              FECHA                         MODIFICACIONES      */
/*ACA               30/Abr/2021   Condición de País para consultas   */
/*ACU               14/Jul/2021   Condición para validar si se usa    */     
/*                                tipo de documento antes de eliminarlo*/
/*PJA               24/Ene/2022   Se aumenta campo estado del registro */     
/*PJA               02/Feb/2022   Se incluye validacion operacion U    */ 
/*PJA               03/Feb/2022   Se incluye logica para mensajes FE   */
/***********************************************************************/
use cobis
go
set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO
                   
if exists (select * from sysobjects where name = 'sp_tipo_identificacion')
    drop proc sp_tipo_identificacion
go
create proc sp_tipo_identificacion(
   @s_user      login                  = null,
   @s_term      varchar(30) = null,
   @s_date      datetime = null,
   @s_ofi       smallint = null,
   @s_culture                              varchar(10)   = 'NEUTRAL',   
   @t_debug     char(1) = 'N',
   @t_file      varchar(14) = null,
   @t_show_version                         bit           = 0,     -- mostrar la version del programa
   @t_trn                 int          = null,
   @i_operacion           char(1),
   @i_tipo                char(1)     = NULL,
   @i_tipo_cliente        char(10)    = NULL,
   @i_tipo_documento      char(10)    = NULL,
   @i_tipo_nacionalidad   char(10)    = NULL,
   @i_tipo_residencia     char(10)    = NULL,
   @i_codigo              char(20)    = NULL,
   @i_descripcion         varchar(64) = NULL,
   @i_mascara             varchar(30) = NULL,
   @i_pais                int         = null,
   @i_estado              char(1)     = null,
   @o_mensaje             char(2)     = 'NN' out
)
as declare 
   @w_sp_name         descripcion,
   @w_return          int,
   @w_sp_msg          varchar(132),   
   @w_error           int,
   @w_idioma          char(10),
   @w_texto           varchar(20),
   @w_pais_local      int,
   @w_mexico          int,
   @w_estado_aux      char(1),
   @w_estado_vig      char(1),
   @w_mascara_aux     varchar(30)

/* CARGAR VARIABLES DE TRABAJO */
select
@w_sp_name       = 'sp_tipo_identificacion',
@w_sp_msg            = '',
@w_estado_aux        = '',
@w_estado_vig    = 'V',
@w_mascara_aux   = '' 


/* VERSIONAMIENTO */
if @t_show_version = 1 begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end



---- EJECUTAR SP DE LA CULTURA ---------------------------------------  
exec cobis..sp_ad_establece_cultura
        @o_culture = @s_culture out
        

select @w_idioma = pa_char
  from cobis..cl_parametro
 where pa_producto = 'ADM'
   and pa_nemonico = 'IDS'

select @w_mexico =  codigo 
from  cobis..cl_catalogo
where tabla = (select top 1 codigo from cobis..cl_tabla where tabla = 'cl_pais'  ) 
and   valor = 'MEXICO'

select @w_pais_local = pa_smallint from cobis..cl_parametro where pa_nemonico = 'CP' and pa_producto = 'CLI'  -- PAIS DONDE ESTÁ EL BANCO


IF @i_operacion IN ('S','Q','C')
BEGIN
    IF @i_pais = NULL
      SELECT @i_tipo_nacionalidad = null
   ELSE
   BEGIN 
      IF @i_pais = @w_pais_local
         SELECT @i_tipo_nacionalidad = 'N'
      ELSE
         SELECT @i_tipo_nacionalidad = 'E'
   END
END


--EVALUACION DEL TIPO DE TRANSACCION 
if (@t_trn <> 172122 and @i_operacion in ('S','A')) or
   (@t_trn <> 172123 and @i_operacion = 'Q') or
   (@t_trn <> 172124 and @i_operacion = 'I') or   
   (@t_trn <> 172125 and @i_operacion = 'D') or
   (@t_trn <> 172126 and @i_operacion = 'H') or
   (@t_trn <> 172127 and @i_operacion = 'B') or
   (@t_trn <> 172128 and @i_operacion = 'C') or
   (@t_trn <> 172187 and @i_operacion = 'U')
begin 
   select @w_error = 1720121
   goto ERROR
end

select @i_descripcion = isnull(@i_descripcion,'')
select @o_mensaje = 'NN'

if @i_operacion = 'A' 
 begin
   select 'Tipo de Cliente'        = ti_tipo_cliente,
          'Tipo de Identificacion' = ti_tipo_documento, 
          'Tipo de Nacionalidad'   = ti_nacionalidad,
          'Tipo de Residencia'     = ti_tipo_residencia,
          'Codigo'                 = ti_codigo, 
          'Descripcion'            = ti_descripcion,
          'Mascara'                = ti_mascara,
          'Estado'                 = ti_estado
     from cobis..cl_tipo_identificacion
     where (ti_tipo_cliente    = @i_tipo_cliente      OR @i_tipo_cliente IS NULL)
      and (ti_tipo_documento   = @i_tipo_documento    OR @i_tipo_documento IS NULL)
      and (ti_nacionalidad     = @i_tipo_nacionalidad OR @i_tipo_nacionalidad IS NULL)      
      and (ti_tipo_residencia  = @i_tipo_residencia   OR @i_tipo_residencia IS NULL)
      and (ti_codigo           = @i_codigo            OR @i_codigo IS NULL)
     ORDER BY ti_tipo_cliente, ti_tipo_documento,ti_nacionalidad

end

if @i_operacion = 'S' 
 begin
   select 'Tipo de Cliente'        = ti_tipo_cliente,
          'Tipo de Identificacion' = ti_tipo_documento, 
          'Tipo de Nacionalidad'   = ti_nacionalidad,
          'Tipo de Residencia'     = ti_tipo_residencia,
          'Codigo'                 = ti_codigo, 
          'Descripcion'            = ti_descripcion,
          'Mascara'                = ti_mascara
     from cobis..cl_tipo_identificacion
     where (ti_tipo_cliente    = @i_tipo_cliente      OR @i_tipo_cliente IS NULL)
      and (ti_tipo_documento   = @i_tipo_documento    OR @i_tipo_documento IS NULL)
      and (ti_nacionalidad     = @i_tipo_nacionalidad OR @i_tipo_nacionalidad IS NULL)      
      and (ti_tipo_residencia  = @i_tipo_residencia   OR @i_tipo_residencia IS NULL)
      and (ti_codigo           = @i_codigo            OR @i_codigo IS NULL)
	  and ti_estado            = @w_estado_vig
     ORDER BY ti_tipo_cliente, ti_tipo_documento,ti_nacionalidad

end

if @i_operacion = 'Q' 
begin
if isnull(@i_tipo_residencia,'') = '' begin
   select ti_tipo_cliente,
          ti_tipo_documento,
          ti_nacionalidad,
          ti_tipo_residencia,
          ti_codigo,
          ti_descripcion,
          ti_mascara
     from cobis..cl_tipo_identificacion
    where ti_tipo_cliente     = @i_tipo_cliente
      and ti_tipo_documento   = @i_tipo_documento
      and ti_nacionalidad     = @i_tipo_nacionalidad
      and ti_codigo           = @i_codigo
      and ti_estado           = @w_estado_vig
  end
  else
  begin
   select ti_tipo_cliente,
          ti_tipo_documento,
          ti_nacionalidad,
          ti_tipo_residencia,
          ti_codigo,
          ti_descripcion,
          ti_mascara
     from cobis..cl_tipo_identificacion
    where ti_tipo_cliente     = @i_tipo_cliente
      and ti_tipo_documento   = @i_tipo_documento
      and ti_nacionalidad     = @i_tipo_nacionalidad
      and ti_tipo_residencia  = @i_tipo_residencia
      and ti_codigo           = @i_codigo
  	  and ti_estado           = @w_estado_vig
  end      
end


if @i_operacion = 'I' 
begin
    /*Validar existencia*/
    if exists (select 1 from cobis..cl_tipo_identificacion
               where   ti_tipo_cliente     = @i_tipo_cliente
                   and ti_tipo_documento   = @i_tipo_documento
                   and ti_nacionalidad     = @i_tipo_nacionalidad
                   and ti_tipo_residencia  = @i_tipo_residencia
                   and ti_codigo           = @i_codigo)
   begin
      select @w_error = 1720477
      goto ERROR
   end
   else
   begin
    insert into cobis..cl_tipo_identificacion (
         ti_tipo_cliente,
         ti_tipo_documento,
         ti_nacionalidad,
         ti_tipo_residencia,
         ti_codigo,
         ti_descripcion,
         ti_mascara,
         ti_estado)
    values (
         @i_tipo_cliente,
         @i_tipo_documento,
         @i_tipo_nacionalidad,
         @i_tipo_residencia,
         @i_codigo,
         @i_descripcion,
         @i_mascara,
         @i_estado)

    if @@error <> 0 begin
       select @w_error = 1720397
       goto ERROR
    end
   end
end

if @i_operacion = 'U'
begin
    if exists (select 1 from cobis..cl_tipo_identificacion
               where   ti_tipo_cliente     = @i_tipo_cliente
                   and ti_tipo_documento   = @i_tipo_documento
                   and ti_nacionalidad     = @i_tipo_nacionalidad
                   and ti_tipo_residencia  = @i_tipo_residencia
                   and ti_codigo           = @i_codigo)
    begin
       select @w_estado_aux  = ti_estado,
              @w_mascara_aux = ti_mascara	   
          from cobis..cl_tipo_identificacion
         where ti_tipo_cliente     = @i_tipo_cliente
           and ti_tipo_documento   = @i_tipo_documento
           and ti_nacionalidad     = @i_tipo_nacionalidad
           and ti_tipo_residencia  = @i_tipo_residencia
           and ti_codigo           = @i_codigo

       update cobis..cl_tipo_identificacion
          set ti_descripcion         = @i_descripcion,
              ti_mascara             = @i_mascara,
              ti_estado              = @i_estado
        where ti_tipo_cliente        = @i_tipo_cliente
             and ti_tipo_documento   = @i_tipo_documento
             and ti_nacionalidad     = @i_tipo_nacionalidad
             and ti_tipo_residencia  = @i_tipo_residencia
             and ti_codigo           = @i_codigo
 
      if @@error <> 0 begin
         select @w_error = 1720396
         goto ERROR
      end       

    if exists (select top 1 en_tipo_ced from cobis..cl_ente where en_tipo_ced = @i_codigo )
    begin
      if (@w_estado_aux <> @i_estado)
      begin
          select @o_mensaje = 'SN'
      end    
      if (@w_mascara_aux <> @i_mascara)
      begin
          select @o_mensaje = 'NS'
      end
      if (@w_estado_aux <> @i_estado and @w_mascara_aux <> @i_mascara)
      begin
          select @o_mensaje = 'SS'
      end    
    end
   end
   else
   begin
     select @w_error = 1720478
     goto ERROR
   end
end

if @i_operacion = 'D' 
begin
    if @i_tipo_cliente = 'PERSONA'
            select @i_tipo_cliente = 'P'
        else
            select @i_tipo_cliente = 'C'
    
    if exists (select top 1 en_tipo_ced from cobis..cl_ente where en_tipo_ced = @i_codigo )
    begin
        select @w_error = 1720531 --NO SE PUEDE ELIMINAR EL TIPO DE DOCUMENTO SELECCIONADO PORQUE ESTA SIENDO USANDO POR UN CLIENTE
        goto ERROR
    end
    
   if exists(select 1 from cobis..cl_tipo_identificacion
               where ti_tipo_cliente     = @i_tipo_cliente
                 and ti_tipo_documento   = @i_tipo_documento
                 and ti_nacionalidad     = @i_tipo_nacionalidad
                 and ti_tipo_residencia  = @i_tipo_residencia
                 and ti_codigo           = @i_codigo)
    begin
        delete cobis..cl_tipo_identificacion
         where  ti_tipo_cliente = @i_tipo_cliente
           and ti_tipo_documento   = @i_tipo_documento
           and ti_nacionalidad     = @i_tipo_nacionalidad
           and isnull(ti_tipo_residencia,'')  = isnull(@i_tipo_residencia,'')
           and ti_codigo           = @i_codigo

        if @@error <> 0 begin
          select @w_error = 1720398
          goto ERROR
        end
   end
   else
   begin
     select @w_error = 1720478
     goto ERROR
   end
end

if @i_operacion = 'H' 
begin
   create table #tipo_cliente (tipo varchar(10), descripcion varchar(30))

   select @w_texto = im_texto
     from cobis..ad_idioma_mensaje
    where im_recurso = 'persona'
      and im_idioma  = @w_idioma

   insert into #tipo_cliente values ('P', isnull(@w_texto,'PERSON'))

   select @w_texto = im_texto
     from cobis..ad_idioma_mensaje
    where im_recurso = 'compania'
      and im_idioma  = @w_idioma

   insert into #tipo_cliente values ('C', isnull(@w_texto,'COMPANY'))

   if @i_tipo = 'V' begin
      select descripcion
        from #tipo_cliente
       where tipo = @i_tipo_cliente
     
      if @@rowcount = 0 begin
         select @w_error = 1720399
         goto ERROR
      end

   end
   else begin
      select '29355' = tipo, '29359' = descripcion
        from #tipo_cliente

   end
end

if @i_operacion = 'B' 
begin
   select 
          'Tipo de Identificacion' = ti_tipo_documento, 
          'Tipo de Nacionalidad'   = ti_nacionalidad,
          'Tipo de Residencia'     = ti_tipo_residencia,
          'C�digo'                 = ti_codigo, 
          'Descripci�n'            = ti_descripcion,
          'Mascara'                = ti_mascara
     from cobis..cl_tipo_identificacion
    where ti_tipo_cliente = @i_tipo_cliente
	  and ti_estado       = @w_estado_vig
end

if @i_operacion = 'C' 
begin
   select 
        ti_tipo_documento, 
        ti_nacionalidad,
        ti_tipo_residencia,
        ti_codigo, 
        ti_descripcion,
        ti_mascara
     from cobis..cl_tipo_identificacion
    where  ti_tipo_cliente  = @i_tipo_cliente
    and ti_tipo_documento   = @i_tipo_documento
    and ti_nacionalidad     = @i_tipo_nacionalidad
    and ti_tipo_residencia  = @i_tipo_residencia
    and ti_codigo           = @i_codigo
	and ti_estado           = @w_estado_vig

      if @@rowcount = 0 begin
         select @w_error = 1720400
         goto ERROR
      end

end

return 0

ERROR:
exec sp_cerror
@t_debug    = @t_debug,
@t_file     = @t_file,
@t_from     = @w_sp_name,
@i_num      = @w_error,
@s_culture = @s_culture
return @w_error
GO
