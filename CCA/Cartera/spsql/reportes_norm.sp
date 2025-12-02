/************************************************************************/
/*      Archivo:                reportes_norm.sp                        */
/*      Stored procedure:       sp_reportes_norm                        */
/*      Base de datos:          cob_cartera                             */
/*      Producto:               COBIS-CARTERA                           */
/*      Disenado por:           Elcira Pelaez B.                        */
/*      Fecha de escritura:     Dic..2014                               */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'MACOSA', representantes  exclusivos  para el  Ecuador  de la   */
/*      'NCR CORPORATION'.                                              */
/*      Su  uso no autorizado  queda expresamente  prohibido asi como   */
/*      cualquier   alteracion  o  agregado  hecho por  alguno de sus   */
/*      usuarios   sin el debido  consentimiento  por  escrito  de la   */
/*      Presidencia Ejecutiva de MACOSA o su representante.             */
/*                              PROPOSITO                               */
/*      Este programa procesa las transacciones del store procedure     */
/*      Insercion de parametrizacion centrales de riesgo                */
/*      Modificacion de parametrizacion centrales de riesgo             */
/*      Busqueda de parametrizacion centrales de riesgo                 */
/************************************************************************/
/*                                PROPOSITO                             */
/* Normalizacion de Cartera - REportes frot-End                         */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*      03/12/2014      E.Pelaez        Emision Inicial                 */
/************************************************************************/
use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_reportes_norm')
   drop proc sp_reportes_norm
go

create proc sp_reportes_norm(
   @s_user           login        = null,
   @i_tipo_norm      int          = null, --TIPO NORMALIZACION (1,2,3)
   @i_banco          cuenta       = null,
   @i_tramite        int          = null

)
as

declare @w_operacionca    int,
        @w_error          int,
        @w_sp_name        varchar(32),
        @w_msg            varchar(132),
        @w_tramite        int,
        @w_cuota          int,
        @w_fecha_prorroga varchar(10),
        @w_tipo_norm      int,
        @w_banco          varchar(24),
        @w_tram_oper      int,
        @w_pend_orden     char(1),
        @w_oper           int,
        @w_monto             money,
        @w_bancos_1          varchar(50),
        @w_reg               tinyint,
        @w_fecha_cca         datetime,
        @w_parametro_cta_pte catalogo,
        @w_monto_desem       money,
        @w_nombre_deudor     varchar(65),
        @w_tipo_ced          char(2),
        @w_ced_ruc           varchar(30),
        ---par el reporte
        @w_tipo_normalizacion       char(1),    
        @w_nombre_titular           varchar(64),
        @w_tipoDoc_titular          varchar(2), 
        @w_ced_ruc_titular          varchar(30),
        @w_nombre_codeudor          varchar(64),
        @w_tipoDoc_codeudor         varchar(2), 
        @w_ced_ruc_codeudor         varchar(30),
        @w_ciudad                   varchar(64),
        @w_fecha                    varchar(15),
        @w_cod_oficina              int ,  
        @w_nombre_oficina           varchar(64),
        @w_nro_operacion1           varchar(20),
        @w_nro_operacion2           varchar(20),
        @w_nro_operacion3           varchar(20),
        @w_nro_operacion_new        varchar(20),
        @w_saldo_new_operacion      money,
        @w_tipo_amor_newOp          varchar(15),
        @w_fecha_ven_new_oper       varchar(15),
        @w_tasa_efa_new_oper        float,      
        @w_monto_desembolsado       money ,
        @w_new_fecha_ven            datetime,
        @w_fecVen_antes_pro         datetime,
        @w_sec_prorroga             int,
        @w_fecha_prorroga1          varchar(15),
        @w_fecha_prorroga2          varchar(15)
        


                 
        
select @w_sp_name = 'sp_reportes_norm'

select @w_fecha_cca = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7

---  OBTIENE DATOS DE LA OPERACION 
select @w_operacionca = op_operacion,
       @w_tramite     = op_tramite
from ca_operacion
where op_banco = @i_banco

---INICIALIZA LA TABLA DE RABAJO
delete ca_formatos_normalizacion_cca
where tipo_normalizacion = @i_tipo_norm
  

insert into ca_formatos_normalizacion_cca
    (  usuario,  tramite,
       tipo_normalizacion,   nombre_titular,   tipoDoc_titular,          ced_ruc_titular,
       nombre_codeudor,    tipoDoc_codeudor,   ced_ruc_codeudor,                 ciudad,
       fecha,                   cod_oficina,   nombre_oficina,           nro_operacion1,
       nro_operacion2,       nro_operacion3,   nro_operacion_new,    saldo_new_operacion,
       tipo_amor_newOp,  fecha_ven_new_oper,   tasa_efa_new_oper,    monto_desembolsado,
       fecha_ven_antesPro,   fecha_ven_despPro)
select  @s_user,  @w_tramite,
        @i_tipo_norm ,            en_nomlar,          en_tipo_ced,             en_ced_ruc,
        null,                         null,               null,           ci_descripcion,
        @w_fecha_cca,           op_oficina,           of_nombre,                    null,
        null,                         null,            op_banco,                op_monto,
        op_tipo_amortizacion,  op_fecha_fin,  ro_porcentaje_efa,                    null,
        null,                          null
from cob_cartera..ca_operacion,
     cob_cartera..ca_rubro_op,
     cobis..cl_ente,
     cobis..cl_oficina,
     cobis..cl_ciudad
where op_tramite = @w_tramite
and   op_operacion = ro_operacion
and   ro_concepto ='INT'
and   op_cliente = en_ente
and   op_oficina = of_oficina
and   op_ciudad = ci_ciudad              
   
if  @i_tipo_norm in (2,3)
begin
   select  'banco'  = t.nm_operacion,
         'oper'   = op_operacion
   into #oper              
   from   cob_credito..cr_normalizacion t,
          cob_cartera..ca_operacion,
          cob_cartera..ca_normalizacion  c
   where  t.nm_tipo_norm = @i_tipo_norm
   and  c.nm_tramite = @w_tramite
   and  t.nm_operacion = op_banco
   and   t.nm_tramite = c.nm_tramite
   and   c.nm_estado = 'A'
   
  
   select @w_oper = 0,
          @w_reg = 0
   while 1 = 1
   begin
          set rowcount 1
          select @w_oper = oper,
                 @w_banco = banco
          from #oper
          where oper > @w_oper
          order by oper
   
          if @@rowcount = 0 begin
            set rowcount 0
            break
          end
          
          select @w_reg = @w_reg + 1
          
          if @w_reg = 1
             update ca_formatos_normalizacion_cca
             set  nro_operacion1 = @w_banco
             where tramite = @w_tramite
             
          if @w_reg = 2
             update ca_formatos_normalizacion_cca
             set  nro_operacion2 = @w_banco
             where tramite = @w_tramite
             
          if @w_reg = 3
             update ca_formatos_normalizacion_cca
             set  nro_operacion3 = @w_banco
             where tramite = @w_tramite
             
      set rowcount 0
   end 
end
ELSE
begin
    update ca_formatos_normalizacion_cca
    set  nro_operacion1 = @i_banco
    where tramite = @w_tramite

end

select @w_monto_desem = 0.00
if @i_tipo_norm   = 3 ---REFINANCIACION
begin      
   ---VAlor desembolsado al cliente
   select @w_parametro_cta_pte = pa_char
   from   cobis..cl_parametro
   where  pa_nemonico = 'PTENOR'
   and    pa_producto = 'CCA'
   
   select @w_monto_desem = isnull(sum(dm_monto_mop),0)
    from ca_desembolso
   where dm_operacion  = @w_operacionca
   and dm_producto <>  @w_parametro_cta_pte 
end
else
begin
   select @w_monto_desem = 0.00
end
            
if @i_tipo_norm   = 1 ---PRORROGA
begin      
    ---DATOS DE A FECHA PRORROGADA
   select  @w_new_fecha_ven    = nm_fecha_pro_despues,
           @w_fecVen_antes_pro = nm_fecha_pro_antes
   from ca_normalizacion 
   where nm_tramite = @i_tramite
   
   update ca_formatos_normalizacion_cca
   set fecha_ven_antesPro     = @w_fecVen_antes_pro,
       fecha_ven_despPro      = @w_new_fecha_ven
   where  tramite = @w_tramite
   
end


---datos codeudor 
set rowcount 1
select @w_nombre_deudor = en_nomlar,
       @w_tipo_ced      = en_tipo_ced,
       @w_ced_ruc       = en_ced_ruc
from cobis..cl_ente,cob_credito..cr_deudores
where en_ente =  de_cliente
and   de_tramite = @w_tramite
and   de_rol = 'C'
set rowcount 0

update ca_formatos_normalizacion_cca
set nombre_codeudor    = @w_nombre_deudor,
    tipoDoc_codeudor   = @w_tipo_ced,
    ced_ruc_codeudor   = @w_ced_ruc,
    monto_desembolsado = @w_monto_desem
where  tramite = @w_tramite
      

--datos para el reporte         
select 
@w_tipo_normalizacion =   tipo_normalizacion, 
@w_nombre_titular     =   nombre_titular,     
@w_tipoDoc_titular    =   tipoDoc_titular,    
@w_ced_ruc_titular    =   ced_ruc_titular,    
@w_nombre_codeudor    =   nombre_codeudor,    
@w_tipoDoc_codeudor   =   tipoDoc_codeudor,   
@w_ced_ruc_codeudor   =   ced_ruc_codeudor,   
@w_ciudad             =   ciudad,             
@w_fecha              =   convert(varchar(15),fecha, 103),             
@w_cod_oficina        =   cod_oficina,        
@w_nombre_oficina     =   nombre_oficina,     
@w_nro_operacion1     =   nro_operacion1,     
@w_nro_operacion2     =   nro_operacion2,     
@w_nro_operacion3     =   nro_operacion3,     
@w_nro_operacion_new  =   nro_operacion_new,  
@w_saldo_new_operacion=   saldo_new_operacion,
@w_tipo_amor_newOp    =   tipo_amor_newOp,    
@w_fecha_ven_new_oper =   convert(varchar(15),fecha_ven_new_oper, 103),
@w_tasa_efa_new_oper  =   tasa_efa_new_oper,  
@w_monto_desembolsado =   monto_desembolsado,
@w_fecha_prorroga1 =   convert(varchar(15),@w_fecVen_antes_pro, 103),
@w_fecha_prorroga2 =   convert(varchar(15),@w_new_fecha_ven, 103)
from  ca_formatos_normalizacion_cca
where tramite = @w_tramite
and tipo_normalizacion = @i_tipo_norm
and usuario = @s_user

select             
@w_nombre_titular     , ---1
@w_tipoDoc_titular    , ---2
@w_ced_ruc_titular    , ---3
@w_nombre_codeudor    , ---4
@w_tipoDoc_codeudor   , ---5
@w_ced_ruc_codeudor   , ---6
@w_ciudad             , ---7
@w_fecha              , ---8
@w_cod_oficina        , ---9
@w_nombre_oficina     , ---10
@w_nro_operacion1     , ---11
@w_nro_operacion2     , ---12
@w_nro_operacion3     , ---13
@w_nro_operacion_new  , ---14
@w_saldo_new_operacion, ---15
@w_tipo_amor_newOp    , ---16
@w_fecha_ven_new_oper , ---17
@w_tasa_efa_new_oper  , ---18
@w_monto_desembolsado,   ---19
@w_fecha_prorroga1,    ---20
@w_fecha_prorroga2        ---21

return 0
  
go