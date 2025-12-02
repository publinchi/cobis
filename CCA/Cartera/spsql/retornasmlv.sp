/************************************************************************/
/*      Archivo:                retornasmlv.sp                          */
/*      Stored procedure:       sp_retona_valor_en_smlv                 */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               Cartera                                 */
/*      Disenado por:           E.pelaez                                */
/*      Fecha de escritura:     Abr. 2013                               */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      "MACOSA".                                                       */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                           PROPOSITO                                  */
/*      par unamatriz y unmonto retornar en smlv segun lo parametrizado */
/************************************************************************/
/*                                              MODIFICACIONES          */
/*      FECHA                   AUTOR           RAZON                   */
/************************************************************************/
use cob_cartera
go

set ansi_warnings off
go

if exists (select 1 from sysobjects where name = 'sp_retona_valor_en_smlv')
   drop proc sp_retona_valor_en_smlv
go
---INC 112845
create proc sp_retona_valor_en_smlv
   @i_matriz               catalogo    = NULL,
   @i_monto                money       = 1,
   @i_smv                  money       = 1,
   @o_MontoEnSMLV          float       = NULL out
   as
   declare  @w_desde     money,
            @w_eje        int,
            @w_fecha     datetime,
            @w_mipymes   varchar(10)
   
create table #rangos_smlv(
matriz  catalogo null,
eje     int  null,
rango   tinyint  null,
desde   money  null,
hasta   money  null,
desdeM     money  null,
hastaM     money  null)


select @w_fecha = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

select @w_mipymes = pa_char 
from cobis..cl_parametro with (nolock)
where pa_producto  = 'CCA'
and   pa_nemonico  = 'MIPYME'


select @o_MontoEnSMLV = -1

return 0


select @w_eje = convert(int,c.valor) from cobis..cl_catalogo c
where c.tabla = (select codigo from cobis..cl_tabla 
                  where tabla = 'ca_matriz_smlv')
and codigo = @i_matriz

if @w_eje is null
begin
  --No esta parametrizado
   select @o_MontoEnSMLV = -1
   insert into ca_errorlog
   (er_fecha_proc,     er_error,      er_usuario,
   er_tran,            er_cuenta,     er_descripcion,
   er_anexo)
   values(@w_fecha,   -1,      'matriz',
   7269,               @i_matriz,      'tabla catalogo ca_matriz_smlv',
   'No se Encontro parametrizada la matriz en la tabla de catalogo'   ) 
    
    return 0
end

insert into #rangos_smlv
select er_matriz, er_eje,er_rango ,convert(float,er_rango_desde), convert(float,er_rango_hasta), 0,0
from ca_eje_rango
where er_matriz = @i_matriz
and er_eje = @w_eje


if @i_matriz <> @w_mipymes
begin
	update #rangos_smlv
	set desde = 1
	where desde = 0
end
update #rangos_smlv
set desdeM =  (desde*@i_smv),
    hastaM =   (hasta*@i_smv)
where matriz = @i_matriz
and rango = 1

update #rangos_smlv
set desdeM =  (desde*@i_smv)+1,
    hastaM =   (hasta*@i_smv)
where matriz = @i_matriz
and rango > 1

---select * from #rangos_smlv

select @w_desde = desdeM from #rangos_smlv
where @i_monto between desdeM and hastaM

select @o_MontoEnSMLV = round((@w_desde / @i_smv) + 1,0)

if @o_MontoEnSMLV is null
   select @o_MontoEnSMLV = 0
   
   
return 0
go