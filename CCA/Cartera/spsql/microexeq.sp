/************************************************************************/
/*      Archivo:                microexeq.sp                            */
/*      Stored procedure:       sp_microseguro_exequial                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           Miguel Roa                              */
/*      Fecha de escritura:     Marzo 2008                              */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA'.                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      Calculo cobro microseguro y seguro exequial                     */
/************************************************************************/  
/*                           MODIFICACIONES                             */
/*      FECHA           AUTOR             RAZON                         */
/************************************************************************/  
use cob_cartera
go

if exists(select 1 from sysobjects where name = 'sp_microseguro_exequial')
   drop proc sp_microseguro_exequial
go

create proc sp_microseguro_exequial
@i_operacion    int,
@i_rubro        catalogo,
@o_valor_rubro  money  = 0 out

as
declare 
@w_sp_name              varchar(30),
@w_return               int,
@w_parametro_microseg   catalogo,
@w_parametro_exequial   catalogo,
@w_op_tramite           int,
@w_op_fecha_liq         datetime,
@w_op_moneda            smallint,
@w_op_tplazo            catalogo,
@w_op_plazo             smallint,
@w_plazo_microseg       smallint,
@w_num_dec              smallint,
@w_op_fecha_fin         smalldatetime,
@w_fecha_proceso        datetime,                      -- REQ 184 - COMPLEMENTO REPOSITORIO - GAL 14/DIC/2010
@w_valor                money,
@w_user                 login,
@w_plazo_meses          int,
@w_dias_per             int

select @o_valor_rubro = 0


/* INICIALIZACION VARIABLES */
select 
    @w_sp_name        = 'sp_microseguro_exequial'

select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

select @w_user = 'cartera'


--LECTURA DEL PARAMETRO SEGURO MICROSEGURO
select @w_parametro_microseg = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'MICSEG'
set transaction isolation level read uncommitted

--LECTURA DEL PARAMETRO SEGURO EXEQUIAL
select @w_parametro_exequial = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'EXEQUI'
set transaction isolation level read uncommitted

/*OBTENER DATOS DE LA OPERACION */
select @w_op_tramite    = op_tramite,
       @w_op_moneda     = op_moneda,
       @w_op_fecha_liq  = op_fecha_liq,
       @w_op_tplazo     = op_tplazo,
       @w_op_fecha_fin  = op_fecha_fin,
       @w_op_plazo      = op_plazo
from   ca_operacion
where  op_operacion = @i_operacion

/* NUMERO DE DECIMALES */
exec @w_return      = sp_decimales
     @i_moneda      = @w_op_moneda,
     @o_decimales   = @w_num_dec out

if @w_return != 0 return  @w_return


/*MROA: OBTENER VALOR DE MICROSEGURO Y SEGURO EXEQUIAL CALCULADO EN TRAMITES */
if @i_rubro = @w_parametro_microseg
begin
   
   select @w_dias_per = pe_factor
   from cob_credito..cr_periodo
   where pe_periodo = @w_op_tplazo
   
   select @w_plazo_meses = (@w_op_plazo * @w_dias_per) / 30  -- PLAZO EN MESES

   --Ejecutar sp para calcular el valor del microseguro 
   exec @w_return = sp_valor_microseg
   @s_date         = @w_fecha_proceso,
   @s_user         = @w_user,
   @i_tramite      = @w_op_tramite,
   @i_plazo_meses  = @w_plazo_meses,
   @o_valor        = @w_valor out

   if @w_return <> 0
      return @w_return

   select @o_valor_rubro = @w_valor

end

if @i_rubro = @w_parametro_exequial
begin
    select @o_valor_rubro = se_val_total 
    from cob_credito..cr_seguro_exequial
    where se_tramite = @w_op_tramite
    and   se_estado  = 'P' --JJMD 22/Ene/2010 Inc. 1611 Se obrendrá el valor solo para no anulados
    if @@rowcount = 0
       select @o_valor_rubro = 0
    else      
        update cob_credito..cr_seguro_exequial
        set se_fecha_ini = @w_op_fecha_liq,
            se_fecha_fin = @w_op_fecha_fin
        where se_tramite = @w_op_tramite
          
end

/* VALOR REDONDEADO DEL RUBRO MICROSEGURO O SEGURO EXEQUIAL */
select @o_valor_rubro = round((@o_valor_rubro), @w_num_dec)


return 0

go