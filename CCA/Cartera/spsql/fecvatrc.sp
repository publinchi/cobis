/************************************************************************/
/*	Archivo: 		      fecvatrc.sp				                           */
/*	Stored procedure: 	sp_fecha_valor_trc                              */
/*	Base de datos:  	   cob_cartera				                           */
/*	Producto: 		      Cartera					                           */
/*	Disenado por:  		Elcira Pelaez Burbano	                        */
/*	Fecha de escritura: 	Feb/2002    				                        */
/************************************************************************/
/*				                  IMPORTANTE                                */
/*	Este programa es parte de los paquetes bancarios propiedad de	      */
/*	"MACOSA"                                                             */
/*	Su uso no autorizado queda expresamente prohibido asi como	         */
/*	cualquier alteracion o agregado hecho por alguno de sus              */
/*	usuarios sin el debido consentimiento por escrito de la              */
/*	Presidencia Ejecutiva de MACOSA o su representante.		            */
/************************************************************************/  
/*	                              PROPOSITO                              */
/*	Realiza fecha valor por cierre de calificacion                 	   */
/*      Las transacciones Para Fecha valor son:                         */
/*          Desembolso, Desembolso Parciales,                           */ 
/*          Cambio de Estado Automaticos   			                     */
/*          Reajustes, Reestructuraciones, Pagos, Provision,            */
/*          Amortizacion                                                */
/************************************************************************/
/*				                       MODIFICACIONES				            */
/*	FECHA                  AUTOR                RAZON                    */
/* MAY:30:2002            PB            Manejo de la fecha para los     */
/*                                      Reversos  = fecha del dia       */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_fecha_valor_trc')
	drop proc sp_fecha_valor_trc
go
create proc sp_fecha_valor_trc (
   @s_date              datetime     = null,
   @s_lsrv	     	      varchar(30)  = null,
   @s_ofi               smallint     = null,
   @s_org		         char(1)      = null,
   @s_rol		         smallint     = null,
   @s_sesn              int          = null,
   @s_ssn               int          = null,
   @s_srv               varchar(30)  = null,
   @s_term              descripcion  = null,
   @s_user              login        = null,
   @i_fecha_valor	      datetime,
   @i_banco		         cuenta,
   @i_secuencial_hfm    int,
   @i_operacion         char(1)      = 'F',
   @i_observacion       char(62)     = ''
   
)  
as
declare @w_sp_name		        varchar (32),
	     @w_return		           int,
	     @w_error		           int,
	     @w_monto		           money,
	     @w_monto_pag		        money,
	     @w_monto_des		        money,
	     @w_operacionca		     int,
        @w_abd_monto_mpg        money,
	     @w_estado_no_vigente    int,
        @w_lin_credito          cuenta,
        @w_toperacion           catalogo,
        @w_moneda               int,
        @w_tramite              int,	
        @w_opcion               char(1),  
        @w_cliente              int,
        @w_shela                tinyint,
        @w_op_activa            int,
        @w_producto             tinyint,
	     @w_numero_comex         cuenta,  
        @w_num_pag              int,
        @w_tipo                 char(1),
        @w_monto_pag_mn         money,
        @w_monto_des_mn         money


/* INICIALIZACION DE VARIABLES */
select 
@w_sp_name           = 'sp_fecha_valor_trc',
@w_estado_no_vigente = 0


select @s_date = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7



/* VALIDAR LA EXISTENCIA DE LA OPERACION */
select	
@w_operacionca      =  op_operacion,
@w_lin_credito      =  op_lin_credito,
@w_toperacion       =  op_toperacion,
@w_moneda           =  op_moneda,
@w_cliente          =  op_cliente,
@w_opcion           =  op_tipo,   
@w_tramite	    =  op_tramite,
@w_numero_comex     = op_num_comex
from  ca_operacion
where op_banco  =  @i_banco
and   op_estado <> @w_estado_no_vigente

if @@rowcount = 0 begin
   select @w_error = 701025
   return @w_error
end


/* BORRAR LAS TASAS MAYORES AL SECUENCIAL RETRO */
delete ca_tasas
where ts_operacion  = @w_operacionca
and   ts_secuencial >= @i_secuencial_hfm
if @@error <> 0 begin
   select @w_error = 71003
   return @w_error
end  


/* PONER LOS HISTORICOS EN LAS TABLAS DEFINITIVAS */
exec @w_return  = sp_historia_def
@i_operacionca = @w_operacionca,  
@i_secuencial  = @i_secuencial_hfm
if @w_return  != 0 begin
   select @w_error = @w_return
   return @w_error
end

/*VERIFICAR SI EXISTEN TRANSACCIONES DE PAGOS >= AL SERCUENCIAL RETRO */
select   @w_num_pag  = isnull(count(*),0)
from ca_transaccion
where tr_operacion  = @w_operacionca
and   tr_secuencial >= @i_secuencial_hfm
and   tr_tran       = 'PAG'
and   tr_estado     <> 'RV'

   
/* ACTUALIZAR PAGOS COMO NO APLICADOS */
if @w_num_pag > 0 begin 
  
      update ca_abono set
      ab_estado         = 'NA',
      ab_dias_retencion = ab_dias_retencion_ini
      where ab_secuencial_pag >= @i_secuencial_hfm
      and   ab_operacion      = @w_operacionca
      and   ab_fecha_pag     >= @i_fecha_valor
      and   ab_estado        not in ('RV','E')

     if @@error != 0 begin
       select @w_error = 710002
       return @w_error
     end

     update ca_abono set
     ab_estado         = 'NA',
     ab_dias_retencion = ab_dias_retencion_ini - 
                       datediff(dd, ab_fecha_pag, @i_fecha_valor)
    where ab_secuencial_pag>= @i_secuencial_hfm
    and   ab_operacion      = @w_operacionca
    and   ab_fecha_pag      < @i_fecha_valor
    and   ab_estado        not in ('RV','E')

    if @@error != 0 begin
      select @w_error = 710002
      return @w_error
    end


     if @w_lin_credito is not null 
         select @w_shela  = 0
     else
         select @w_shela = 1

      select @w_monto_pag    = isnull(sum(dtr_monto),0),
             @w_monto_pag_mn = isnull(sum(dtr_monto),0)
      from ca_transaccion, ca_det_trn, ca_rubro_op
      where tr_banco = @i_banco
      and   tr_tran  = 'PAG'
      and   tr_secuencial >= @i_secuencial_hfm
      and   tr_estado     <> 'RV'
      and   tr_secuencial  = dtr_secuencial
      and   tr_operacion   = dtr_operacion
      and   ro_operacion   = tr_operacion
      and   dtr_concepto   = ro_concepto 
      and   ro_tipo_rubro  = 'C' 


      select @w_monto_des    = isnull(sum(dtr_monto),0),
             @w_monto_des_mn = isnull(sum(dtr_monto),0)
      from ca_transaccion, ca_det_trn, ca_rubro_op
      where tr_banco      = @i_banco
      and   tr_tran        = 'DES'
      and   tr_secuencial >= @i_secuencial_hfm
      and   tr_estado     <> 'RV'
      and   tr_secuencial  = dtr_secuencial
      and   tr_operacion   = dtr_operacion
      and   ro_operacion   = tr_operacion
      and   dtr_concepto   = ro_concepto 
      and   ro_tipo_rubro  = 'C' 

      if @w_moneda = 0
         select @w_monto_des = @w_monto_des - @w_monto_pag
      else
         select @w_monto_des = @w_monto_des_mn - @w_monto_pag_mn


      if @w_monto_des > 0 
         select @w_tipo ='X' --'D' XSA
      else
         select 
         @w_tipo ='Y',  --'C' XSA
         @w_monto_des = -1 * @w_monto_des 

      if @w_monto_des > 0 begin

         if @w_opcion = 'R'         -- REDESCUENTO
            select @w_opcion = 'P'  -- PASIVA
         else
            select @w_opcion = 'A'  -- ACTIVA

         exec @w_return = cob_credito..sp_utilizacion
         @s_date        = @s_date,
         @s_lsrv        = @s_lsrv,
         @s_ofi         = @s_ofi,
         @s_org         = @s_org,
         @s_rol         = @s_rol,
         @s_sesn        = @s_sesn,
         @s_srv         = @s_srv,
         @s_ssn         = @s_ssn,
         @s_term        = @s_term,
         @s_user        = @s_user,
         @t_trn         = 21888,
         @i_linea_banco = @w_lin_credito,
         @i_producto    = 'CCA',
         @i_toperacion  = @w_toperacion,
         @i_tipo        = @w_tipo,
         @i_moneda      = @w_moneda,
         @i_monto       = @w_monto_des,
	      @i_secuencial  = @i_secuencial_hfm,  	
	      @i_tramite	   = @w_tramite,	
         @i_opcion      = @w_opcion,  
         @i_opecca      = @w_operacionca,
         @i_fecha_valor = @i_fecha_valor,
	      @i_cliente     = @w_cliente,
         @i_modo        = @w_shela,
         @i_numoper_cex = @w_numero_comex 

         if @w_return != 0 begin 
            PRINT 'facvatrc.sp salio por error de sp_utilizacion @w_operacionca'+ @w_operacionca +  '@w_opcion' + @w_opcion
            return  @w_return
         end

      end

      /*ELIMINAR DATOS DE SIPLA*/

      exec @w_return  = sp_interfaz_otros_modulos
      @s_user         = @s_user,
      @i_cliente      = 0,
      @i_modulo	      = 'CCA',
      @i_interfaz     =	'S',
      @i_modo	      =	'D',
      @i_obligacion   =	@i_banco,
      @i_moneda	      = 0,
      @i_sec_trn      =	@i_secuencial_hfm,
      @i_fecha_trn    = '',
      @i_desc_trn     = '',
      @i_monto_trn    = 0,
      @i_gerente      = @s_user,
      @i_cotizacion   = 0,
      @i_categoria    = ''

      if @w_return <> 0 begin
         select @w_error = @w_return    
         return @w_error
      end
end
/* FIN ACTUALIZAR PAGOS COMO NO APLICADOS */ 

/*PRODUCTO COBIS */
/*****************/
select 
@w_producto = dt_prd_cobis
from cob_cartera..ca_default_toperacion
where dt_toperacion = @w_toperacion
and   dt_moneda     = @w_moneda


/*
/****ACTUALIZACIONES PARA PRODUCTO COMEX  ****/
/*********************************************/

if @w_producto = 9 and @w_tramite is not null and @w_numero_comex is not null begin

   exec @w_return       = cob_comext..sp_integracion_cartera
   @s_date              = @s_date,
   @t_trn               = 9986,
   @i_opcion            = 14,
   @i_banco_cca_act     = @i_banco,     
   @i_banco_cex         = @w_numero_comex,
   @i_operacion_cca_act = @w_operacionca

   if @w_return != 0 begin
      print '..errror...en cob_comext..sp_integracion_cartera..1  NUMCOMEX ,  @w_operacionca' + cast(@w_numero_comex as varchar) + cast(@w_operacionca as varchar)
      select @w_error = @w_return
      return @w_error
   end
end   

if @w_producto = 9 and @w_tramite is null begin
/* Leer la operacion activa relacionada */

   select @w_op_activa = rp_activa
   from ca_relacion_ptmo
   where rp_pasiva = @w_operacionca

   exec @w_return = cob_comext..sp_integracion_cartera
   @s_date              = @s_date,
   @t_trn               = 9986,
   @i_opcion            = 14,
   @i_banco_cca_pas     = @i_banco,     
   @i_banco_cex         = @w_numero_comex,
   @i_operacion_cca_pas = @w_operacionca,
   @i_operacion_cca_act = @w_op_activa

   if @w_return != 0 begin
      print '...error...cob_comext..sp_integracion_cartera..2 NUMCOMEX , @w_op_activa' + cast(@w_numero_comex as varchar) + cast(@w_op_activa as varchar)
      select @w_error = @w_return
      return @w_error
   end
end

*/
/*REVERSAR  LAS TRANSACCIONES >= AL SECUENCIAL RETRO */


insert into ca_transaccion (
tr_secuencial,     tr_fecha_mov,  	tr_toperacion,  
tr_moneda,         tr_operacion,   	tr_tran,       
tr_en_linea,       tr_banco,       	tr_dias_calc,
tr_ofi_oper,       tr_ofi_usu,     	tr_usuario,
tr_terminal,       tr_fecha_ref,   	tr_secuencial_ref, 
tr_estado,         tr_observacion, 	tr_gerente , 	  
tr_gar_admisible,  tr_reestructuracion ,tr_calificacion,
tr_fecha_cont,	   tr_comprobante) 					
select 
-1 * tr_secuencial,  @s_date,        tr_toperacion,  
tr_moneda,           tr_operacion,   'REV', 
tr_en_linea,         tr_banco,       tr_dias_calc,
tr_ofi_oper,         @s_ofi,         @s_user,
@s_term,             tr_fecha_ref,   tr_secuencial, 
'ING',               isnull(tr_observacion,''), tr_gerente,	      
isnull(tr_gar_admisible,''), isnull(tr_reestructuracion,''),isnull(tr_calificacion,''),
tr_fecha_cont,	   tr_comprobante 					
from   ca_transaccion
where  tr_operacion   = @w_operacionca
and    tr_secuencial >= @i_secuencial_hfm
and    tr_estado      = 'CON' 
and    tr_tran       not in ('RPA', 'REV')
and    tr_secuencial != 0

if @@error <> 0 return 710001

insert into ca_det_trn (
dtr_secuencial,     dtr_operacion,    dtr_dividendo,
dtr_concepto,
dtr_estado,         dtr_periodo,      dtr_codvalor,
dtr_monto,          dtr_monto_mn,     dtr_moneda,
dtr_cotizacion,     dtr_tcotizacion,  dtr_afectacion,
dtr_cuenta,         dtr_beneficiario, dtr_monto_cont )
select  
-1*dtr_secuencial,  dtr_operacion, dtr_dividendo,
dtr_concepto,
dtr_estado,         dtr_periodo,                       dtr_codvalor,     
dtr_monto,          dtr_monto_mn, 		       dtr_moneda,
dtr_cotizacion,     isnull(dtr_tcotizacion,''),        dtr_afectacion,
dtr_cuenta,         dtr_beneficiario,                  0
from   ca_transaccion, ca_det_trn 
where  tr_operacion   = @w_operacionca
and    tr_secuencial >= @i_secuencial_hfm
and    tr_estado      = 'CON'
and    tr_tran       not in ('RPA', 'REV')
and    tr_secuencial  = dtr_secuencial
and    tr_operacion   = dtr_operacion
and    tr_secuencial != 0

if @@error <> 0 return 710001

/* ACTUALIZAR LAS TRANSACCIONES COMO REVERSADAS */
update ca_transaccion set 
tr_estado = 'RV',
tr_observacion = isnull(@i_observacion,'')
where tr_operacion   = @w_operacionca
and   tr_secuencial >= @i_secuencial_hfm
and   tr_tran       not in ('RPA', 'REV')
and   tr_estado     in ('CON','ING', 'ANU', 'NCO')
and   tr_secuencial != 0

if @@error != 0 return 710002




return 0


go


