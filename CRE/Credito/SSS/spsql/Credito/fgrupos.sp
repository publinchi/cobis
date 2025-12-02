/************************************************************************/
/*  Archivo:                fgrupos.sp                                  */
/*  Stored procedure:       sp_fgrupos                                  */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jonatan Rueda                               */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          LOGIN_DESA       Emision Inicial                  */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_fgrupos')
    drop proc sp_fgrupos
go

create proc sp_fgrupos(
  @s_ssn                  int = null,
  @s_date                 datetime = null,
  @s_user                 login = null,
  @s_term                 descripcion = null,
  @s_ofi                  smallint = null,
  @s_srv                  varchar(30) = null,
  @s_lsrv                 varchar(30) = null, 
  @t_rty                  char(1) =null,
  @t_trn                  smallint =null,
  @t_debug                char(1) = 'N',
  @t_file                 varchar(14) = null,
  @t_from                 varchar(32) = null,
  @i_operacion            char(1) = null,
  @i_tramite              int = null,
        @i_grupo                int = null,
        @i_toperacion   catalogo = null,
        @i_num_negocio          varchar(64) = null,   --LRE 02/07/01
  @i_documento    varchar(24) = null, --DAY 02/13/01  antes xma 16
        @i_filial               tinyint     = 1,
        @i_formato_fecha        smallint = null,
        @i_doc_secuencial       int = null --FIZ C467
)
as
declare
  @w_sp_name              varchar(32),/*nombre del sp*/
  @w_today                datetime,/*fecha del dia*/
  @w_error               int,      /*valor que retorna*/
        @w_existe               int,
        @w_grupo                int,
        @w_valor                money,
        @w_moneda               tinyint,
        @w_fec_inineg           datetime,
        @w_fec_finneg           datetime,
        @w_referencia           varchar(16),
        @w_num_negocio          varchar(64),    --LRE 02/07/01
        @w_op_tipo              char(1)         --WRU
        
        
        
        
select @w_today = @s_date
select @w_sp_name = 'sp_fgrupos'
/*****************************[ DEBUG ]******************************/
if (@i_operacion = 'S' and @t_trn != 21970) or
   (@i_operacion = 'D' and @t_trn != 21971) or
   (@i_operacion = 'V' and @t_trn != 21972)
begin
/**tipo de transaccion no corresponde**/
 exec cobis..sp_cerror
     @t_debug      = @t_debug,
     @t_file       = @t_file,
     @t_from       = @w_sp_name,
     @i_num        = 2101006
     return 1
end
/************* Chequeo de Existencias *********/
if @i_operacion != 'S'
begin
   select @w_grupo = fa_grupo,
          @w_valor = fa_valor,
          @w_moneda = fa_moneda,
          @w_fec_inineg = fa_fecini_neg,
          @w_fec_finneg = fa_fecfin_neg,
          @w_referencia = fa_referencia,
          @w_num_negocio= fa_num_negocio  --LRE 02/07/01
   from cr_facturas
   where fa_tramite = @i_tramite
   if @@rowcount > 0 
      select @w_existe=1 /*Si existe*/
   else
      select @w_existe = 0
   select @w_num_negocio
end  
if @i_operacion = 'V'  --LRE 02/07/01
begin
    if @i_tramite is null
    begin
          select @w_error = 2101001
          goto ERROR
       end
   select @w_num_negocio= fa_num_negocio 
   from cr_facturas
   where fa_tramite = @i_tramite      
   select @w_num_negocio
end
/**** Search ****/
/****************/
if @i_operacion = 'S'
begin


-- ------------------------------
-- CAMBIO FACTORING INICIO WRU
-- ------------------------------


select  @w_op_tipo = null

select @w_op_tipo = op_tipo
from cob_credito..cr_tramite, cob_cartera..ca_operacion 
where   tr_tramite = op_tramite
and     tr_tramite = @i_tramite

if @w_op_tipo = 'D'
begin 

-- CONSIDEAR NEGOCIO Y DOCUMENTOS COMO ORDEN DE LA CONSULTA
        SELECT  @i_num_negocio  = isnull(@i_num_negocio, ''),
    @i_documento  = isnull(@i_documento, '')
    
  set rowcount 20
    SELECT  'Emisor' = do_emisor,  
      'Negocio' = fa_num_negocio,
      'Monto' = fa_valor,
      'Moneda' = fa_moneda ,
      'Fecha inicio Negocio' = convert(varchar(10),fa_fecini_neg,@i_formato_fecha), --DIEGO
      'Fecha fin Negocio' = convert(varchar(10),fa_fecfin_neg,@i_formato_fecha), --DIEGO
      'Nro. Documento' = fa_referencia,
      'Porcentaje' = fa_porcentaje,
                        'Secuencial' = fa_documento
          FROM  cr_facturas,
      cob_custodia..cu_doctos,
      cob_credito..cr_cupo_documento
 WHERE   fa_tramite  = @i_tramite
    AND ((fa_num_negocio > @i_num_negocio) or
       (fa_num_negocio = @i_num_negocio  and  fa_documento  > @i_doc_secuencial)) --FIZ C467
                and     do_filial    = @i_filial
                and     fa_documento = do_documento
                and     do_emisor    = cd_emisor
    ORDER BY  fa_num_negocio,
        fa_documento
  set rowcount 0



-- ------------------------------
-- CAMBIO FACTORING FIN WRU
-- ------------------------------


end
else
begin 


-- CONSIDEAR NEGOCIO Y REFERENCIA COMO ORDEN DE LA CONSULTA
        SELECT  @i_num_negocio  = isnull(@i_num_negocio, ''),
    @i_documento  = isnull(@i_documento, '')
  set rowcount 20
    SELECT  'Cuota' = fa_grupo, --fa_dividendo,   
      'Negocio' = fa_num_negocio,
      'Monto' = fa_valor,
      'Moneda' = fa_moneda ,
      'Fecha inicio Negocio' = convert(varchar(10),fa_fecini_neg,@i_formato_fecha), --DIEGO
      'Fecha fin Negocio' = convert(varchar(10),fa_fecfin_neg,@i_formato_fecha), --DIEGO
      'Nro. Documento' = fa_referencia,
      'Porcentaje' = fa_porcentaje,
                        'Secuencial' = fa_documento
          FROM  cr_facturas,
      cob_custodia..cu_doctos
      --cobis..cl_ente
    WHERE   fa_tramite  = @i_tramite
    AND ((fa_num_negocio > @i_num_negocio) or
       (fa_num_negocio = @i_num_negocio  and  fa_referencia   > @i_documento))
                and     do_filial    = @i_filial
                and     fa_documento = do_documento
    ORDER BY  fa_num_negocio,
        fa_referencia
  set rowcount 0


end


end





if @i_operacion = 'D'
begin
   if @i_tramite is null
   begin
      select @w_error = 2101001
      goto ERROR
   end
       
   /*if @w_existe = 0    ---cuando se crea un tramite y no se ha ingresado facturas, no permite eliminarlo..(error)
   begin
      select @w_error = 2107002
      goto ERROR
   end
   */

   BEGIN TRAN

   -- Elimina el registro de cr_facturas
   delete cr_facturas
    where fa_tramite = @i_tramite

   if @@error != 0
   begin
      select @w_error = 2107001
      goto ERROR
   end
       
   update cob_custodia..cu_negocio_dd
      set nd_tramite = null,
          nd_estado  = 'P'  --Propuesto
    where nd_tramite = @i_tramite

    COMMIT TRAN 
end

return 0

ERROR:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = @w_error
   return @w_error


GO

