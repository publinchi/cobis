/************************************************************************/
/*      Archivo:                rev_interface.sp                        */
/*      Stored procedure:       sp_rev_interfase                        */
/*      Producto:               cob_interface                           */
/*      Disenado por:           Jorge Baque H                           */
/*      Fecha de escritura:     DIC 29 2016                             */
/************************************************************************/
/*                              IMPORTANTE                              */
/*      Este programa es parte de los paquetes bancarios propiedad de   */
/*      'COBISCORP'.                                                    */
/*      Su uso no autorizado queda expresamente prohibido asi como      */
/*      cualquier alteracion o agregado hecho por alguno de sus         */
/*      usuarios sin el debido consentimiento por escrito de la         */
/*      Presidencia Ejecutiva de COBISCORP o su representante.          */
/************************************************************************/  
/*                              PROPOSITO                               */
/*      SP interface DE DESACOPLAMIENTO                                 */
/************************************************************************/
/*   FECHA                 AUTOR                RAZON                   */
/* DIC 29/2016             JBA              DESACOPLAMIENTO             */     
/************************************************************************/
use cob_interface
go
if exists (select 1 from sysobjects where name = 'sp_rev_interfase')
   drop proc sp_rev_interfase 
go

create proc sp_rev_interfase(
    @s_ssn                  int            =     null,
	@s_user                 login          =     null,
    @s_date                 datetime       =     null,
    @i_operacion            varchar(5),          
    @i_cliente              int            =     null,
    @i_referencia_sidac     varchar(50)    =     null,
    @i_concepto_devseg      catalogo       =     null,
    @i_operacionca          int            =     null,
	@i_banco                cuenta         =     null
    )
as
declare @w_error         int, 
		@w_sp_name       varchar(100),
        @w_secuencial_cxp int,
        @w_rp_saldo       money,
		@w_msg     varchar(256)

select @w_sp_name      =  'sp_rev_interfase'
if exists(select 1 from cobis..cl_producto where pd_producto = 100)
begin
    if @i_operacion = 'OP1'
    begin
          select @w_secuencial_cxp = 0
          
          select @w_secuencial_cxp =  isnull(rp_consecutivo,0)
          from   cob_sidac..sid_registros_padre
          where  rp_empresa       = 1
          and    rp_submodulo     = 'CP'
          and    rp_ente          = @i_cliente
          and    rp_numero_referencia = @i_referencia_sidac
          and    rp_estado in  ('V','P')
          and    rp_concepto = @i_concepto_devseg
          
          if @@rowcount > 0 and @w_secuencial_cxp > 0    
          begin
             select @w_rp_saldo = sum(isnull(rp_saldo,0))
             from    cob_sidac..sid_registros_padre
             where  rp_empresa       = 1
             and    rp_ente          = @i_cliente
             and    rp_consecutivo = @w_secuencial_cxp
             
             if @s_ssn is null
             begin
                ---SECUENCIAL PARA SIDAC
                exec @s_ssn = cob_cartera..sp_gen_sec
                     @i_operacion      = @i_operacionca
             end
		  end
          ELSE
          begin
             insert into ca_errorlog
                   (er_fecha_proc,      er_error,      er_usuario,
                    er_tran,            er_cuenta,     er_descripcion,
                    er_anexo)
             values(@s_date,         0,             @s_user,
                    7269,             @i_banco,      'EL SOBRANTE POR DEVOLUCION DE SEGUROS NO SE ENCUENTRA PENDIENTE',
                    'REVERSO o FECHA VALOR DE PAGO')
          end
    end
end
else
begin
	select @w_error = 404000, @w_msg = 'PRODUCTO NO INSTALADO'
    GOTO ERROR
end
return 0
ERROR:
exec cobis..sp_cerror
@t_debug  = 'N',          
@t_file = null,
@t_from   = @w_sp_name,   
@i_num = @w_error,
@i_msg = @w_msg
return @w_error
go

