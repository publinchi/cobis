use cob_cartera
go

set nocount on
go

if exists (select 1 from sysobjects where name = 'sp_param_condonacion_venta')
   drop proc sp_param_condonacion_venta
go

create proc sp_param_condonacion_venta (
@i_param1        int,      -- ROL
@i_param2        smallint, -- CORTE
@i_param3        char(1)   -- OPERACION

)

as
declare 
@w_concepto   varchar(10),
@w_estado     char(1),
@w_secuencial int,
@w_anio       smallint,
@w_banca      tinyint,
@w_date       datetime,
@w_error      int,
@w_user       login,
@w_sp_name    varchar(30),
@w_msg        varchar(255)

select @w_msg = null

select @w_date = fp_fecha
from cobis..ba_fecha_proceso

select @w_sp_name = 'sp_param_condonacion_venta'

if @i_param3 = 'R'   --Respaldo de la Parametrizacion
begin

   begin tran

   insert into ca_param_condona_control 
   values ('ca_param_condona', 'I')

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESPALDO PARAMETRIZACION (1) '
      rollback tran
      goto ERRORFIN
   end

   if exists(select 1 from sysobjects where name = 'ca_param_condona_COPY')
   begin
      select @w_msg = 'ERROR YA EXISTE RESPALDO DE PARAMETRIZACION'
      rollback tran
      goto ERRORFIN
   end

   select * into ca_param_condona_COPY from ca_param_condona

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESPALDO PARAMETRIZACION (2) '
      rollback tran
      goto ERRORFIN
   end

   select * into ca_rol_condona_COPY   from ca_rol_condona

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESPALDO PARAMETRIZACION (3) '
      rollback tran
      goto ERRORFIN
   end

   delete  ca_param_condona WHERE pc_codigo >= 0

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESPALDO PARAMETRIZACION (4) '
      rollback tran
      goto ERRORFIN
   end

   delete  ca_rol_condona WHERE rc_rol >= 0

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESPALDO PARAMETRIZACION (5) '
      rollback tran
      goto ERRORFIN
   end

   commit tran
end


if @i_param3 = 'P'   --Proceso de Cambio de Parametrizacion
begin

   select @w_secuencial = 0

   create table #conceptos (
   concepto      varchar(10)    null,
   estado        varchar(1)     null
   )

   select @w_anio  = 2008

   --Ciclo por A¤os
   while @w_anio <= @i_param2
   begin

      select @w_banca = 1
      --Ciclo por Banca
      while @w_banca <= 4
      begin

         select @w_concepto = ''

         truncate table #conceptos

         insert into #conceptos
         select distinct ru_concepto, 'I'
         from cob_cartera..ca_rubro order by ru_concepto

         --Ciclo por Conceptos
         while 1=1
         begin

            set rowcount 1
            select @w_concepto = concepto
            from #conceptos

            if @@rowcount = 0
            begin
               set rowcount 0
               break
            end

            set rowcount 0
   
            delete #conceptos
            where concepto = @w_concepto

            select @w_secuencial = @w_secuencial + 1
  
            insert into ca_param_condona
            (pc_codigo,           pc_estado,           pc_banca,       pc_rubro,
             pc_mora_inicial,     pc_mora_final,       pc_ano_castigo, pc_porcentaje_max,
             pc_valor_maximo,     pc_valores_vigentes, pc_control_autorizacion)			
            select 
             @w_secuencial,       4,                   @w_banca,       @w_concepto,
             null,                null,                @w_anio,        100,
             999999999,           'S',                 'N'

            insert into ca_rol_condona 
            select @i_param1 , @w_secuencial

         end

         select @w_banca = @w_banca + 1

      end

      select @w_anio = @w_anio + 1

   end
end

if @i_param3 = 'X'   --Restaurar la Parametrizacion Original
begin

   begin tran

   delete ca_param_condona_control  WHERE tabla >= ''

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (1) '
      rollback tran
      goto ERRORFIN
   end

   delete  ca_param_condona WHERE pc_codigo >= 0

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (2) '
      rollback tran
      goto ERRORFIN
   end

   delete  ca_rol_condona WHERE rc_rol >= 0

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (3) '
      rollback tran
      goto ERRORFIN
   end

   insert into ca_param_condona
   select * from ca_param_condona_COPY

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (4) '
      rollback tran
      goto ERRORFIN
   end

   insert into ca_rol_condona
   select * from ca_rol_condona_COPY

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (5) '
      rollback tran
      goto ERRORFIN
   end

   drop table ca_param_condona_COPY

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (6) '
      rollback tran
      goto ERRORFIN
   end

   drop table ca_rol_condona_COPY

   if @@error <> 0
   begin
      select @w_msg = 'ERROR RESTAURANDO PARAMETRIZACION (7) '
      rollback tran
      goto ERRORFIN
   end

   commit tran

end

ERRORFIN:
if @w_msg is not null
begin
 
      select @w_error = 7000
      select @w_user  = 'batch'

      exec sp_errorlog 
      @i_fecha     = @w_date,
      @i_error     = @w_error,
      @i_usuario   = @w_user,
      @i_tran      = 0,
      @i_tran_name = @w_sp_name,
      @i_cuenta    = 'PARAM VTA_CAR',
      @i_descripcion = @w_msg,
      @i_rollback  = 'S'
end

return 0
go

