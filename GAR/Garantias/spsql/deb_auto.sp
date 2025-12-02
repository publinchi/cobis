/*************************************************************************/
/*   Archivo:              deb_auto.sp                                   */
/*   Stored procedure:     sp_deb_automatico                             */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:                                                       */
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
/*                                   PROPOSITO                           */
/*    Creacion de objetos de la base. Comprende: tablas, indices,sp      */
/*    tipos de datos, claves primarias y foraneas                        */
/*                                                                       */
/*			                                                             */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA                   AUTOR                 RAZON                */
/*    Marzo/2019                                      emision inicial    */
/*                                                                       */
/*************************************************************************/
USE cob_custodia
go
IF OBJECT_ID('dbo.sp_deb_automatico') IS NOT NULL
    DROP PROCEDURE dbo.sp_deb_automatico
go
create proc sp_deb_automatico (
   @s_ssn                int      = null,
   @s_date               datetime = null,
   @s_user               login    = null,
   @s_term               descripcion = null,
   @s_corr               char(1)  = null,
   @s_ssn_corr           int      = null,
   @s_srv                varchar(30) =null,
   @s_ofi                smallint  = null,
   @t_rty                char(1)  = null,
   @t_trn                smallint = null,
   @t_debug              char(1)  = 'N',
   @t_file               varchar(14) = null,
   @t_from               varchar(30) = null,
   @i_operacion          char(1)  = null,
   @i_modo               smallint = null,
   @i_param1     	 descripcion = null,
   @i_en_linea 	         char(1)  = "S",
   @i_commit 	         char(1)  = "N",
   @i_fecha              datetime,
   @i_fecha_insp         datetime = null,
   @i_secuencial         int = null,    --- REVISAR
   @i_banco              cuenta = null, --- REVISAR
   @i_afectacion         char(1)= null, --- REVISAR
   @i_afect_prod         char(1)  = 'S',
   @i_concepto           catalogo = null,
   @i_provision          char(1) = null,
   @i_monto              money,
   @i_moneda             tinyint,
   @i_oficina            smallint = null,
   @i_codvalor	         smallint = null,
   @i_empresa	         tinyint = null,
   @i_filial 	         tinyint = null,
   @i_sucursal           smallint = null,
   @i_tipo_cust          varchar(64) = null,
   @i_custodia           int = null,
   @i_codigo_externo     varchar(64) = null,
   @i_perfil	         varchar(10) = null,
   @i_tipo_cta_cli       char(3) = null,
   @i_cuenta_cliente     cuenta = null,
   @i_tipo_cta_insp      char(3)  = null,
   @i_cuenta_insp        cuenta = null,
   @i_inspector          tinyint = null,
   @i_oficina_contabiliza smallint = null
)
as

declare @w_error        int,
        @w_today        datetime,     /* fecha del dia */ 
        @w_return       int,          /* valor que retorna */
        @w_sp_name      varchar(32),  /* nombre stored proc*/
        @w_existe       tinyint,      /* existe el registro*/
        @w_estado       char(1),
        @w_tantos       int,
        @w_trn_prod     int,
        @w_ind          tinyint,
        @w_money        money,
        @w_valor_pagado money,
        @w_rever_credito money,
        @w_rever_debito money,
        @w_fecha_hoy    datetime,
        @w_cg_cuenta    cuenta,
        @w_moneda       tinyint,
	@w_cuenta       cuenta,
        @w_ssn          int   


/***********************************************************/
/** CARGADO DE VARIABLES DE TRABAJO                       **/

select @w_today     = convert(varchar(10),getdate(),101),
       @w_sp_name   = 'sp_deb_automatico',
       @w_moneda    = isnull(@i_moneda,0),
       @i_en_linea  = isnull(@i_en_linea,'S'),
       @w_fecha_hoy = convert(varchar,getdate(),101)

/***********************************************************/
/* Codigos de Transacciones                                */

if (@t_trn <> 19371 and @i_operacion = 'I') or
   (@t_trn <> 19377 and @i_operacion = 'R') 

begin
/* tipo de transaccion no corresponde */
    exec cobis..sp_cerror
    @t_debug = @t_debug,
    @t_file  = @t_file, 
    @t_from  = @w_sp_name,
    @i_num   = 1901006
    return 1 
end

/* Chequeo de Transacciones en Ctas Ctes y Ctas Ahorros */
/********************************************************/
if @i_operacion = 'I'
begin
       /* Actualiza los numeros y tipos de cuentas del cliente */
        update cu_custodia
        set cu_cta_inspeccion = @i_cuenta_cliente,
            cu_tipo_cta       = @i_tipo_cta_cli
        where cu_filial   = @i_filial
          and cu_sucursal = @i_sucursal
          and cu_tipo     = @i_tipo_cust
          and cu_custodia = @i_custodia

   begin tran 
   
        /*  Debito de la Cuenta del Cliente */
        /************************************/
/*        if @i_tipo_cta_cli = 'CTE'
        begin 
        /* Cuentas Corrientes */ 
           select @w_trn_prod = 50 
        exec @w_return = cob_cuentas..sp_ccndc_automatica
             @s_ssn   = @s_ssn,
             @s_date  = @s_date,
             @s_srv   = @s_srv,
             @t_trn   = @w_trn_prod,
             @s_ofi   = @s_ofi,
             @i_cta   = @i_cuenta_cliente,
             @i_val   = @i_monto,
             @i_cau   = '57',
             @i_mon   = @i_moneda,
  	     @i_fecha = @w_fecha_hoy,
             @i_alt   = 1

             if @w_return <> 0
             begin 
                select @w_error = 1901010
                select @w_estado = 'N' -- No se pudo cobrar Ctas Ctes
                goto ERROR
             end
         
           /* CONTABILIZACION DEL PAGO A INSPECTORES 
           exec @w_return = sp_conta
             @s_ssn = @s_ssn,
             @s_date = @s_date,
             @t_trn = 19300,
             @i_operacion = 'I',
             @i_filial = @i_filial,
             @i_oficina_orig = @i_oficina_contabiliza,
             @i_oficina_dest = @i_oficina_contabiliza,
             @i_tipo = @i_tipo_cust,
             @i_moneda = @i_moneda,
             @i_valor = @i_monto,
             @i_operac = 'M',
             @i_signo  = 1 */
             
             if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901006
                return 1 
            end
        end
        else*/
        begin
           if @i_tipo_cta_cli = 'AHO'
           begin 
           /* Debito Cuenta Ahorros del Cliente*/    
           /* Cuentas Ahorros */ 
              select @w_trn_prod = 264   --228
           exec @w_return = cob_ahorros..sp_ahndc_automatica
              @s_ssn   = @s_ssn,
              @s_srv   = @s_srv,
              @s_date  = @s_date,
              @t_trn   = @w_trn_prod,
              @s_ofi   = @s_ofi,
              @i_cta   = @i_cuenta_cliente,
              @i_val   = @i_monto,
              @i_cau   = '200', --43
              @i_mon   = @i_moneda,
  	      @i_fecha = @w_fecha_hoy,
              @i_alt   = 1

              if @w_return <> 0
              begin 
                 select @w_error = 1901011
                 select @w_estado = 'N' -- No se pudo cobrar de Ctas Ahorros
                 goto ERROR
              end
           end
           /* CONTABILIZACION DEL PAGO A INSPECTORES 
           exec @w_return = sp_conta
             @s_ssn = @s_ssn,
             @s_date = @s_date,
             @t_trn = 19300,
             @i_operacion = 'I',
             @i_filial = @i_filial,
             @i_oficina_orig = @i_oficina_contabiliza,
             @i_oficina_dest = @i_oficina_contabiliza,
             @i_tipo = @i_tipo_cust,
             @i_moneda = @i_moneda,
             @i_valor = @i_monto,
             @i_operac = 'N',
             @i_signo  = 1 */
             
             if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901012
                return 1 
            end 
        end  -- Fin Debitos cta del cliente

        /* Credito a la cuenta del inspector */      
        /*************************************/
        /*if @i_tipo_cta_insp = 'CTE'
        begin 
        /* Cuentas Corrientes */ 
           select @w_trn_prod = 48
        exec @w_return = cob_cuentas..sp_ccndc_automatica
             @s_ssn   = @s_ssn,
             @s_date  = @s_date,
             @s_srv   = @s_srv,
             @t_trn   = @w_trn_prod,
             @s_ofi   = @s_ofi,
             @i_cta   = @i_cuenta_insp,
             @i_val   = @i_monto,
             @i_cau   = '45',
             @i_mon   = @i_moneda,
  	     @i_fecha = @w_fecha_hoy,
             @i_alt   = 2

             if @w_return <> 0
             begin 
                select @w_error = 1901010
                select @w_estado = 'N' -- No se pudo cobrar Ctas Ctes
                goto ERROR
             end
           /* CONTABILIZACION DEL PAGO A INSPECTORES 
           exec @w_return = sp_conta
             @s_ssn = @s_ssn,
             @s_date = @s_date,
             @t_trn = 19300,
             @i_operacion = 'I',
             @i_filial = @i_filial,
             @i_oficina_orig = @i_oficina_contabiliza,
             @i_oficina_dest = @i_oficina_contabiliza,
             @i_tipo = @i_tipo_cust,
             @i_moneda = @i_moneda,
             @i_valor = @i_monto,
             @i_operac = 'O',
             @i_signo  = 1 */
             
             if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901006
                return 1 
            end
        end
        else*/
        begin
           if @i_tipo_cta_insp = 'AHO'
           begin 
           /*Credito Cuenta Ahorros Inspector*/
	   /* Cuentas Ahorros */ 
              select @w_trn_prod = 253 --229 
           exec @w_return = cob_ahorros..sp_ahndc_automatica
              @s_ssn   = @s_ssn,
              @s_srv   = @s_srv,
              @s_date  = @s_date,
              @t_trn   = @w_trn_prod,
              @s_ofi   = @s_ofi,
              @i_cta   = @i_cuenta_insp,
              @i_val   = @i_monto,
              @i_cau   = '200', --32
              @i_mon   = @i_moneda,
  	      @i_fecha = @w_fecha_hoy,
              @i_alt   = 2

              if @w_return <> 0
              begin 
                 /*inicio prueba*/
                   select @w_trn_prod = 253 --229 
	           exec @w_return = cob_ahorros..sp_ahndc_automatica
        	   @s_ssn   = @s_ssn,
              	   @s_srv   = @s_srv,
                   @s_date  = @s_date,
                   @t_trn   = @w_trn_prod,
                   @s_ofi   = @s_ofi,
                   @i_cta   = @i_cuenta_cliente,
                   @i_val   = @i_monto,
                   @i_cau   = '200', --32
                   @i_mon   = @i_moneda,
  	           @i_fecha = @w_fecha_hoy,
                   @i_alt   = 2
 
                 /*fin prueba*/  
		 select @w_error = 1901011
                 select @w_estado = 'N' -- No se pudo cobrar de Ctas Ahorros
                 goto ERROR
              end
           end
       /* CONTABILIZACION DEL PAGO A INSPECTORES 
          exec @w_return = sp_conta
             @s_ssn = @s_ssn,
             @s_date = @s_date,
             @t_trn = 19300,
             @i_operacion = 'I',
             @i_filial = @i_filial,
             @i_oficina_orig = @i_oficina_contabiliza,
             @i_oficina_dest = @i_oficina_contabiliza,
             @i_tipo = @i_tipo_cust,
             @i_moneda = @i_moneda,
             @i_valor = @i_monto,
             @i_operac = 'P',
             @i_signo  = 1 */
             
             if @w_return <> 0 
             begin
             /* Error en actualizacion de registro */
                exec cobis..sp_cerror
                @t_debug = @t_debug,
                @t_file  = @t_file, 
                @t_from  = @w_sp_name,
                @i_num   = 1901012
                return 1 
            end 

        end   -- Fin credito cta del inspector

        
        update cu_control_inspector
           set ci_fecha_pago        = @w_fecha_hoy
         where ci_inspector         = @i_inspector
           and ci_frecep_reporte    is not null
           and ci_fecha_pago        is null
       
        select @w_valor_pagado = isnull(ci_valor_pagado,0)
          from cu_control_inspector
         where ci_inspector    = @i_inspector
           and ci_fecha_pago   = @w_fecha_hoy  
 
        update cu_control_inspector
           set ci_valor_pagado = isnull(@w_valor_pagado + isnull(@i_monto,0),0)
         where ci_inspector    = @i_inspector
           and ci_fecha_pago   = @w_fecha_hoy 

        update cob_custodia..cu_inspeccion
           set in_estado_tramite = 'S'
         where in_filial      = @i_filial
           and in_sucursal    = @i_sucursal
           and in_tipo_cust   = @i_tipo_cust  
           and in_custodia    = @i_custodia
           and in_fecha_insp  = @i_fecha_insp    

          select @w_estado = 'S' -- Si se pudo cobrar
    
   commit tran
   select @w_estado       -- Estado: Cobrado, No cobrado
return 0
end

if @i_operacion = 'R'
begin
        update cu_custodia
        set cu_cta_inspeccion = @i_cuenta_cliente,
            cu_tipo_cta       = @i_tipo_cta_cli
        where cu_filial   = @i_filial
          and cu_sucursal = @i_sucursal
          and cu_tipo     = @i_tipo_cust
          and cu_custodia = @i_custodia

   begin tran 

        /*  Debito de la Cuenta del Inspector */
        /************************************/
        /*if @i_tipo_cta_insp = "CTE"
        begin 
        /* Cuentas Corrientes */ 
           select @w_trn_prod = 50 
        exec @w_return = cob_cuentas..sp_ccndc_automatica
             @s_ssn   = @s_ssn,
             @s_date  = @s_date,
             @s_srv   = @s_srv,
             @t_trn   = @w_trn_prod,
             @s_ofi   = @s_ofi,
             @i_cta   = @i_cuenta_cliente,
             @i_val   = @i_monto,
             @i_cau   = '57',
             @i_mon   = @i_moneda,
  	     @i_fecha = @w_fecha_hoy,
             @i_alt   = 1

             if @w_return <> 0
             begin 
                select @w_error = 1901010
                select @w_estado = 'S' -- No se pudo reversar Ctas Ctes
                goto ERROR
             end
        end
        else*/
        begin
           if @i_tipo_cta_insp = 'AHO'
           begin 
           /* Cuentas Ahorros */ 
              select @w_trn_prod = 264 --228
           exec @w_return = cob_ahorros..sp_ahndc_automatica
              @s_ssn   = @s_ssn,
              @s_date  = @s_date,
              @s_srv   = @s_srv,
              @t_trn   = @w_trn_prod,
              @s_ofi   = @s_ofi,
              @i_cta   = @i_cuenta_cliente,
              @i_val   = @i_monto,
              @i_cau   = '43',
              @i_mon   = @i_moneda,
  	      @i_fecha = @w_fecha_hoy,
              @i_alt   = 1

              if @w_return <> 0
              begin 
                 select @w_error = 1901011
                 select @w_estado = 'S' -- No se pudo reversar de Ctas Ahorros
                 goto ERROR
              end
           end
        end  -- Fin Debitos cta del inspector


        /* Credito a la cuenta del cliente */      
        /*************************************/

        /*if @i_tipo_cta_cli = "CTE"
        begin 
        /* Cuentas Corrientes */ 
           select @w_trn_prod = 48
        exec @w_return = cob_cuentas..sp_ccndc_automatica
             @s_ssn   = @s_ssn,
             @s_date  = @s_date,
             @s_srv   = @s_srv,
             @t_trn   = @w_trn_prod,
             @s_ofi   = @s_ofi,
             @i_cta   = @i_cuenta_insp,
             @i_val   = @i_monto,
             @i_cau   = '45',
             @i_mon   = @i_moneda,
  	     @i_fecha = @w_fecha_hoy,
             @i_alt   = 2

             if @w_return <> 0
             begin 
                select @w_error = 1901010
                select @w_estado = 'S' -- No se pudo cobrar Ctas Ctes
                goto ERROR
             end
        end
        else*/
        begin
           if @i_tipo_cta_cli = 'AHO'
           begin 
           /* Cuentas Ahorros */ 
              select @w_trn_prod = 253 --229 
           exec @w_return = cob_ahorros..sp_ahndc_automatica
              @s_ssn   = @s_ssn,
              @s_date  = @s_date,
              @s_srv   = @s_srv,
              @t_trn   = @w_trn_prod,
              @s_ofi   = @s_ofi,
              @i_cta   = @i_cuenta_insp,
              @i_val   = @i_monto,
              @i_cau   = '32',
              @i_mon   = @i_moneda,
  	      @i_fecha = @w_fecha_hoy,
              @i_alt   = 2

              if @w_return <> 0
              begin 
                 select @w_error = 1901011
                 select @w_estado = 'S' -- No se pudo cobrar de Ctas Ahorros
                 goto ERROR
              end
           end
        end   -- Fin credito cta del cliente

        update cob_custodia..cu_inspeccion
           set in_estado_tramite = 'N'
         where in_filial      = @i_filial
           and in_sucursal    = @i_sucursal
           and in_tipo_cust   = @i_tipo_cust  
           and in_custodia    = @i_custodia
           and in_fecha_insp  = @i_fecha_insp    

          select @w_estado = 'N' -- Si se pudo reversar

   commit tran
   select @w_estado       -- Estado: Cobrado, No cobrado
return 0
end
ERROR:
    exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,  
         @t_from  = @w_sp_name,
         @i_num   = @w_error
         return 1
go