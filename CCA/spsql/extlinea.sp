/************************************************************************/
/*      Archivo:                extlinea.sp                             */
/*      Stored procedure:       sp_imp_extracto_linea_ext               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Elcira Pelaez			        */
/*      Fecha de escritura:     Dic-2002                                */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA"							*/
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Ejecuta sp interno para generar extracto del cliente en linea   */
/************************************************************************/  
/*                              MODIFICACIONES                          */
/*      Fecha           Nombre      	Proposito                        */
/*      17/Ene/2003	Luis Mayorga    Dar funcionalidad procedimiento    */
/************************************************************************/  

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_imp_extracto_linea_ext')
	drop proc sp_imp_extracto_linea_ext 
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

create proc sp_imp_extracto_linea_ext
   @s_user		login,
   @s_date              datetime     = null,
   @i_cliente		int 	     = 0
	  
as
declare 
   @w_sp_name           	descripcion,
   @w_return            	int,
   @w_error             	int,
   @w_operaciones_directas 	char(1),
   @w_operaciones_directas_uvr	char(1),
   @w_operaciones_indirectas 	char(1),
   @w_cuentas_no_cartera 	char(1),
   @w_directas			char(1),
   @w_directasuvr		char(1),
   @w_indirectas		char(1),
   @w_garantias	   char(1),
   @w_cxc			   char(1),
   @w_sobregiros    	char(1),
   @w_tc    			char(1)
   


/* CARGAR VALORES INICIALES */
select @w_sp_name = 'sp_imp_extracto_linea_ext'

  
  
--Eliminar informacion del cliente
delete ca_extracto_linea_tmp
where exl_user = @s_user
and   exl_cliente = @i_cliente

delete ca_cxc_no_cartera
where cc_user = @s_user
and   cc_cliente = @i_cliente

delete ca_detalles_garantia_deudor
where dg_user = @s_user
and   dg_cliente = @i_cliente

if @s_date is null
   select @s_date = getdate()

/*VALIDAR SI EL CLIENTE TIENE DEUDAS DIRECTAS */
select @w_operaciones_directas = 'N'
if exists (select 1 from ca_operacion 
   where op_cliente = @i_cliente 
   and   op_moneda = 0
   and   op_estado not in (0, 3,99,98,6))
   select @w_operaciones_directas = 'S'       

select @w_operaciones_directas_uvr = 'N'
if exists (select 1 from ca_operacion 
   where op_cliente = @i_cliente 
   and   op_moneda = 2
   and   op_estado not in (0, 3,99,98,6))
   select @w_operaciones_directas_uvr = 'S'       

--VALIDAR SI EL CLIENTE TIENE DEUDAS INDIRECTAS 
select @w_operaciones_indirectas = 'N'
if exists(select 1 from cob_credito..cr_deudores,ca_operacion 
          where de_cliente = @i_cliente
          and   de_rol  !=  'D'
          and   op_tramite = de_tramite
          and   op_estado not in (0, 3,99,98,6))
   select @w_operaciones_indirectas = 'S'

--- VALIDAR SI EL CLIENTE TIENE C x C  SIDAC
select @w_cuentas_no_cartera = 'N'
if exists (select 1 from cob_credito..cr_dato_operacion, cobis..cl_producto
	   where do_tipo_reg = 'D'
	   and do_codigo_producto  = 48
	   and do_numero_operacion > 0
	   and do_codigo_cliente = @i_cliente
	   and do_estado_contable not in (4)
 	   and do_codigo_producto = pd_producto )
 	   
      select @w_cuentas_no_cartera = 'S'

select @w_sobregiros = 'N'

if exists (select 1 from cob_credito..cr_dato_operacion, cobis..cl_producto
	   where do_tipo_reg = 'D'
	   and do_codigo_producto in (50,51)
	   and do_numero_operacion > 0
	   and do_codigo_cliente = @i_cliente
	   and do_estado_contable not in (4)
 	   and do_codigo_producto = pd_producto )
   select @w_sobregiros = 'S'

---VALIDAR SI EL CLIENTE TIENE DEUDAS POR  TARJETAS DE CREDITO
select @w_tc = 'N'

if exists (select 1 from cob_credito..cr_dato_operacion, cobis..cl_producto
 	   where do_tipo_reg = 'D'
	   and do_codigo_producto  = 58
	   and do_numero_operacion > 0
	   and do_codigo_cliente = @i_cliente
	   and do_estado_contable not in (4)
	   and do_codigo_producto = pd_producto )
   select @w_tc = 'S'

begin tran
if @w_operaciones_directas = 'S' or @w_operaciones_directas_uvr = 'S'
 begin
   exec @w_return = sp_extracto_linea_int
   @s_user		         = @s_user,
   @s_date              = @s_date,
   @i_operacion         = 'D', --Directas y Garantias
   @i_cliente           = @i_cliente
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end
end


if @w_operaciones_indirectas = 'S' begin
 
   exec @w_return = sp_extracto_linea_int
   @s_user		         = @s_user,
   @s_date              = @s_date,
   @i_operacion         = 'I', --Indirectas
   @i_cliente           = @i_cliente
   if @w_return != 0 begin
      select @w_error = @w_return
      goto ERROR
   end
 
end
	
---PRINT 'exlinea.sp @s_user %1! @i_cliente %2! ',@s_user,@i_cliente
if @w_cuentas_no_cartera = 'S' 
begin
   
   insert into ca_cxc_no_cartera
   select @s_user, @i_cliente, do_numero_operacion_banco,(do_saldo_cap + do_saldo_int + do_saldo_otros + do_saldo_int_contingente),pd_descripcion
   from cob_credito..cr_dato_operacion, cobis..cl_producto
   where do_tipo_reg = 'D'
   and do_codigo_producto  = 48
   and do_numero_operacion > 0
   and do_codigo_cliente = @i_cliente
   and do_estado_contable not in (4)
   and do_codigo_producto = pd_producto
	   
   
   if @@error != 0 begin
      select @w_error = 710389  ---definir error
      goto ERROR
   end
end

if @w_sobregiros = 'S'
begin
   --INSERTAR LOS VALORES DE DEUDA DE SOBREGIROS

   insert into ca_cxc_no_cartera
   select @s_user, @i_cliente, do_numero_operacion_banco,(do_saldo_cap + do_saldo_int + do_saldo_otros + do_saldo_int_contingente),pd_descripcion
   from cob_credito..cr_dato_operacion, cobis..cl_producto
   where do_codigo_cliente = @i_cliente
   and do_tipo_reg = 'D'
   and do_codigo_producto in (50,51)
   and do_numero_operacion > 0
   and do_estado_contable != (4)
   and do_codigo_producto = pd_producto
end

if @w_tc = 'S'
begin
   --INSERTAR LOS VALORES DE DEUDA DE TARJETAS DE CREDITO
 
   insert into ca_cxc_no_cartera
   select @s_user, @i_cliente, do_numero_operacion_banco,(do_saldo_cap + do_saldo_int + do_saldo_otros + do_saldo_int_contingente),pd_descripcion
   from cob_credito..cr_dato_operacion, cobis..cl_producto
   where do_codigo_cliente = @i_cliente
   and do_tipo_reg = 'D'
   and do_codigo_producto  = 58
   and do_numero_operacion > 0
   and do_estado_contable != (4)
   and do_codigo_producto = pd_producto
end

commit tran

select @w_directas = 'N'
if exists (select 1 from ca_extracto_linea_tmp 
   	   where exl_cliente = @i_cliente
           and   exl_user    = @s_user
           and   exl_tipo_deuda = 'DIRECTA')
  select @w_directas = 'S',
         @w_garantias = 'S'


select @w_directasuvr = 'N'
if exists (select 1 from ca_extracto_linea_tmp 
   	   where exl_cliente = @i_cliente
           and   exl_user    = @s_user
           and   exl_tipo_deuda = 'DIRECTAUVR')
   select @w_directasuvr = 'S'


select @w_indirectas = 'N'
if exists (select 1 from ca_extracto_linea_tmp
           where exl_cliente = @i_cliente
           and   exl_user    = @s_user
           and   exl_tipo_deuda = 'INDIRECTA')
   select @w_indirectas = 'S'



select @w_cxc = 'N'
if exists (select 1 from ca_cxc_no_cartera
           where cc_cliente = @i_cliente
           and   cc_user    = @s_user)
   select @w_cxc = 'S'



select @w_directas,
       @w_directasuvr,
       @w_indirectas,
       @w_garantias,
       @w_cxc,
       @w_sobregiros,
       @w_tc

return 0

ERROR:

exec cobis..sp_cerror
@t_debug  ='N',   
@t_file   = null,
@t_from   =@w_sp_name,  
@i_num    = @w_error
--@i_cuenta = ' '

return @w_error

go



