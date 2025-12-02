/************************************************************************/
/*      Archivo:                sp_llenauniverso.sp                     */
/*      Stored procedure:       sp_llenauniverso                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Sandro Vallejo                          */
/*      Fecha de escritura:     Nov. 2017                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes exclusivos para el Ecuador de la       */
/*      'NCR CORPORATION'.                                              */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                              PROPOSITO                               */
/*      Llena la tabla de operaciones a procesar batch en paralelo.     */
/*      @i_pago = 'S', solamente se consideran operaciones que tienen   */
/*      pagos automáticos resagados o que van a tratar de debitar en    */
/*      el rango de fechas de ejecuci=n.                                */
/*      @i_pago = 'N', Se consideran todas las operaciones que          */
/*      procesan                                                        */
/************************************************************************/
/*                              MODIFICACIONES                          */
/************************************************************************/

use cob_cartera
go

------------------------------------
--    Tablas para paralelismo     --
------------------------------------
--LPO CDIG Se comenta creacion de ca_universo, degrada el batch INICIO
--/* 
if exists (select 1 from sysobjects where name = 'ca_universo')
   drop table ca_universo
go

create table ca_universo
(
id             int IDENTITY NOT NULL,  
operacion      int,
banco          cuenta,
intentos       tinyint NOT NULL,
hilo           tinyint
)
--lock datarows
go

CREATE CLUSTERED INDEX ca_universo_1 ON ca_universo (id)
   
CREATE INDEX ca_universo_2 ON ca_universo (operacion)

CREATE INDEX ca_universo_3 ON ca_universo (hilo,intentos)
go
--*/
--LPO CDIG Se comenta creacion de ca_universo, degrada el batch FIN


/* INICIO SP */
if exists (select 1 from sysobjects where name = 'sp_llenauniverso')
   drop proc sp_llenauniverso
go

create procedure sp_llenauniverso (
        @i_fecha             datetime, 
        @i_pago              char(1)  = 'N',
        @i_sarta             int      = null,
        @i_batch             int      = null,
        @i_tipo_batch        char(1)  = NULL  --LPO CDIG Nuevo Esquema Paralelismo
        )
as
declare @w_sp_name           descripcion,

@w_return          int,
@w_oficina_central int,
@w_rowcount        int,
@w_cont            int,
@w_marcados        int,
@w_ctrl_fin        char(1),
@w_sig_dia_habil   datetime,                         -- FCP Interfaz Ahorros
@w_est_cancelado   tinyint,                          -- FCP Interfaz Ahorros
@w_est_vencido     tinyint,                          -- FCP Interfaz Ahorros
@w_est_vigente     tinyint,                          -- FCP Interfaz Ahorros
@w_ciudad_nacional int,                              -- FCP Interfaz Ahorros
@w_tipo_batch      char(1),                           -- FCP Interfaz Ahorros
@w_fecha_cierre	   datetime,
@w_fin_mes 	   char(1),
@w_ejecutar_fin_mes	char(1),
@w_ult_dia_mes     varchar(2),
@w_ultimo_dia      varchar(10), 
@w_mes             varchar(2), 
@w_ano             varchar(4), 
@w_ultimo_dia_def_habil  DATETIME,
@w_ndah_finan      catalogo



/* INICIALIZACION DE VARIABLES */
select 
@w_sp_name       = 'sp_llenauniverso' 


--TRUNCATE TABLE ca_universo --LPO CDIG Nuevo esquema de Paralelismo


BEGIN TRAN

/* LLENAR TABLA CON LAS OPERACIONES A PROCESAR */
-- poblar ca_universo con todos los prestamos que deben procesar

/*
insert into ca_universo
select op_operacion,
       op_banco,   
       0,   -- empezamos con intentos 0
       0    -- empezamos con hilo 0
from   ca_operacion, ca_estado
where  op_estado             = es_codigo
and    es_procesa            = 'S'
and    op_fecha_ult_proceso <= @i_fecha
*/


if @i_tipo_batch = 'D'
begin 
   select  @w_ejecutar_fin_mes = isnull(pa_char,'N')
   from    cobis..cl_parametro
   where   pa_producto = 'CCA'
   and     pa_nemonico = 'FM7X24'
    --  En el fin de mes ultimo dia habil se ejecuta solo si el paramero general de cartera segun nemonico 'FM7X24' esta en 'S'
   
   select @w_ult_dia_mes  	= datepart(dd,dateadd(dd,datepart(dd,dateadd(mm,1,@w_fecha_cierre ))*(-1),dateadd(mm,1,@w_fecha_cierre )))
   select @w_mes 		= datepart(mm, @w_fecha_cierre)
   select @w_ano 		= datepart(yy, @w_fecha_cierre)
   select @w_ultimo_dia 	= @w_mes + '/' + @w_ult_dia_mes + '/' + @w_ano 
   select @w_ultimo_dia_def_habil  = convert(datetime, @w_ultimo_dia )
   while exists(select 1 from cobis..cl_dias_feriados
                where df_ciudad = @w_ciudad_nacional
                and   df_fecha  = @w_ultimo_dia_def_habil ) begin
      select @w_ultimo_dia_def_habil = dateadd(day,-1,@w_ultimo_dia_def_habil)
   end
   
   if @w_ultimo_dia_def_habil = @w_fecha_cierre and @w_ejecutar_fin_mes  <>  'S'
      return 0
   
      -- operaciones con abono ingresado 
	   
   select  op_operacion
   into    #univ_operaciones_aux  
   from    cob_cartera..ca_operacion with (index = ca_operacion_1), 
           cob_cartera..ca_abono -- with (index = ca_abono_1)
   where  op_operacion    = ab_operacion 
   and    ab_estado	in( 'ING' )
   
   -- operaciones con fecha valor
   
   insert into  #univ_operaciones_aux  
   select  bi_operacion 
   from    cob_cartera..ca_en_fecha_valor      
   
   -- operaciones con traslado de cartera
   
   insert into  #univ_operaciones_aux  
   select  trc_operacion 
   from    cob_cartera..ca_traslados_cartera
            
   if @w_ultimo_dia_def_habil = @w_fecha_cierre and @w_ejecutar_fin_mes  =  'S'
   begin
      -- evita procesar operaciones vencidas o que vencen el dia de proceso cuando es fin de mes.
	  insert into #univ_operaciones_aux
	  select di_operacion 
	  from ca_dividendo
	  where di_fecha_ven = @w_fecha_cierre -- Vencen Hoy
	  and di_estado      = @w_est_vigente
	
	  insert into #univ_operaciones_aux
	  select distinct di_operacion 
	  from ca_dividendo
	  where di_estado = @w_est_vencido     -- Se encentrasn vencidas
   end
   ---LLS000303  insertar las operaciones con nota debito el dia del proceso 
   ---           para eliminarlas despues
      
   insert into #univ_operaciones_aux
   select op_operacion
   from   cob_cartera..ca_operacion with (index = ca_operacion_1),
          cob_cartera..ca_estado,
          cob_cartera..ca_dividendo             
   where  op_estado     = es_codigo
   and    op_forma_pago = @w_ndah_finan --'NDAH_FINAN'
   and    op_operacion   = di_operacion
   and    di_estado    = @w_est_vigente
   and    di_fecha_ven = @w_fecha_cierre -- Vencen Hoy
      
   ---LLS000303 Que se inserten todas las operacion incluyendo las de nota Debito
   ---          ya que enla tabla #univ_operaciones_aux estan la que se desean eliminar
   ---          para queno queden en el universo. Que serian unicamente las que tiene pago el dia
   ---          de l fecha de ejecucion
    
   ---ORS000337 Insertar en esta temporal las operaciones con renovaqcion pendiente
   insert into #univ_operaciones_aux
   select op_operacion
   from cob_credito..cr_tramite with (nolock),
        cob_credito..cr_op_renovar with (nolock),
        cob_cartera..ca_operacion  with (nolock)
   where tr_estado <> 'Z'  ----rechazados
   and op_banco = or_num_operacion
   and or_sec_prn   is null  ---Indica que la renovacion aun no se ha efectuado
   and op_operacion = tr_numero_op 
   and op_estado in (1,2,4,9)
   and tr_tipo in('U','R')
   and tr_tramite = or_tramite
   
   ---ORS 000337
      
   ---INC 60364 Excluir las que se castigaran en esta fecha
   insert into #univ_operaciones_aux
   select op_operacion
   from ca_castigo_masivo with (nolock),
        ca_operacion  with (nolock)
   where op_banco = cm_banco
   and   cm_estado = 'I'
   and   cm_fecha_castigo = @w_fecha_cierre -- FEcha Cartera
   ---INC 60364		
   
   ---LLS 77314
   insert into #univ_operaciones_aux
   select op_operacion
   from  ca_operacion  with (nolock)
   where op_fecha_ini = @w_fecha_cierre -- desembolsadas hoy
   and   op_estado = 1
   ---FIN LLS 77314

   ---SACAR LAS NORMALIZACIONES DEL DIA
   ---POR DESMARCA DE OPERACIONES DEL PROCESO 7321
   insert into #univ_operaciones_aux
   select   op_operacion
   from cob_cartera..ca_operacion with (nolock),
        cob_credito..cr_tramite with (nolock)
   where op_tramite = tr_tramite
   and   tr_tipo = 'M'
   and   op_estado = 1
   and   op_fecha_liq = @w_fecha_cierre
   ---FIN SACAR LAS NORMALIZACIONES DEL DIA
   
   insert into ca_universo  
   select   op_operacion,
            op_banco,
       0,   -- empezamos con intentos 0
       0    -- empezamos con hilo 0

   from     cob_cartera..ca_operacion with (index = ca_operacion_1),
            cob_cartera..ca_estado
   where  op_estado 	     = es_codigo
   and    es_procesa      = 'S'
   
   delete ca_universo
   from   ca_universo,
          #univ_operaciones_aux   
   where  operacion = op_operacion
end

   --  BATCH NORMAL

if  @i_tipo_batch = 'N'       -- FCP Interfaz Ahorros 
begin       
   -- SELECCIONAR UNIVERSO DE LAS OPERACIONES A PROCESAR ()
   select  op_operacion,
           op_banco
   into    #univ_operaciones_aux1  --LPO TEC PAGOS GRUPALES E INTERCICLOS
   from   ca_operacion, ca_estado
   where  op_estado             = es_codigo
   and    es_procesa            = 'S'
   and    op_fecha_ult_proceso <= @i_fecha --@i_siguiente_dia    
   order by op_operacion
      
   --LPO TEC PAGOS GRUPALES E INTERCICLOS
   -- SELECCIONAR LAS OPERACIONES DE INTERCICLOS
   select op_operacion,
          op_banco
   into   #univ_operaciones_interciclo
   from   ca_operacion, ca_det_ciclo
   where  op_operacion       = dc_operacion
   and   (op_grupal          = 'N' or op_grupal is null)
   and    op_ref_grupal is not null
   and    dc_tciclo          = 'I'
   -- ELIMINAR DEL UNIVERSO LAS OPERACIONES DE INTERCICLOS
   delete #univ_operaciones_aux1
   where  op_operacion in (select op_operacion from #univ_operaciones_interciclo)
   
   -- INSERTAR EL UNIVERSO DE LAS OPERACIONES A PROCESAR 
   insert into ca_universo (operacion, banco, intentos, hilo) --LPO CDIG Modificacion por sintaxis MySql
   select op_operacion,
          op_banco,   
          0,   -- empezamos con intentos 0
          0    -- empezamos con hilo 0
   from   #univ_operaciones_aux1
   order by op_operacion
   --LPO TEC FIN PAGOS GRUPALES E INTERCICLOS
end  
   -- INICIO FCP Interfaz Ahorros  -- MANEJO DE OPS CON DEBITO UNICAMENTE


-- BATCH AHORROS

if @i_tipo_batch = 'S'
begin
   -- PAGOS PENDIENTES EN NOTA DEBITO        
      select op_operacion,
             op_banco
      into   #universo_batch 
      from   ca_operacion, ca_estado
      where  op_estado    = es_codigo
      and    es_procesa   = 'S'
      and    op_fecha_ult_proceso <= @i_fecha --@i_siguiente_dia    
      and    op_operacion in (
      select ab_operacion 
      from   ca_abono with (nolock), ca_abono_det (nolock), ca_producto (nolock)
      where  ab_fecha_pag      = @i_fecha --@i_siguiente_dia
      and    ab_estado        in ('ING','P', 'NA')
      and    ab_operacion      = abd_operacion
      and    ab_secuencial_ing = abd_secuencial_ing
      and    abd_concepto      = cp_producto
      and    cp_categoria     in ('NDAH', 'NDCC'))
      
      -- DEBITOS AUTOMATICOS - Ops con cuotas Vencidas      
      insert into #universo_batch
      select distinct op_operacion,
                      op_banco
      from   ca_operacion O, ca_estado, ca_producto, ca_dividendo
      where  op_estado = es_codigo
      and    es_procesa = 'S'
      and    op_fecha_ult_proceso <= @i_fecha --@i_siguiente_dia    
      and    op_forma_pago = cp_producto
      and    cp_pago_aut   = 'S'
      and    op_cuenta     is not null
      and   (cp_pcobis = 3 or cp_pcobis = 4)
      and    cp_categoria  in ('NDAH', 'NDCC')
      and    op_naturaleza = 'A'      
      and    di_operacion  = op_operacion
      and    (di_estado      = @w_est_vencido  or (di_estado = @w_est_vigente and di_fecha_ven = op_fecha_ult_proceso))
      --and   (di_fecha_ven between op_fecha_ult_proceso and @w_sig_dia_habil or op_fecha_fin <= @w_sig_dia_habil)

      insert into ca_universo_batch
      select distinct op_operacion,
                      op_banco,
                      0,   -- empezamos con intentos 0
                      0    -- empezamos con hilo 0
      from   #universo_batch
      order  by op_operacion              
end       
-- FIN FCP Interfaz Ahorros -- MANEJO DE OPS CON DEBITO UNICAMENTE                         

                                    
If @@error <> 0 return 710001    
                                    
/*
   delete cobis..ba_ctrl_ciclico    
   where ctc_sarta = @i_sarta       
                                    
   insert into cobis..ba_ctrl_ciclico
   select sb_sarta,sb_batch, sb_secuencial, 'S', 'P'
   from cobis..ba_sarta_batch       
   where sb_sarta = @i_sarta        
   and   sb_batch = @i_batch
*/

COMMIT TRAN        

--update statistics ca_universo  --LPO CDIG Se comenta temporalmente porque MySql no lo soprta
--update INDEX STATISTICS ca_universo
                               
return 0
go
