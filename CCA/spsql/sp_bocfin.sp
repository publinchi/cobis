use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_bocfin')
   drop proc sp_bocfin
go

create procedure sp_bocfin
/************************************************************************/
/*   Archivo:              bocfin.sp                                    */
/*   Stored procedure:     sp_bocfin                                    */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Sandro Vallejo                               */
/*   Fecha de escritura:   Sep 2020                                     */
/************************************************************************/
/*                              IMPORTANTE                              */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                               PROPOSITO                              */
/*   Balance Operativo Contable Fin de Cartera                          */
/************************************************************************/
/************************************************************************/
(
    @i_debug         char(1) = 'N',
    @i_fecha         datetime, 
    @i_hilo          tinyint         -- numero de hilos a generar o hilo que debe procesar
)
as

declare
@w_producto           int,
@w_sp_name            varchar(20),
@w_moneda_nacional    int,
@w_area_cartera       smallint,
@w_error              int,
@w_co_estado          char(1),
@w_detener_proceso    char(1),
@w_agrupado           varchar(64),
@w_commit             char(1),
@w_mensaje            varchar(100),
@w_cuenta_final       varchar(40),
@w_val_opera_mn       money,
@w_val_opera_me       money,
@w_oficina_conta      smallint,
@w_moneda_cta         int,
@w_cotizacion         float

-- INICIO DE VARIABLES DE TRABAJO 
select
@w_sp_name         = 'sp_bocfin',
@w_producto        = 7,
@w_commit          = 'N',
@w_detener_proceso = 'N'

-- CODIGO DE LA MONEDA LOCAL
select @w_moneda_nacional = pa_tinyint
from   cobis..cl_parametro with (nolock)
where  pa_producto = 'ADM'
and    pa_nemonico = 'MLO'

-- AREA DE CARTERA
select @w_area_cartera = pa_smallint
from   cobis..cl_parametro
where  pa_producto = 'CCA'
and    pa_nemonico = 'ARC'

-- ESTADO DEL PERIODO CONTABLE
select @w_co_estado = co_estado
from   cob_conta..cb_corte
where  co_empresa   = 1
and    co_fecha_ini = @i_fecha

if @w_co_estado <> 'A' --Sólo si el corte está Abierto se llena el BOC
begin
   select 
   @w_mensaje = 'ERROR AL VALIDAR PERIODO CONTABLE PARA BOCFIN',
   @w_error   = 607140
   goto ERRORFIN
end

-- LAZO DE TRANSACCIONES A CONTABILIZAR 
while @w_detener_proceso = 'N' 
begin 

   select @w_error = 0

   -- OPERACION A PROCESAR
   set rowcount 1 
 
   select @w_agrupado = agrupado
   from   ca_universo_bocfin
   where  hilo     = @i_hilo 
   and    intentos < 2 
   order by id 

   if @@rowcount = 0 
   begin 
      set rowcount 0 
      select @w_detener_proceso = 'S' 
      break 
   end 
 
   if @i_debug = 'S' print 'Oficina-cuenta ' + @w_agrupado 
   
   set rowcount 0 
 
   -- ATOMICIDAD 
   BEGIN TRAN
      
   update ca_universo_bocfin set 
   intentos = intentos + 1, 
   hilo     = 100 -- significa Procesado o procesando 
   where  agrupado = @w_agrupado  
   and    hilo     = @i_hilo 
      
   COMMIT TRAN
   
   -- INICIALIZAR TRANSACCIONALIDAD
   BEGIN TRAN 
   select @w_commit = 'S'

   -- OBTENER LOS DATOS DE LA OFICINA_CUENTA
   select @w_oficina_conta = bt_ofi_oper, 
          @w_cuenta_final  = bt_cuenta, 
          @w_val_opera_mn  = bt_monto,
          @w_moneda_cta    = cu_moneda
   from   ca_bocfin_tmp, cob_conta..cb_cuenta 
   where  bt_agrupado = @w_agrupado
   and    cu_empresa  = 1
   and    bt_cuenta   = cu_cuenta 

   -- SI LA MONEDA DE LA OPERACION ES DIFERENTE A LA MONEDA NACIONAL
   if @w_moneda_cta <> @w_moneda_nacional
   begin
      -- BUSCAR COTIZACION
      exec @w_error = sp_buscar_cotizacion
           @i_moneda     = @w_moneda_cta,
           @i_fecha      = @i_fecha,
           @o_cotizacion = @w_cotizacion output
         
      if @w_error <> 0 
      begin      
         select @w_mensaje = 'Error en Busqueda Cotizacion BOCFIN:(sp_buscar_cotizacion)' +
                          ' moneda: ' + convert(varchar, @w_moneda_cta),
                @w_error = 701070
         goto ERROR1                    
      end
      
      -- OBTENER EL VALOR EN MONEDA NACIONAL
      select @w_val_opera_me = @w_val_opera_mn
      select @w_val_opera_mn = round((@w_val_opera_me * @w_cotizacion), 2)
   end
   else
      select @w_val_opera_me = 0
   
   --REGISTRA DATOS DEL BOC
   exec @w_error = cob_conta..sp_ing_opera
        @t_trn            = 6063,
        @i_operacion      = 'I',
        @i_empresa        = 1,
        @i_producto       = @w_producto,
        @i_fecha          = @i_fecha, 
        @i_cuenta         = @w_cuenta_final,
        @i_oficina        = @w_oficina_conta,
        @i_area           = @w_area_cartera,
        @i_moneda         = @w_moneda_nacional,
        @i_val_opera_mn   = @w_val_opera_mn,
        @i_val_opera_me   = @w_val_opera_me, 
        @i_batch          = 'S'
   
   if @w_error = 0
      goto SIGUIENTE 
   else       
   begin
      select @w_mensaje = 'Error al ingresar registro del BOCFIN:(sp_ing_opera)' +
                          ' oficina: ' + convert(varchar(5), @w_oficina_conta) + 
                          ' cuenta: ' + @w_cuenta_final +
                          ' valor: ' + convert(varchar(30), @w_val_opera_mn),
      @w_error = 710001
      goto ERROR1                    
   end  
      
   ERROR1:
      
   if @w_commit = 'S' 
   begin
      rollback tran
      select @w_commit = 'N'
   end      

   if @i_debug = 'S' print '            ERROR1 --> ' + @w_mensaje

   exec sp_errorlog
   @i_fecha       = @i_fecha, 
   @i_error       = 7300, 
   @i_usuario     = 'OPERADOR',
   @i_tran        = 7000, 
   @i_tran_name   = @w_sp_name, 
   @i_rollback    = 'N',
   @i_cuenta      = @w_agrupado, 
   @i_descripcion = @w_mensaje

   SIGUIENTE:

   if @w_commit = 'S' 
   begin 
      commit tran
      select @w_commit = 'N'
   end  
end  --while @w_detener_proceso = 'N' 

return 0

ERRORFIN:

exec cob_cartera..sp_errorlog
@i_fecha       = @i_fecha, 
@i_error       = 7300,
@i_usuario     = 'OPERADOR',
@i_tran        = 7000,
@i_tran_name   = @w_sp_name,
@i_rollback    = 'N',
@i_cuenta      = 'BOCFIN',
@i_descripcion = @w_mensaje

return @w_error
go
  
