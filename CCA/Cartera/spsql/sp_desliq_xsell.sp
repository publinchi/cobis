/************************************************************************/
/*   Archivo:              sp_desliq_xsell.sp                           */
/*   Stored procedure:     sp_desliq_xsell                              */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Kevin Rodríguez                              */
/*   Fecha de escritura:   18/Junio/2021                                */
/************************************************************************/
/*                     IMPORTANTE                                       */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Realiza el registro de formas de desembolso o la liquidación de    */
/*   préstamos que vienen desde XSell                                   */
/*                                                                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 18/Jun/2021   Kevin Rodríguez      Version inicial                   */
/* 09/Feb/2021   Kevin Rodriguez      Ajuste Liquidación de Desem Reestr*/
/* 04/Abr/2022   Kevin Rodríguez      Parámetro externo en func. Liquida*/
/* 14/Jun/2022   Juan C. Guzman       Se añade @i_modo = 'CHEQUES'      */
/* 17/Jun/2022   Juan C. Guzman       Cambio en parametro de envío de   */
/*                                    oficina en sp_tran_general        */
/* 22/Jun/2022   Juan C. Guzman       Valid. para interfaz con bancos   */
/*                                    en forma desembolso CHBC y TBAN   */
/* 23/06/2022    Kevin Rodríguez      Ajustes liquidación (sp_liquida)  */
/* 04/07/2022    Kevin Rodríguez      Nuevo @i_modo = 'ODP'             */
/* 06/07/2022    Kevin Rodríguez      Retornar 0 cuando no existen ODPs */
/* 14/07/2022    Kevin Rodríguez      Retornar error de interfaz Bancos */
/* 11/10/2022    Guisela Fernandez    R195199 En CHEQUES actualizacion  */
/*                                    ca_desembolso por dm_desembolso   */
/* 15/05/2023    Guisela Fernandez    S825268 Se incluye parametro para */
/*                                    desembolso indidual en op. hijas  */
/* 21/08/2023    Kevin Rodríguez      S873644 Se valida que el tramite  */
/*                                    es una renovación para actualiza  */
/*                                    el estado                         */
/* 25/08/2023    Guisela Fernandez    R213766 Act. consulta por renov.  */
/************************************************************************/ 

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_desliq_xsell')
   drop proc sp_desliq_xsell
go

create proc sp_desliq_xsell (
@s_ofi                  SMALLINT     = null,
@s_user                 login        = null,
@s_date                 DATETIME     = null,
@s_term                 descripcion  = null,
@s_ssn                  INT          = null,
@s_rol                  smallint     = null,
@s_sesn                 int          = null,
@s_srv                  varchar(30)  = null, 
@t_trn                  int          = null,  
@i_tramite              int,
@i_modo                 varchar(12),
@i_externo              char(1)      = 'S'   -- KDR Bandera que indica si es llamado desde un programa superior (SP)
)

as declare
@w_sp_name              varchar(30),
@w_error                int,
@w_fdesliq_ncah          catalogo,    -- Forma de desembolso para liquidación con Nota de credito cuenta de ahorros
@w_prod_des             catalogo,    -- Producto de desembolso
@w_fpago_reestruc       catalogo,    -- Forma desembolso-pago reestructuración
@w_banco                cuenta,
@w_operacionca          int,
@w_monto                money, 
@w_moneda               tinyint, 
@w_fecha_ini            datetime,
@w_fecha_fin            datetime,
@w_fecha_liq            datetime,
@w_tipo                 char(1) ,
@w_oficina              smallint,
@w_siguiente            int,
@w_est_vigente          smallint,
@w_est_novigente        smallint,
@w_est_credito          smallint,
@w_est_cancelado        smallint,
@w_estado               smallint,
@w_dias                 int,
@w_num_oficial          smallint,
@w_filial               tinyint,
@w_cliente              int, 
@w_direccion            int,      
@w_op_direccion         tinyint,
@w_lin_credito          cuenta,
@w_tipo_amortizacion    catalogo,
@w_total_desem_reest    tinyint,
@w_secuencial           int,
@w_num_desembolso       tinyint,
@w_fecha_proceso        datetime,
@w_cont                 int,
@w_ssn                  int,
@w_cod_banco_ach        bigint,
@w_cuenta               varchar(30),
@w_beneficiario         varchar(255),
@w_monto_ds             money,
@w_secuencial_dem       int,
@w_desembolso           int,
@w_forma_desem          varchar(10),
@w_causal               varchar(14),
@w_sec_desembolso       int,
@w_sec_chq              int,
@w_oficina_chq          smallint,
@w_cat_chbc             varchar(20),
@w_cat_tban             varchar(20),
@w_tipo_tran            smallint,
@w_pagado               char(1),
@w_grupal               char(1),
@w_ref_grupal           cuenta

---  VARIABLES DE TRABAJO  
select  
@w_sp_name       = 'sp_desliq_xsell'

-- Validación transacción
if @t_trn <> 77546 
begin        
   select @w_error = 141018 -- Error en codigo de transaccion
   goto ERROR
end

-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_novigente  = @w_est_novigente out,
@o_est_vigente    = @w_est_vigente   out,
@o_est_credito    = @w_est_credito   out,
@o_est_cancelado  = @w_est_cancelado out

if @w_error <> 0 GOTO ERROR

-- Datos de la operación
select 
@w_operacionca = op_operacion,
@w_fecha_liq   = op_fecha_liq,
@w_monto       = op_monto,
@w_moneda      = op_moneda,
@w_fecha_ini   = op_fecha_ini,
@w_fecha_fin   = op_fecha_fin,
@w_oficina     = op_oficina,
@w_banco       = op_banco,  
@w_cliente     = op_cliente,
@w_estado      = op_estado,
@w_op_direccion = op_direccion,
@w_lin_credito   = op_lin_credito,
@w_tipo_amortizacion = op_tipo_amortizacion,
@w_grupal       = op_grupal,
@w_ref_grupal   = op_ref_grupal,
@w_beneficiario = op_nombre
from  ca_operacion
where op_tramite = @i_tramite


-- Forma de desembolso para liquidación con Nota de credito cuenta de ahorros
select @w_fdesliq_ncah = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'LIQNCA' and
       pa_producto = 'CCA'
       
if @@rowcount = 0 begin
   select @w_error = 2600023 --No existe parametro general
   goto ERROR
end

-- Forma desembolso-pago reestructuración
select @w_fpago_reestruc = pa_char
from   cobis..cl_parametro
where  pa_nemonico = 'REESFP' and    
       pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_error = 2600023 --No existe parametro general
   goto ERROR
end


if @i_modo = 'LIQNCAH'
BEGIN
   
   -- Se valida que exista forma de desembolso
    IF NOT EXISTS (SELECT 1 FROM ca_desembolso WHERE dm_operacion = @w_operacionca)
   BEGIN 
      select @w_error = 701121 -- No existe Desembolso
      GOTO ERROR
   END
   
   -- Se valida que exista unica forma desembolso Nota de Credito Cuenta de Ahorros
   select  @w_prod_des       = dm_producto
      FROM ca_desembolso 
      where dm_operacion = @w_operacionca 
      group by dm_producto
      
   if @@ROWCOUNT <> 1 
   BEGIN
      GOTO SALIR
   end
   else
   begin
      if @w_prod_des <> @w_fdesliq_ncah
      BEGIN
         GOTO SALIR
      end
   END
   
   select  @w_secuencial     = dm_secuencial,
           @w_num_desembolso = dm_desembolso,
           @w_pagado         = dm_pagado   
   FROM ca_desembolso 
   where dm_operacion = @w_operacionca
   and   dm_producto  = @w_fdesliq_ncah
	  
   -- Liquidación del préstamo
   if @w_estado = @w_est_novigente
   begin
   
      exec @w_error = sp_borrar_tmp
        @s_sesn   = @s_ssn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco
        
      if @w_error <> 0  goto ERROR
   
      exec @w_error      = sp_pasotmp
      @s_term             = @s_term,
      @s_user             = @s_user,
      @i_banco            = @w_banco,
      @i_operacionca      = 'S',
      @i_dividendo        = 'S',
      @i_amortizacion     = 'S',
      @i_cuota_adicional  = 'S',
      @i_rubro_op         = 'S',
      @i_nomina           = 'S'   
      
      if @w_error <> 0  goto ERROR
         
      exec @w_error     = sp_liquida
        @s_ssn            = @s_ssn,
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_rol            = @s_rol,
        @s_term           = @s_term,
        @i_banco_ficticio = @w_operacionca,
        @i_banco_real     = @w_banco,
        @i_fecha_liq      = @w_fecha_liq,
        @i_externo        = 'N',
		@i_desde_cartera  = 'N',           -- KDR No es ejecutado desde Cartera[FRONT]
		@i_liq_grupal     = 'S'            -- Permite liquidación de cada una de la operaciones hijas
        
      if @w_error <> 0 goto ERROR
        
      exec @w_error = sp_borrar_tmp
        @s_sesn   = @s_ssn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco
      
      if @w_error <> 0  goto ERROR
   
   end
   
   if @w_pagado = 'N'
   begin
      update ca_desembolso
      set    dm_pagado  = 'S'
      where dm_operacion  = @w_operacionca
      and   dm_secuencial = @w_secuencial 
      and   dm_desembolso = @w_num_desembolso
      
      if @@error <> 0
      begin
         select @w_error = 710002 -- Error en la actualizacion del registro
         goto ERROR
      end 
   end
   else
   begin
      select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
      goto ERROR  
   end
   
end --  Fin @i_modo LIQNCAH


if @i_modo = 'CTAPTE'
BEGIN

   select @w_fpago_reestruc = rtrim(@w_fpago_reestruc)

   -- Validación que exista única forma de desembolso para REEST.
   select @w_total_desem_reest  = count(1)  
   from ca_desembolso 
   where dm_operacion = @w_operacionca
   and   dm_producto  = @w_fpago_reestruc
   
   if isnull(@w_total_desem_reest , 0) <> 1
   begin
      select @w_error = 725140 -- Error, el préstamo no tiene, o tiene más de una forma de desembolso para Reestructuraciones.
      goto ERROR
   end
   
   select @w_secuencial     = dm_secuencial,
          @w_num_desembolso = dm_desembolso,
		  @w_pagado         = dm_pagado
   from ca_desembolso
   where dm_operacion = @w_operacionca
   and   dm_producto  = @w_fpago_reestruc

   -- Validación para poder realizar la liquidación
   if exists(select 1 from cob_cartera..ca_desembolso
            where dm_operacion = @w_operacionca
            and   dm_secuencial > 0
            and   dm_desembolso > 0) 
            and   @w_estado =  @w_est_novigente 
   BEGIN
         -- Liquidación del préstamo
        exec @w_error = sp_borrar_tmp
           @s_sesn   = @s_ssn,
           @s_user   = @s_user,
           @s_term   = @s_term,
           @i_banco  = @w_banco
           
        if @w_error <> 0  goto ERROR
      
         exec @w_error      = sp_pasotmp
         @s_term             = @s_term,
         @s_user             = @s_user,
         @i_banco            = @w_banco,
         @i_operacionca      = 'S',
         @i_dividendo        = 'S',
         @i_amortizacion     = 'S',
         @i_cuota_adicional  = 'S',
         @i_rubro_op         = 'S',
         @i_nomina           = 'S'   
         
         if @w_error <> 0  goto ERROR
            
         exec @w_error     = sp_liquida
           @s_ssn            = @s_ssn,
           @s_sesn           = @s_sesn,
           @s_user           = @s_user,
           @s_date           = @s_date,
           @s_ofi            = @s_ofi,
           @s_rol            = @s_rol,
           @s_term           = @s_term,
           @i_banco_ficticio = @w_operacionca,
           @i_banco_real     = @w_banco,
           @i_fecha_liq      = @w_fecha_liq,
           @i_externo        = 'N', 
		   @i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
		   @i_liq_grupal     = 'S'           -- Permite liquidación de cada una de la operaciones hijas
           
           if @w_error <> 0 goto ERROR
           
         exec @w_error = sp_borrar_tmp
           @s_sesn   = @s_ssn,
           @s_user   = @s_user,
           @s_term   = @s_term,
           @i_banco  = @w_banco
         
         if @w_error <> 0  goto ERROR
   end
   
   if @w_pagado = 'N'
   begin
      update ca_desembolso
      set    dm_pagado  = 'S'
      where dm_operacion  = @w_operacionca
      and   dm_secuencial = @w_secuencial 
      and   dm_desembolso = @w_num_desembolso
      
      if @@error <> 0
      begin
         select @w_error = 710002 -- Error en la actualizacion del registro
         goto ERROR
      end 
   end
   else
   begin
      select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
      goto ERROR  
   end
   
   -- Si la Operación hija es parte de Un Trámite de Renovación Grupal, se cancela el préstamo
   -- Padre solo si no tiene desembolsos de operaciones hijas pendientes de entregar
   if 'R' = (select tr_tipo 
             from cob_credito..cr_tramite, cob_credito..cr_tramite_grupal
			 where tg_operacion = @w_operacionca
			 and tg_tramite = tr_tramite)
	  and @w_grupal = 'S'
	  and @w_ref_grupal is not null
   begin
      if not exists (select 1 
                     from cob_credito..cr_tramite_grupal, cob_credito..cr_tramite, ca_operacion with (nolock)
                     where tg_tramite = (select op_tramite
                                         from ca_operacion  with (nolock)
                                         where op_banco = @w_ref_grupal)
                     and tg_operacion = tr_numero_op
                     and tr_numero_op = op_operacion
                     and op_estado    = 0)
      begin
         update ca_operacion with (rowlock)
         set    op_estado  = @w_est_cancelado
         where  op_banco  = @w_ref_grupal
		 and    op_estado = @w_est_novigente
         
         if @@error <> 0
         begin
             select @w_error = 705076 -- Error al actualizar informacion de ca_operacion
             goto ERROR
         end
      end
   end

end --  Fin @i_modo CTAPTE


if @i_modo = 'CHEQUES'
begin
   --CREACION DE TABLA PARA VALIDACIÓN      
   create table #ca_desembolso_tmp
   (
      dmt_cod_banco_recep   bigint         null,  
      dmt_cta_recep         varchar(30)    null,  
      dmt_beneficiario      varchar(255)   null,        
      dmt_monto_mn          money          null,
      dmt_secuencial        int            null,
      dmt_desembolso        int            null,
      dmt_operacion         int            null,
      dmt_producto          varchar(10)    null,
	  dmt_oficina           smallint       null
   )
   
   select @w_fecha_proceso = fc_fecha_cierre
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7  -- 7 pertenece a Cartera
   
   insert into #ca_desembolso_tmp
   select dm_cod_banco,
          dm_cuenta,
          dm_beneficiario,
          dm_monto_mn,
          dm_secuencial,
          dm_desembolso,
          dm_operacion,
          dm_producto,
          dm_oficina_chg
   from ca_desembolso, ca_producto
   where dm_operacion = @w_operacionca
   and   cp_producto  = dm_producto
   and   cp_categoria in ('CHBC', 'TBAN')
   and   dm_estado    = 'NA'
   order by dm_desembolso
   
   select @w_cont = count(*) from #ca_desembolso_tmp
   
   select @w_cat_chbc = cp_producto
   from ca_producto
   where cp_categoria = 'CHBC'
   
   select @w_cat_tban = cp_producto
   from ca_producto
   where cp_categoria = 'TBAN'
   
   
   while @w_cont > 0
   begin
      select @w_ssn    = -1,
          @w_error  = 0
          
      exec @w_ssn = master..rp_ssn   

      -- Se obtiene la información de desembolso
      select top 1
         @w_cod_banco_ach    = dmt_cod_banco_recep,
         @w_cuenta           = dmt_cta_recep,
         @w_beneficiario     = dmt_beneficiario,
         @w_monto_ds         = dmt_monto_mn,
         @w_secuencial_dem   = dmt_secuencial,
         @w_desembolso       = dmt_desembolso,
         @w_operacionca      = dmt_operacion,
         @w_forma_desem      = dmt_producto,
		 @w_oficina_chq      = dmt_oficina
      from #ca_desembolso_tmp    
     
     select @w_sec_desembolso = dm_carga
     from ca_desembolso
     where dm_operacion  = @w_operacionca
     and   dm_producto   = @w_forma_desem
     and   dm_secuencial = @w_secuencial_dem
     
     if @w_sec_desembolso != 0 and @w_sec_desembolso is not null
     begin
        goto NEXT_REG
     end

      select @w_causal = c.valor 
      from cobis..cl_tabla t, cobis..cl_catalogo c
      where t.tabla  = 'ca_fpago_causalbancos'
      and   t.codigo = c.tabla
      and   c.estado = 'V'
      and   c.codigo = @w_forma_desem    

      if @@rowcount = 0 or @w_causal is null
      begin
        select @w_error = 725139
         goto ERROR
      end 

      if @w_forma_desem = @w_cat_chbc
         select @w_tipo_tran = 103
		 
	  if @w_forma_desem = @w_cat_tban
         select @w_tipo_tran = 106

      exec @w_error = cob_bancos..sp_tran_general  
         @i_operacion      ='I',
         @i_banco          = @w_cod_banco_ach,  
         @i_cta_banco      = @w_cuenta, 
         @i_fecha          = @w_fecha_proceso,
         @i_tipo_tran      = @w_tipo_tran, 
         @i_causa          = @w_causal,      
         @i_documento      = @w_banco,                 
         @i_concepto       = 'DESEMBOLSO CARTERA',
         @i_beneficiario   = @w_beneficiario,
         @i_valor          = @w_monto_ds,   
         @i_producto       = 7,
         @i_sec_monetario  = @w_desembolso,
         @t_trn            = 171013, 
         @i_ref_modulo2    = @s_ofi,
         @s_user           = @s_user,
         @s_term           = @s_term,
         @s_ofi            = @w_oficina_chq,
         @s_ssn            = @w_ssn,
         @s_corr           = 'I',
         @s_date           = @s_date,
         @o_secuencial     = @w_sec_chq out        

      if @w_error <> 0
         goto ERROR


      update ca_desembolso
      set dm_carga = @w_sec_chq
      where dm_operacion  = @w_operacionca
      and   dm_producto   = @w_forma_desem
      and   dm_secuencial = @w_secuencial_dem
      and	dm_desembolso = @w_desembolso  --GFP Actualización por dm_desembolso

      if @@error != 0 
      begin
         select @w_error = 710305
         goto ERROR
      end
     

      NEXT_REG:
         delete #ca_desembolso_tmp 
         where dmt_secuencial = @w_secuencial_dem
         and   dmt_desembolso = @w_desembolso 
         and   dmt_operacion  = @w_operacionca    

     select @w_cont = @w_cont -1
     
   end -- END WHILE
   
   drop table #ca_desembolso_tmp
   
end -- Fin @i_modo = 'CHEQUES'

if @i_modo = 'ODP'
begin

   select @w_secuencial     = dm_secuencial,
          @w_num_desembolso = dm_desembolso,
          @w_pagado         = dm_pagado
   from cob_cartera..ca_desembolso 
   left join cob_cartera..ca_operacion on op_operacion = dm_operacion
   left join cob_cartera..ca_producto 	on cp_producto 	= dm_producto
   left join cob_bancos..ba_banco 		on ba_codigo 	= dm_cod_banco
   where dm_pagado = 'N'
   and op_estado in (@w_est_novigente, @w_est_vigente, @w_est_credito)
   and cp_categoria = 'ORPA'
   and op_banco = @w_banco

   if @@rowcount = 0
      GOTO SALIR
   
   if @@rowcount >  1
   begin
      select @w_error = 725157 -- PRESTAMO NO TIENE O TIENE MAS DE UNA ORDEN DE PAGO PENDIENTE
      goto ERROR
   end
  
   -- Si la formas de desembolso ya ha sido pagada, no se debe generar pin
   if @w_pagado = 'S'
   begin
      select @w_error = 725130 -- Error, la orden de desembolso ya ha sido pagada.
      goto ERROR
   end
	
   -- Generación de PIN
   exec @w_error = cob_cartera..sp_pin_odp 
   @t_trn            = 77549,
   @i_operacion      = 'I',
   @i_banco          = @w_banco,
   @i_desembolso     = @w_num_desembolso,
   @i_secuencial_des = @w_secuencial,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_date           = @s_date,
   @s_sesn           = @s_sesn,
   @s_ofi            = @s_ofi
   
   if @w_error <> 0 goto ERROR

end -- Fin @i_modo = 'ODP'

SALIR:

return 0

ERROR:

IF OBJECT_ID ('dbo.#ca_desembolso_tmp') IS NOT NULL
   drop table #ca_desembolso_tmp

if @i_externo = 'N'
   exec cobis..sp_cerror
   @t_debug   = 'N',
   @t_file    = null,
   @t_from    = @w_sp_name,
   @i_num     = @w_error

return @w_error

GO


