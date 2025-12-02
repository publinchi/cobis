/************************************************************************/
/*   Archivo:            log_pagos.sp                                */
/*   Stored procedure:   sp_log_pagos                                   */
/*   Base de datos:      cob_cartera                                    */
/*   Producto:           Cartera                                        */
/*   Disenado por:       Alcivar Chicaiza                               */
/*   Fecha de escritura: 25-Julio 2017                                  */
/************************************************************************/
/*          IMPORTANTE                                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA',representantes exclusivos para el Ecuador de la            */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de MACOSA o su representante                  */
/************************************************************************/
/*          PROPOSITO                                                   */
/*  Consulta el log de procesamiento de ordenes de debitos              */
/************************************************************************/
/*                               OPERACIONES                            */
/*   OPER.                      DESCRIPCION                             */
/*     C            Consulta de ordenes de debitos                      */
/************************************************************************/
/*                              TIPO ERRORES                            */
/*   VALOR.                      DESCRIPCION                            */
/*     C                        Errores Cobis                           */
/*     S                        Errores Santander                       */
/*     T                        Todos                                   */
/************************************************************************/
/*          MODIFICACIONES                                              */
/*  FECHA           AUTOR           RAZON                               */
/*  25/Julio/2017   A.Chicaiza      Emision Inicial                     */
/*  24/Nov/2017     Ma. Jose Taco   Ajustes en sp de operacion y cuenta */
/************************************************************************/
use cob_cartera
go
if exists (select 1 from   sysobjects where  name = 'sp_log_pagos')
   drop proc sp_log_pagos
go

create proc sp_log_pagos(
 @s_ssn             int             = null,
 @s_user            login           = null,
 @s_term            varchar(32)     = null,
 @s_date            datetime        = null,
 @s_sesn            int             = null,
 @s_culture         varchar(10)     = null,
 @s_srv             varchar(30)     = null,
 @s_lsrv            varchar(30)     = null,
 @s_ofi             smallint        = null,
 @s_rol             smallint        = null,
 @s_org_err         char(1)         = null,
 @s_error           int             = null,
 @s_sev             tinyint         = null,
 @s_msg             descripcion     = null,
 @s_org             char(1)         = null,
 @t_debug           char(1)         = 'N',
 @t_file            varchar(10)     = null,
 @t_from            varchar(32)     = null,
 @t_trn             int             = null,
 @t_show_version    bit             = 0, 
 @i_operacion       char(1)         = null,
 @i_cliente         int             = null,
 @i_fecha_desde     datetime        = null,
 @i_fecha_hasta     datetime        = null,
 @i_num_prestamo    cuenta          = null,
 @i_num_cuenta      cuenta          = null,
 @i_tipo_error      char(1)         = null,
 @i_referencia      varchar(64)     = null,
 @i_archivo         varchar(255)    = null
)
as 
  declare
    @w_sp_name           varchar(30),
    @w_error_santander   int,
    @w_tipo_error        int,
    @w_id_file_ien       varchar(10),
	@w_tipo_trn_cobro    catalogo,
	@w_tipo_trn_pago     catalogo,
	@w_id_file_ien_cob   int,
	@w_id_file_ien_pag   int

	
  select @w_sp_name = 'sp_log_pagos'
  
  select @w_tipo_error  = codigo 
  from   cobis..cl_tabla 
  where tabla = 'ca_tipo_error'
  
  select @w_error_santander = codigo 
  from   cobis..cl_tabla 
  where tabla = 'ca_errores_santander_pagos'
  

  if @i_num_prestamo = ''  select @i_num_prestamo = null
  if @i_num_cuenta   = ''  select @i_num_cuenta   = null
  if @i_tipo_error   = ''  select @i_tipo_error   = null
  if @i_referencia   = ''  select @i_referencia   = null
  if @i_archivo      = ''  select @i_archivo      = null

  
  select @w_tipo_trn_cobro = 'COBRO', 
         @w_tipo_trn_pago  = 'PGRFR'
		 
		 
  select @w_id_file_ien_cob = afd_id
  from cob_ien..ree_ien_agent_file_def 
  where afd_in_out           = 'IN' 
  and afd_transaction_type = @w_tipo_trn_cobro


  select @w_id_file_ien_pag = afd_id
  from cob_ien..ree_ien_agent_file_def 
  where afd_in_out           = 'IN' 
  and afd_transaction_type = @w_tipo_trn_pago
		 

  if @i_operacion = 'Q'
  begin 
    if @t_trn = 7301
    begin
        ----------------
        --ERRORES COBIS
        ----------------
        if @i_tipo_error = 'C'
        begin            
            select 'fechaGeneracionOrden'  = sl_fecha_gen_orden ,
                   'num.prestamo'          = sl_banco,
                   'num.cuenta'            = sl_cuenta,
                   'referencia'            = sl_referencia,
                   'archivoPago'           = sl_archivo,
                   'montoPago'             = sl_monto_pag,
                   'tipoError'             = sl_tipo_error,
                   'estado'                = sl_estado,                   
                   'mensajeError'          = isnull(sl_mensaje_err, mensaje),
                   'nombreCliente'         = ''
            from cob_cartera..ca_santander_log_pagos, cobis..cl_errores
            where sl_tipo_error = 'DC'              
              and (sl_banco      = @i_num_prestamo or @i_num_prestamo is null)
              and (sl_ente       = @i_cliente or @i_cliente is null)
              and (sl_referencia = @i_referencia or @i_referencia is null)
              and (sl_cuenta     = @i_num_cuenta or @i_num_cuenta is null) 
              and (sl_archivo    = @i_archivo or @i_archivo is null)                                                 
              and sl_fecha_gen_orden between isnull(@i_fecha_desde, sl_fecha_gen_orden) and isnull(@i_fecha_hasta, sl_fecha_gen_orden)
              and sl_estado = convert(varchar(10),numero)
        end 
        --------------------
        --ERRORES SANTANDER
        --------------------
        if @i_tipo_error = 'S'
        begin
            select 'fechaGeneracionOrden'  = cl.sl_fecha_gen_orden ,
                   'num.prestamo'          = cl.sl_banco,
                   'num.cuenta'            = cl.sl_cuenta,
                   'referencia'            = cl.sl_referencia,
                   'archivoPago'           = cl.sl_archivo,
                   'montoPago'             = cl.sl_monto_pag,
                   'tipoError'             = cl.sl_tipo_error,
                   'estado'                = cl.sl_estado,                   
                   'mensajeError'          = cl.sl_mensaje_err,
                   'nombreCliente'         = ''--co.op_nombre
              from cob_cartera..ca_santander_log_pagos cl,
                   cob_ien..ree_ien_transactions_files a,
                   cob_ien..ree_ien_file_transfer b
          --join cob_cartera..ca_operacion co ON cl.sl_banco = co.op_banco --eso quitar no va contra la ca_operacion ir contra tablas de ien
            where cl.sl_tipo_error = 'DS'                       
              and (cl.sl_ente    = @i_cliente or @i_cliente is null)
              and (cl.sl_banco   = @i_num_prestamo or @i_num_prestamo is null)
              and (cl.sl_cuenta  = @i_num_cuenta or @i_num_cuenta is null)
              and (cl.sl_referencia   = @i_referencia or @i_referencia is null)
              and cl.sl_fecha_gen_orden between isnull(@i_fecha_desde, cl.sl_fecha_gen_orden) and isnull(@i_fecha_hasta, cl.sl_fecha_gen_orden)
              and cl.sl_estado        in (select codigo from cobis..cl_catalogo where tabla = @w_error_santander)
              and cl.sl_archivo       = b.ftr_file_name
              and a.ftr_id            = b.ftr_id
              and a.ftr_id            = @w_id_file_ien_cob
        end
        ---------------------------
        --ERRORES PAGOS REFERIDOS
        ---------------------------
        if @i_tipo_error = 'P'
        begin             
            select distinct 
                   'fechaGeneracionOrden'  = cl.sl_fecha_gen_orden , --equivale a ftr_date en la tabla de ien
                   'num.prestamo'          = cl.sl_banco,
                   'num.cuenta'            = cl.sl_cuenta,
                   'referencia'            = cl.sl_referencia,
                   'archivoPago'           = cl.sl_archivo, --equivale b.ftr_file_name, en la tabla de ien
                   'montoPago'             = cl.sl_monto_pag,
                   'tipoError'             = cl.sl_tipo_error,
                   'estado'                = cl.sl_estado,                   
                   'mensajeError'          = isnull(cl.sl_mensaje_err, ce.mensaje),
                   'nombreCliente'         = (select op_nombre from cob_cartera..ca_operacion where op_banco = cl.sl_banco)
            from cob_cartera..ca_santander_log_pagos cl,
                 cobis..cl_errores ce,
                 cob_ien..ree_ien_transactions_files a,
                 cob_ien..ree_ien_file_transfer b 
           where cl.sl_tipo_error    = 'P'
             and (cl.sl_banco   = @i_num_prestamo or @i_num_prestamo is null)
             and (cl.sl_referencia   = @i_referencia or @i_referencia is null)
             and (cl.sl_cuenta       = @i_num_cuenta or @i_num_cuenta is null) 
             and (cl.sl_archivo      = @i_archivo or @i_archivo is null)                                                 
             and (cl.sl_ente         = @i_cliente or @i_cliente is null)
             and cl.sl_fecha_gen_orden between isnull(@i_fecha_desde, cl.sl_fecha_gen_orden) and isnull(@i_fecha_hasta, cl.sl_fecha_gen_orden)
             and cl.sl_estado          = convert(varchar(10),numero)
             and a.ftr_id              = b.ftr_id       
             and cl.sl_archivo         = b.ftr_file_name
             and b.afd_id              = @w_id_file_ien_pag
        end
        
        if @i_tipo_error = 'T'
        begin
            select 'fechaGeneracionOrden'  = sl_fecha_gen_orden ,
                   'num.prestamo'          = sl_banco,
                   'num.cuenta'            = sl_cuenta,
                   'referencia'            = sl_referencia,
                   'archivoPago'           = sl_archivo,
                   'montoPago'             = sl_monto_pag,
                   'tipoError'             = sl_tipo_error,
                   'estado'                = sl_estado,                   
                   'mensajeError'          = isnull(sl_mensaje_err, mensaje),
                   'nombreCliente'         = ''
            from cob_cartera..ca_santander_log_pagos, cobis..cl_errores
            where sl_tipo_error = 'DC'              
              and (sl_banco      = @i_num_prestamo or @i_num_prestamo is null)
              and (sl_ente       = @i_cliente or @i_cliente is null)
              and (sl_referencia = @i_referencia or @i_referencia is null)
              and (sl_cuenta     = @i_num_cuenta or @i_num_cuenta is null) 
              and (sl_archivo    = @i_archivo or @i_archivo is null)                                                 
              and sl_fecha_gen_orden between isnull(@i_fecha_desde, sl_fecha_gen_orden) and isnull(@i_fecha_hasta, sl_fecha_gen_orden)
              and sl_estado = convert(varchar(10),numero)
            union   
            select 'fechaGeneracionOrden'   = cl.sl_fecha_gen_orden ,
                   'num.prestamo'          = cl.sl_banco,
                   'num.cuenta'            = cl.sl_cuenta,
                   'referencia'            = cl.sl_referencia,
                   'archivoPago'           = cl.sl_archivo,
                   'montoPago'             = cl.sl_monto_pag,
                   'tipoError'             = cl.sl_tipo_error,
                   'estado'                = cl.sl_estado,                   
                   'mensajeError'          = cl.sl_mensaje_err,
                   'nombreCliente'         = ''--co.op_nombre
              from cob_cartera..ca_santander_log_pagos cl,
                   cob_ien..ree_ien_transactions_files a,
                   cob_ien..ree_ien_file_transfer b
          --join cob_cartera..ca_operacion co ON cl.sl_banco = co.op_banco --eso quitar no va contra la ca_operacion ir contra tablas de ien
            where cl.sl_tipo_error = 'DS'                       
              and (cl.sl_ente       = @i_cliente or @i_cliente is null)
              and (cl.sl_banco      = @i_num_prestamo or @i_num_prestamo is null)              
              and (cl.sl_cuenta     = @i_num_cuenta or @i_num_cuenta is null)
              and (cl.sl_referencia = @i_referencia or @i_referencia is null)
              and cl.sl_fecha_gen_orden between isnull(@i_fecha_desde, cl.sl_fecha_gen_orden) and isnull(@i_fecha_hasta, cl.sl_fecha_gen_orden)
              and cl.sl_estado          in (select codigo from cobis..cl_catalogo where tabla = @w_error_santander)
              and cl.sl_archivo         = b.ftr_file_name
              and a.ftr_id              = b.ftr_id
              and a.ftr_id              = @w_id_file_ien_cob
            union
            select distinct 
                   'fechaGeneracionOrden'  = cl.sl_fecha_gen_orden , --equivale a ftr_date en la tabla de ien
                   'num.prestamo'          = cl.sl_banco,
                   'num.cuenta'            = cl.sl_cuenta,
                   'referencia'            = cl.sl_referencia,
                   'archivoPago'           = cl.sl_archivo, --equivale b.ftr_file_name, en la tabla de ien
                   'montoPago'             = cl.sl_monto_pag,
                   'tipoError'             = cl.sl_tipo_error,
                   'estado'                = cl.sl_estado,                   
                   'mensajeError'          = isnull(cl.sl_mensaje_err, ce.mensaje),
                   'nombreCliente'         = (select op_nombre from cob_cartera..ca_operacion where op_banco = cl.sl_banco)
            from cob_cartera..ca_santander_log_pagos cl,
                 cobis..cl_errores ce,
                 cob_ien..ree_ien_transactions_files a,
                 cob_ien..ree_ien_file_transfer b 
           where cl.sl_tipo_error    = 'PR'
             and (cl.sl_banco      = @i_num_prestamo or @i_num_prestamo is null)
             and (cl.sl_referencia = @i_referencia or @i_referencia is null)
             and (cl.sl_cuenta     = @i_num_cuenta or @i_num_cuenta is null) 
             and (cl.sl_archivo    = @i_archivo or @i_archivo is null) 
             and (cl.sl_ente       = @i_cliente or @i_cliente is null)
             and cl.sl_fecha_gen_orden between isnull(@i_fecha_desde, cl.sl_fecha_gen_orden) and isnull(@i_fecha_hasta, cl.sl_fecha_gen_orden)
             and cl.sl_estado      = convert(varchar(10),numero)
             and a.ftr_id          = b.ftr_id       
             and cl.sl_archivo     = b.ftr_file_name
             and b.afd_id          = @w_id_file_ien_pag    
        end
    end
  end

go

