/************************************************************************/
/*  Archivo:            ref_eco2.sp                                     */
/*  Stored procedure:   sp_ref_eco2                                    */
/*  Base de datos:      cobis                                           */
/*  Producto:           Clientes                                        */
/************************************************************************/
/*              IMPORTANTE                                              */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  "COBIS", representantes exclusivos para el Ecuador de la            */
/*  "FINCA IMPACT".                                                     */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de COBIS o su representante.                  */
/************************************************************************/
/*              PROPOSITO                                               */
/*  Este programa procesa las transacciones del stored procedure        */
/*  Insercion de referencia economica                                   */
/*  Actualizacion de referencia economica                               */
/*  Borrado de referencia economica                                     */
/*  Busqueda de referencia economica  general y especifica              */
/************************************************************************/
/*              MODIFICACIONES                                          */
/*  FECHA           AUTOR    RAZON                                      */
/*  03/06/21        COB      Se crea SP para llamar al sp_ref_eco para  */
/*                           VCC                                        */
/************************************************************************/
use cobis

go

if exists (select 1 from sysobjects where name = 'sp_ref_eco2')
   drop proc sp_ref_eco2
go

create proc sp_ref_eco2 (
   @s_ssn              int             = null,
   @s_user             login           = null,
   @s_term             varchar(30)     = null,
   @s_date             datetime        = null,
   @s_srv              varchar(30)     = null,
   @s_lsrv             varchar(30)     = null,
   @s_ofi              smallint        = null,
   @s_rol              smallint        = null,
   @s_org_err          char(1)         = null,
   @s_error            int             = null,
   @s_sev              tinyint         = null,
   @s_msg              descripcion     = null,
   @s_org              char(1)         = null,
   @t_debug            char(1)         = 'N',
   @t_file             varchar(10)     = null,
   @t_from             varchar(32)     = null,
   @t_trn              int             = null,
   @i_operacion        char(1),
   @i_ente             int             = null,
   @i_tipo             char(1)         = 'T',
   @i_formato_fecha    int             = null
)

as
declare
@w_sp_name varchar(10),
@w_return int

select @w_sp_name = 'sp_ref_eco2', 
       @w_return  = 0

if @i_operacion = 'S'
begin
   exec @w_return = cobis..sp_ref_eco
   @t_trn       = 172189,
   @i_operacion = 'G',
   @i_ente      = @i_ente,
   @i_tipo      = @i_tipo

   if @w_return <> 0
   begin
      exec sp_cerror
      @t_debug	    = @t_debug,
      @t_file		= @t_file,
      @t_from		= @w_sp_name,
      @i_num		= @w_return

	  return @w_return
   end
end

return 0

go
