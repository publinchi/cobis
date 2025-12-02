/************************************************************************/
/*  Archivo:                DISPARADOR_REGLAS.sp                        */
/*  Stored procedure:       SP_DISPARADOR_REGLAS                        */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'SP_DISPARADOR_REGLAS' and type = 'P')
   drop proc SP_DISPARADOR_REGLAS
go


CREATE proc SP_DISPARADOR_REGLAS (  
   @i_tramite            int         = NULL,
   @i_operacion          cuenta      = NULL,
   @i_cliente            int         = NULL,
   @i_tipo_normalizacion char(2)     = NULL,
   @i_momento            char(2)     = NULL,
   @i_num_cuota          int         = NULL,
   @i_fecha              datetime    = NULL,
   @i_debug              char(1)     = 'N',
   @o_retorno            smallint    = NULL out
)  
  
as  
declare  
   @w_sp_name          varchar(60),
   @w_retorno          int,
   @w_programa         varchar(60),
   @w_return           int,
   @w_tabla            varchar(10),
   @w_mensaje          varchar(255)

select @w_sp_name = 'SP_DISPARADOR_REGLAS' 
select @o_retorno = 0
select @w_return = 0

-- Extrayendo el codigo de la tabla de correspondencia

select @w_tabla = codigo 
from cobis..cl_catalogo 
where tabla = 395 
and   codigo = 'T158'

-- Seleccionando el programa a ejecutar

DECLARE cur_reglas CURSOR FOR
select 
codigo_sib
from cob_credito..cr_param_normalizacion, cob_credito..cr_corresp_sib 
where tabla        = @w_tabla
and   nr_regla     = codigo
and   nr_tipo_norm = @i_tipo_normalizacion
and   nr_momento   = @i_momento
and   nr_estado    = 'V'
order by nr_secuencial
for read only

OPEN cur_reglas

FETCH cur_reglas INTO
     @w_programa

WHILE @@fetch_status = 0
begin
   if @i_debug = 'S'
      print '@w_programa: '+ cast(@w_programa as varchar)
      
   exec @w_return             = @w_programa
        @i_tramite            = @i_tramite,
        @i_cliente            = @i_cliente,
        @i_operacion          = @i_operacion,
        @i_num_cuota          = @i_num_cuota,
        @i_tipo_normalizacion = @i_tipo_normalizacion,
        @i_fecha              = @i_fecha,
        @o_retorno            = @w_retorno out
   
   if @w_return <> 0
   begin
      CLOSE cur_reglas
      deallocate cur_reglas
      goto ERROR
   end
   
   FETCH cur_reglas INTO
         @w_programa
end

return 0

ERROR:
   exec cobis..sp_cerror
      @t_from  = @w_sp_name,
      @i_num   = @w_return
   
   return @w_return


GO
