/*************************************************************************/
/*   Archivo:              conpfijo.sp                                   */
/*   Stored procedure:     sp_conpfijo                                   */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
GO

IF OBJECT_ID('dbo.sp_conpfijo') IS NOT NULL
    DROP PROCEDURE dbo.sp_conpfijo
go

create proc dbo.sp_conpfijo  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)     = null,
   @i_modo               smallint    = null,
   @i_filial             tinyint     = null,
   @i_sucursal           smallint    = null,
   @i_tipo_cust          varchar(64) = null,
   @i_custodia           int         = null,
   @i_tramite            int         = null,
   @i_codigo_externo  	 varchar(64) = null,
   @i_cliente            int         = null,
   @i_producto           varchar(20) = null,
   @i_operac             varchar(15) = null,
   @i_detalle            char(1)     = null,
   @i_num_operacion      varchar(30) = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_codigo_externo     varchar(64),
   @w_abierta_cerrada    char(1),
   @w_cliente            int,       
   @w_operacion          varchar(30),
   @w_monto_ini          money, 
   @w_monto_act          money,
   @w_tasa               money,
   @w_pignorado          char(1),
   @w_moneda             tinyint

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_conpfijo'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19674 and @i_operacion = 'Q') 
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'Q'
begin
   select @w_operacion = op_num_banco,
          @w_monto_ini = op_monto,
          @w_monto_act = op_monto_pg_int,
          @w_tasa      = op_tasa,
          @w_pignorado = op_pignorado,
          @w_moneda    = op_moneda
     from cob_pfijo..pf_operacion
    where op_num_banco = @i_num_operacion

   if @@rowcount > 0
      select @w_existe = 1
   else
      select @w_existe = 0
 
   if @w_existe = 0
   begin
       /* Registro a actualizar no existe */
        exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file, 
        @t_from  = @w_sp_name,
        @i_num   = 1905002
        return 1 
   end

   if @w_existe = 1
       select @w_operacion,
              @w_monto_ini,
              @w_monto_act,
              @w_tasa,     
              @w_pignorado

return 0
end
go