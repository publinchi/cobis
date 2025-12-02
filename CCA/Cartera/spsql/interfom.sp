/************************************************************************/
/*      Archivo:                interfom.sp                             */
/*      Stored procedure:       sp_interfaz_otros_modulos               */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Juan Sarzosa                            */
/*      Fecha de escritura:     Enero 2001                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Inserta en la tabla cob_compensacion.co_consolidacion todas las */
/*      transacciones de pagos generadas por los clientes. (SIPLA)      */ 
/*	     Opciones:                                                      */
/*	 	  @i_interfaz:                                                  */
/*			    'S' (SIPLA)                                             */
/*      @i_modo                                                         */
/*            I: Insert                                                 */
/*            D: Delete                                                 */
/************************************************************************/
/*         FECHA           AUTOR                    CAMBIO              */
/*      julio-18-2001      Elcira Pelaez            Quitar control de   */
/*                                             oficial por @s_user      */
/*      Marzo-16-2006      Elcira Pelaez       Colocar moneda de pago   */
/*                                             defecto 6145             */
/************************************************************************/  
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_interfaz_otros_modulos')
	drop proc sp_interfaz_otros_modulos
go

create proc sp_interfaz_otros_modulos
@s_user         login,
@i_cliente	int         = null,
@i_modulo	char(3)     = null,
@i_interfaz	char(1)     = null,
@i_modo		char(1)     = null,
@i_obligacion	cuenta   = null,
@i_moneda	smallint    = null,
@i_sec_trn	int         = null,
@i_fecha_trn	datetime = null,
@i_desc_trn	varchar(64) = null,
@i_monto_trn	money    = null,
@i_cotizacion   money    = null,
@i_monto_des    money    = null,
@i_forma_pago  catalogo  = null,
@i_oficina      smallint = null,
@i_gerente      login    = null,
@i_afec_trn     char(1)  = null,
@i_tipo_trn     char(3)  = 'N',
@i_categoria    catalogo = null,
@i_en_linea     char(1)  = 'N',
@i_moneda_uvr   smallint = 2,
@i_forma_desm   catalogo = null

as
declare
@w_forma                char(10),
@w_sp_name              descripcion,	
@w_co_ingreso_mn        money,
@w_co_ingreso_me        money,
@w_co_ingreso_do        money,
@w_cot_usd              money,  
@w_error 	            int,
@w_trn                  char(1),
@w_monto_trn            money,
@w_funcionario          smallint,     
@w_oficial              smallint,
@w_cedula               varchar(20),
@w_tipo_ced             catalogo,
@w_nombre               descripcion,
@w_mon_nacional         smallint,
@w_cotizacion		      money,
@w_num_dec		         tinyint,
@w_num_dec_mn           tinyint,
@w_naturaleza           char(1),
@w_msg                  varchar(134),
@w_oficina_op           smallint,
@w_categoria            catalogo

return 0

-- CARGADO DE LOS PARAMETROS DE CARTERA 
select 
@w_sp_name = 'sp_interfaz_otros_modulos',
@w_oficial = 1

select @w_naturaleza = op_naturaleza,
       @w_oficina_op = op_oficina  
from ca_operacion
where op_banco = @i_obligacion


--EL REPORTE DEBE SER SOLO DE LAS ACTIVAS O SE ESTARIA ENVIANDO DOBLE REGSITRO
if @w_naturaleza = 'P'
  return 0

select @w_categoria = cp_categoria
from ca_producto
where cp_producto = @i_forma_pago

--LA CATEGORIA OTRO ESTA PARAMETRIZADA PARA PAGOS DE RECONOCIMIENTOS UNICAMENTE
if @w_categoria = 'OTRO'
  return 0

select @w_oficial = fu_funcionario
from  cobis..cl_funcionario
where fu_login = @s_user
set transaction isolation level read uncommitted

select @w_oficial = isnull(@w_oficial, 1) 

exec sp_decimales
@i_moneda       = @i_moneda,
@o_decimales    = @w_num_dec		out,
@o_mon_nacional = @w_mon_nacional	out,
@o_dec_nacional = @w_num_dec_mn		out


if @i_interfaz = 'S' 
begin
   if @i_modo = 'I' 
   begin
      
      select 
         @w_co_ingreso_mn = 0,
         @w_co_ingreso_me = 0,	
         @w_co_ingreso_do = 0	
      
      begin tran
         --INFORMACION CLIENTE 
         select @w_cedula  = en_ced_ruc,
                @w_tipo_ced = en_tipo_ced,
                @w_nombre   = en_nombre + ' ' + p_p_apellido  + ' ' +  p_s_apellido
         from  cobis..cl_ente
         where en_ente = @i_cliente
         set transaction isolation level read uncommitted

         --VALIDACION DE VALORES EN MONEDA EXTRANJERA
         if @i_moneda <> @w_mon_nacional  and @i_moneda <> @i_moneda_uvr
         begin  --Moneda Extranjera
            exec sp_buscar_cotizacion
                 @i_moneda     = @i_moneda,
                 @i_fecha      = @i_fecha_trn,
                 @o_cotizacion = @w_cotizacion output

            if @w_cotizacion is null
               select @w_cotizacion = 1

            select 
            @w_co_ingreso_mn = round(@i_monto_trn * @w_cotizacion,@w_num_dec_mn),
            @w_co_ingreso_me = round(@i_monto_trn, @w_num_dec)
            
            --MANEJO VALORES EN DOLARES
	         if @i_moneda =  1 
	         begin -- Moneda Extranjera
               -- COTIZACION DOLARES 
               exec sp_buscar_cotizacion
                    @i_moneda     = 1,
                    @i_fecha      = @i_fecha_trn,
                    @o_cotizacion = @w_cot_usd output

               if @w_cot_usd is null
                  select @w_cot_usd = 0

               if @w_cot_usd != 0
                  select @w_co_ingreso_do = round((@i_monto_trn * (@w_cotizacion/@w_cot_usd)),@w_num_dec)
               else
                  select @w_co_ingreso_do = 0
               
            end


      	    if @i_moneda = 1 -- Dolares
               select @w_co_ingreso_do = round(@i_monto_trn,@w_num_dec)
         end

         if @i_moneda = @w_mon_nacional 
            select @w_co_ingreso_mn = round(@i_monto_trn, @w_num_dec_mn)


         if  @i_moneda = @i_moneda_uvr
             select @w_co_ingreso_mn = round(@i_monto_des, @w_num_dec_mn)
         
         /* para BANCAMIA SE ELIMINARA LA BASE DE DATOS Y LA TABLA
         -- INSERTAR LA INFORMACION
         insert into cob_compensacion..co_consolidacion 
         (co_codigo,     	co_tipo_ced,	co_ced_ruc,	co_nombre,
          co_sec_prod,   	co_fecha_tra,
          co_tipo_tra,   	co_forma,     	co_forma_hom,
          co_producto,   	co_cuenta,    	co_moneda,
          co_ingreso_mn, 	co_egreso_mn, 	co_ingreso_me,
          co_egreso_me,  	co_ingreso_do,	co_egreso_do, 
          co_cotizacion,	co_oficina,     co_oficina_destino)
          values  
         (@i_cliente,    	@w_tipo_ced, 	  @w_cedula,	@w_nombre,
          @i_sec_trn,    	@i_fecha_trn,
          @i_desc_trn,   	@i_forma_pago, 	isnull(@i_categoria,@i_forma_pago),
          @i_modulo,     	@i_obligacion, 	@w_mon_nacional,
          isnull(@w_co_ingreso_mn,0),        0.00,          	@w_co_ingreso_me,
          0.00,          	@w_co_ingreso_do, 0.00,
          @i_cotizacion,	@i_oficina,      @w_oficina_op)

          if @@error != 0 begin
             rollback tran
             select @w_error = 710153
             goto ERROR
          end     

          */
      commit tran
      return 0
   end  --modo I


   if @i_modo = 'D' 
   begin 
      begin tran
         delete cob_compensacion..co_consolidacion 
         where co_sec_prod >= @i_sec_trn
          and co_cuenta = @i_obligacion
          if @@error != 0 
          begin
             rollback tran
            select @w_error = 710154
            goto ERROR
         end           
      commit tran   
      return 0
   end


end  --@i_interfaz = 'S' 

return 0

ERROR:

if @i_en_linea = 'S'
begin
   exec cobis..sp_cerror 
        @t_debug = 'N',
        @t_file  = null,
        @t_from  = @w_sp_name,
        @i_num   = @w_error,
        @i_msg   = @w_msg
   return @w_error
end
ELSE
  return 0


go 
