/*************************************************************************/
/*   Archivo:            sp_consulta_candidata_castigo.sp                */
/*   Stored procedure:   sp_consulta_candidata_castigo                   */
/*   Base de datos:      cob_credito                                     */
/*   Producto:           Originación - Solicitud de Castigo              */
/*   Disenado por:       Diego Castro                                    */
/*   Fecha de escritura: 05-08-2015                                      */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Este programa es parte de los paquetes bancarios propiedad de       */
/*   'MACOSA', representantes exclusivos para el Ecuador de NCR          */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier acion o agregado hecho por alguno de sus                  */
/*   usuarios sin el debido consentimiento por escrito de la             */
/*   Presidencia Ejecutiva de MACOSA o su representante.                 */
/*************************************************************************/
/*                                  PROPOSITO                            */
/*   Este procedimiento almacenado, permite dar mantenimiento a la tabla */
/*   cob_cartera..ca_candidata_castigo                                   */
/*************************************************************************/
/*     I                 Creacion de Castigo - Cambio de estado          */
/*     U                 Actualizacion de Castigo                        */
/*     D                 Eliminacion de castigo                          */
/*     S          A      Listado de operaciones candidatas               */
/*     Q          A      Consulta de de una Operacion candidata          */
/*************************************************************************/
/*                                MODIFICACIONES                         */
/*   FECHA           AUTOR                       RAZON                   */
/*   05-08-2015  Diego Castro             Emision Inicial                */
/*   29-07-2016  Pablo Gaibor             Integracion CPA                */
/*   02-01-2018  ALF                      Migracion          .           */
/*************************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_consulta_candidata_castigo')
    drop proc sp_consulta_candidata_castigo
go

CREATE PROCEDURE sp_consulta_candidata_castigo(

   @s_ssn                  int          = null,
   @s_user                 login        = null,
   @s_sesn                 int          = null,
   @s_term                 varchar(30)  = null,
   @s_date                 datetime     = null,
   @s_srv                  varchar(30)  = null,
   @s_lsrv                 varchar(30)  = null,
   @s_rol                  smallint     = null,
   @s_ofi                  smallint     = null,
   @s_org_err              char(1)      = null,
   @s_error                int          = null,
   @s_sev                  tinyint      = null,
   @s_msg                  descripcion  = null,
   @s_org                  char(1)      = null,
   @t_debug                char(1)      = 'N',
   @t_file                 varchar(14)  = null,
   @t_from                 varchar(32)  = null,
   @t_trn                  int          = null,
   @i_operation            char(1)      = null,      -- Operacion que se realiza en el store procedure,

   -----------------------------------------
   --Variables de castigo
   -----------------------------------------
   @i_num_operacion      int           = null,
   @i_check              char(1)       = 'N'
)

as

declare

   @w_return                int,                       -- Codigo de retorno del reclamo
   @w_sp_name               varchar(30),               -- Nombre del store procedure 
   @w_num_error             int,                       -- Numero de error que se envia al store procedure sp_cerror
   -----------------------------------------
   --Variables internas de castigo 
   -----------------------------------------
   @w_date_rate            datetime,
   @w_oficial                                     int,
   @w_alternate_code                  varchar(50),
   @w_numero_juicio   varchar(250),  
   @w_estado_cobranza  varchar(250), 
   @w_problema     varchar(250), 
   @w_razones      varchar(250), 
   @w_razones2     varchar(250), 
   @w_imp_pago     varchar(250), 
   @w_imp_pago2    varchar(250),
   @w_paramMassive char(2),
   @w_masiva       char(1)

-----------------------------------------
--Inicializacion de Variables
-----------------------------------------
       
select @w_sp_name        = 'sp_consulta_candidata_castigo'
    
select @w_paramMassive = pa_char from cobis..cl_parametro 
                where pa_nemonico = 'CASOMA'
       
-----------------------------------------
--Control Transacciones vs. Operaciones
-----------------------------------------

if (@t_trn != 87000 and @i_operation = 'I')
   or (@t_trn != 21682 and (@i_operation = 'U' or @i_operation = 'R'))
   or (@t_trn != 87002 and @i_operation = 'D')
   or (@t_trn != 21681 and @i_operation = 'S')
   or (@t_trn != 87004 and (@i_operation = 'Q'  or @i_operation = 'V'))

begin
   select @w_num_error = 151051 --Transaccion no permitida
   goto errores
end


----------------------------------------
--  Carga de Datos de Parametrizacion --
----------------------------------------
if @i_operation = 'U'
begin
                
        select @w_date_rate = max(cc_fecha_corte) 
        from cob_cartera..ca_candidata_castigo 
                
        update cob_cartera..ca_candidata_castigo
        set cc_estado_castigo=99
        where cc_fecha_corte   = @w_date_rate  
        and cc_operacion       = @i_num_operacion

end --@i_operation = 'U'


if @i_operation = 'S'
begin
                           
        select @w_oficial = oc_oficial from cobis..cl_funcionario, cobis..cc_oficial
        where fu_login = @s_user
        and   oc_funcionario = fu_funcionario
        
        select @w_date_rate = max(cc_fecha_corte) 
          from cob_cartera..ca_candidata_castigo
                         
            select    'CC_Operacion'               = A.cc_operacion,
                        'CC_Banco'                   = ltrim(rtrim(A.cc_banco)),
                        'CC_Cliente'                 = ltrim(rtrim(B.op_nombre)),
                        'CC_Estado_Operacion'        = A.cc_estado,
                        'CC_Saldo_Capital'           = A.cc_saldo_cap,
                        'CC_Saldo_Interes'           = A.cc_saldo_int,
                        'CC_Saldo_Mora'              = A.cc_saldo_mora,
                        'CC_Saldo_Otros_Conceptos'   = A.cc_saldo_otros,
                        'CC_Fecha_Ultimo_Plazo'      = A.cc_fecha_ult_pago,
                        'CC_Dias_Mora'               = A.cc_dias_mora,
                        'CC_FechaCorte'              = A.cc_fecha_corte,
            'CC_IdCLiente'               = B.op_cliente,
            'CC_OperationType'       = ISNULL((select bp_name 
                            from cob_fpm..fp_bankingproducts 
                            where bp_product_id = B.op_toperacion),B.op_toperacion),
                        'CC_Check'                   = isnull(A.cc_check, 'N') --case A.cc_check when 'S' then 1 else 0 end
                from cob_cartera..ca_candidata_castigo              A, 
                     cob_cartera..ca_operacion                      B
                where A.cc_fecha_corte=@w_date_rate
                and A.cc_estado_castigo =0
        and B.op_operacion = A.cc_operacion
        and A.cc_oficial   = @w_oficial
        and A.cc_banco not in (select ca_banco from cob_credito..cr_tr_castigo
                                where ca_fecha_corte = @w_date_rate
                                  and ca_estado in ('R', 'G') and @w_paramMassive = 'S')
        order by A.cc_masiva desc --A.cc_fecha_corte,  A.cc_banco
        


end -- @i_operation = 'S'

if @i_operation = 'R' --CHECK DE OPERACION
begin
                
        select @w_date_rate = max(cc_fecha_corte) 
        from cob_cartera..ca_candidata_castigo 
                
        update cob_cartera..ca_candidata_castigo
           set cc_check = @i_check
         where cc_fecha_corte   = @w_date_rate  
         and cc_operacion       = @i_num_operacion

end --@i_operation = 'R'

if @i_operation = 'V' -- VALIDA OPERACION
begin              
        select @w_date_rate = max(cc_fecha_corte) 
        from cob_cartera..ca_candidata_castigo 
                
        if @i_check = 'S'
        begin
           select @w_numero_juicio  = isnull(ca_numero_juicio,''),  
                  @w_estado_cobranza = isnull(ca_estado_cobranza,''), 
                  @w_problema    = isnull(ca_problema,''), 
                  @w_razones     = isnull(ca_razones,'')
             from cob_cartera..ca_candidata_castigo a, cr_tr_castigo b
            where cc_fecha_corte = @w_date_rate  
              and cc_banco       = ca_banco
              and cc_operacion   = @i_num_operacion
              and isnull(cc_check,'N')       = 'N'
        
           if (@w_numero_juicio = '' or @w_estado_cobranza = '' or @w_problema    = '' or 
               @w_razones    = '' )
           begin
                  select @w_num_error = 151051 --Transaccion no permitida
                    goto errores
           end
        end
end --@i_operation = 'V'

goto fin

-----------------
--Control errores
-----------------
errores:
   exec cobis..sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_num_error
   return @w_num_error
fin:
return 0
                                                                                                                                                                                                                              

GO

