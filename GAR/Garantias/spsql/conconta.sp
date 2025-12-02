/*************************************************************************/
/*   Archivo:              conconta.sp                                   */
/*   Stored procedure:     sp_conconta                                   */
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

IF OBJECT_ID('dbo.sp_conconta') IS NOT NULL
    DROP PROCEDURE dbo.sp_conconta
go

create proc dbo.sp_conconta  (
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
   @i_num_operacion      varchar(30) = null,
   @i_secuencial         int         = null,
   @i_fecha              datetime    = null
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
   @w_pignorado          char(1)

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_conconta'

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19684 and @i_operacion = 'Q') 
     
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
   set rowcount 20
   select 'No.'    = th_secuencial, 
          --'FILIAL'        = to_filial,
          'OFICINA'  = th_oficina_orig,
          'TIPO GARANTIA' = th_tipo_cust,
          'MONEDA'        = th_moneda,
          'VALOR ML'      = th_valor,
          'VALOR ME'      = th_valor_me,
          'OPERACION'     = th_operacion 
     from cu_tran_conta_his
    where (th_secuencial > @i_secuencial or @i_secuencial is null)
      and (th_oficina_dest = @i_sucursal or @i_sucursal is null) 
      and (th_fecha_tran = @i_fecha or @i_fecha is null)
    order by th_fecha_tran, th_secuencial --CSA Migracion Sybase
return 0
end
go