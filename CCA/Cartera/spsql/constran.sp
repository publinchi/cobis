/************************************************************************/
/*   NOMBRE LOGICO:      constran.sp                                    */
/*   NOMBRE FISICO:      sp_consultar_transacciones                     */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Francisco Yacelga                              */
/*   FECHA DE ESCRITURA: 25/Nov/97                                      */
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
/*                             PROPOSITO                                */
/*   Consulta de transacciones en base a uno o varios criterios de      */
/*   búsqueda.                                                          */
/************************************************************************/ 
/*                             CAMBIOS                                  */
/* 04/10/2010         Yecid Martinez   Fecha valor baja Intensidad      */
/*                                     NYMR 7x24                        */
/*  26/Nov/2020   Patricio Narvaez Conta. provisiones en moneda nacional*/
/*  09/Mar/2023   Kevin Rodríguez  Ajustes masivos consultas OP 'S'     */
/*  12/Oct/2023   Kevin Rodríguez  B919231 Ajuste tipo dato @i_usuario  */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_consultar_transacciones')
   drop proc sp_consultar_transacciones
go

create proc sp_consultar_transacciones 
   @s_sesn              int,
   @s_user              login,
   @s_ssn               int         = null,
   @s_date              datetime    = NULL,
   @s_term              descripcion = NULL,
   @s_corr              char(1)     = NULL,
   @s_ofi               smallint    = NULL,
   @t_debug             char(1)     = 'N',
   @t_file              varchar(14) = NULL,
   @t_trn               int         = NULL,  
   @i_operacion         char(1)     = NULL,
   @i_modo              smallint    = 0,
   @i_formato_fecha     int         = 103,
   
   -- Criterios de búsqueda principales
   @i_fecha             datetime    = NULL,
   @i_banco             cuenta      = NULL,
   @i_grupo		        int	        = NULL,
   -- Criterios de búsqueda opcionales
   @i_usuario           varchar(14) = NULL, 
   @i_toperacion        catalogo    = NULL,
   @i_moneda            tinyint     = NULL,
   @i_monto             money       = NULL,
   @i_oficina           smallint    = NULL,
   @i_estado            varchar(10) = NULL, 
   @i_tipo              varchar(10) = NULL,

   @i_siguiente         int         = null, -- número de operación desde la cual se obtendrá los registros
   @i_siguiente_banco   cuenta      = null, -- número largo de operacion desde la cual se obtendrá los registros
   @i_siguiente_tran    int         = 0     -- número de transacción

   
as
declare @w_sp_name           varchar(32),
        @w_return            int,
        @w_error             int,
        @w_operacionca       int,
        @w_det_producto      int,
        @w_tipo              char(1),
        @w_tramite           int,
        @w_opcion            int,
        @w_numero            int,
        @w_contador          int,
        @w_clase_nor         catalogo   

-- INICIALIZACION DE VARIABLES
select @w_sp_name  = 'sp_consultar_transacciones',
       @w_opcion   = 1  ,
       @w_contador = 1


if @i_operacion = 'S' -- Search
begin

   -- Tablas temporales
   select tr_operacion,    tr_fecha_mov, tr_ofi_usu,    tr_ofi_oper,       tr_tran,        tr_toperacion, 
          0 as 'tr_grupo', tr_moneda,    tr_banco,      tr_estado,         tr_usuario,     tr_terminal,   
		  tr_fecha_ref,    tr_en_linea,  tr_secuencial, tr_secuencial_ref, tr_comprobante, tr_fecha_cont, 
		  tr_fecha_real	  
   into #ca_transaccion
   from ca_transaccion
   where 1=2

   select * into #ca_trn2
   from #ca_transaccion
   where 1=2
   
   if @i_modo = 0
   begin
      
	  delete ca_qr_transacciones_tmp
	  where trt_user = @s_user
      and   trt_sesn = @s_sesn
	  
	  if @@error != 0 
      begin
         select @w_error = 725275 -- Error al eliminar la tabla ca_qr_transacciones_tmp 
         goto ERROR
      end
	  
	  insert into ca_qr_transacciones_tmp
      select @s_user,                @s_sesn,       tr_operacion,      tr_fecha_mov,   tr_ofi_usu,    
	         tr_ofi_oper,            tr_tran,       tr_toperacion,     op_grupo,       tr_moneda,     
			 ltrim(rtrim(tr_banco)), tr_estado,     tr_usuario,        tr_terminal,    tr_fecha_ref,  
			 tr_en_linea,            tr_secuencial, tr_secuencial_ref, tr_comprobante, tr_fecha_cont, 
			 tr_fecha_real
      from ca_transaccion with (nolock), ca_operacion with (nolock)
      where tr_operacion = op_operacion
	  and (tr_fecha_mov  = @i_fecha or @i_fecha is null)
      and (tr_banco      = @i_banco or @i_banco is null)
	  and (op_grupo      = @i_grupo or @i_grupo is null)
	  and (tr_usuario    = @i_usuario or @i_usuario is null)
	  and (tr_toperacion = @i_toperacion or @i_toperacion is null)
	  and (tr_moneda     = @i_moneda or @i_moneda is null)
	  and (tr_ofi_usu    = @i_oficina or @i_oficina is null)
      and (tr_estado     = @i_estado or @i_estado is null)
      and (tr_tran       = @i_tipo or @i_tipo is null)
      order by tr_operacion,tr_secuencial
	  
	  if @i_monto is not null
	  begin
	     
         insert into #ca_trn2
         select distinct 
		 trt_operacion,      trt_fecha_mov,   trt_ofi_usu,    trt_ofi_oper,  trt_tran,          
		 trt_toperacion,     trt_grupo,       trt_moneda,     trt_banco,     trt_estado,      
		 trt_usuario,        trt_terminal,    trt_fecha_ref,  trt_en_linea,  trt_secuencial,    
		 trt_secuencial_ref, trt_comprobante, trt_fecha_cont, trt_fecha_real     
         from ca_qr_transacciones_tmp, ca_det_trn
         where trt_user     = @s_user
		 and trt_sesn       = @s_sesn
		 and trt_operacion  = dtr_operacion
         and trt_secuencial = dtr_secuencial
         and dtr_monto      = @i_monto
	     
         delete ca_qr_transacciones_tmp
         where trt_user = @s_user
         and   trt_sesn = @s_sesn
		 
         if @@error != 0 
         begin
            select @w_error = 725275 -- Error al eliminar la tabla ca_qr_transacciones_tmp 
            goto ERROR
         end
	     
         insert into ca_qr_transacciones_tmp
         select @s_user,       @s_sesn,       tr_operacion,      tr_fecha_mov,   tr_ofi_usu,    
		        tr_ofi_oper,   tr_tran,       tr_toperacion,     tr_grupo,       tr_moneda,     
				tr_banco,      tr_estado,     tr_usuario,        tr_terminal,    tr_fecha_ref,  
				tr_en_linea,   tr_secuencial, tr_secuencial_ref, tr_comprobante, tr_fecha_cont, 
				tr_fecha_real 
		 from #ca_trn2
	  
	  end  

      set rowcount 20
	  insert into #ca_transaccion
	  select trt_operacion,      trt_fecha_mov,   trt_ofi_usu,    trt_ofi_oper,  trt_tran,          
		     trt_toperacion,     trt_grupo,       trt_moneda,     trt_banco,     trt_estado,        
		     trt_usuario,        trt_terminal,    trt_fecha_ref,  trt_en_linea,  trt_secuencial,    
		     trt_secuencial_ref, trt_comprobante, trt_fecha_cont, trt_fecha_real  
	  from ca_qr_transacciones_tmp
      where trt_user = @s_user
      and trt_sesn   = @s_sesn
	  order by trt_operacion, trt_secuencial

   end
   
   if @i_modo = 1
   begin 
   
      if @i_siguiente is null
      begin
         select @i_siguiente = op_operacion
         from ca_operacion
         where op_banco = @i_siguiente_banco 
	     
	     if @@rowcount = 0
	     begin
	        select @w_error = 701013 -- No existe operación activa de cartera
            goto ERROR
         end
      end

	  set rowcount 20
	  insert into #ca_transaccion
	  select trt_operacion,      trt_fecha_mov,   trt_ofi_usu,    trt_ofi_oper,  trt_tran,          
		     trt_toperacion,     trt_grupo,       trt_moneda,     trt_banco,     trt_estado,        
		     trt_usuario,        trt_terminal,    trt_fecha_ref,  trt_en_linea,  trt_secuencial,    
		     trt_secuencial_ref, trt_comprobante, trt_fecha_cont, trt_fecha_real  
	  from ca_qr_transacciones_tmp
      where trt_user = @s_user
      and trt_sesn   = @s_sesn
      and (trt_operacion > @i_siguiente or 
	       (trt_operacion = @i_siguiente and trt_secuencial > @i_siguiente_tran)) 
      order by trt_operacion asc, trt_secuencial asc
	  
   end
   
   select 'Fecha'         = substring(convert(varchar,tr_fecha_mov, @i_formato_fecha),1,15), 
          'Ofi_usu'       = tr_ofi_usu,    
		  'Ofi_oper'      = tr_ofi_oper,       
		  'Tipo'          = tr_tran,        
		  'Tipo_oper'     = tr_toperacion, 
          'Grupo'         = tr_grupo, 
		  'Moneda'        = tr_moneda,    
		  'Num_oper'      = tr_banco,      
		  'Estado'        = tr_estado,         
		  'Usuario'       = tr_usuario,     
		  'Terminal'      = tr_terminal,   
		  'Fecha_ref'     = substring(convert(varchar,tr_fecha_ref, @i_formato_fecha),1,15),    
		  'En_linea'      = tr_en_linea,  
		  'Secuencial'    = tr_secuencial, 
		  'Secuencial_ref'= tr_secuencial_ref, 
		  'Comprobante'   = tr_comprobante, 
		  'Fecha_cont'    = substring(convert(varchar,tr_fecha_cont, @i_formato_fecha),1,15), 
		  'Fecha_real'    = FORMAT(tr_fecha_real,'dd/MM/yyyy HH:mm:ss')
   from #ca_transaccion
   order by tr_operacion, tr_secuencial
   
   if @@rowcount = 0 begin
     -- No existe informacion para los criterios consultados / No existen  mas datos para esta consulta
     select @w_error = case when @i_modo = 0 then 725277 else 710244 end
     goto ERROR
   end  
   
   set rowcount 0
   
end


if @i_operacion = 'S' and @i_modo = 0
begin

   select 'Concepto' = dtr_concepto, 
          'Estado'   = dtr_estado, 
		  'Periodo'  = dtr_periodo, 
		  'Moneda'   = dtr_moneda, 
		  'Monto'    = sum(dtr_monto), 
		  'Monto_mn' = sum(dtr_monto_mn) 
   from ca_qr_transacciones_tmp, ca_det_trn with (nolock)
   where trt_user     = @s_user
   and trt_sesn       = @s_sesn
   and trt_operacion  = dtr_operacion
   and trt_secuencial = dtr_secuencial
   group by dtr_concepto, dtr_estado, dtr_periodo, dtr_moneda --, dtr_monto, dtr_monto_mn
   
   if @@rowcount = 0 begin
     select @w_error = 725276 -- Error al generar totales de las transacciones en base a la tabla ca_qr_transacciones_tmp
     goto ERROR
   end  
  
end

return 0

ERROR:

set rowcount 0

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
