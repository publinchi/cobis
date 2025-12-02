USE cob_cartera
GO
/* ********************************************************************* */
/*      Archivo:                sp_precancela_refer.sp                   */
/*      Stored procedure:       sp_precancela_refer                      */
/*      Base de datos:          cob_cartera                              */
/*      Producto:               Cartera                                  */
/*      Disenado por:           Luis Guachamin                           */
/*      Fecha de escritura:     12-Dic-2017                              */
/* ********************************************************************* */
/*                              IMPORTANTE                               */
/*      Este programa es parte de los paquetes bancarios propiedad de    */
/*      "MACOSA", representantes exclusivos para el Ecuador de la        */
/*      "NCR CORPORATION".                                               */
/*      Su uso no autorizado queda expresamente prohibido asi como       */
/*      cualquier alteracion o agregado hecho por alguno de sus          */
/*      usuarios sin el debido consentimiento por escrito de la          */
/*      Presidencia Ejecutiva de MACOSA o su representante.              */
/* ********************************************************************* */
/*                              PROPOSITO                                */
/*   Mantenimiento tala de referencias para precancelaciones de Grupales */
/* ********************************************************************* */
/*                              MODIFICACIONES                           */
/*      FECHA           AUTOR                RAZON                       */
/*      12/Dic/2017     LGU                  Version Inicial             */
/*      11/Nov/2018     SRO                  Referencias Numéricas       */
/* ********************************************************************* */

if exists (select 1 from sysobjects where name = 'sp_precancela_refer')
   drop proc sp_precancela_refer
go
create proc sp_precancela_refer
    @s_user            login        = 'admuser',
    @s_term            varchar(32)  = 'consola',

    @i_operacion       varchar(10)  = NULL, -- C =consuylta montos // I = inserta tabla
    @i_fecha_proceso   DATETIME     = NULL,
    @i_cliente         INT          = NULL,
    @i_banco           VARCHAR(32)  = null,
    @i_monto_pre       MONEY        = 0,
    @i_tipo            tinyint      = 1, --- 1 = PDF, 2 = email

    @o_monto_op        MONEY        =  0  output,
    @o_monto_pre       MONEY        =  0  output,
    @o_monto_seg       MONEY        =  0  output,
    @o_pagado_seg      VARCHAR(1)   = 'N' OUTPUT,
    @o_nombre          VARCHAR(100) = NULL OUTPUT,
    ---------------------------
    @o_fecha_liq       VARCHAR(10)  = NULL OUTPUT,
    @o_nombre_banco    VARCHAR(100) = NULL  OUTPUT,
    @o_fecha_ven       VARCHAR(10)  = NULL OUTPUT,
    @o_num_abono       INT          = 0 OUTPUT,
    @o_nom_oficina     VARCHAR(100) = NULL  OUTPUT,
    @o_referencia      VARCHAR(100) = NULL  OUTPUT,
    @o_convenio        INT          = 0 OUTPUT,
    @o_secuencial      int          = 0 output

as


DECLARE
@w_sp_name              VARCHAR(32),
@w_operacionca          INT,
@w_fecha_liq            DATETIME,
@w_fecha_ven            DATETIME,
@w_moneda               SMALLINT,
@w_oficina              SMALLINT,
@w_return               INT,
@w_grupo                INT,
@w_referencia           VARCHAR(64),
@w_secuencial           INT,
@w_precancela_dias      INT,
@w_convenio             VARCHAR(32),
@w_nombre_banco         VARCHAR(32),
@w_mail                 VARCHAR(32),
@w_estado               varchar(1),
@w_id_corresp           varchar(10),
@w_sp_corresponsal      varchar(50),
@w_descripcion_corresp  varchar(30),
@w_fail_tran            char(1),
@w_corresponsal         varchar(30),
@w_toperacion           varchar(50),
@w_tramite              int

select @w_sp_name = 'sp_precancela_refer'

--Fecha proceso
select @i_fecha_proceso = isnull(@i_fecha_proceso, fp_fecha)
from cobis..ba_fecha_proceso

select @w_precancela_dias = pa_int
from  cobis..cl_parametro
WHERE pa_nemonico = 'DIPRE'
and  pa_producto = 'CCA'

select @w_precancela_dias = isnull(@w_precancela_dias , 10), 
       @w_grupo           = 0

IF @i_cliente IS NULL OR @i_cliente = 0
BEGIN
   select
   @w_operacionca = op_operacion,
   @w_fecha_liq   = op_fecha_liq,
   @w_moneda      = op_moneda,
   @w_oficina     = op_oficina,
   @i_cliente     = op_cliente,
   @o_nombre      = op_nombre,
   @o_monto_op    = op_monto,
   @w_toperacion  = op_toperacion,
   @w_tramite     = op_tramite
   from cob_cartera..ca_operacion
   where op_estado  NOT IN (3,0,99)
  --and op_toperacion = 'GRUPAL'
   and op_banco      = @i_banco
   order by op_operacion

   if (@@rowcount = 0)
   begin
       select @w_return = 70121
       goto ERROR
   end
END
ELSE
begin
   select
   @w_operacionca = op_operacion,
   @w_fecha_liq   = op_fecha_liq,
   @w_moneda      = op_moneda,
   @w_oficina     = op_oficina,
   @i_banco       = op_banco,
   @o_nombre      = op_nombre,
   @o_monto_op    = op_monto,
   @w_toperacion  = op_toperacion,
   @w_tramite     = op_tramite
   from cob_cartera..ca_operacion
   where op_estado    NOT IN (3,0,99)
  --and op_toperacion = 'GRUPAL'
   and op_cliente    = @i_cliente
   order by op_operacion

   if (@@rowcount = 0)
   begin

       select @w_return = 70121
       goto ERROR
   end
END

IF @i_operacion = 'C'
BEGIN

   select
   @o_monto_seg  = isnull(se_monto, 0),
   @o_pagado_seg = isnull(se_estado, 'N')
   from ca_seguro_externo
   where se_operacion = @w_operacionca
   --MTA
   if (@@rowcount = 0)
   BEGIN
      select @o_monto_seg  = 0,
      @o_pagado_seg =  'N'
   END

   -- saldo precancelar es el monto del prestamo menos el valor pagado del seguro
   IF datediff(dd, @w_fecha_liq, @i_fecha_proceso) <= @w_precancela_dias
   BEGIN
      IF @o_pagado_seg = 'S'
         select @o_monto_pre = @o_monto_op - @o_monto_seg
      else
         select @o_monto_pre = @o_monto_op
   END
   ELSE
   BEGIN
      select @o_monto_pre = sum(am_acumulado + am_gracia - am_pagado)
      from ca_amortizacion, ca_dividendo
      where am_operacion = @w_operacionca
      AND am_operacion = di_operacion
      AND am_dividendo = di_dividendo
      AND di_estado <> 3 -- no cancelados
   END

   select @o_monto_pre = isnull(@o_monto_pre,0)
   RETURN 0
END -- IF @i_operacion = 'C'

IF @i_operacion = 'I'
BEGIN
     -- controlar la fecha de vencimiento del pago para precancelar
   IF datediff(dd, @w_fecha_liq, @i_fecha_proceso) < @w_precancela_dias
       select @w_fecha_ven = dateadd(dd,1, @i_fecha_proceso)
   else
       select @w_fecha_ven = @i_fecha_proceso

   select @o_monto_seg  = 0
   select @o_monto_seg  = se_monto
   from ca_seguro_externo
   where se_operacion = @w_operacionca

   select @o_monto_seg  = isnull(@o_monto_seg, 0)

   select TOP 1
   @w_mail = di_descripcion
   from cobis..cl_direccion
   where di_tipo = 'CE'
   AND di_ente = @i_cliente
   ORDER BY di_direccion
 
   select
   @o_fecha_liq = convert(VARCHAR(10),@w_fecha_liq,103),
   @o_fecha_ven = convert(VARCHAR(10),@w_fecha_ven,103),
   @o_num_abono = (select count(1) from cob_cartera..ca_abono where ab_operacion = @w_operacionca),
   @o_monto_pre = @i_monto_pre,
   @o_nom_oficina = (select of_nombre from cobis..cl_oficina where of_oficina = @w_oficina AND of_filial = 1)

   
   if not exists (select 1 from ca_precancela_refer where pr_operacion = @w_operacionca and pr_cliente = @i_cliente) begin

      if isnull(@i_monto_pre,0) <= 0 return 0
       
	  
	  if @w_toperacion = 'GRUPAL' begin
         select
         @w_grupo      = tg_grupo,
         @w_tramite    = tg_tramite --trámite grupal
         from cob_credito..cr_tramite_grupal
         where tg_operacion = @w_operacionca
         
         if (@@rowcount = 0)
         begin      
             select @w_return = 724637
             goto ERROR
         end
	   end

        
          
       exec @w_secuencial = cob_cartera..sp_gen_sec
           @i_operacion       = @w_operacionca		    
      
       insert into ca_precancela_refer (
       pr_secuencial,     pr_monto_op,      pr_monto_seg,
       pr_operacion,      pr_banco,         pr_cliente,
       pr_monto_pre,      pr_grupo,         pr_tramite_grupal,
       pr_fecha_pro,      pr_fecha_ven,     pr_user,           
       pr_term,           pr_estado,		pr_fecha_liq,	   
       pr_nombre_cl,	  pr_num_abono,     pr_nombre_of,	   
       pr_mail)
       values(
       @w_secuencial,     @o_monto_op,      @o_monto_seg,
       @w_operacionca,    @i_banco,         @i_cliente,
       @i_monto_pre,      @w_grupo,         @w_tramite,
       @i_fecha_proceso,  @w_fecha_ven,     @s_user,           
       @s_term,           'I',     	        @w_fecha_liq,      
       @o_nombre,         @o_num_abono,     @o_nom_oficina,    
       @w_mail)
       
       
       if @@error != 0
       begin
          select @w_return = 70180
          goto ERROR
       end	   
      
   end
   else begin
      select @w_secuencial = pr_secuencial 
      from ca_precancela_refer 
      where pr_operacion = @w_operacionca 
      and pr_cliente = @i_cliente
      
      
      --print '@o_fecha_liq'+convert(varchar,@o_fecha_liq)
      update ca_precancela_refer set 
      pr_monto_pre     = @o_monto_pre,
      pr_monto_op      = @o_monto_op,
      pr_monto_seg     = @o_monto_seg,
      pr_fecha_pro     = @i_fecha_proceso,
      pr_fecha_ven     = @w_fecha_ven,
      pr_fecha_liq     = @w_fecha_liq,
      pr_mail          = @w_mail,
      pr_num_abono     = @o_num_abono
      where pr_operacion = @w_operacionca 
      and pr_cliente = @i_cliente
      	  
      delete ca_precancela_refer_det 
      where prd_secuencial = @w_secuencial
      and   prd_operacion  = @w_operacionca
      and   prd_cliente    = @i_cliente
   end
   
   select @w_id_corresp = 0
   
       
       
   while 1 = 1 begin 
      select top 1
      @w_id_corresp          = co_id,   
      @w_corresponsal        = co_nombre,
      @w_descripcion_corresp = co_descripcion,
      @w_sp_corresponsal     = co_sp_generacion_ref,
      @w_convenio            = co_convenio
      from  ca_corresponsal 
      where co_id            > @w_id_corresp
      and   co_estado        = 'A'
      order by co_id asc
   
      if @@rowcount = 0 break 
      
      exec @w_return    = @w_sp_corresponsal
      @i_tipo_tran      = 'CI',
      @i_id_referencia  = @w_operacionca ,
      @i_monto          = @i_monto_pre,
      @i_monto_desde    = null,
      @i_monto_hasta    = null,
      @i_fecha_lim_pago = @w_fecha_ven,	  
      @o_referencia     = @w_referencia out
      
      
      if @w_return <> 0 begin           
         GOTO ERROR
      end
      
      insert into ca_precancela_refer_det 
      (prd_secuencial, prd_operacion,   prd_cliente, prd_corresponsal, prd_institucion,         prd_referencia, prd_convenio)
      values
      (@w_secuencial,  @w_operacionca,  @i_cliente,    @w_corresponsal,  @w_descripcion_corresp, @w_referencia,   @w_convenio)
      
      

     
   end

   select @o_secuencial = @w_secuencial

   if exists (select 1 from cob_cartera..ca_ns_precancela_refer 
              where npr_codigo = @o_secuencial 
              and npr_operacion = @w_operacionca) begin
          
      if @i_tipo = 1  begin 
          select @w_estado = 'X'
      end 
      else begin
          select @w_estado = 'P'
      end
      update cob_cartera..ca_ns_precancela_refer
      set npr_estado = @w_estado
      where npr_codigo = @o_secuencial 
      and npr_operacion = @w_operacionca	   
   end
   else begin
    insert into cob_cartera..ca_ns_precancela_refer (npr_codigo, npr_operacion, npr_estado)
       values(@o_secuencial, @w_operacionca, 'X')	   
   end


END -- IF @i_operacion = 'I'

RETURN 0

ERROR:
set transaction isolation level read uncommitted

exec cobis..sp_cerror
     @t_from = @w_sp_name,
     @i_num  = @w_return

return @w_return


GO

