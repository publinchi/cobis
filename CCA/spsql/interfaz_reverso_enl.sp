/************************************************************************/
/*   NOMBRE LOGICO:      interfaz_reverso_enl.sp                        */
/*   NOMBRE FISICO:      sp_interfaz_reverso_enl                        */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Guisela Fernandez                              */
/*   FECHA DE ESCRITURA: Julio 2023                                     */
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
/*                     PROPOSITO                                        */ 
/*  Procedimiento encargado de orquestar el reverso de pagos realizados */
/*  por interfaz                                                        */
/************************************************************************/ 
/*                     MODIFICACIONES                                   */ 
/*   FECHA       AUTOR           RAZON                                  */ 
/* 05/07/2023    G. Fernandez    Versión Inicial                        */
/* 12/07/2023    G. Fernandez    Cambio de cod. error por el seuencial  */
/* 28/07/2023    G. Fernandez    S857741 Parametros de licitud          */
/* 01/08/2023    G. Fernandez    Se cambio codigos de errores de cartera*/
/* 15/08/2023    G. Fernandez    Obtencion de parametros de facturacion */
/* 29/08/2023    G. Fernandez    Coreccion de num de caracteres en op   */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_reverso_enl')
   drop proc sp_interfaz_reverso_enl
go
create proc sp_interfaz_reverso_enl
@s_ssn                int           = null,
@s_sesn               int           = null,
@s_ofi                smallint      = null,
@s_rol                smallint      = null,
@s_user               login         = null,
@s_date               datetime      = null,
@s_term               descripcion   = null,
@t_debug              char(1)       = 'N',
@t_file               varchar(10)   = null,
@s_srv                varchar(30)   = null,
@s_lsrv               varchar(30)   = null,
@s_org                char(1)       = null,
@t_trn                int           = null,
@s_format_date        int           = null,   
@s_ssn_branch         int           = null,            
@i_operacion          char(1)       = 'R',     -- Q: R: Reverso
@i_idcolector         smallint,                -- Código de Banco en Bancos.
@i_numcuentacolector  varchar(30),             -- Número de cuenta en Bancos
@i_idreferencia       varchar(30),             -- Número de referencia [Boleta]
@i_banco              varchar(30),             -- Número de operación de Cartera [Número largo]
@i_amounttopay        money,

@o_reference          varchar(30)  = null out,
@o_status             varchar(255)  = null out,
-- Parámetros factura electrónica
@o_guid               varchar(36)  = null out,
@o_fecha_registro     varchar(10)  = null out,
@o_ssn                int          = null out,
@o_orquestador_fact   char(1)      = null out

         
as declare
@w_return               int,
@w_error		        int,
@w_sp_name              varchar(64),
@w_operacionca          int, 
@w_tipo_operacion       char(1),
@w_f_pago               varchar(20),
@w_secuencial_ing       int,
@w_fecha_proceso         datetime,
@w_secuencial_pag       int,
@w_monto_reg            money

-- Información inicial
select @w_sp_name              = 'sp_interfaz_reverso_enl'

-- Fecha de proceso
select @w_fecha_proceso = fp_fecha from cobis..ba_fecha_proceso

--Validación de número de operación con 11 caracteres
if (LEN(@i_banco) > 11)
   select @i_banco = SUBSTRING(@i_banco, LEN(@i_banco)-10,11)

select @w_operacionca = op_operacion from ca_operacion 
where op_banco = @i_banco

if not exists (select 1 from ca_operacion where op_banco = @i_banco)
begin
   select @w_error = 701013 -- No existe operación activa de cartera
   goto ERROR
end
else
   select @o_reference = @i_banco

--Valida que el colector este registrado en bancos
if @i_idcolector not in (select cu_banco 
                         from cob_bancos..ba_cuenta)
begin
   select @w_error = 711101 -- El código de banco ingresado no existe
   goto ERROR  
end

--Valida que el colector este registrado en bancos
if @i_numcuentacolector not in (select cu_cta_banco 
                         from cob_bancos..ba_cuenta where cu_banco = @i_idcolector)
begin
   select @w_error = 711102 -- El número de cuenta ingresado no existe
   goto ERROR  
end

--Se obtine la forma de pago   
select @w_f_pago =  c.valor
from cobis..cl_tabla t, cobis..cl_catalogo c
where c.tabla  = t.codigo
and   t.tabla  = 'ca_bco_fpago_canales_externos'
and   c.codigo = @i_idcolector
and   c.estado = 'V'   

if @@rowcount = 0
begin
   select @w_error = 725200 -- Error, no existe forma de pago por defecto para el colector
   goto ERROR
end

--Se obtine el monto registrado en el pago
select @w_monto_reg = ip_monto
from cob_cartera..ca_intefaz_pago 
where ip_operacionca        = @w_operacionca
and ip_fecha_pago           = @w_fecha_proceso --@s_date
and ip_banco_pago           = @i_idcolector
and ip_cta_banco_pago       = @i_numcuentacolector
and ip_id_referencia_origen = @i_idreferencia 
and ip_estado               = 'N'

if @w_monto_reg <> @i_amounttopay
begin
   select @w_error = 725295 -- Error, El monto ingresado para reveso no coincide con el monto pagado
   goto ERROR
end

-- Tipo de operación [G: Grupal Padre, H: Grupal Hija, N: Individual]
exec @w_return = sp_tipo_operacion
@i_banco    = @i_banco,
@i_en_linea = 'N',
@o_tipo     = @w_tipo_operacion out

if @w_return <> 0
begin
   select @w_error = @w_return
   goto ERROR
end

if @i_operacion = 'R'
begin

   begin tran
   
   if @w_tipo_operacion in ('G')
   begin

   	  select  @w_secuencial_ing = ip_sec_ing_cartera
   	  from cob_cartera..ca_intefaz_pago 
   	  where ip_operacionca        = @w_operacionca
   	  and ip_fecha_pago           = @w_fecha_proceso --@s_date
   	  and ip_monto                = @i_amounttopay
	  and ip_banco_pago           = @i_idcolector
      and ip_cta_banco_pago       = @i_numcuentacolector
      and ip_id_referencia_origen = @i_idreferencia 
   	  and ip_estado               = 'N'
   	  
   	  if @@rowcount <> 1
   	  BEGIN
   	  	select @w_error = 725101
            goto ERROR
   	  end
       
      --Llamada a reversos_grupales
      exec  @w_return = cob_cartera..sp_pago_grupal_reverso
      @s_srv              = 'CTSSRV',
      @s_user             = @s_user,
      @s_term             = @s_term,
      @s_ofi              = @s_ofi,
      @s_rol              = @s_rol,
      @s_ssn              = @s_ssn,
      @s_lsrv             = @s_lsrv,
      @s_date             = @s_date,
      @s_sesn             = @s_sesn,
      @s_org              = @s_org,
      @t_debug            = @t_debug,
      @t_file             = @t_file,
      @t_trn              = 77589,
      @i_operacion        = 'R',
      @i_banco_grupal     = @i_banco,
      @i_secuencial_ing_abono_grupal = @w_secuencial_ing,
      @i_externo          = 'N',
      @i_observacion      = 'Reverso por interfaz',
      @o_ssn              = @o_ssn out,
      @o_orquestador_fact = @o_orquestador_fact out,
      @o_guid             = @o_guid out,
      @o_fecha_registro   = @o_fecha_registro out,
	  @i_aplica_licitud   = 'S'
      
      if @@error != 0 or  @w_return <> 0	
      begin                                    	
         select @w_error = @w_return
         goto ERROR
      end	
      
   end
   else
   begin
      
   	  select  @w_secuencial_ing = ip_sec_ing_cartera
   	  from cob_cartera..ca_intefaz_pago 
   	  where ip_operacionca        = @w_operacionca
   	  and ip_fecha_pago           = @w_fecha_proceso --@s_date
   	  and ip_monto                = @i_amounttopay
	  and ip_banco_pago           = @i_idcolector
      and ip_cta_banco_pago       = @i_numcuentacolector
      and ip_id_referencia_origen = @i_idreferencia 
   	  and ip_estado               = 'N'
   	  
   	  if @@rowcount <> 1
   	  begin
   	  	select @w_error = 725101
            goto ERROR
   	  end
      
      select @w_secuencial_pag = ab_secuencial_pag 
      from ca_abono
      where ab_secuencial_ing = @w_secuencial_ing
      and ab_operacion = @w_operacionca
      
      if @@rowcount <> 1
   	  begin
   	  	 select @w_error = 725101 
         goto ERROR
   	  end
      
   	  if @w_secuencial_pag <> 0 
   	  begin
   	  	 exec  @w_return = cob_cartera..sp_fecha_valor
         @s_srv         	      = @s_srv,
         @s_user        	      = @s_user,
         @s_term        	      = @s_term,
         @s_ofi         	      = @s_ofi,
         @s_rol         	      = @s_rol,
         @s_ssn         	      = @s_ssn,
         @s_lsrv        	      = @s_lsrv,
         @s_date        	      = @s_date,
         @s_sesn        	      = @s_sesn,
         @t_trn         	      = 7049,
         @i_banco                 = @i_banco,
         @i_secuencial            = @w_secuencial_pag, --Secuencial pago
         @i_secuencial_rv_int     = @w_secuencial_ing, --Secuencial ingreso pago
         @i_operacion             = 'R',	
         @i_observacion 	      = 'Reverso por interfaz',
         @i_es_atx                = 'S',	
         @i_en_linea              = 'S',
         @i_pago_interfaz         = 'S',
		 @i_aplica_licitud        = 'S',
		 @o_ssn                   = @o_ssn out,
         @o_orquestador_fact      = @o_orquestador_fact out,
         @o_guid                  = @o_guid out,
         @o_fecha_registro        = @o_fecha_registro out
                             	
         if @@error != 0 or  @w_return <> 0	
         begin                                    	
            select @w_error =725102
            goto ERROR
         end	
   	  end
   	  else
   	  begin
   	      exec @w_error = sp_eliminar_pagos
          @t_trn             = 7036,
          @i_banco           = @i_banco,
          @i_operacion       = 'D',
          @i_secuencial_ing  = @w_secuencial_ing, --Secuencial ingreso pago	
          @i_en_linea        = 'S',
          @i_pago_interfaz   = 'S'  
          
          if @@error != 0 or @w_error <> 0
          goto ERROR
   	  end
      
   end
   
   update ca_intefaz_pago 
   set ip_estado = 'R'
   where ip_operacionca         = @w_operacionca
   and ip_id_referencia_origen  = @i_idreferencia
   and ip_sec_ing_cartera       = @w_secuencial_ing
   
   commit tran
   	
   select @o_status = 'REVERSADO'
end

return 0

ERROR:

begin
   exec cobis..sp_cerror
   @t_debug='N',    
   @t_file=null,
   @t_from=@w_sp_name,   
   @i_num = @w_error
end

return @w_error    

go
