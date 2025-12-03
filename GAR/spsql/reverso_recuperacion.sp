/****************************************************************/
/* ARCHIVO:              reverso_recuperacion.sp                */
/* Stored procedure:	 sp_reverso_recuperacion	          	*/
/* BASE DE DATOS:        cob_custodia 					        */
/* PRODUCTO:             GARANTIAS              	            */
/****************************************************************/
/*                         IMPORTANTE                           */
/* Esta aplicacion es parte de los paquetes bancarios propiedad */
/* de MACOSA S.A.						                        */
/* Su uso no  autorizado queda  expresamente prohibido asi como */
/* cualquier  alteracion  o agregado  hecho por  alguno  de sus */
/* usuarios sin el debido consentimiento por escrito de MACOSA. */
/* Este programa esta protegido por la ley de derechos de autor */
/* y por las  convenciones  internacionales de  propiedad inte- */
/* lectual.  Su uso no  autorizado dara  derecho a  MACOSA para */
/* obtener  ordenes de  secuestro o retencion y  para perseguir */
/* penalmente a los autores de cualquier infraccion.            */
/****************************************************************/
/*                      MODIFICACIONES                          */
/* FECHA               AUTOR                         RAZON      */
/* 28/Mar/2019       Luis  Ramirez  	        Emision Inicial */
/****************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_reverso_recuperacion') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.sp_reverso_recuperacion
    IF OBJECT_ID('dbo.sp_reverso_recuperacion') IS NOT NULL
        PRINT '<<< FAILED DROPPING PROCEDURE dbo.sp_reverso_recuperacion >>>'
    ELSE
        PRINT '<<< DROPPED PROCEDURE dbo.sp_reverso_recuperacion >>>'
END
go
create proc dbo.sp_reverso_recuperacion (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_rol                smallint    = NULL, 
   @s_org                char(1)     = NULL, 
   @s_srv                varchar(30) = null, 
   @s_sesn               int = null, 
   @s_lsrv               varchar(30) = null, 
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @t_trn                smallint = null,
   @i_codigo_externo     varchar(64) = null,
   @i_recuperacion       smallint  = null,   
   @i_commit             char(1) = 'S',
   @i_ejecuta_inc        char(1)
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_descripcion        descripcion,
   @w_filial             tinyint,
   @w_sucursal           smallint,
   @w_tipo_cust          descripcion,
   @w_custodia           int,
   @w_valor              money,
   @w_valor_abs          money,
   @w_ret_iva            money, 
   @w_ret_fte            money,
   @w_fecha              datetime,
   @w_vencimiento        smallint


select @w_today          = convert(varchar(10),getdate(),101),
       @w_sp_name        = 'sp_reverso_recuperacion'


---Datos Generales
------------------
select   @w_filial = re_filial,
         @w_sucursal = re_sucursal,
         @w_tipo_cust = re_tipo_cust,
         @w_custodia = re_custodia,
         @w_valor = re_valor,
         @w_ret_iva = isnull(re_ret_iva,0), 
         @w_ret_fte = isnull(re_ret_fte,0), 
         @w_vencimiento = re_vencimiento,
         @w_fecha = re_fecha
    from cob_custodia..cu_recuperacion
    where re_codigo_externo = @i_codigo_externo
      and re_recuperacion = @i_recuperacion

if @@rowcount = 0
begin
   exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1905002
   return 1 
end


/* Generacion de la transaccion monetaria */
select @w_descripcion = 'REV. RECUPERACION VENCIMIENTO # ' + convert(varchar(20),@w_vencimiento),
       @w_valor_abs = abs (@w_valor + @w_ret_iva + @w_ret_fte)


if @i_commit = 'S'
  begin tran

   if @i_ejecuta_inc = 'S'
   begin

     /*exec @w_return = sp_transaccion
        @s_ssn = @s_ssn,
        @s_date = @s_date,
        @s_user = @s_user,
        @s_ofi = @s_ofi,
        @t_trn = 19000,
        @i_operacion = 'I',
        @i_filial = @w_filial,
        @i_sucursal = @w_sucursal,
        @i_tipo_cust = @w_tipo_cust,
        @i_custodia = @w_custodia,
        @i_fecha_tran = @s_date,
        @i_debcred = "C", 
        @i_valor = @w_valor_abs,
        @i_descripcion = @w_descripcion,
        @i_usuario = @s_user */

     if @w_return <> 0 
     begin
       /* Error en insercion de Registro Contable */
       exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file, 
         @t_from  = @w_sp_name,
         @i_num   = 1901012
       return 1 
     end
   end --- @i_ejecuta_inc = "S"

   delete cob_custodia..cu_recuperacion
    where re_codigo_externo = @i_codigo_externo
      and re_recuperacion = @i_recuperacion

   if @@error <> 0
   begin
     /*Error en eliminacion de registro */
     exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 1907001
     return 1 
   end

   /* Transaccion de Servicio */
   /***************************/
   insert into ts_recuperacion
   values (@s_ssn,@t_trn,'B',@s_date,@s_user,@s_term,@s_ofi,'cu_recuperacion',
           @w_filial, @w_sucursal, @w_tipo_cust,
           @w_custodia, @i_recuperacion, @w_valor,
           @w_ret_iva, @w_ret_fte, @w_vencimiento,
           @w_fecha, null, null,
           null, @i_codigo_externo) 

   if @@error <> 0 
   begin
    /* Error en insercion de transaccion de servicio */
    exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 1903003
    return 1 
   end

   ---Actualizar estado de Vencimiento 
   update cu_vencimiento
      set ve_estado = 'T'
    where ve_codigo_externo = @i_codigo_externo
      and ve_vencimiento = @w_vencimiento

   if @@error <> 0 
   begin            
     exec cobis..sp_cerror
       @t_debug = @t_debug,
       @t_file  = @t_file, 
       @t_from  = @w_sp_name,
       @i_num   = 1905001
     return 1 
   end

   if @w_tipo_cust = '990' 
   begin
     --revesar estado del cheque de cobranza
     /*update cob_credito..cr_cheques_cobranza
        set cc_estado = 'A' 
      where cc_custodia = @w_custodia
        and cc_nro_vec_doc = @w_vencimiento*/
		print 'pendiente'
   end

         
if @i_commit = 'S'
  commit tran

return 0
go
--EXEC sp_procxmode 'dbo.sp_reverso_recuperacion', 'unchained'
go
IF OBJECT_ID('dbo.sp_reverso_recuperacion') IS NOT NULL
    PRINT '<<< CREATED PROCEDURE dbo.sp_reverso_recuperacion >>>'
ELSE
    PRINT '<<< FAILED CREATING PROCEDURE dbo.sp_reverso_recuperacion >>>'
go