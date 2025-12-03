/***********************************************************************/
/*  Archivo:                   contabiliza_gar.sp                      */
/*  Stored procedure:          sp_contabiliza_garantia                 */
/*  Base de Datos:             cob_custodia                            */
/*  Producto:                  Custodia                                */
/*  Disenado por:              Roxana Sánchez                          */
/*  Fecha de Documentacion:    04/Julio/2017                           */
/***********************************************************************/
/*                          IMPORTANTE                                 */
/*  Este programa es parte de los paquetes bancarios propiedad de      */
/*  "MACOSA",representantes exclusivos para el Ecuador de la           */
/*  AT&T                                                               */
/*  Su uso no autorizado queda expresamente prohibido asi como         */
/*  cualquier autorizacion o agregado hecho por alguno de sus          */
/*  usuario sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante                 */
/***********************************************************************/
/*          PROPOSITO                                                  */
/*  Este stored procedure permite crear o devolver el valor            */
/*  de la garantia                                                     */
/*                                                                     */
/***********************************************************************/
/*          MODIFICACIONES                                             */
/*  FECHA              AUTOR               RAZON                       */
/* 04/Julio/2017    Roxana Sánchez       Emision Inicial               */
/***********************************************************************/


use cob_custodia
go


if exists (select * from sysobjects where name = 'sp_contabiliza_garantia' and xtype = 'P')
    drop proc sp_contabiliza_garantia
go

create proc sp_contabiliza_garantia (
@s_date               datetime,
@s_user               login        = null,
@s_ofi                INT          = null,
@s_term               descripcion  = null,
@i_operacion          char(2)  = null, /*C = Creacion y D = Devolver*/
@i_tramite            varchar(100) = null,
@i_monto              money        = NULL,
@i_en_linea           CHAR(1)      = 'S',
@i_ente               int          = null,
@i_grupo              int          = null,
@i_forma_pago         varchar(15)  = 'SANTANDER',
@i_moneda             int          = 0,
@o_secuencial         int          = null output          
)
as
declare

@w_error              int,          /* VALOR QUE RETORNA  */
@w_sp_name            varchar(32),  /* NOMBRE STORED PROC */
@w_commit             char(1),
@w_monto              money,
@w_fecha_proc         datetime,
@w_clase_cartera      catalogo,
@w_calificacion       char(1),
@w_hora               varchar(8),
@w_secuencial         int,
@w_concepto           varchar(50),
@w_grupo              int, 
@w_monto_gar          money,
@w_toper_trn_gar      catalogo,
@w_banco_trn_gar      cuenta,
@w_codigo_externo     cuenta,
@w_codvalor           varchar(10)


select 
@w_sp_name = 'sp_contabiliza_garantia',
@w_commit = 'N'

select @w_fecha_proc = fp_fecha
from cobis..ba_fecha_proceso

select @s_date = @w_fecha_proc

select @w_toper_trn_gar = pa_char 
from  cobis..cl_parametro
where pa_nemonico in ('TOPGAR')
and   pa_producto = 'CCA'

select @w_toper_trn_gar = isnull(@w_toper_trn_gar, 'GARANTIA')

--AGO. Grupo se envia desde sp_miembro_grupo_busin
if @i_grupo IS NOT NULL
begin 
	select @w_grupo   = @i_grupo
end
else
begin
	select @w_grupo   = gl_grupo
	from   cob_cartera..ca_garantia_liquida
    where  gl_cliente = @i_ente 
    and    gl_tramite = @i_tramite	
end

--AGO. Devolución de Garantía por Cancelación de Préstamo
select @w_banco_trn_gar = convert(varchar, @i_ente)


if @i_operacion = 'PD' begin
     
   update cob_cartera..ca_garantia_liquida
   set    gl_dev_estado = 'PD'
   where  gl_grupo      = @w_grupo 
   and    gl_cliente    = @i_ente
   and    gl_tramite    = @i_tramite
   and    gl_pag_valor  != 0
   
   return 0
          
end 

if @i_operacion = 'D' begin

   select @w_monto     = gl_pag_valor,
          @w_monto_gar = gl_monto_garantia
   from   cob_cartera..ca_garantia_liquida 
   where  gl_cliente = @i_ente 
   and    gl_grupo   = @w_grupo
   and    gl_tramite = @i_tramite
   
   if (@w_monto != @w_monto_gar)  select @w_monto = @w_monto - @w_monto_gar
      
   
   update cob_cartera..ca_garantia_liquida
   set    gl_dev_estado = 'D',
          gl_dev_valor  = @w_monto,
          gl_dev_fecha  = @w_fecha_proc,
          gl_pag_valor  = isnull(gl_pag_valor,0) - @w_monto  
   where  gl_grupo      = @w_grupo 
   and    gl_cliente    = @i_ente
   and    gl_tramite    = @i_tramite
   
   select @w_monto    = @w_monto * -1
   
   select @w_concepto = 'DEVOLVER GARANTIA'

end 

if @i_operacion = 'C' begin

   update cob_cartera..ca_garantia_liquida
   set    gl_pag_estado = 'CB',
          gl_pag_valor  = isnull(gl_pag_valor,0) + @i_monto,
          gl_pag_fecha  = @w_fecha_proc
   where  gl_grupo      = @w_grupo 
   and    gl_cliente    = @i_ente
   and    gl_tramite    = @i_tramite
   
   select 
   @w_monto    = @i_monto,
   @w_concepto = 'CONSTITUIR GARANTIA'

end

if @i_operacion = 'RC' begin
  
   update cob_cartera..ca_garantia_liquida
   set    gl_pag_estado = 'PC',
          gl_pag_valor  = isnull(gl_pag_valor,0) - @i_monto,
          gl_pag_fecha  = @w_fecha_proc
   where  gl_grupo      = @w_grupo 
   and    gl_cliente    = @i_ente
   and    gl_tramite    = @i_tramite
   
   select @w_monto    = @i_monto * -1,
   @w_concepto = 'CONSTITUIR GARANTIA'
end


if @i_operacion = 'V' begin --deVolucion por pago incompleto
   select @w_monto    = @i_monto,
   @w_concepto = 'DEVOLUCION POR PAGO INCOMPLETO DE GARANTIA'
end 


/*SECUENCIAL DE GARANTIA*/   
exec @o_secuencial = cob_cartera..sp_gen_sec
@i_operacion       = -3

insert into cob_cartera..ca_transaccion(
tr_fecha_mov,          tr_toperacion,        tr_moneda,
tr_operacion,          tr_tran,              tr_secuencial,
tr_en_linea,           tr_banco,             tr_dias_calc,
tr_ofi_oper,           tr_ofi_usu,           tr_usuario,
tr_terminal,           tr_fecha_ref,         tr_secuencial_ref,
tr_estado,             tr_gerente,           tr_gar_admisible,
tr_reestructuracion,   tr_calificacion,      tr_observacion,                              
tr_fecha_cont,         tr_comprobante)
values(
@s_date,               @w_toper_trn_gar,        @i_moneda,
-3,                    'GAR',                   @o_secuencial, 
'S',                   @w_banco_trn_gar,        0,
@s_ofi,                @s_ofi,                  @s_user,
@s_term,               @s_date,                 -999,  
'ING',                 '',                      '',
'',                    '',                      @w_concepto,
@s_date,               0)
   
if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end


select @w_codvalor = cp_codvalor 
from cob_cartera..ca_producto
where cp_producto = @i_forma_pago

if @w_codvalor is null
begin
   select @w_error = 70203
   goto ERROR
end
				 
insert into cob_cartera..ca_det_trn(
dtr_secuencial,     dtr_operacion, dtr_dividendo,
dtr_concepto,       dtr_estado,    dtr_periodo,
dtr_codvalor,       dtr_monto,     dtr_monto_mn,
dtr_moneda,         dtr_cotizacion,dtr_tcotizacion,
dtr_afectacion,     dtr_cuenta,    dtr_beneficiario,
dtr_monto_cont)
values(
@o_secuencial,     -3,              0,
@i_forma_pago,     1,               0,
@w_codvalor,       @w_monto,        @w_monto,
@i_moneda,         1,               'N',
'D',              '00000',          'CUSTODIA',
0.00)

if @@error <> 0 begin
   select @w_error = 710001
   goto ERROR
end
 
 
return 0

ERROR:
if @w_commit = 'S'
begin
   select @w_commit = 'N'
   rollback tran
   return @w_error
end

IF @i_en_linea = 'S' BEGIN 
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error   
END
   
return @w_error
   

GO
