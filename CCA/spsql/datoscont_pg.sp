/************************************************************************/
/*   Archivo:              datoscont_pg.sp                              */
/*   Stored procedure:     sp_datos_contables_pg                        */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Credito y Cartera                            */
/*   Disenado por:         WGCC                                         */
/*   Fecha de escritura:   Oct 2007                                     */
/************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Cumplimiento del requerimiento SNR7MAACCA808                       */ 
/*   Leer informacion de las tablas cob_conta_tercero..ct_scomprobante  */
/*   y cob_conta_tercero..ct_sasiento para llenar la estructura         */ 
/*   para generar el archivo de interfaz de movimiento mensual de PyG   */
/*   por concepto de intereses                                          */
/*                                                                      */
/************************************************************************/
/*                             MODIFICACIONES                           */
/*   FECHA              AUTOR           RAZON                           */
/*                                                                      */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_datos_contables_pg')
   drop proc sp_datos_contables_pg
go

create proc sp_datos_contables_pg (
   @s_user          login       = null,
   @s_term          varchar(64) = null,-- IFJ 14-Nov-2006 NREQ 671
   @s_ofi           smallint    = null,-- IFJ 14-Nov-2006 NREQ 671
   @i_debug         char(1)     = 'N',
   @i_fecha_ini     datetime    = null,
   @i_fecha_fin     datetime    = null,
   @i_fecha_corte   datetime    = null				
)
as

declare
   @w_error                    int,
   @w_sp_name                  descripcion,
   -- VARIABLES REQ808         
   @w_fecha_fin_mes            datetime,   	
   @w_dias                     int,
   @w_fecha                    datetime,
   @w_fechap                   datetime,
   @w_contador                 int, 
   @w_cuenta                   descripcion,
   @w_fecha_cierre             datetime,
   @w_descripcion01            descripcion

select       
   @w_sp_name = 'sp_datos_contables_pg',   
   @w_error = 0,
   @w_fecha = getdate()
   
declare
   cursor_cuenta cursor --(cursor:1)
   for select valor
       from cob_cartera..ca_cuentas_revisoria_tmp
       for  read only


   
if @i_fecha_corte is null     
begin 
   select @w_fecha_cierre = fc_fecha_cierre  
   from   cobis..ba_fecha_cierre
   where  fc_producto = 7  
end
else
begin
   select @w_fecha_fin_mes = dateadd(dd, -1, dateadd(mm, 1, dateadd(dd, 1, dateadd(dd, -datepart(dd, @i_fecha_corte), @i_fecha_corte))))   	
   select @w_fecha_cierre = @w_fecha_fin_mes 
end 




   
open  cursor_cuenta --(cursor:2)


fetch cursor_cuenta --(cursor:3)
into  @w_cuenta

--while (@@fetch_status not in (-1,0)) --(cursor:4)
while (@@fetch_status = 0) --(cursor:4)
begin 
   --inicio while cursor_cuenta
   --Significado de @@sqlstatus		
   --0 	Indica que la instrucción fetch se ha completado correctamente. 
   --1 	Indica que la instrucción fetch ha dado como resultado un error. 
   --2 	Indica que no hay más datos en el conjunto de resultados. 
   --    Esta advertencia puede aparecer si la posición actual del cursor es la última fila del 
   --    conjunto de resultados y el cliente envía una instrucción fetch a ese cursor. 

   select  
   @w_contador = 0,                                       
   @w_fechap   = @i_fecha_ini,
   @w_dias     = datediff(dd,@i_fecha_ini,@i_fecha_fin)
   if @i_debug = 'S' print '---------------------------------------------------------------'
   if @i_debug = 'S' print 'procesando cuenta' + @w_cuenta	  
   if @i_debug = 'S' print '---------------------------------------------------------------'
   while @w_contador <= @w_dias       
   begin
      
         
         if @i_debug = 'S' print 'procesando dia' + cast(@w_fechap as varchar)
                                                       		     
         insert into cob_cartera..ca_interfaz_mm_pygint
            (
            inmp_fecha_corte,                        inmp_fecha_ultimo_vto,                         inmp_obligacion,
            inmp_producto,                           inmp_clase_cartera,                            inmp_cliente,
            inmp_identificacion,                     inmp_nombre_cliente,                           inmp_oficina,
            inmp_estado_act,                         inmp_cuenta_auxiliar,                          inmp_perfil,
            inmp_ind_movimiento,                     inmp_valor_debito,                             inmp_valor_credito
            )
         select  
            convert(char(10),@w_fecha_cierre,101),   convert(char(10),cao.op_fecha_ult_proceso,101),cao.op_banco,
            7,                                  	 cao.op_clase,                                  cao.op_cliente,	      										  								
            cliente.en_ced_ruc,                      cao.op_nombre,                                 sc_oficina_orig,			
            cao.op_estado,                           sa_cuenta,                                     sc_perfil, 
            substring(sa_concepto,1,5),              sa_debito,                                     sa_credito
         from   cob_conta_tercero..ct_scomprobante,cob_conta_tercero..ct_sasiento,
                cob_cartera..ca_operacion cao, cobis..cl_ente cliente 
         where  sc_fecha_tran  = @w_fechap
         and    sc_producto    = 7
         and    sc_comprobante > 0 
         and    sc_empresa     = 1
         and    sa_fecha_tran  = sc_fecha_tran
         and    sa_producto    = sc_producto
         and    sa_comprobante = sc_comprobante
         and    sa_empresa     = sc_empresa
         and    sa_cuenta      = @w_cuenta
         and    sc_digitador   <> 'resumen' --Para que no salgan ya las resumidas
         and    charindex(':',sc_tran_modulo) > 0
         and    cao.op_operacion = convert(int,substring(sc_tran_modulo,1,charindex(':',sc_tran_modulo)-1)) 
         and    cao.op_cliente = cliente.en_ente 
         
         if @@error != 0 
         begin 

	    select @w_descripcion01 = 'ERROR INSERTANDO INFORMACION DE LA CUENTA'+@w_cuenta +' PARA FECHA: '+convert(char(10),@w_fechap,101)	

            exec sp_errorlog 
               @i_fecha      = @w_fecha,                    
               @i_error      = 724503, 
               @i_usuario    = 'USR_BATCH', 
               @i_tran       = 7245,
               @i_tran_name  = @w_sp_name,
               --@i_cuenta     = @w_banco,
               @i_descripcion = @w_descripcion01,
               @i_rollback    = 'N'
         end 
         
         select @w_fechap = dateadd(dd,1,@w_fechap)
    	 select @w_contador = @w_contador + 1 
      
   end

   SIGUIENTE: 
   
   fetch cursor_cuenta --(cursor:5)
   into  @w_cuenta
      
end 

close cursor_cuenta  --(cursor:6)
deallocate cursor_cuenta  --(cursor:6)


--Insertar registro de control en la tabla ( Total registros, sumatoria debitos, sumatoria creditos)
insert into cob_cartera..ca_interfaz_mm_pygint
      (
      inmp_oficina,   inmp_valor_debito,           inmp_valor_credito
      )
select 
      count(0),       sum(inmp_valor_debito),      sum(inmp_valor_credito)
from  cob_cartera..ca_interfaz_mm_pygint 

return 0
go
