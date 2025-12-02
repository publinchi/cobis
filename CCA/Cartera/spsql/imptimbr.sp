/************************************************************************/
/*   Archivo:              imptimbr.sp                                  */
/*   Stored procedure:     sp_imprimir_timbre                           */
/*   Base de datos:        cob_cartera                                  */
/*   Producto:             Cartera                                      */
/*   Disenado por:         Ramiro Buitron                               */
/*   Fecha de escritura:   30/Jul/1999                                  */
/************************************************************************/
/*                         IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'MACOSA'.                                                          */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de MACOSA o su representante.                */
/************************************************************************/  
/*                         PROPOSITO                                    */
/*   Imprimir el certificado de retencion de impuesto de timbre         */
/************************************************************************/

use cob_cartera
go
 
if exists (select 1 from sysobjects where name = 'sp_imprimir_timbre')
   drop proc sp_imprimir_timbre
go

create proc sp_imprimir_timbre(
   @s_ssn               int         = null,
   @s_date              datetime    = null,
   @s_user              login       = null,
   @s_term              descripcion = null,
   @s_corr              char(1)     = null,
   @s_ssn_corr          int         = null,
   @s_ofi               smallint    = null,
   @t_rty               char(1)     = null,
   @t_debug             char(1)     = 'N',
   @t_file            varchar(14) = null,
   @t_trn      smallint    = null,  
   @i_formato_fecha     int         = null,
   @i_operacion         char(1)     = null,
   @i_banco             cuenta      = null,
   @i_descripcion1      varchar(80) = null,
   @i_descripcion2      varchar(80) = null,
   @i_descripcion3      varchar(80) = null
)

as
declare @w_sp_name               varchar(32),
        @w_return                  int,
        @w_error                 int,
        @w_oficina               smallint,
        @w_timbre                varchar(30),
        @w_cliente               int,
        @w_nombre                varchar(60), 
        @w_banco                 cuenta,
        @w_monto                 money,
        @w_fecha_mov             varchar(15),
        @w_nit                   numero,             
        @w_nit_prim_digitos      varchar(29),
        @w_nit_ulti_digito       char(1),
        @w_nit_ofi               numero,
        @w_nit_ofi_prim_digitos  varchar(29),
        @w_nit_ofi_ulti_digito   char(1),
        @w_direc_ofici           direccion,
        @w_descr_ciudad          descripcion,
        @w_descr_depart          descripcion,
        @w_descripcion1          varchar(80),
        @w_descripcion2          varchar(80),
        @w_descripcion3          varchar(80),
        @w_monto_op              money,
        @w_en_subtipo              char(1)


/* Captura nombre de Stored Procedure  */
select   @w_sp_name = 'sp_imprimir_timbre'

if @i_banco is null
begin
   exec cobis..sp_cerror
      @t_debug = 'N',
      @t_from  = @w_sp_name,
      @i_num   = 710026,
      @i_msg   = 'Error: numero de obligacion no valido. por favor envie evidencias en modo debug'
   return @w_error   
end

if @i_operacion = 'Q'
begin
   select ti_descripcion1,ti_descripcion2,ti_descripcion3
   from ca_timbre where ti_banco = @i_banco
end

if @i_operacion = 'D'
begin
   select ti_descripcion1,ti_descripcion2,ti_descripcion3
   from ca_timbre where ti_banco = @i_banco

   if @@rowcount = 0
      insert into ca_timbre values (@i_banco, @i_descripcion1, @i_descripcion2, @i_descripcion3)
   else
       update ca_timbre set ti_descripcion1 = @i_descripcion1,
       ti_descripcion2 = @i_descripcion2,
       ti_descripcion3 = @i_descripcion3
       where ti_banco = @i_banco
end
  
if @i_operacion = 'T'
begin   

  --- PARAMETRO GENERAL DE TIMBRE 
   
   select @w_timbre =  pa_char
   from cobis..cl_parametro where pa_producto = 'CCA'
   and pa_nemonico = 'TIMBRE'
   set transaction isolation level read uncommitted


   -- DATOS DEL TIMBRE 

   select
   @w_cliente   = op_cliente,
   @w_nombre    = op_nombre,
   @w_nit       = en_ced_ruc,
   @w_banco     = op_banco,    
   @w_monto     = dtr_monto_mn,
   @w_fecha_mov = substring(convert(varchar,tr_fecha_mov,@i_formato_fecha),1,15),
   @w_oficina   = tr_ofi_usu,
   @w_en_subtipo  = en_subtipo
   from ca_transaccion,ca_det_trn,ca_rubro_op,ca_operacion,cobis..cl_ente noholdlock
   where  op_banco = @i_banco
   and    tr_secuencial = dtr_secuencial
   and    tr_operacion = dtr_operacion
   and    tr_tran      = 'DES'
   and    tr_estado in ('ING','CON')
   and    dtr_concepto = @w_timbre
   and    dtr_concepto = ro_concepto
   and    ro_operacion = tr_operacion
   and    ro_operacion = dtr_operacion
   and    op_operacion = tr_operacion
   and    en_ente = op_cliente
  
   if @@rowcount = 0
   begin 
      select @w_error = 710026
      goto ERROR
   end  


  --- SEPARACION DE CARACTERES DE LA FECHA DE LA TRANSACCION 

   select @w_fecha_mov = substring(@w_fecha_mov,1,2) + '  ' + substring(@w_fecha_mov,4,2) + '  ' +
                  substring(@w_fecha_mov,7,4)


  --- SEPARACION DE ULTIMO DIGITO DEL NIT 
   if @w_en_subtipo = 'P'
   begin
      select @w_nit_prim_digitos = ltrim(rtrim(@w_nit))  
      select @w_nit_ulti_digito = ''
   end
   else   
   begin
      select @w_nit = ltrim(rtrim(@w_nit))  
      select @w_nit_prim_digitos = substring(@w_nit,1,datalength(@w_nit)-1)
      select @w_nit_ulti_digito = substring(@w_nit,datalength(@w_nit),1)
  end

  --- DATOS DE LA OFICINA QUE GENERA LA RETENCION DEL TIMBRE

   select
   @w_direc_ofici  =  of_direccion,
   @w_descr_ciudad =  ci_descripcion,
   @w_descr_depart =  pv_descripcion
   from cobis..cl_oficina,cobis..cl_ciudad,cobis..cl_provincia
   where of_oficina = @w_oficina
   and of_ciudad    = ci_ciudad
   and ci_provincia = pv_provincia
   set transaction isolation level read uncommitted

  --- NIT DE LA OFICINA
 
   select @w_nit_ofi = fi_ruc
   from cobis..cl_filial B,cobis..cl_oficina A,cobis..cl_ciudad
   where  fi_filial = 1
   and fi_filial  = of_filial
   and of_oficina = @s_ofi
   and ci_ciudad = of_ciudad           
   set transaction isolation level read uncommitted

  --- SEPARACION DE ULTIMO DIGITO DEL NIT DE LA OFICINA 

   select @w_nit_ofi = ltrim(rtrim(@w_nit_ofi))  
   select @w_nit_ofi_prim_digitos = substring(@w_nit_ofi,1,datalength(@w_nit_ofi)-1)
   select @w_nit_ofi_ulti_digito = substring(@w_nit_ofi,datalength(@w_nit_ofi),1)


  --- DETALLE DEL TIMBRE

   select
   @w_descripcion1 = ti_descripcion1,
   @w_descripcion2 = ti_descripcion2,
   @w_descripcion3 = ti_descripcion3
   from ca_timbre where ti_banco = @i_banco


  --- MONTO ORIGINAL DE LA OPERACION

 select  @w_monto_op     = isnull(sum(dtr_monto_mn),0)
   from ca_transaccion,ca_det_trn
   where  tr_banco = @i_banco
   and    tr_secuencial = dtr_secuencial
   and    tr_operacion = dtr_operacion
   and    tr_tran      = 'DES'
   and    tr_estado in ('ING','CON')
   and    dtr_concepto = 'CAP'
  
 
   select 
   @w_cliente,
   @w_nombre,
   @w_nit_prim_digitos,
   @w_nit_ulti_digito,
   @w_banco,    
   @w_monto,
   @w_fecha_mov,
   substring(@w_direc_ofici,1,60),
   substring(@w_descr_ciudad,1,30),
   substring(@w_descr_depart,1,30),
   @w_nit_ofi_prim_digitos,
   @w_nit_ofi_ulti_digito,
   @w_descripcion1,
   @w_descripcion2,
   @w_descripcion3,
   @w_monto_op

end

return 0


ERROR:

exec cobis..sp_cerror
   @t_debug = 'N',
   @t_from  = @w_sp_name,
   @i_num   = @w_error
return @w_error

go

