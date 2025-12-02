/************************************************************************/
/*  Archivo:                qrproduc.sp                                 */
/*  Stored procedure:       sp_qr_producto                              */
/*  Base de datos:          cobis                                       */
/*  Producto:               Credito y Cartera                           */
/*  Disenado por:           R. Garces                                   */
/*  Fecha de escritura:     16-may-2017                                 */
/************************************************************************/
/*                              IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                              PROPOSITO                               */
/*  Este programa presenta la lista de productos del credito.           */
/*    FECHA                AUTOR                  RAZON                 */
/*  16-05-2017             Milton Custode        Version Inicial        */
/*  17-05-2017             Ma Jose Taco          Opcion de grupales     */
/*  13/Feb/2019            Adriana Giler.        Campo cp_categoria     */
/*  11/Jun/2020            Luis Ponce            CDIG Multimoneda       */
/*  14/Abr/2022            Guisela Fernandez     Se amplia el tamaño de */
/*                                               descripcion            */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_qr_producto')
   drop proc sp_qr_producto
go
create proc sp_qr_producto (
   @s_ofi          int         = null,
   @t_trn          INT         = NULL, --LPO CDIG Cambio de Servicios a Blis
   @i_tipo         tinyint,
   @i_operacion    char(1)     = null,
   @i_producto     catalogo    = '',
   @i_moneda       tinyint     = null ,
   @i_linea_cre    catalogo    = null ,
   @i_categoria    catalogo    = null
)
as declare
@w_sp_name      varchar(30),
@w_error        int,
@w_naturaleza   char(1),
@w_opi          char(1)

/*  Captura Nombre de Stored Procedure  */
select  @w_sp_name = 'sp_qr_producto'

/** NATURALEZA DE LA OPERACION **/
/********************************/

select @w_naturaleza = dt_naturaleza
from  ca_default_toperacion
where dt_toperacion = @i_linea_cre

/*IDENTIFICA OFICINA OPI*/

select @w_opi = 'N'
--to_opi
--from cob_credito..cr_tipo_oficina
--where to_oficina = @s_ofi 


/* Comprueba la moneda local  */

if @i_operacion = 'A' and @i_tipo= 1 
begin
   if @i_producto is null
      select @i_producto =  '0'

   if @w_opi <> 'S' 
   begin
      select
         'PRODUCTO'    = cp_producto,
         'DESCRIPCION' = substring(cp_descripcion,1,50),  --GFP 14/Abr/2022
         'RETENCION'   = cp_retencion,
         'CATEGORIA'   = cp_categoria,
         'INSTRUMENTO' = cp_pcobis --cp_pago_aut
      from ca_producto
      where cp_moneda = @i_moneda
      and   cp_desembolso  = 'S'
      and   cp_producto > @i_producto
      and   cp_estado  = 'V'
      order by cp_producto
   end
   else
   begin
      select
         'PRODUCTO'    = cp_producto,
         'DESCRIPCION' = substring(cp_descripcion,1,30),
         'RETENCION'   = cp_retencion,
         'CATEGORIA'   = cp_pcobis,
         'NSTRUMENTO' = cp_pcobis --cp_pago_aut
      from ca_producto, cob_credito..cr_corresp_sib
      where cp_moneda = @i_moneda
      and   cp_desembolso  = 'S'
            and   cp_producto = codigo_sib
      and   tabla       = 'T148'
      and   cp_producto > @i_producto
      and   cp_estado  = 'V'
      order by cp_producto
   end
end

/** DOCUMENTOS DESCONTADOS, PAGOS FACTORING Y PAGOS MASIVOS **/
/*************************************************************/

if @i_operacion = 'A' and @i_tipo = 2 begin

   if @i_producto is null
      select @i_producto =  '0'
      
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = substring(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion,
      'CATEGORIA'   = cp_categoria,
      'P.COBIS'     = cp_pcobis
   from  ca_producto
   where (cp_pago  = 'S' or @i_categoria = 'PLANO')
   and   cp_categoria <> 'EFEC'
   and   cp_producto > @i_producto
   and   cp_act_pas  in (isnull(@w_naturaleza,'A'),'T')
   and   cp_estado   = 'V'
   and   (cp_categoria = @i_categoria  or  @i_categoria is null)
   AND   cp_moneda = @i_moneda --LPO CDIG Multimoneda
   order by cp_producto
   
   select capital = b.valor
   into #formas
   from cobis..cl_tabla a, cobis..cl_catalogo b
   where a.tabla  = 'ca_pago_capital'
   and   b.tabla  = a.codigo
   and   b.estado = 'V'
   order by b.codigo
   
   select * from #formas 

end



if @i_operacion = 'A' and @i_tipo = 3 begin
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = substring(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion
   from  ca_producto
   where cp_retencion  <> 0
   and   cp_categoria <> 'EFEC'
   and   cp_moneda = @i_moneda
   and   cp_act_pas     in (@w_naturaleza,'T')
   and   cp_estado   = 'V'
   order by cp_producto
end

if @i_operacion = 'A' and @i_tipo = 4 begin
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = subString(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion
   from   ca_producto
   where  cp_pago_aut = 'S'
   and    cp_moneda   = @i_moneda
   and    cp_act_pas     in (@w_naturaleza,'T')
   and    cp_estado   = 'V'
   order by cp_producto
end

--MTA Inicio
if @i_operacion = 'G' and @i_tipo = 1 begin
   select
   'PRODUCTO'    = cp_producto,
   'DESCRIPCION' = subString(cp_descripcion,1,30)
   from   ca_producto
   where  cp_pago_aut= 'S'
   and    cp_pago= 'S'
   and    cp_pcobis= 99
   and    cp_moneda   = @i_moneda
   and    cp_act_pas     in (@w_naturaleza,'T')
   and    cp_estado   = 'V'
   order by cp_producto
end
--MTA Fin

if @i_operacion = 'A' and @i_tipo = 5 begin -- Para consulta desde ATX
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = subString(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion
   from  ca_producto
   where cp_atx  = 'S'
   and   cp_moneda = @i_moneda
   order by cp_producto
end

if @i_operacion = 'A' and @i_tipo = 6 begin -- Para productos de reversa
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = subString(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion
   from  ca_producto
   where  cp_moneda = @i_moneda
   order by cp_producto

end

if @i_operacion = 'A' and @i_tipo = 7 begin
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = subString(cp_descripcion,1,30)
   from  ca_producto
   where cp_pago_aut = 'S'
   and   cp_pcobis  in(3,4)
   and   cp_estado   = 'V'
   and   cp_afectacion = 'C' ---Credito
   order by cp_producto
end

-- INI JAR REQ 205
if @i_operacion = 'A' and @i_tipo = 8 
begin
   select @i_producto = isnull(@i_producto,'')

   select 
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = substring(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion,
      'CATEGORIA'   = cp_categoria,
      'P.COBIS'     = cp_pcobis
     from ca_producto
    where (cp_pago       = 'S' or @i_categoria = 'PLANO')
      and cp_producto    > @i_producto
      and cp_act_pas    in (isnull(@w_naturaleza,'A'),'T')
      and cp_estado      = 'V'
      and cp_categoria   = isnull(@i_categoria,cp_categoria)
      and cp_categoria  <>'EFEC'
      and cp_categoria not in (select cp_categoria from ca_producto
                                where cp_pcobis    in (3,4)
                                  and cp_afectacion = 'D')
    order by cp_producto
end

if @i_operacion = 'A' and @i_tipo = 9 
begin
   select 
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = subString(cp_descripcion,1,30)
     from ca_producto
    where cp_pago_aut   = 'S'
      and cp_pcobis    in (3,4)
      and cp_estado     = 'V'
      and cp_afectacion = 'D'
    order by cp_producto
end

-- FIN JAR REQ 205


if @i_operacion = 'V' and @i_tipo= 1
begin
   if not exists (select 1 from ca_producto
                  where cp_producto     = @i_producto
                  and   cp_desembolso   = 'S'
                  and   cp_moneda       = @i_moneda)
   begin
      select @w_error = 708188
      goto ERROR
   end

   if @w_opi <> 'S' begin

      select 
      substring(cp_descripcion,1,30),
      cp_categoria
      from  ca_producto
      where cp_producto = @i_producto
      and   cp_act_pas     in (@w_naturaleza,'T')

      if @@rowcount = 0
         print 'ERROR EN FORMA DE PAGO...NO CORRESPONDE CON LA NATURALEZA DE LA LINEA'
   end
   
   else
   begin
      select 
      substring(cp_descripcion,1,30),
      cp_categoria
      from  ca_producto, cob_credito..cr_corresp_sib  --REQ 352
      where cp_producto = @i_producto
      and   cp_act_pas     in (@w_naturaleza,'T')
      and   cp_producto = codigo_sib
      and   tabla       = 'T148'

      if @@rowcount = 0
         print 'ERROR EN FORMA DE PAGO...NO CORRESPONDE CON LA NATURALEZA DE LA LINEA'     
   end  
   

end

/** DOCUMENTOS DESCONTADOS, PAGOS FACTORING Y PAGOS MASIVOS **/
/*************************************************************/

if @i_operacion = 'V' and @i_tipo = 2 begin
   if not exists (select 1 from ca_producto
          where cp_producto = @i_producto
          and (cp_pago = 'S' or @i_categoria = 'PLANO')
          and (cp_moneda = @i_moneda or @i_moneda is null)
          and (cp_categoria = @i_categoria  or  @i_categoria is null))
   begin
      select @w_error = 708135
      goto ERROR
   end

   select
   substring(cp_descripcion,1,30),
   cp_retencion,
   cp_categoria,
   cp_pcobis
   from  ca_producto
   where cp_producto = @i_producto
   and   cp_categoria <> 'EFEC'

end

-- INI JAR REQ 205
if @i_operacion = 'V' and @i_tipo = 3 
begin
   if not exists (select 1 from ca_producto
                   where cp_producto    = @i_producto
                     and (cp_pago       = 'S' or @i_categoria = 'PLANO')
                     and cp_moneda      = isnull(@i_moneda,cp_moneda)
                     and cp_estado      = 'V'
                     and cp_categoria   = isnull(@i_categoria,cp_categoria)
                     and cp_categoria  <> 'EFEC'
                     and cp_categoria not in (select cp_categoria from ca_producto
                                               where cp_pcobis    in (3,4)
                                                 and cp_afectacion = 'D'))
   begin
      select @w_error = 708135
      goto ERROR
   end

   select substring(cp_descripcion,1,30),
          cp_retencion,
          cp_categoria,
          cp_pcobis
     from ca_producto
    where cp_producto = @i_producto
end
-- FIN JAR REQ 205


if @i_operacion = 'V' and @i_tipo = 4 begin
   if not exists (select 1 from ca_producto
                  where cp_producto = @i_producto
                  and   cp_pago_aut = 'S'
                  and   cp_moneda   = @i_moneda)
   begin
      select @w_error = 708135
      goto ERROR
   end

   select substring(cp_descripcion,1,30),cp_retencion
   from ca_producto
   where cp_producto = @i_producto

end

if @i_operacion = 'V' and @i_tipo = 5 begin
   if not exists (select 1 from ca_producto
                  where cp_producto = @i_producto
                  and   cp_atx      = 'S'
                  and   cp_moneda   = @i_moneda)
   begin
      select @w_error = 708135
      goto ERROR
   end

   select substring(cp_descripcion,1,30),cp_retencion
   from  ca_producto
   where cp_producto = @i_producto
end

if @i_operacion = 'V' and @i_tipo = 6 begin
   if not exists (select 1 from ca_producto
                  where cp_producto = @i_producto
                  and   cp_moneda   = @i_moneda)
   begin
      select @w_error = 708135
      goto ERROR
   end

   select substring(cp_descripcion,1,30),cp_retencion
   from ca_producto
   where cp_producto = @i_producto

end

-- INI JAR REQ 205
if @i_operacion = 'V' and @i_tipo = 7 
begin
   if not exists (select 1 from ca_producto
                   where cp_producto   = @i_producto
                     and cp_pago_aut   = 'S'
                     and cp_pcobis    in (3,4)
                     and cp_estado     = 'V'
                     and cp_afectacion = 'D')
   begin
      select @w_error = 708135
      goto ERROR
   end
   
   select substring(cp_descripcion,1,30),
          cp_retencion,
          cp_categoria,
          cp_pcobis
     from ca_producto
    where cp_producto = @i_producto
end

--LCM - 293
if @i_operacion = 'V' and @i_tipo = 8 begin
   if not exists (select 1 from ca_producto
          where cp_producto = @i_producto
          and (cp_pago = 'S' or @i_categoria = 'PLANO')
          and (cp_moneda = @i_moneda or @i_moneda is null)
          and (cp_categoria = @i_categoria  or  @i_categoria is null))
   begin
      select @w_error = 708135
      goto ERROR
   end

   select
   cp_producto,
   substring(cp_descripcion,1,30),
   cp_retencion,
   cp_categoria,
   cp_pcobis
   from  ca_producto
   where cp_producto = @i_producto
   and   cp_categoria <> 'EFEC'

   select capital = b.valor
   into #formas_c
   from cobis..cl_tabla a, cobis..cl_catalogo b
   where a.tabla  = 'ca_pago_capital'
   and   b.tabla  = a.codigo
   and   b.estado = 'V'
   order by b.codigo
   
   select * from #formas_c

end

-- FIN JAR REQ 205

/* TODOS LOS PRODUCTOS SIN TOMAR EN CUENTA LA MONEDA NI LA NATURALEZA DE LA CARTERA */
/************************************************************************************/
if @i_operacion = 'T' and @i_tipo= 1 begin
   select
      'PRODUCTO'    = cp_producto,
      'DESCRIPCION' = substring(cp_descripcion,1,30),
      'RETENCION'   = cp_retencion,
      'MONEDA'      = cp_moneda
   from ca_producto

   order by cp_producto
end


/** CONSULTA DE TRANSACCION **/
/*****************************/
if @i_operacion = 'V' and @i_tipo= 7 begin
   select substring(cp_descripcion,1,30)
   from ca_producto
   where cp_producto = @i_producto

   if @@rowcount = 0 begin
      select @w_error =  700026
      goto ERROR
   end

end

set rowcount 0

return 0

ERROR:

exec cobis..sp_cerror
@t_debug='N',
@t_file = null,
@t_from = @w_sp_name,
@i_num = @w_error

return @w_error
go

