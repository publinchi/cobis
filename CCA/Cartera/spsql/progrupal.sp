/************************************************************************/
/*  Archivo:                        progrupal.sp                        */
/*  Stored procedure:               sp_prorroga_grupal                  */
/*  Base de datos:                  cob_cartera                         */
/*  Producto:                       Cartera                             */
/*  Disenado por:                   Sandro Vallejo                      */
/*  Fecha de escritura:             Agosto 2019                         */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'                                                        */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/
/*                                  PROPOSITO                           */
/*  Realiza la aplicacion de prorroga de la operacion grupal y sus      */
/*  operaciones interciclos                                             */
/************************************************************************/
/*                            ACTUALIZACIONES                           */
/*      FECHA            AUTOR          MODIFICACION                    */
/*      22-Ago-2019      Sandro Vallejo Emision Inicial                 */
/*      26-Ago-2019      Luis Ponce     Ajustes Prorroga Grupal         */
/************************************************************************/
use cob_cartera
go


if exists (select 1 from sysobjects where name = 'sp_prorroga_grupal')
   drop proc sp_prorroga_grupal
go

create proc sp_prorroga_grupal
(  
   @t_trn                  int          = NULL,
   @s_org                  char(1)      = NULL,
   @s_sesn                 int          = NULL,
   @s_user                 login        = NULL,
   @s_term                 varchar (30) = NULL,
   @s_date                 datetime     = NULL,
   @s_ofi                  smallint     = NULL,
   @s_ssn                  int          = null,
   @s_srv                  varchar (30) = null,
   @s_lsrv                 varchar (30) = null,
   @i_operacion            char(1)      = null,
   @i_banco                cuenta       = null,
   @i_fecha                datetime     = null,
   @i_formato_fecha        smallint     = null,
   @i_cuota                smallint     = null,
   @i_valor_calculado      money        = null,
   @i_fecha_vencimiento    datetime     = null,
   @i_fecha_max_prorroga   datetime     = null,
   @i_fecha_prorroga       datetime     = null,
   @i_modo                 char(1)      = null,
   @i_secuencial_prorroga  int          = null,
   @i_secuencial_tran      int          = null 
)

as
declare 
   @w_sp_name              varchar(32),
   @w_operacionca          int,
   @w_error                int,
   @w_banco                cuenta,
   @w_fecha_liq            datetime,
   @w_fecha_valor          datetime,
   @w_fecha_ult_proceso    datetime,
   @w_operacion_pro        int,
   @w_dividendo_max        int,
   @w_fecha_cuota_grupal   datetime,
   @w_cuota                int,
   @w_dividendo_vig        int,
   @w_est_vigente          int,
   @w_secuencial_prorroga  int,     
   @w_secuencial_tran      int       

-- INICIALIZACION DE VARIABLES
select @w_est_vigente = 1

select @w_operacionca       = op_operacion,
       @w_fecha_ult_proceso = op_fecha_ult_proceso
from   ca_operacion
where  op_banco = @i_banco    

/* CREAR TABLAS TEMPORALES */                                                                                                                                                                                                                                              
/* CREAR TABLA DE OPERACIONES INTERCICLOS */
create table #TMP_operaciones (
       operacion     int,
       banco         cuenta,
       fecha_proceso datetime,
       fecha_liq     datetime)

/* CREAR TABLA DE OPERACIONES QUE DEBEN EJECUTAR FECHA VALOR */
create table #TMP_fecha_valor (
       banco         cuenta,
       fecha_liq     datetime)

/* DETERMINAR LAS OPERACIONES INTERCICLOS */
insert into #TMP_operaciones
select op_operacion, op_banco, op_fecha_ult_proceso, op_fecha_liq
from   ca_operacion 
where  op_operacion in (select dc_operacion from ca_det_ciclo where dc_referencia_grupal = @i_banco and dc_tciclo = 'I') 
and    op_estado <> 3
order by op_operacion

/* ATOMICIDAD POR TRANSACCION */
begin tran

/* VERIFICAR SI SE DEBE EJECUTAR EL FECHA VALOR DE OPERACIONES INTERCICLO */
insert into #TMP_fecha_valor 
select banco, fecha_liq
from   #TMP_operaciones
where  fecha_proceso <> @w_fecha_ult_proceso


/* EJECUTAR EL PROCESO DE FECHA VALOR */
declare cursor_fecha_valor cursor for
select  banco, fecha_liq
from    #TMP_fecha_valor
for read only
   
open    cursor_fecha_valor
fetch   cursor_fecha_valor 
into    @w_banco, @w_fecha_liq
    
/* WHILE cursor_fecha_valor */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 710004
      goto ERROR
   end
  
   /* SI LA FECHA DE PROCESO ES MENOR A LA DE DESEMBOLSO */
   if @i_fecha_prorroga < @w_fecha_liq
      select @w_fecha_valor = @w_fecha_liq
   else
      select @w_fecha_valor = @w_fecha_ult_proceso

   /* APLICAR PROCESO DE FECHA VALOR */
   exec @w_error        = sp_fecha_valor
        @s_date         = @s_date,
        @s_ofi          = @s_ofi,
        @s_sesn         = @s_sesn,
        @s_ssn          = @s_ssn,
        @s_srv          = @s_srv,
        @s_term         = @s_term,
        @s_user         = @s_user,
        @t_trn          = 7049,
        @i_operacion    = 'F',
        @i_banco        = @w_banco,
        @i_fecha_valor  = @w_fecha_valor,
        @i_observacion  = 'PRORROGA FECHA VALOR'

   if @w_error <> 0 
   begin
      close cursor_fecha_valor 
      deallocate cursor_fecha_valor

      goto ERROR
   end

   fetch   cursor_fecha_valor 
   into    @w_banco, @w_fecha_liq

end /* WHILE cursor_fecha_valor */

close cursor_fecha_valor
deallocate cursor_fecha_valor

/* INSERTAR DATOS DE LA OPERACION GRUPAL - PADRE */
insert into ca_secuencial_prorroga_grupal (
pg_operacion_prorroga, pg_secuencial_prorroga, pg_banco_prorroga,
pg_operacion,          pg_secuencial,          pg_banco,
pg_fecha_ing,          pg_fecha_real,          pg_estado)
values(
@w_operacionca,        @i_secuencial_prorroga, @i_banco,           
@w_operacionca,        @i_secuencial_tran,     @i_banco,
@i_fecha_prorroga,     getdate(),              'I')

if @@error <> 0 
begin
   select @w_error = 77534
   goto ERROR
end

/* FECHA DE VENCIMIENTO DE LA OPERACION GRUPAL */
select @w_fecha_cuota_grupal = di_fecha_ven
from   ca_dividendo
where  di_operacion = @w_operacionca
and    di_dividendo = @i_cuota + 1



/* EJECUTAR EL PROCESO DE PRORROGAS INTERCICLOS */

declare cursor_prorroga cursor for
select  operacion, banco
from    #TMP_operaciones
where   fecha_liq <= @i_fecha_prorroga
for read only

open    cursor_prorroga
fetch   cursor_prorroga
into    @w_operacion_pro, @w_banco
   
/* WHILE cursor_prorroga */
while @@fetch_status = 0 
begin 
   if (@@fetch_status = -1) 
   begin
      select @w_error = 710004
      goto ERROR
   end

   --MAXIMO DIVIDENDO
   select @w_dividendo_max = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacion_pro

   -- BUSCAR DIVIDENDO VIGENTE 
   select @w_dividendo_vig = max(di_dividendo)
   from   ca_dividendo
   where  di_operacion = @w_operacion_pro
   and    di_estado    = @w_est_vigente
   
   select @w_dividendo_vig = isnull(@w_dividendo_vig, @w_dividendo_max)
   
   /* VERIFICAR QUE NO SEA LA ULTIMA CUOTA DE LA OPERACION */
   if @w_dividendo_max = @w_dividendo_vig
   begin  
      select @w_error = 77535 -- /* OPERACION INTERCICLO NO PUEDE PRORROGARSE */
      goto ERROR
   end

   /* VERIFICAR QUE NO SE PRORROGE A UNA FECHA MAYOR A LA DE VENCIMIENTO */
   if @i_fecha_prorroga >= @i_fecha_max_prorroga
   begin  
      select @w_error = 77536 -- /* OPERACION INTERCICLO NO PUEDE PRORROGARSE VON FECHA MAYOR A SU VENCIMIENTO */
      goto ERROR
   end
 
   /* DETERMINAR LA CUOTA A PRORROGAR */
   select @w_cuota = di_dividendo - 1
   from   ca_dividendo
   where  di_operacion = @w_operacion_pro
   and    di_fecha_ven = @w_fecha_cuota_grupal
   
    select @w_fecha_cuota_grupal = di_fecha_ven
    from   ca_dividendo
    where  di_operacion = @w_operacionca
    and    di_dividendo = @i_cuota

   
   /* EJECUTAR PROCESO DE CARGA DE PRORROGA DE LA OPERACION INTERCICLO */
   exec @w_error               = sp_prorroga_cuota
        @s_sesn                = @s_sesn,
        @s_user                = @s_user,
        @s_term                = @s_term,
        @s_date                = @s_date,
        @s_ofi                 = @s_ofi,
        @s_ssn                 = @s_ssn,
        @s_srv                 = @s_srv,
        @s_lsrv                = @s_lsrv,
        @s_org                 = @s_org,
        @t_trn                 = 7232,
        @i_operacion           = 'I',
        @i_modo                = 'A',
        @i_banco               = @w_banco,
        @i_fecha               = @i_fecha,
        @i_formato_fecha       = @i_formato_fecha,
        @i_cuota               = @w_cuota,
        @i_externo             = 'N',
        @i_fecha_prorroga      = @i_fecha_prorroga
        
   if @w_error <> 0 
   begin       
      close cursor_prorroga 
      deallocate cursor_prorroga

      goto ERROR
   end
    
   /* EJECUTAR PROCESO DE ACTUALIZACION DE PRORROGA DE LA OPERACION INTERCICLO */
   exec @w_error             = sp_prorroga_cuota
        @s_sesn              = @s_sesn,
        @s_user              = @s_user,
        @s_term              = @s_term,
        @s_date              = @s_date,
        @s_ofi               = @s_ofi,
        @s_ssn               = @s_ssn,
        @s_srv               = @s_srv,
        @s_lsrv              = @s_lsrv,
        @s_org               = @s_org,
        @t_trn               = 7232,
        @i_operacion         = 'I',
        @i_modo              = 'B',
        @i_banco             = @w_banco,
        @i_fecha             = @i_fecha,
        @i_formato_fecha     = @i_formato_fecha,
        @i_cuota             = @w_cuota,
        @i_externo           = 'N',
        @i_fecha_prorroga    = @i_fecha_prorroga,
        @o_secuencial_prorroga = @w_secuencial_prorroga out,
        @o_secuencial_tran     = @w_secuencial_tran     out 
        
   if @w_error <> 0 
   begin
      close cursor_prorroga 
      deallocate cursor_prorroga

      goto ERROR
   end


   /* INSERTAR DATOS DE LA OPERACION INTERCICLO */
   insert into ca_secuencial_prorroga_grupal (
   pg_operacion_prorroga, pg_secuencial_prorroga, pg_banco_prorroga,
   pg_operacion,          pg_secuencial,          pg_banco,
   pg_fecha_ing,          pg_fecha_real,          pg_estado)
   values(
   @w_operacionca,        @i_secuencial_prorroga, @i_banco,           
   @w_operacion_pro,      @w_secuencial_tran,     @w_banco,
   @i_fecha_prorroga,     getdate()         ,     'I')

   if @@error <> 0 
   begin
      select @w_error = 77534
      goto ERROR
   end

   fetch   cursor_prorroga 
   into    @w_operacionca, @w_banco

end /* WHILE cursor_prorroga */

close cursor_prorroga
deallocate cursor_prorroga

--AGC. 10SEP19. Actualizar hijas
exec @w_error = cob_cartera..sp_actualiza_hijas
     @i_banco = @i_banco

if @w_error <> 0 
   goto ERROR
   
/* ATOMICIDAD POR TRANSACCION */

commit tran


return 0
                                                                                                                  
ERROR:
while @@trancount > 0 rollback tran
              
return @w_error
go
