/************************************************************************/
/*	Archivo: 		impcta.sp				*/
/*	Stored procedure: 	sp_impcta        		        */
/*	Base de datos:  	cob_cartera				*/
/*	Producto: 		Cartera					*/
/*	Disenado por:  		Xavier Maldonado 			*/
/*	Fecha de escritura: 	02/Oct./2000				*/
/************************************************************************/
/*				IMPORTANTE				*/
/*	Este programa es parte de los paquetes bancarios propiedad de	*/
/*	"MACOSA".							*/
/*	Su uso no autorizado queda expresamente prohibido asi como	*/
/*	cualquier alteracion o agregado hecho por alguno de sus		*/
/*	usuarios sin el debido consentimiento por escrito de la 	*/
/*	Presidencia Ejecutiva de MACOSA o su representante.		*/
/************************************************************************/  
/*				PROPOSITO				*/
/*	Impresion del Estado de Cuenta de una Operacion                	*/
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'ca_transaccion_imp_tmp')
   drop table ca_transaccion_imp_tmp
go


   create table ca_transaccion_imp_tmp (
   td_tran	  varchar(10),
   td_fpro        varchar(12),
   td_capi        money,
   td_inte        float,
   td_mora        float,
   td_otros       money,
   td_total       money, 
   td_user        login,
   td_producto     catalogo)
go


if exists (select 1 from sysobjects where name = 'sp_impcta')
   drop proc sp_impcta
go

create proc sp_impcta (
@s_ssn               int         = null,
@s_date              varchar(12) = null,
@s_user              login       = null,
@s_term              descripcion = null,
@s_corr              char(1)     = null,
@s_ssn_corr          int         = null,
@s_ofi               smallint    = null,
@t_rty               char(1)     = null,
@t_debug             char(1)     = 'N',
@t_file		     varchar(14) = null,
@t_trn		     smallint    = null,  
@i_operacion	     char(1)     = null,
@i_formato_fecha     int         = null,
@i_banco	     cuenta      = null
)

as
declare	
@w_sp_name			varchar(32),
@w_return			int,
@w_error        		int,
@w_operacionca                  int,
@w_fecha_crea                   varchar(12),
@w_fecha_hasta                  varchar(12),
@w_banco                        cuenta,
@w_toperacion                   catalogo,
@w_nombre                       varchar(30),
@w_dir_descripcion              varchar(254),
@w_monto_aprobado               money,
@w_cuenta_ahorro                char(16),
@w_cuota                        money,
@w_fecha_liq                    varchar(12),
@w_tasa_int                     varchar(50),
@w_fecha_pago                   varchar(12),
@w_telefono                     varchar(16),
@w_tasa_mora                    float,
@w_fecha_ingreso                varchar(12),
@w_cod_cliente                  int,
@w_direccion                    tinyint,
@w_direccion_desc               varchar(254),
@w_ciudad_desc                  descripcion,
@w_tabla                        smallint,
@w_oficina                      smallint,
@w_fecha_fin                    varchar(12),
@w_toperacion_desc              descripcion,
@w_transaccion 		        char(10),
@w_fecha_proceso 	        varchar(12),
@w_concepto     	        catalogo, 
@w_monto		        money,
@w_secuencial                   int,
@w_count                        int,
@w_cap                          money,
@w_int                          money,
@w_imo                          money,
@w_otros                        money,
@w_fecha_mov			varchar(12),
@w_tran				varchar(10),
@w_ref_exterior 		cuenta,
@w_fec_embarque			varchar(15),
@w_fec_dex           		varchar(15),
@w_num_deuda_ext    		cuenta,
@w_num_comex     		cuenta,
@w_afectacion                   char(1),
@w_total                        money,
@w_fpago                        catalogo,
@w_op_direccion                 tinyint

/* Captura nombre de Stored Procedure  */
select	@w_sp_name = 'sp_impcta'


 select @w_fecha_crea   = op_fecha_ini, 
   @w_fecha_fin    = op_fecha_fin,
   @w_operacionca  = op_operacion   
   from ca_operacion
   where op_banco        = @i_banco


if @i_operacion='C'
begin

   select
   @w_banco             = op_banco,
   @w_operacionca       = op_operacion,
   @w_fecha_crea        = substring(convert(varchar,op_fecha_ini,@i_formato_fecha),1,15),
   @w_toperacion        = op_toperacion,
   @w_cod_cliente       = op_cliente,
   @w_nombre            = op_nombre,
   @w_monto_aprobado    = op_monto_aprobado,
   @w_ciudad_desc       = ci_descripcion,
   @w_oficina           = op_oficina,
   @w_cuota             = op_cuota,
   @w_fecha_liq         = substring(convert(varchar,op_fecha_liq,@i_formato_fecha),1,15),  
   @w_fecha_fin         = substring(convert(varchar,op_fecha_fin,@i_formato_fecha),1,15),
   @w_ref_exterior      = op_ref_exterior,
   @w_fec_embarque      = substring(convert(varchar,op_fecha_embarque,@i_formato_fecha),1,15),
   @w_fec_dex           = substring(convert(varchar,op_fecha_dex,@i_formato_fecha),1,15),
   @w_num_deuda_ext     = op_num_deuda_ext,
   @w_num_comex         = op_num_comex,
   @w_op_direccion      = op_direccion
   from ca_operacion, cobis..cl_ciudad noholdlock
   where op_banco     = @i_banco
   and op_ciudad      = ci_ciudad         

   if @@rowcount = 0
   begin
      select @w_error = 710026
      goto ERROR
   end 


   select @w_direccion       = di_direccion,
          @w_dir_descripcion = di_descripcion
   from cobis..cl_direccion
   where di_ente = @w_cod_cliente
   and   di_direccion  = @w_op_direccion
   set transaction isolation level read uncommitted

   select @w_telefono = te_valor
   from cobis..cl_telefono
   where te_ente = @w_cod_cliente
   and te_direccion = @w_direccion   
   set transaction isolation level read uncommitted

   select
   @w_tasa_int         = convert(varchar(50),round(isnull(ro_porcentaje,0),2))
   from ca_rubro_op
   where ro_operacion  =  @w_operacionca
   and   ro_tipo_rubro =  'I'
   and   ro_concepto   = 'INT'

   select
   @w_tasa_mora          = isnull(ro_porcentaje ,0)
   from ca_rubro_op
   where ro_operacion    = @w_operacionca
   and   ro_tipo_rubro   = 'M'
   and   ro_concepto     = 'IMO'

   select
   @w_cuenta_ahorro      = isnull(dp_cuenta,'000000000')
   from cobis..cl_det_producto
   where dp_cliente_ec = @w_cod_cliente      
   and dp_producto = 4
   set transaction isolation level read uncommitted

   if @w_cuenta_ahorro = '' or @w_cuenta_ahorro = null
   select @w_cuenta_ahorro = '000000000'  --VALOR FICTICIO

   select @w_fecha_hasta = @s_date
 
   select @w_fecha_ingreso = ab_fecha_ing,
   @w_fecha_pago    = ab_fecha_pag
   from cob_cartera..ca_abono b
   where b.ab_operacion = @w_operacionca
   and b.ab_tipo      = 'PAG'
   and b.ab_secuencial_ing in (select max(ab_secuencial_ing) from ca_abono a
                               where a.ab_operacion = @w_operacionca
                               and a.ab_tipo      = 'PAG')
   select
   @w_fecha_crea,
   @w_fecha_hasta,
   @w_toperacion,
   @w_telefono,
   @w_nombre,
   @w_dir_descripcion,
   @w_monto_aprobado,
   @w_cuota,
   @w_tasa_int,
   @w_tasa_mora,
   @w_cuenta_ahorro,
   @w_fecha_liq,
   @w_fecha_pago,
   @w_fecha_fin,
   @w_ref_exterior,
   @w_fec_embarque,
   @w_fec_dex,
   @w_num_deuda_ext,
   @w_num_comex  ---19

end


/*DETALLE DE LA TRANSACCION */

if @i_operacion = 'D'
begin


/* ELIMINAR REGISTROS DEL USUARIO */
 delete ca_transaccion_imp_tmp
 where td_user = @s_user

  
   declare transaccion  cursor for
   select tr_secuencial,tr_fecha_mov,tr_tran 
   from ca_transaccion
   where tr_banco = @i_banco
   and tr_tran not in ('REV','PRV','RPA','EST','CGR')
   and tr_estado <> 'RV'
   order by tr_secuencial

   open transaccion
   fetch transaccion into
   @w_secuencial,@w_fecha_mov,@w_tran

      while (@@fetch_status = 0 ) begin

         if @@fetch_status = -1 begin    /* error en la base */
            print 'impcta.sp -->  error en el cursor...transaccion .' 
            select @w_error = 70894
            goto  ERROR
         end

         select @w_total = 0
         select @w_cap = 0
         select @w_int = 0
         select @w_imo = 0
         select @w_otros = 0


 
         declare det_transaccion  cursor for
         select dtr_secuencial,dtr_concepto,dtr_afectacion,sum(dtr_monto)
         from ca_det_trn
         where dtr_secuencial = @w_secuencial
         and   dtr_operacion  = @w_operacionca
         group by dtr_secuencial,dtr_concepto,dtr_afectacion

         open det_transaccion
         fetch det_transaccion into
         @w_secuencial,@w_concepto,@w_afectacion,@w_monto

         while (@@fetch_status = 0 ) begin
 
            if @@fetch_status = -1 begin    /* error en la base */
               print 'impcta.sp --> error en el cursor.... det_transaccion' 
               select @w_error = 70894
               goto  ERROR
            end 

          
          if (@w_tran = 'PAG' and @w_afectacion = 'C') or (@w_tran = 'DES' and @w_afectacion = 'D') begin

               if @w_concepto = 'CAP' begin
                  select @w_cap = @w_cap + @w_monto
               end else
                   if @w_concepto in ('INT','INTDES','INTANT') begin
                      select @w_int = @w_int + @w_monto
                   end else
                      if @w_concepto = 'IMO' begin
                         select @w_imo = @w_imo + @w_monto
                      end 
                      else begin --OTROS
                         select @w_otros = @w_otros + @w_monto
                      end 

              select @w_total = @w_total + @w_monto
          end 
        

         fetch det_transaccion into
         @w_secuencial,@w_concepto,@w_afectacion,@w_monto
      end

     close det_transaccion
     deallocate det_transaccion


     if (@w_tran = 'DES' and @w_afectacion = 'C')  begin

        select @w_fpago = dm_producto 
        from ca_desembolso
        where dm_operacion = @w_operacionca
        and dm_secuencial = @w_secuencial

     end
 


     if (@w_tran = 'PAG' and @w_afectacion = 'D') begin

        select @w_fpago = abd_concepto 
        from ca_abono,
        ca_abono_det
        where ab_operacion = @w_operacionca
        and abd_operacion = ab_operacion
        and abd_secuencial_ing = ab_secuencial_ing
        and ab_secuencial_pag = @w_secuencial

     end


     insert into ca_transaccion_imp_tmp 
     (td_tran,      td_fpro,      td_capi,
      td_inte,      td_mora,      td_otros,
      td_total,     td_user,       td_producto)
      values (
      @w_tran,      @w_fecha_mov, @w_cap, 
      @w_int,       @w_imo,       @w_otros,
      @w_total,     @s_user,      @w_fpago)   
      if @@error <> 0 begin
         print 'error en insercion ca_transaccion_imp_tmp'
         select @w_error = 710001
         goto ERROR
      end               

  fetch transaccion into
  @w_secuencial,@w_fecha_mov,@w_tran
end

close transaccion
deallocate transaccion

  select td_tran,      td_fpro,       td_producto,
         td_capi,      td_inte,       td_mora,  
         td_otros,     td_total
  from ca_transaccion_imp_tmp 
  where  td_user  = @s_user
end


return 0

ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go
