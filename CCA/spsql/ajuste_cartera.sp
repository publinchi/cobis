
/*ajusopera.sp***********************************************************/
/*   Stored procedure:     sp_ajuste_operativo_cont                     */
/*   Base de datos:        cob_conta_super                              */
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
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_ajuste_operativo_cont')
   drop proc sp_ajuste_operativo_cont
go

create procedure sp_ajuste_operativo_cont (
@i_param1   varchar(255),        --FECHA
@i_param2   varchar(255),        --PRODUCTO
@i_param3   varchar(255),        --EMPRESA
@i_param4   varchar(255),        --BATCH
@i_param5   varchar(255) = null, --CONCEPTO
@i_param6   varchar(255) = 'S',  --SOLO COMPENSADAS
@i_param7   varchar(255) = null  -- CLIENTE

)
as 


/* GENERACION DE DATOS PARA AJUSTAR EL SALDO DE LOS CONCEPTOS QUE CAUSAN */

declare 
@w_cont         int,
@w_contador     int,
@w_oficina      smallint,
@w_contofi      int,
@w_rowcount     int,
@w_error        int,
@w_fecha        datetime,
@w_producto     int,
@w_concepto     varchar(255),
@w_sp           varchar(255),
@w_area         int,
@w_msg          varchar(255),
@w_empresa      int,
@w_cliente      int,
@w_comprobante  int,
@w_asientos     int,
@w_perfil_ajus  catalogo,
@w_tot_debito   money,
@w_tot_credito  money,
@w_batch        int,
@w_area_cart    catalogo,
@w_compensados  char(1),
@w_aprobado     char(1)

select @w_sp  = 'sp_ajuste_operativo_cont'
select @w_msg = null
select @w_aprobado = 'N'

select @w_fecha        = convert(datetime, @i_param1)
select @w_producto     = convert(int, @i_param2)
select @w_empresa      = convert(int, @i_param3)
select @w_batch        = convert(int, @i_param4)
select @w_concepto     = convert(varchar, @i_param5)
select @w_compensados  = convert(char(1), @i_param6)
select @w_cliente      = convert(int, @i_param7)
/*
select @w_aprobado = pa_char
from cobis..cl_parametro
where pa_producto = 'CCA'
and   pa_nemonico = 'AEPAC'

if @w_aprobado = 'N' begin
   if @w_compensados <> 'S' begin
      print 'SOLO ES PERMITIDO EJECUTAR CON OPCION COMPENSADOS S'
      return 1
   end
end

if @w_concepto is null  select @w_concepto = 'RECLASIFICACION DE CARTERA POR CALIFICACION'

select @w_perfil_ajus = 'AJUS_CAR'

-- PARAMETRO AREA AJUSTES CARTERA
select @w_area_cart = pa_char
from   cobis..cl_parametro with (nolock)
where  pa_nemonico = 'CTB_OF'
and    pa_producto = 'CCA'

select @w_area = ta_area
from cob_conta..cb_tipo_area
where ta_producto = @w_producto
and   ta_tiparea  = @w_area_cart

if @@rowcount = 0 begin
   select 
   @w_msg     = ' ERR NO DEFINIDA AREA DE CARTERA ' ,
   @w_error   = 708176
   goto ERRORFIN
end

create table #asientos(
Codcta         varchar(20)	not null,
oficina    int		    not null,
valorcred      money        not null,
valordeb       money        not null,
Concepto_ret   varchar(4)	not null,
Base_ret       money		not null,
ente           int          not null,
partida        char(1)      not null
)


select *
into #boc
from cob_conta..cb_boc
where bo_producto   = @w_producto
--and   bo_cliente    =  isnull(@w_cliente,bo_cliente)  AGI COMENTADO PORQUE NO EXISTE EL CAMPO bo_cliente EN LA TABLA cob_conta..cb_boc
--and   bo_diferencia <> 0  AGI COMENTADO PORQUE NO EXISTE EL CAMPO bo_diferencia EN LA TABLA cob_conta..cb_boc

--AGI COMENTADO PORQUE NO EXISTE EL CAMPO bo_cliente, bo_diferencia EN LA TABLA cob_conta..cb_boc

if @w_compensados = 'S' begin

   select 
   cliente    = bo_cliente, 
   diferencia = sum(bo_diferencia)
   into #clientes_descuadrados
   from #boc
   group by bo_cliente
   having sum(bo_diferencia) <> 0
   
   delete #boc
   from #clientes_descuadrados
   where bo_cliente = cliente

end


--GRUPO 1 (AJUSTES NORMALES AL 100% )
insert into #asientos
select 
Codcta         = ca_cta_asoc,
oficina        = bo_oficina,
valorcred      = case when ca_debcred = 'C' and bo_diferencia > 0 then round(bo_diferencia, 2) when ca_debcred = 'D' and bo_diferencia < 0 then round(abs(bo_diferencia), 2) else 0 end,
valordeb       = case when ca_debcred = 'D' and bo_diferencia > 0 then round(bo_diferencia, 2) when ca_debcred = 'C' and bo_diferencia < 0 then round(abs(bo_diferencia), 2) else 0 end,
Concepto_ret   = '', 
Base_ret       = 0,  
ente           = bo_cliente,
partida        = case when ca_cta_asoc = bo_cuenta then 'S' else 'N' end
from #boc, cob_conta..cb_cuenta_proceso, cob_conta..cb_cuenta_asociada
where bo_cuenta     = ca_cuenta
and   cp_proceso    = ca_proceso
and   cp_cuenta     = ca_cuenta
and   cp_area       = ca_area
and   cp_oficina    = ca_oficina
and   cp_area       = 0
and   cp_proceso    = @w_batch
order by bo_oficina, bo_cliente, ca_cuenta



--GRUPO 2  (AJUSTES AL 16% )
insert into #asientos
select 
Codcta         = ca_cta_asoc,
oficina        = bo_oficina,
valorcred      = case when ca_debcred = 'C' and ((bo_diferencia*16)/116.0) > 0 then round(((bo_diferencia*16)/116.0), 2) when ca_debcred = 'D' and ((bo_diferencia*16)/116.0) < 0 then round(abs(((bo_diferencia*16)/116.0)), 2) else 0 end,
valordeb       = case when ca_debcred = 'D' and ((bo_diferencia*16)/116.0) > 0 then round(((bo_diferencia*16)/116.0), 2) when ca_debcred = 'C' and ((bo_diferencia*16)/116.0) < 0 then round(abs(((bo_diferencia*16)/116.0)), 2) else 0 end,
Concepto_ret   = '0281', 
Base_ret       = ((bo_diferencia*100)/116.0),
ente           = bo_cliente,
partida        = case when ca_cta_asoc = bo_cuenta then 'S' else 'N' end
from #boc, cob_conta..cb_cuenta_proceso, cob_conta..cb_cuenta_asociada
where bo_cuenta     = ca_cuenta
and   cp_proceso    = ca_proceso
and   cp_cuenta     = ca_cuenta
and   cp_area       = ca_area
and   cp_oficina    = ca_oficina
and   cp_area       = 1
and   cp_proceso    = @w_batch
order by bo_oficina, bo_cliente, ca_cuenta



--GRUPO 3 (AJUSTES AL 84%)
insert into #asientos
select 
Codcta         = ca_cta_asoc,
oficina        = bo_oficina,
valorcred      = case when ca_debcred = 'C' and ((bo_diferencia*100)/116.0) > 0 then round(((bo_diferencia*100)/116.0), 2) when ca_debcred = 'D' and ((bo_diferencia*100)/116.0) < 0 then round(abs(((bo_diferencia*100)/116.0)), 2) else 0 end,
valordeb       = case when ca_debcred = 'D' and ((bo_diferencia*100)/116.0) > 0 then round(((bo_diferencia*100)/116.0), 2) when ca_debcred = 'C' and ((bo_diferencia*100)/116.0) < 0 then round(abs(((bo_diferencia*100)/116.0)), 2) else 0 end,
Concepto_ret   = '', 
Base_ret       = 0,
ente           = bo_cliente,
partida        = case when ca_cta_asoc = bo_cuenta then 'S' else 'N' end
from #boc, cob_conta..cb_cuenta_proceso, cob_conta..cb_cuenta_asociada
where bo_cuenta     = ca_cuenta
and   cp_proceso    = ca_proceso
and   cp_cuenta     = ca_cuenta
and   cp_area       = ca_area
and   cp_oficina    = ca_oficina
and   cp_area       = 2
and   cp_proceso    = @w_batch
order by bo_oficina, bo_cliente, ca_cuenta


create index idx1 on #asientos(ente)


-- CONTABILIDAD 


-------ELIMINAR LOS COMPROBANTES Y ASIENTOS TEMPORALES DEL PRODUCTO 

if @w_cliente is null begin

   delete cob_conta_tercero..ct_scomprobante_tmp
   where sc_fecha_tran   = @w_fecha
   and   sc_producto     = @w_producto
   and   sc_empresa      = @w_empresa
   and   sc_descripcion  = @w_concepto
   
   if @@error <> 0 begin
      select 
      @w_error = 710002,
      @w_msg   = 'ERROR AL ELIMINAR LOS COMPROBANTES TEMPORALES DE CONTABILIDAD --> ' + @w_concepto
      goto ERRORFIN
   end
   
   
   delete cob_conta_tercero..ct_sasiento_tmp
   where sa_fecha_tran = @w_fecha
   and   sa_producto   = @w_producto
   and   sa_empresa    = @w_empresa
   and   sa_concepto   = @w_concepto
   
   if @@error <> 0 begin
      select 
      @w_error = 710002,
      @w_msg   = 'ERROR AL ELIMINAR LOS ASIENTOS TEMPORALES DE CONTABILIDAD --> ' + @w_concepto
      goto ERRORFIN
   end
   
end else begin

   delete cob_conta_tercero..ct_scomprobante_tmp
   from cob_conta_tercero..ct_sasiento_tmp
   where sc_fecha_tran   = @w_fecha
   and   sc_producto     = @w_producto
   and   sc_empresa      = @w_empresa
   and   sc_descripcion  = @w_concepto
   and   sa_comprobante  = sc_comprobante
   and   sa_fecha_tran   = sc_fecha_tran
   and   sa_producto     = sc_producto 
   and   sa_ente         = @w_cliente
   
   if @@error <> 0 begin
      select 
      @w_error = 710002,
      @w_msg   = 'ERROR AL ELIMINAR LOS COMPROBANTES TEMPORALES DE CONTABILIDAD --> ' + @w_concepto
      goto ERRORFIN
   end
   
   
   delete cob_conta_tercero..ct_sasiento_tmp
   where sa_fecha_tran = @w_fecha
   and   sa_producto   = @w_producto
   and   sa_empresa    = @w_empresa
   and   sa_concepto   = @w_concepto
   and   sa_ente       = @w_cliente
   
   if @@error <> 0 begin
      select 
      @w_error = 710002,
      @w_msg   = 'ERROR AL ELIMINAR LOS ASIENTOS TEMPORALES DE CONTABILIDAD --> ' + @w_concepto
      goto ERRORFIN
   end
end   

--DETERMINAR POR CADA CLIENTE LA OFICINA DONDE CONTABILIZAR LAS CONTRAPARTIDAS 
select 
cliente = ente,
max_ofi = max(oficina)
into #clientes
from #asientos
group by ente

--AJUSTAR LA OFICINA DE LA CONTRAPARTIDA 
update #asientos set
oficina = max_ofi
from #clientes
where ente = cliente
and   partida = 'N'


select @w_cont    = -1
select @w_cliente = 0

while @w_cont < 99 begin	

   select @w_cont = @w_cont + 1

   create table #asientos_ajuste_p(
   codasiento1     int           identity,              -- PARA GENERAR EL NUMERO DE SECUENCIAL DEL ASIENTO POR OFICINA
   Codcta1         varchar(20)   not null,
   oficina         int	         not null,
   valordeb1       money         not null,
   Concepto_ret1   varchar(4)    not null,
   Base_ret1       money	     not null,
   ente            int           not null)

   --REGISTRAR LAS PARTIDAS 
   insert into #asientos_ajuste_p
   select 
   Codcta1         = Codcta,
   oficina	       = oficina,
   valordeb1       = round(sum(isnull(valordeb,0)-isnull(valorcred,0)), 2),
   Concepto_ret1   = Concepto_ret,
   Base_ret1	   = round(Base_ret, 2),
   ente            = ente
   from #asientos with (index = idx1)
   where (valorcred > 0 or valordeb > 0)
   and   ente % 100 = @w_cont
   and   partida    = 'S'
   group by Codcta, oficina, Concepto_ret, Base_ret, ente
   having abs(sum(isnull(valordeb,0)-isnull(valorcred,0))) <> 0
   
   if @@rowcount = 0 goto SIGUIENTE  --continuar con el siguiente grupo si no hay partidas

   --REGISTRAR LAS CONTRAPARTIDAS 
   insert into #asientos_ajuste_p
   select 
   Codcta1         = Codcta,
   oficina	       = oficina,
   valordeb1       = round(sum(isnull(valordeb,0)-isnull(valorcred,0)), 2),
   Concepto_ret1   = Concepto_ret,
   Base_ret1	   = round(Base_ret, 2),
   ente            = ente
   from #asientos with (index = idx1)
   where (valorcred > 0 or valordeb > 0)
   and   ente % 100 = @w_cont
   and   partida    = 'N'
   group by Codcta, oficina, Concepto_ret, Base_ret, ente
   having abs(sum(isnull(valordeb,0)-isnull(valorcred,0))) <> 0

   --OBTENER EL NUMERO DE COMPROBANTE 
   exec @w_error = cob_conta..sp_cseqcomp
   @i_tabla     = 'cb_scomprobante', 
   @i_empresa   = @w_empresa,
   @i_fecha     = @w_fecha,
   @i_modulo    = @w_producto,
   @i_modo      = 0,         -- Numera por EMPRESA-FECHA-PRODUCTO
   @o_siguiente = @w_comprobante out


   if @w_error <> 0 begin
      select 
      @w_msg = ' ERROR AL GENERAR NUMERO COMPROBANTE ' 
      goto ERRORFIN
   end

   --REGISTRAR PARTIDA 
   insert into cob_conta_tercero..ct_sasiento_tmp with (rowlock) (                                                                                                                                              
   sa_producto,        sa_fecha_tran,      sa_comprobante,
   sa_empresa,         sa_asiento,         sa_cuenta,
   sa_oficina_dest,    sa_area_dest,       sa_debito,
   sa_concepto,        sa_credito_me,      sa_credito,          
   sa_debito_me,       sa_cotizacion,      sa_tipo_doc,
   sa_tipo_tran,       sa_moneda,          sa_opcion,
   sa_ente,            sa_con_rete,        sa_base,
   sa_valret,          sa_con_iva,         sa_valor_iva,
   sa_iva_retenido,    sa_con_ica,         sa_valor_ica,
   sa_con_timbre,      sa_valor_timbre,    sa_con_iva_reten,
   sa_con_ivapagado,   sa_valor_ivapagado, sa_documento,
   sa_mayorizado,      sa_con_dptales,     sa_valor_dptales,
   sa_posicion,        sa_oper_banco,      sa_debcred,         
   sa_cheque,          sa_doc_banco,       sa_fecha_est, 
   sa_detalle,         sa_error )
   select
   @w_producto,        @w_fecha,           @w_comprobante,
   @w_empresa,         codasiento1,        Codcta1,
   oficina,            @w_area,            case when valordeb1>0 then round(abs(valordeb1),2) else 0 end, --debito
   @w_concepto,        0.00,               case when valordeb1<0 then round(abs(valordeb1),2) else 0 end, --credito
   0.00,               1.00,              'N',
   'A',                0,                  0,
   ente,               null,               0.00,
   null,               'N',                0.00,
   null,               null,               null,
   null,               null,               null,
   null,               null,               '',
   'N',                null,               null,
   'S',                null,               case when valordeb1>0 then '1' else '2' end,      
   null,               null,               null,
   null,               'N' 
   from #asientos_ajuste_p

   if @@error <> 0 begin
      select 
      @w_error = 710001,
      @w_msg   = 'ERROR AL REGISTRAR LA PARTIDA EN LA TABLA ct_sasiento' 
      goto ERRORFIN
   end

   select
   @w_oficina     = max(sa_oficina_dest),
   @w_asientos    = max(sa_asiento),
   @w_tot_debito  = round(sum(sa_debito), 2),
   @w_tot_credito = round(sum(sa_credito), 2)
   from cob_conta_tercero..ct_sasiento_tmp
   where sa_comprobante = @w_comprobante
   and   sa_fecha_tran  = @w_fecha
   and   sa_producto    = @w_producto

   insert into cob_conta_tercero..ct_scomprobante_tmp with (rowlock) (
   sc_producto,       sc_comprobante,   sc_empresa,
   sc_fecha_tran,     sc_oficina_orig,  sc_area_orig,
   sc_digitador,      sc_descripcion,   sc_fecha_gra,      
   sc_perfil,         sc_detalles,      sc_tot_debito,
   sc_tot_credito,    sc_tot_debito_me, sc_tot_credito_me,
   sc_automatico,     sc_reversado,     sc_estado,
   sc_mayorizado,     sc_observaciones, sc_comp_definit,
   sc_usuario_modulo, sc_tran_modulo,   sc_error)
   values (
   @w_producto,       @w_comprobante,   @w_empresa,
   @w_fecha,          @w_oficina,       @w_area,
   'sa',              @w_concepto,      convert(char(10),getdate(),101),     
   @w_perfil_ajus,    @w_asientos,      @w_tot_debito,
   @w_tot_credito,    0.00,             0.00,
   @w_producto,       'N',              'I',
   'N',               null,             null,
   'sa',              0,                'N')
     
   if @@error !=0 begin
      select 
      @w_error = 710001,
      @w_msg   = 'ERROR AL INGRESAR EL COMPROBANTE (ct_scomprobante)'
      goto ERRORFIN
   end  
   
   SIGUIENTE:  

   drop table #asientos_ajuste_p

end  --while 1 = 1

*/
return 0

ERRORFIN:

print @w_msg

return @w_error

 
go

