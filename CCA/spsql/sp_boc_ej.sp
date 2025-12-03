use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_boc_ej')
   drop proc sp_boc_ej
go

create procedure sp_boc_ej
/*************************************************************************/
/*      Archivo:                sp_boc_ej.sp                             */
/*      Stored procedure:       sp_boc_ej                                */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Sandro Vallejo                           */
/*      Fecha de escritura:     Sep 2020                                 */
/*********************************************************************** */
/*                         IMPORTANTE                                    */
/* Esta aplicacion es parte de los paquetes bancarios propiedad          */
/* de COBISCorp.                                                         */
/* Su uso no autorizado queda expresamente prohibido asi como            */
/* cualquier alteracion o agregado hecho por alguno de sus               */
/* usuarios sin el debido consentimiento por escrito de COBISCorp.       */
/* Este programa esta protegido por la ley de derechos de autor          */
/* y por las convenciones internacionales de propiedad inte-             */
/* lectual. Su uso no autorizado dara derecho a COBISCorp para           */
/* obtener ordenes de secuestro o retencion y para perseguir             */
/* penalmente a los autores de cualquier infraccion.                     */
/*************************************************************************/
/*                              PROPOSITO                                */
/*      Realizar la invocacion al proceso de generacion de boc de cartera*/
/*      en paralelo.                                                     */
/*************************************************************************/
/*                              MODIFICACIONES                           */
/*     Fecha        Autor          Razón                                 */
/*     16/07/2021   K. Rodríguez   Estandarización de parámetros         */
/*     06/05/2022   J. Guzman      Cambio tipo de dato param. @w_cont    */
/*************************************************************************/
/*************************************************************************/

( 
	@i_param1        datetime,            -- Fecha
	@i_param2        char(1)       = 'N', -- Debug
	@i_param3        char(1)       = 'E', -- Tipo: 'E'=TABLAS DE EXTRACTOR - 'S'=TABLAS CONTA SUPER 
	@i_param4        tinyint,             -- Hilo
	@i_param5        int                  -- Número registros
) 
as 
 
declare 
   @w_sp_name       varchar(30), 
   @w_error         int, 
   @w_cont          int,
   @i_debug         char(1) = 'N',
   @i_fecha         datetime, 
   @i_tipo          char(1) = 'E',  
   @i_hilo          tinyint,       
   @i_numreg        int
   
-- KDR 16/07/21 Paso de parámetros a variables locales.
select @i_fecha   =  @i_param1,        
       @i_debug   =  @i_param2,         
       @i_tipo    =  @i_param3,
	   @i_hilo    =  @i_param4,
       @i_numreg  =  @i_param5   
 
select @w_sp_name   = 'sp_boc_ej',
       @w_error     = 0

-- CREAR TABLAS DE TRABAJO

-- PERFIL
create table #perfil_boc
(
 pb_perfil     varchar(10) not null,
 pb_concepto   varchar(10) not null,
 pb_codigo     int         not null,
 pb_codvalor   int         not null,
 pb_parametro  catalogo    not null,
 pb_tparametro varchar(20) not null
)

-- CUENTAS
create table #cuentas_boc 
(
 parametro  varchar(10) not null,
 clave      varchar(40) not null,
 cuenta     varchar(40) not null,
 tercero    char(1)     not null,
 naturaleza char(1)     not null
)

-- DATOS RUBRO
create table #dato_rubro 
(
 dr_banco         varchar(24) not null,
 dr_toperacion    varchar(20) not null,
 dr_cliente       int         not null,
 dr_oficina       smallint    not null,
 dr_concepto      varchar(10) not null,
 dr_tgarantia     varchar(10) not null,
 dr_calificacion  varchar(10) not null,
 dr_clase_cartera varchar(10) not null,
 dr_parametro     varchar(40) not null,
 dr_clave         varchar(40) not null,
 dr_valor         money       not null
)

-- LLENA DATOS EN TABLAS DE TRABAJO

-- PERFIL
insert into #perfil_boc
(pb_perfil, pb_concepto, pb_codigo, pb_codvalor, pb_parametro, pb_tparametro)
select distinct dp_perfil, co_concepto, co_codigo, dp_codval, dp_cuenta, ''
from   cob_conta..cb_det_perfil, cob_cartera..ca_concepto
where  dp_perfil in ('BOC_ACT', 'BOC_PAS', 'BOC_ADM') 
and    co_codigo  = dp_codval / 1000

--create index #perfil_boc_1 on #perfil_boc (pb_perfil, pb_codvalor)
create index perfil_boc_1 on #perfil_boc (pb_perfil, pb_codvalor)

update #perfil_boc 
set    pb_tparametro = pa_stored
from   cob_conta..cb_parametro
where  pa_parametro = pb_parametro
   
-- CUENTAS
insert into #cuentas_boc
select distinct
       parametro  = re_parametro,
       clave      = re_clave,
       cuenta     = re_substring,
       tercero    = 'N',
       naturaleza = ''
from   cob_conta..cb_relparam, cob_conta..cb_det_perfil
where  dp_perfil    in ('BOC_ACT', 'BOC_PAS', 'BOC_ADM')
and    re_empresa   = dp_empresa
and    re_producto  = dp_producto
and    re_parametro = dp_cuenta

--create index #cuentas_boc_1 on #cuentas_boc (parametro, clave)
create index cuentas_boc_1 on #cuentas_boc (parametro, clave)

update #cuentas_boc 
set    naturaleza = cu_categoria
from   cob_conta..cb_cuenta
where  cu_cuenta = cuenta

-- DETERMINO SI ES CUENTA DE TERCERO 
update #cuentas_boc 
set    tercero = 'S'
from   cob_conta..cb_cuenta_proceso 
where  cp_proceso in (6003, 6095) 
and    cp_cuenta   = cuenta

-- LAZO DE PROCESAMIENTO POR HILO       
while 1 = 1
begin 
   select @w_cont = count(*)
   from   ca_universo_boc  
   where  hilo     = @i_hilo
   and    intentos < 2
      
   select @w_cont = @i_numreg - isnull(@w_cont, 0)
      
   if @w_cont < 0 select @w_cont = @i_numreg

   if @w_cont > 0 
   begin
      BEGIN TRAN

      set rowcount @w_cont
         
      update ca_universo_boc 
      set    hilo = @i_hilo
      where  hilo     = 0
      and    intentos = 0
       
      if @@rowcount = 0
      begin
         COMMIT TRAN 
         return 0 --SALIR
      end
      
      COMMIT TRAN 
      set rowcount 0
   end

   exec @w_error = cob_cartera..sp_boc 
        @i_debug = @i_debug,
        @i_fecha = @i_fecha, 
        @i_tipo  = @i_tipo,
        @i_hilo  = @i_hilo 
        
   if @w_error <> 0 
   begin                 
      exec sp_errorlog
      @i_fecha       = @i_fecha, 
      @i_error       = @w_error, 
      @i_usuario     = 'consola',
      @i_tran        = 7000, 
      @i_tran_name   = @w_sp_name, 
      @i_rollback    = 'N',
      @i_cuenta      = 'BOC', 
      @i_descripcion = 'ERROR: Ejecucion cob_cartera..sp_boc_ej '
        
      return @w_error  
   end
end
 
return 0 

go
