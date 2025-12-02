/************************************************************************/
/*   Stored procedure:     sp_cartas_desembolso                         */
/*   Base de datos:        cob_cartera                                  */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'                                                           */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/
/*                            PROPOSITO                                 */
/*   06OCT2008    SALBAN      Cartas del desembolso                     */
/*   08MAY2014  Luis Moreno   CCA 406 SEGDEUEM                          */
/************************************************************************/
 
use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_cartas_desembolso')
   drop proc sp_cartas_desembolso
go
 
---LLS48545 FEB.24.2012
create proc sp_cartas_desembolso(
@i_banco           varchar(15),
@i_operacion       char(1)
)
as 
declare
@w_today             datetime,
@w_msg               varchar (255),
@w_sp_name           varchar (24),
@w_error             int, 
@w_monto             money,
@w_comision          float,
@w_tasa              float,
@w_tasa_mora         float,
@w_cuota_sin_seg     float,
@w_plazo             smallint,
@w_seguro            money,
@w_operacion         int,
@w_ente              int,
@w_nombre            varchar(35),
@w_tipo_ced          varchar(3),
@w_subtipo           char(1),
@w_ced               numero,
@w_tipodoc           varchar(25),
@w_p_lugar_doc       int,
@w_ci_descripcion    descripcion,
@w_ano               char(4),
@w_fecha_ult_p       smalldatetime,
@w_oficina_op        smallint,
@w_cliente_nuevo     char(1),
@w_monto_parametro   float,
@w_op_monto          money,
@w_mipymes           varchar(10),
@w_SMV               money,
@w_parametro_fng     catalogo,
@w_ivafng            catalogo,
@w_cuota             float,
@w_cuota_fng         float,
@w_cuota_ivafng      float,
@w_tplazo            varchar(60),
@w_cliente_rl        int


select  @w_sp_name = 'sp_cartas_desembolso'


select 
@w_monto          = op_monto,
@w_plazo          = op_plazo,
@w_tplazo         = td_descripcion,
@w_operacion      = op_operacion,
@w_ente           = op_cliente,
@w_nombre         = op_nombre,
@w_fecha_ult_p    = op_fecha_ult_proceso,
@w_oficina_op     = op_oficina
from ca_operacion, ca_tdividendo
where op_banco  = @i_banco
and   op_tplazo = td_tdividendo
   
if exists(select 1 from cobis..cl_ente where en_ente = @w_ente and en_subtipo = 'C') begin

   select @w_cliente_rl = in_ente_i
   from cobis..cl_instancia
   where in_relacion = 205   --Representante Legal
   and   in_lado     = 'I'
   and   in_ente_d   = @w_ente

   select @w_nombre = en_nombre  + ' ' + p_p_apellido + ' ' + p_s_apellido
   from cobis..cl_ente 
   where en_ente = @w_cliente_rl

end

if @i_operacion = 'D'
begin 

   select @w_tasa  = isnull(ro_porcentaje_efa,0)
   from   cob_cartera..ca_rubro_op
   where  ro_operacion = @w_operacion 
   and    ro_concepto  ='INT '
   
   select @w_SMV       = pa_money 
   from   cobis..cl_parametro
   where  pa_producto  = 'ADM'
   and    pa_nemonico  = 'SMV'

   select @w_mipymes = pa_char 
   from   cobis..cl_parametro
   where  pa_producto  = 'CCA'
   and    pa_nemonico  = 'MIPYME'
   
   
   /*PARAMETRO DE LA GARANTIA DE FNG*/
   select @w_parametro_fng = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'COMFNG'
   
   
   /*PARAMETRO IVA DE LA GARANTIA DE FNG*/
   select @w_ivafng = pa_char
   from   cobis..cl_parametro
   where  pa_producto = 'CCA'
   and    pa_nemonico = 'IVAFNG'   
   
   select @w_monto_parametro  = @w_monto/@w_SMV
   
   if exists (select 1 from ca_operacion 
      where op_cliente = @w_ente
      and   op_estado  in (0,1,2,3,4,5,9,99)
      and   op_operacion <> @w_operacion)
         select @w_cliente_nuevo = 'R'     --R: Renovado
      else         
         select @w_cliente_nuevo = 'N'     --N: new
   
   exec @w_error  = sp_matriz_valor
   @i_matriz      = @w_mipymes,      
   @i_fecha_vig   = @w_fecha_ult_p,  
   @i_eje1        = @w_oficina_op,   
   @i_eje2        = @w_monto_parametro,     
   @i_eje3        = @w_cliente_nuevo,
   @o_valor       = @w_comision out, 
   @o_msg         = @w_msg    out 
          
   if @w_error <> 0  
      return @w_error

   select @w_seguro = isnull(sum(am_cuota) ,0)
   from ca_amortizacion
   where am_operacion = @w_operacion
   and   am_dividendo = 2    
   and   am_concepto  in ('SEGDEUVEN','SEGDEUANT','SEGDEUEM')


   select @w_tasa_mora = ro_porcentaje 
   from   cob_cartera..ca_rubro_op
   where  ro_operacion = @w_operacion
   and    ro_concepto = 'IMO' 

   select @w_cuota = isnull(sum(am_cuota) ,0) 
   from ca_amortizacion
   where  am_concepto not in (
   select co_concepto 
   from   cob_cartera..ca_concepto
   where  co_categoria = 'S')
   and    am_dividendo = 2
   and    am_operacion = @w_operacion
   
   --COMISION FNG
   
   select @w_cuota_fng = isnull(convert(float,sum(am_cuota + am_gracia)),0)
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacion
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   = 2
   and ro_concepto    = @w_parametro_fng
    
   --IVA COMISION FNG    

   select @w_cuota_ivafng = isnull(convert(float,sum(am_cuota + am_gracia)),0)   
   from ca_amortizacion,ca_rubro_op
   where ro_operacion = @w_operacion
   and am_operacion   = ro_operacion
   and am_concepto    = ro_concepto
   and ro_tipo_rubro  not in ('C', 'I')
   and am_dividendo   = 2
   and ro_concepto    = @w_ivafng
   
   
   select @w_cuota_sin_seg = @w_cuota - (@w_cuota_fng + @w_cuota_ivafng)
   
   select 
   substring(@w_nombre,1,40),
   @w_monto,
   @w_plazo,
   @w_tasa,
   @w_tasa_mora,
   @w_comision,
   @w_seguro,
   convert(money,@w_cuota_sin_seg),
   @w_tplazo

end

if @i_operacion = 'N'
begin 
   select 
   @w_ced         = en_ced_ruc,
   @w_tipo_ced    = en_tipo_ced,
   @w_subtipo     = en_subtipo,
   @w_p_lugar_doc = p_lugar_doc 
   from   cobis..cl_ente 
   where  en_ente  = @w_ente

   --Datos Representante Legal si es Juridico
   if exists(select 1 from cobis..cl_ente where en_ente = @w_ente and en_subtipo = 'C') begin

      select @w_cliente_rl = in_ente_i
      from cobis..cl_instancia
      where in_relacion = 205   --Representante Legal
      and   in_lado     = 'I'
      and   in_ente_d   = @w_ente

      select
      @w_ced         = en_ced_ruc,
      @w_tipo_ced    = en_tipo_ced,
      @w_subtipo     = en_subtipo,
      @w_p_lugar_doc = p_lugar_doc 
      from cobis..cl_ente 
      where en_ente = @w_cliente_rl
   end

   select @w_tipodoc = td_descripcion
   from   cobis..cl_tipo_documento
   where  td_codigo  = @w_tipo_ced
   and    td_tipoper = @w_subtipo --td_subtipo = @w_subtipo
   and    td_estado  = 'V'

   select @w_ci_descripcion = ci_descripcion
   from   cobis..cl_ciudad 
   where  ci_ciudad = @w_p_lugar_doc  

   select @w_ano = convert(char(4),datepart(yyyy,dateadd(yy, -1,getdate())))

   select 
   isnull(@w_nombre,'') ,
   @w_tipodoc ,
   @w_ced ,
   @w_ci_descripcion ,
   @w_ano 

end


return 0


GO

