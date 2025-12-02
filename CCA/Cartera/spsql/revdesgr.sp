/******************************************************************/
/*  Archivo:            revdesgr.sp                               */
/*  Stored procedure:   sp_reversa_desem_grupal                   */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Lorena Regalado                           */
/*  Fecha de escritura: 01-Ago-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de COBISCORP o su representante.        */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Interface de Creacion de Operaciones                       */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  01/Ago/19        Lorena Regalado    Reversa desembolso        */
/*                                      Operaciones Grupales      */
/*  01/Jun/22        Guisela Fernandez  Se comenta prints         */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_reversa_desem_grupal')
   drop proc sp_reversa_desem_grupal
go

create proc sp_reversa_desem_grupal
   @i_secuencial           int,
   @s_sesn                 int            = null,
   @s_ofi                  smallint     = null,
   @s_ssn                  int            = null,
   @s_user                 login          = null,
   @s_term                 varchar(30)    = null,
   @s_date                 datetime       = NULL,
   @i_banco                cuenta,                            --Operacion Grupal para los interciclos
   @i_es_interciclo        char(1)        = 'N',
   --LRE 03Ago @i_secuencial_seg       varchar(100),
   @i_fecha_proceso        datetime 


as declare
   @w_sp_name              varchar(30),
   @w_error                int,
   @w_mensaje              varchar(500),
   @w_operacion            int,
   @w_moneda               int,
   @w_oficina              int,
   @w_return               int,
   @w_cta_grupal           cuenta,
   @w_fecha_proceso        datetime,
   @w_grupo                int,
   @w_tramite              int,
   @w_bandera_be           char(1)

select @w_bandera_be = 'N'

--GFP se suprime print
--print 'Entro a procesos propios de Grupales TEC '  + 'Banco ' +  @i_banco

--Obtengo los datos de la Operacion

select @w_operacion  = op_operacion,
       @w_moneda     = op_moneda,
       @w_oficina    = op_oficina,
       @w_cta_grupal = op_cuenta,
       @w_grupo      = op_grupo,
       @w_tramite    = op_tramite
from cob_cartera..ca_operacion
where op_banco = @i_banco

if @@rowcount = 0 
begin
   select @w_error = 701025
   goto ERROR
end

--GFP se suprime print
--print 'Antes del sp_debito_seguros'
   
--Reverso los Seguros y ND de los mismos
--OJO EN EL CASO DE REVERSA DE DESEMBOLSO GRUPAL CAMBIAR EL ESTADO DEL SEGURO A C(CANCELADO)
execute @w_return = sp_debito_seguros
   @s_ssn            = @s_ssn,
   @s_sesn           = @s_sesn,
   @s_user           = @s_user,
   @s_date           = @s_date,
   @s_ofi            = @w_oficina,
   @i_operacion      = @w_operacion,
   @i_cta_grupal     = @w_cta_grupal,
   @i_moneda         = @w_moneda,
   @i_fecha_proceso  = @i_fecha_proceso, 
   @i_oficina        = @w_oficina,
   @i_secuencial_trn = @i_secuencial,
   @i_es_interciclo  = @i_es_interciclo,
   @i_op_interciclo  = @w_operacion,
   --LRE 03Ago2019 @i_sec_seguros    = @i_secuencial_seg ,   
   @i_opcion         = 'R',  --Reversa
   @i_origen         = 'G'   --Reversa de Desembolso Grupal
        
   if @w_return <> 0
   begin
      --GFP se suprime print
      --print 'ERROR AL EJECUTAR DEBITOS SEGUROS ' + cast (@i_banco as varchar)
      select @w_error = @w_return
      select @w_sp_name = 'cob_cartera..sp_debito_seguros'
      goto ERROR
   end  

  --INI AGI 22AGO19 APLICACION REVERSO NOTA DEBITO/CREDITO POR INCENTIVOS
        
    exec @w_error =  sp_incentivos_grp
         @s_ssn               = @s_ssn,
         @s_sesn              = @s_sesn,
         @s_user              = @s_user,
         @s_date              = @s_date,
         @s_ofi               = @s_ofi,
         @s_term              = @s_term,
         @i_opcion            = 'R',
         @i_operacion         = @w_operacion, 
         @i_secuencial_trn    = @i_secuencial,
         @o_mensaje           = @w_mensaje out
         
    if @w_error != 0 
    begin
	    --GFP se suprime print
        --print 'ERROR INSERTANDO INCENTIVO DE CREDITO' + cast (@w_error as varchar)
        select @w_mensaje = 'Error insertando Incentivo de Credito:  '  + cast(@w_error as varchar)
        select @w_error = 725061
        goto ERROR  
    end
    --FIN AGI
    
    
--Reversar las Ordenes de Desembolso
/*
print 'Antes del sp_reversar_desembolso_cartera' + 'Grupo ' + cast(@w_grupo as varchar) + 'Operacion ' + cast(@w_operacion as varchar)

execute @w_return      =  cob_bancos..sp_reversar_desembolso_cartera
    @s_ssn             = @s_ssn,
    @s_user            = @s_user,
    @s_ofi             = @s_ofi,
    @s_date            = @s_date,
    @i_grupo           = @w_grupo,
    @i_car_operacion   = @w_operacion

if @w_return <> 0
begin
   print 'ERROR AL EJECUTAR REVERSO DE ORDENES DE PAGO ' + cast (@i_banco as varchar)
   select @w_error = @w_return
   select @w_sp_name = 'cob_bancos..sp_reversar_desembolso_cartera'
   goto ERROR
end  
*/

--Cancelar las Garantias
--GFP se suprime print
--print 'antes del sp_activar_garantia TRAMITE: ' + cast(@w_tramite as varchar)

   exec @w_error = cob_custodia..sp_activar_garantia
   @i_opcion         = 'C',
   @i_tramite        = @w_tramite,
   --@i_reconocimiento = @w_reconocimiento,
   @i_modo           = 2,
   @i_operacion      = 'I',
   @s_ssn            = @s_ssn,
   @s_date           = @s_date,
   @s_user           = @s_user,
   @s_term           = @s_term,
   @s_ofi            = @s_ofi,
   @i_bandera_be     = @w_bandera_be,
   @i_rev_des        = 'S'            --Solo se activa en la reversa del desembolso
   
   if @@error <> 0 return 708201
   if @w_error <> 0 return @w_error  


--Actualizar el estado de las hijas a R

  update cob_cartera..ca_operacion set op_estado_hijas = 'R'
  where op_banco = @i_banco

  if @@error <> 0
  begin
 	select @w_error = 725030
	goto ERROR 
  end

  
  

return 0

ERROR:

        
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error,
    @i_msg    = ' Error en Reversa de Desembolso Grupal',
    @i_sev    = 0
   
   return @w_error
   
go

