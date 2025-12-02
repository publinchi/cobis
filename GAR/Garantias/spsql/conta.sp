/*************************************************************************/
/*   Archivo:              conta.sp                                      */
/*   Stored procedure:     sp_conta                                      */
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

IF OBJECT_ID('dbo.sp_conta') IS NOT NULL
    DROP PROCEDURE dbo.sp_conta
go

create proc dbo.sp_conta  (
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
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_filial		     tinyint = null,
   @i_oficina_orig	     smallint = null,
   @i_oficina_dest 	     smallint = null,
   @i_tipo     		     descripcion = null,
   @i_moneda		     tinyint = null,
   @i_valor		         money = null,
   @i_operac		     char(1) = null,
   @i_signo              int = null,
   @i_codigo_externo     varchar(64) = null,
   @i_tipo_cca           catalogo = null,
   @i_codval             int = 19
)
as

declare
   @w_today              datetime,     /* fecha del dia */ 
   @w_ayer               datetime,     /* fecha de ayer */ 
   @w_return             int,          /* valor que retorna */
   @w_sp_name            varchar(32),  /* nombre stored proc*/
   @w_existe             tinyint,      /* existe el registro*/
   @w_error              int,
   @w_valor		         money,
   @w_valor_me		     money,
   @w_cotizacion         money,
   @w_cotizacion_c       money,
   @w_cotizacion_v       money,
   @w_secuencial         int,
   @w_sucursal 		     smallint, --PSE 07/Sep/2007
   @w_transaccion        int  --GFP Actualizacion de campo en cu_tran_conta

select @w_today = convert(varchar(10),getdate(),101)
select @w_sp_name = 'sp_conta'
select @w_ayer    = convert(char(10),dateadd(dd,-1,getdate()),101)
/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19300 and @i_operacion = 'I') 
begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

if @i_operacion = 'I'
begin
     begin tran
         select @w_cotizacion_c = isnull(ct_compra,1),
                @w_cotizacion_v = isnull(ct_venta,1) 
         from cob_conta..cb_cotizacion
         where ct_moneda = @i_moneda
           and ct_fecha  in (select max(ct_fecha)
                             from cob_conta..cb_cotizacion
                             where ct_fecha <= @s_date 
                               and ct_moneda = @i_moneda)

         if @i_operac = 'I' or @i_operac = 'C'
            select @w_cotizacion = @w_cotizacion_v
         else
            select @w_cotizacion = @w_cotizacion_c
         
	select 	@i_valor = isnull(@i_valor,0),
		@w_cotizacion = isnull(@w_cotizacion,1)

         if exists (select * from cob_conta..cb_empresa
                    where em_empresa = @i_filial
                      and em_moneda_base = @i_moneda)
            select @w_valor    = @i_valor,
                   @w_valor_me = 0
         else  -- Moneda extranjera
            select @w_valor    = @i_valor * @w_cotizacion,
		   @w_valor_me = @i_valor

         select @w_secuencial = isnull(max(to_secuencial),0) + 1
         from cu_tran_conta
	
	 --PSE 07/SEP/2007
	 if @i_oficina_orig is null 
	 begin
	    select @w_sucursal = cu_sucursal
	      from cob_custodia..cu_custodia
	     where cu_codigo_externo = @i_codigo_externo
	
	    select @i_oficina_orig = @w_sucursal 
	 end
	 --PSE 07/SEP/2007               

--print '@i_oficina_orig %1! @i_codigo_externo %2!', @i_oficina_orig, @i_codigo_externo

	 --GFP Obtencion de secuencial de transaccion
     select @w_transaccion = isnull(max(tr_transaccion)+1,1)
     from cu_transaccion 
     where tr_codigo_externo = @i_codigo_externo
	 
	 if @w_transaccion is null
     select @w_transaccion = 1

	 insert into cu_tran_conta (
                to_secuencial,
		        to_filial,
		        to_oficina_orig,
		        to_oficina_dest,
		        to_tipo_cust,
                to_moneda,
                to_valor,
                to_valor_me,
                to_operacion,
                to_codigo_externo,
                to_contabiliza,  --SPO Campo que determina si se contabilizo o no una garantia
                to_fecha,         --SPO Indica la fecha en que se realiza la transaccion
                to_codval,
                to_tipo_cca,
				to_estado, --GFP Estado de proceso de contabilidad
				to_secuencial_trn, --GFP secuencial de la transaccion
				to_usuario  --GFP usuario de la transaccion
                )
	        values (
                @w_secuencial,
		        @i_filial,
		        @i_oficina_orig,
		        @i_oficina_dest,
	  	        @i_tipo,  
		        @i_moneda,
		        @w_valor,
		        @w_valor_me,
		        @i_operac,
                @i_codigo_externo,
                null,
                @s_date,
                @i_codval,        
                @i_tipo_cca,
                'I',  --GFP Estado de proceso de contabilidad
                @w_transaccion,  --GFP secuencial de la transaccion
                @s_user	 --GFP usuario de la transaccion			
                )

         if @@error <> 0
         begin
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = @w_error
              return 1 
           end

         /* INSERCION EN LA TABLA DE HISTORICOS */
	 insert into cu_tran_conta_his (
                th_fecha_tran, 
                th_secuencial,
		th_filial,
		th_oficina_orig,
		th_oficina_dest,
		th_tipo_cust,
                th_moneda,
                th_valor,
                th_valor_me,
                th_operacion,
                th_codigo_externo,
                th_codval,
                th_tipo_cca
               )
	values (
                getdate(),
                @w_secuencial,
		@i_filial,
		@i_oficina_orig,
		@i_oficina_dest,
	  	@i_tipo,  
		@i_moneda,
		@w_valor,
		@w_valor_me,
		@i_operac,
                @i_codigo_externo,
                @i_codval,
                @i_tipo_cca)

           if @@error <> 0
           begin
              exec cobis..sp_cerror
              @t_debug = @t_debug,
              @t_file  = @t_file, 
              @t_from  = @w_sp_name,
              @i_num   = @w_error
              return 1 
           end
           commit tran
           return 0
end
go
