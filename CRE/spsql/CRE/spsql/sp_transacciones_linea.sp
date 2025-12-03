/************************************************************************/
/*  Archivo:              sp_transacciones_linea.sp                     */
/*  Stored procedure:     sp_transacciones_linea                        */
/*  Base de datos:        cob_credito                                   */
/*  Producto:             credito                                       */
/*  Disenado por:         William Lopez                                 */
/*  Fecha de escritura:   23/Dic/2021                                   */
/************************************************************************/
/*                        IMPORTANTE                                    */
/*  Esta aplicacion es parte de los paquetes bancarios propiedad de     */
/*  COBISCORP.                                                          */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado  hecho por alguno de sus            */
/*  usuarios sin el debido consentimiento por escrito de COBISCORP.     */
/*  Este programa esta protegido por la ley de derechos de autor        */
/*  y por las convenciones  internacionales   de  propiedad inte-       */
/*  lectual.    Su uso no  autorizado dara  derecho a COBISCORP para    */
/*  obtener ordenes  de secuestro o retencion y para  perseguir         */
/*  penalmente a los autores de cualquier infraccion.                   */
/************************************************************************/
/*                        PROPOSITO                                     */
/*  Transacciones de contabilizacion de lineas de credito               */
/************************************************************************/
/*                        MODIFICACIONES                                */
/*  FECHA         AUTOR           RAZON                                 */
/*  23/Dic/2021   William Lopez   Emision Inicial-ORI-S575137-GFI       */
/*  13/May/2022    PJA            Modificacion Proceso Cancelacion      */
/************************************************************************/
use cob_credito
go

if exists(select 1 from sysobjects where name = 'sp_transacciones_linea' and type = 'P')
   drop procedure sp_transacciones_linea
go

create proc sp_transacciones_linea (
   @s_ssn          int         = null,
   @s_user         login       = null,
   @s_sesn         int         = null,
   @s_srv          varchar(30) = null,
   @s_lsrv         varchar(30) = null,
   @s_date         datetime    = null,
   @s_term         descripcion = null,
   @s_rol          smallint    = null,
   @s_ofi          smallint    = null,
   @s_org_err      char(1)     = null,
   @s_error        int         = null,
   @s_sev          tinyint     = null,
   @s_msg          descripcion = null,
   @s_org          char(1)     = null,
   @t_trn          smallint    = null,
   @t_debug        char(1)     = 'N',
   @t_file         varchar(14) = null,
   @t_from         varchar(30) = null,
   @t_show_version bit         = 0,
   @i_transaccion  char(1)     = null,
   @i_linea        int         = null,
   @i_secuencial   int         = null,
   @i_valor        money       = null,
   @i_valor_ref    money       = null,
   @i_contabiliza  money       = null,
   @i_operacion    int         = null,
   @i_moneda       tinyint     = null,
   @i_estado       char(3)     = null,
   @i_oficina      smallint    = null,
   @i_prorroga     char(1)     = 'N',
   @i_fecha_vto    datetime    = null,
   @i_pgroup       catalogo    = null,
   @i_en_linea     char(1)     = 'S',
   @i_concepto     catalogo    = null
)
as
declare 
   @w_sp_name      varchar(32),  -- Nombre stored proc
   @w_error        int,
   @w_monto_linea  money,
   @w_ajuste       money,
   @w_banco        varchar(20),
   @w_secuencial   int,
   @w_aumentos     money,
   @w_decrementos  money,
   @w_valor        money,
   @w_fecha        datetime,
   @w_pgroup       catalogo,
   @w_valor_mn     money,
   @w_cotizacion   float
-------------------------------------
-- Versionamiento del Programa 
-------------------------------------   
if @t_show_version = 1
begin
   print 'Stored procedure sp_transacciones_linea, Version 4.0.0.2'
   return 0
end

select @w_sp_name = 'sp_transacciones_linea'

select @s_date = convert(varchar(10),fp_fecha, 101)
from   cobis..ba_fecha_proceso

select @i_oficina = li_oficina
from   cr_linea
where  li_numero = @i_linea

select @w_fecha = fp_fecha
from   cobis..ba_fecha_proceso

select @w_valor_mn   = @i_valor * ct_valor,
       @w_cotizacion = ct_valor
from   cb_cotizaciones
where  ct_moneda = @i_moneda

/* select @w_secuencial = max(tl_secuencial)  + 1
   from cr_transaccion_linea
   where tl_linea = @i_linea

   select @i_secuencial = isnull(@i_secuencial, @w_secuencial)
*/

/***********************************************************/
/* Codigos de Transacciones                                */
if (@t_trn != 21447  and @i_transaccion = 'V') or
   (@t_trn != 21450  and @i_transaccion = 'C') or
   (@t_trn != 21448  and @i_transaccion = 'A') or
   (@t_trn != 21449  and @i_transaccion = 'D') or
   (@t_trn != 21469  and @i_transaccion = 'E')
begin
   /* tipo de transaccion no corresponde */
   exec cobis..sp_cerror
      @t_debug = @t_debug,
      @t_file  = @t_file, 
      @t_from  = @w_sp_name,
      @i_num   = 2101006
   return 1 
end

/*** VERIFICACION DE CAMPOS NULOS Y CALCULOS VARIOS ***/
If (@i_transaccion = 'V') or
   (@i_transaccion = 'C') or
   (@i_transaccion = 'A') or
   (@i_transaccion = 'D') or
   (@i_transaccion = 'E')
begin
   if (@i_linea is null)
   begin
      /* Campos NOT null con valores nulos */
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101001
      return 1
   end
end

if @i_transaccion = 'E'
begin
   select @w_secuencial = isnull(max(tl_secuencial), 1)
   from   cob_credito..cr_transaccion_linea
   where  tl_linea = @i_linea
   
   insert into cr_det_transaccion_linea(
   dtl_linea,    dtl_secuencial, dtl_fecha_tran,
   dtl_concepto, dtl_valor,      dtl_moneda,
   dtl_oficina,  dtl_valor_mn,   dtl_cotizacion)
   values(
   @i_linea,     @w_secuencial,  @s_date,
   @i_concepto,  @i_valor,       @i_moneda,
   @i_oficina,   @w_valor_mn,    @w_cotizacion)

   if @@error != 0
   begin
      if @i_en_linea ='S'
      begin
         exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file, 
            @t_from  = @w_sp_name,
            @i_num   = 2103001
         return 1
      end--if @i_en_linea ='S'
      else--@i_en_linea ='N'
         return 2103001
   end--if @@error != 0 
end--if @i_transaccion = 'E'

if @i_transaccion = 'V' 
begin
   if @i_prorroga = 'S'
   begin
      select @w_monto_linea = li_monto
      from   cr_linea
      where  li_numero  = @i_linea
             
      select @w_secuencial = max(tl_secuencial)
      from   cr_transaccion_linea
      where  tl_linea = @i_linea

      if @w_secuencial is null
         select @w_secuencial = 1
      else
         select @w_secuencial = @w_secuencial + 1

      if exists(select dtl_secuencial 
                from   cob_credito..cr_det_transaccion_linea
                where  dtl_linea      = @i_linea
                and    dtl_secuencial = @w_secuencial)
         select @w_secuencial = @w_secuencial + 1

      select @w_ajuste = @i_valor - @w_monto_linea

      if @w_ajuste > 0
      begin
         insert into cr_transaccion_linea(
         tl_linea,          tl_secuencial,     tl_fecha_tran,  tl_transaccion,
         tl_moneda,         tl_valor,          tl_valor_ref,   tl_estado,
         tl_operacion,      tl_oficina,        tl_usuario,     tl_terminal,
         tl_secuencial_ref, tl_pgroup)
         values(
         @i_linea,          @w_secuencial,     @s_date,        'A',
         @i_moneda,         @w_ajuste,         @w_monto_linea, @i_estado,
         null,              @i_oficina,        @s_user,        @s_term,
         null,              null)

         if @@error != 0
         begin
            /* Error en insercion de registro */
            exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file, 
               @t_from  = @w_sp_name,
               @i_num   = 2103001
            return 1 
         end
      end

      if @w_ajuste < 0
      begin
         select @w_ajuste = @w_ajuste * -1

         insert into cr_transaccion_linea(
         tl_linea,          tl_secuencial, tl_fecha_tran,  tl_transaccion,
         tl_moneda,         tl_valor,      tl_valor_ref,   tl_estado,
         tl_operacion,      tl_oficina,    tl_usuario,     tl_terminal,
         tl_secuencial_ref, tl_pgroup)
         values(
         @i_linea,          @w_secuencial, @s_date,        'D',
         @i_moneda,         @w_ajuste,     @w_monto_linea, @i_estado,
         null,              @i_oficina,    @s_user,        @s_term,
         null,              null)

         if @@error != 0
         begin
            /* Error en insercion de registro */
            exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2103001
            return 1
         end
      end
      
      if @i_fecha_vto = @w_fecha
      begin
         --Obtengo el mayor secuencial para la linea seleccionada
         if exists (select 1
                    from   cr_transaccion_linea
                    where  tl_linea = @i_linea
                    and    tl_transaccion = 'C')
         begin
            /* Registro ya existe */
            exec cobis..sp_cerror
               @t_debug = @t_debug,
               @t_file  = @t_file,
               @t_from  = @w_sp_name,
               @i_num   = 2101002
            return 1
         end

         select @w_secuencial = max(tl_secuencial)
         from   cob_credito..cr_transaccion_linea
         where  tl_linea = @i_linea

         if @w_secuencial is null
            select @w_secuencial = 1
         else
            select @w_secuencial = @w_secuencial + 1
             
         if @w_secuencial >= 1
         begin
            --Obtengo saldo de la linea
            select @w_decrementos = isnull(sum(tl_valor),0)
            from   cob_credito..cr_transaccion_linea
            where  tl_linea       = @i_linea
            and    tl_transaccion = 'D'

            select @w_aumentos = isnull(sum(tl_valor),0)
            from   cob_credito..cr_transaccion_linea
            where  tl_linea       = @i_linea
            and    tl_transaccion in ('A', 'V')

            select @w_valor = @w_aumentos - @w_decrementos

            insert into cr_transaccion_linea(
            tl_linea,          tl_secuencial, tl_fecha_tran,  tl_transaccion,
            tl_moneda,         tl_valor,      tl_valor_ref,   tl_estado,
            tl_operacion,      tl_oficina,    tl_usuario,     tl_terminal,
            tl_secuencial_ref, tl_pgroup)
            values(
            @i_linea,          @w_secuencial, @s_date,        'C',
            @i_moneda,         @w_valor,      @w_monto_linea, 'I',
            null,              @i_oficina,    @s_user,        null,
            null,              null)

            if @@error != 0
            begin
               /* Error en insercion de registro */
               exec cobis..sp_cerror
                  @t_debug = @t_debug,
                  @t_file  = @t_file,
                  @t_from  = @w_sp_name,
                  @i_num   = 2103001
               return 1
            end
         end
      end
   end
   else
   begin
      select @w_secuencial = max(tl_secuencial)
      from   cr_transaccion_linea
      where  tl_linea = @i_linea
                       
      if @w_secuencial is null
         select @w_secuencial = 1
      else
         select @w_secuencial = @w_secuencial + 1
        
      if exists(select dtl_secuencial
                from   cob_credito..cr_det_transaccion_linea
                where  dtl_linea = @i_linea
                and    dtl_secuencial = @w_secuencial)
         select @w_secuencial = @w_secuencial + 1

      insert into cr_transaccion_linea(
      tl_linea,          tl_secuencial, tl_fecha_tran, tl_transaccion,
      tl_moneda,         tl_valor,      tl_valor_ref,  tl_estado,
      tl_operacion,      tl_oficina,    tl_usuario,    tl_terminal,
      tl_secuencial_ref, tl_pgroup)
      values(
      @i_linea,          @w_secuencial, @s_date,       @i_transaccion,
      @i_moneda,         @i_valor,      @i_valor_ref,  @i_estado,
      null,              @i_oficina,    @s_user,       @s_term,
      null,              null)

      if @@error != 0
      begin
         /* Error en insercion de registro */
         exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103001
         return 1
      end
   end
end

if (@i_transaccion = 'A' or @i_transaccion = 'D' or @i_transaccion = 'C')
begin

   select @w_secuencial = max(tl_secuencial)
   from   cr_transaccion_linea
   where  tl_linea = @i_linea

   if @w_secuencial is null
       select @w_secuencial = 1
   else
       select @w_secuencial = @w_secuencial + 1

   if exists(select dtl_secuencial
             from   cob_credito..cr_det_transaccion_linea
             where  dtl_linea      = @i_linea
             and    dtl_secuencial = @w_secuencial)
      select @w_secuencial = @w_secuencial + 1

   insert into cr_transaccion_linea(
   tl_linea,          tl_secuencial, tl_fecha_tran, tl_transaccion,
   tl_moneda,         tl_valor,      tl_valor_ref,  tl_estado,
   tl_operacion,      tl_oficina,    tl_usuario,    tl_terminal,
   tl_secuencial_ref, tl_pgroup)
   values(
   @i_linea,          @w_secuencial, @s_date,       @i_transaccion,
   @i_moneda,         @i_valor,      @i_valor_ref,  @i_estado,
   null,              @i_oficina,    @s_user,       @s_term,
   null,              null)

   if @@error != 0
   begin
      if @i_en_linea = 'S'
      begin
         /* Error en insercion de registro */
         exec cobis..sp_cerror
            @t_debug = @t_debug,
            @t_file  = @t_file,
            @t_from  = @w_sp_name,
            @i_num   = 2103001
         return 1
      end
      else--if @i_en_linea = 'N'
         return 2103001
   end--if @@error != 0
end--if @i_transaccion = 'A' or

/*if @i_transaccion = 'C'
begin
   select li_numero, li_monto,li_moneda,li_oficina
   from   cr_linea
   where  li_numero  = @i_linea
   order by li_numero, li_monto, li_moneda, li_oficina

   --Obtengo el mayor secuencial para la linea seleccionada
   if exists (select 1
              from   cr_transaccion_linea
              where  tl_linea = @i_linea
              and    tl_transaccion = 'C')
   begin
      --Registro ya existe
      exec cobis..sp_cerror
         @t_debug = @t_debug,
         @t_file  = @t_file,
         @t_from  = @w_sp_name,
         @i_num   = 2101002
      return 1
   end

   select @w_secuencial = max(tl_secuencial) + 1
   from cob_credito..cr_transaccion_linea
   where tl_linea = @i_linea

   if @w_secuencial is null
      select @w_secuencial = 1
   else
      select @w_secuencial = @w_secuencial + 1

   if exists(select dtl_secuencial
             from   cob_credito..cr_det_transaccion_linea
             where  dtl_linea     = @i_linea
             and    dtl_secuencial = @w_secuencial)
      select @w_secuencial = @w_secuencial + 1

    if @w_secuencial >= 1
    begin
       select @w_valor = (select li_monto from cr_linea where li_numero  = @i_linea)    ---- MONTO APROBADO DE LA LINEA ----
       
       insert into cr_transaccion_linea(
       tl_linea,          tl_secuencial, tl_fecha_tran, tl_transaccion,
       tl_moneda,         tl_valor,      tl_valor_ref,  tl_estado,
       tl_operacion,      tl_oficina,    tl_usuario,    tl_terminal,
       tl_secuencial_ref, tl_pgroup)
       values(
       @i_linea,          @w_secuencial, @s_date,       'C',
       @i_moneda,         @w_valor,      @i_valor_ref,  'I',
       null,              @i_oficina,    @s_user,       @s_term,
       null,              null)

       if @@error != 0
       begin
          exec cobis..sp_cerror
             @t_debug = @t_debug,
             @t_file  = @t_file, 
             @t_from  = @w_sp_name,
             @i_num   = 2103001
          return 1
       end
    end
end
*/
return 0
go
