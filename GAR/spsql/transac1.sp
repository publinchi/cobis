/************************************************************************/
/*    Archivo:                  transac1.sp                             */
/*    Stored procedure:         sp_transac1                             */
/*    Base de datos:            cob_custodia                            */
/*    Producto:                 GARANTIAS                               */
/*    Disenado por:                                                     */
/*    Fecha de escritura:       29/Mar/2019                             */
/************************************************************************/
/*                             IMPORTANTE                               */
/*    Este programa es parte de los paquetes bancarios propiedad de     */
/*    "COBISCORP",  representantes  exclusivos  para  el Ecuador de la  */
/*    "NCR CORPORATION".                                                */
/*    Su uso no autorizado  queda  expresamente  prohibido asi como     */
/*    cualquier  alteracion  o  agregado  hecho  por  alguno de sus     */
/*    usuarios  sin  el  debido  consentimiento  por  escrito de la     */
/*    Presidencia Ejecutiva de COBISCORP o su representante.            */
/************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_transac1') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_transac1
    IF OBJECT_ID('dbo.sp_transac1') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_transac1 >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_transac1 >>>'
END
go

create proc sp_transac1  (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               varchar(64) = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_producto           char(64) = null,
   @i_modo               smallint = null,
   @i_cliente            int = null,
   @i_ente               int = null,
   @i_filial 		 tinyint = null,
   @i_sucursal		 smallint = null,
   @i_tipo_cust		 varchar(64) = null,
   @i_custodia 		 int = null,
   @i_garante  		 int = null,
   @i_opcion             tinyint = null,
   @i_codigo_externo     varchar(64) = null,
   @i_operacion          cuenta      = null,
   @i_formato_fecha      int         = null
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_contador           tinyint,
   @w_ente               int,
   @w_cliente            descripcion,
   @w_moneda             tinyint,
   @w_codigo_externo     varchar(64),
   @w_valor_actual       money

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_transac1'

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn <> 19584 and @i_operacion = 'S') 
begin
   /* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1901006
    return 1 
end

if @i_operacion = 'S'
begin
     /* exec @w_return = sp_tipo_custodia
        @i_tipo = @i_tipo_cust,
        @t_trn  = 19123,
        @i_operacion = 'V',
        @i_modo = 0*/

      if @w_return <> 0 
      begin
         return 1 
      end 

      /*exec @w_return = sp_custopv
        @i_filial     = @i_filial,
        @i_sucursal   = @i_sucursal,
        @i_tipo       = @i_tipo_cust,
        @i_custodia   = @i_custodia,
        @t_trn        = 19565,
        @i_operacion  = 'B',
        @i_modo       = 0*/
 
      if @w_return <> 0 
      begin
         return 1 
      end 

      select cu_estado from cu_custodia
      where cu_filial   = @i_filial
        and cu_sucursal = @i_sucursal
        and cu_tipo     = @i_tipo_cust
        and cu_custodia = @i_custodia 

     /*        exec sp_externo 
        @i_filial = @i_filial,
        @i_sucursal = @i_sucursal,
        @i_tipo     = @i_tipo_cust,
        @i_custodia = @i_custodia,
        @o_compuesto = @w_codigo_externo out
*/

     select @w_ente = cg_ente,
            @w_cliente = cg_nombre,
            @w_moneda = cu_moneda,
            @w_valor_actual = cu_valor_actual
     from cu_custodia,cu_cliente_garantia 
     where  cu_codigo_externo = @w_codigo_externo
       and  cg_codigo_externo = @w_codigo_externo
       and  cg_principal      = 'S'
    
 
     select @w_ente,
            @w_cliente,
            @w_moneda,
            @w_valor_actual,
            convert(char(10),@s_date,@i_formato_fecha) 

end
go
--EXEC sp_procxmode 'dbo.sp_transac1', 'unchained'
go
IF OBJECT_ID('dbo.sp_transac1') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_transac1 >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_transac1 >>>'
go

