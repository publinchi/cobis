/************************************************************************/
/*  Archivo              :      clauacel.sp                             */
/*  Stored procedure     :      sp_clausula_aceleratoria                */
/*  Base de datos        :      cob_cartera                             */
/*  Producto             :      Cartera                                 */
/*  Disenado por         :      Juan Carlos Espinosa V.                 */
/*  Fecha de escritura   :      8/Mayo/1998                             */
/************************************************************************/
/*                       IMPORTANTE                                     */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  'MACOSA'.                                                           */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier alteracion o agregado hecho por alguno de sus             */
/*  usuarios sin el debido consentimiento por escrito de la             */
/*  Presidencia Ejecutiva de MACOSA o su representante.                 */
/************************************************************************/
/*                          PROPOSITO                                   */
/*              Aplica la Clausula Aceleratoria sp externo              */
/*      FECHA               AUTOR                     MODIFICACIONES    */
/*      11/28/2002  Julio C Quintero  Aplicacion de la Clausula a todas */
/*                                    las obligaciones del Cliente,     */
/*                                    creando   un cursor de clientes   */
/*                                    que extraiga sus Operaciones      */
/*                                    activas.                          */
/*     02/06/2003   Julio C Quintero  Funcionalidad para aplicar Cl usu-*/
/*                                   la Aceleratoria a una sola Opera-  */
/*                                   ci¢n.                              */
/*     Ssep-05-2007 E.Pelaez         def. 8726 capitales pagados futuros*/
/************************************************************************/

use cob_cartera
go 


if exists (select 1 from sysobjects where name = 'sp_clausula_aceleratoria')
   drop proc sp_clausula_aceleratoria
go

create proc  sp_clausula_aceleratoria(
   @s_user          login,      
   @s_term          varchar(30),
   @s_date          datetime,   
   @s_ofi           smallint,   
   @i_cliente       int = null,             
   @i_en_linea      char(1),
   @i_opcion        char(1),         
   @i_banco         cuenta  = null   
)
as
declare
    @w_sp_name              varchar(32),
    @w_error                int,
    @w_return               int,
    @w_operacionca          int,
    @w_est_cancelado        tinyint,
    @w_est_credito          tinyint,
    @w_est_comext           tinyint,
    @w_est_anulado          tinyint,
    @w_est_novedades        tinyint

--- Captura nombre de Stored Procedure 
select  @w_sp_name = 'sp_clausula_aceleratoria'

begin tran

--- APLICA CLAUSULA ACELERATORIA A UNA SOLA OPERACION JCQ 02/06/2003 
if @i_opcion = 'O'
begin
    select @w_operacionca = op_operacion 
    from ca_operacion,
         ca_estado                    
    where op_banco = @i_banco
    and op_estado = es_codigo
    and es_procesa = 'S'
    and  op_clausula_aplicada = 'N'
    and  op_tipo <> 'R'
   
    if @@rowcount = 0 
    begin
        select @w_error =  724301
        goto ERROR
    end
    else
    begin
        exec @w_error  =  sp_clausula_aceleratoria_int
             @s_user         = @s_user,
             @s_term         = @s_term,
             @s_date         = @s_date,
             @s_ofi          = @s_ofi,
             @i_operacionca  = @w_operacionca,
             @i_en_linea     = @i_en_linea

        if @w_error <> 0 
           goto ERROR

    end
end

-- CURSOR DE CLIENTE PARA APLICAR CLAUSULA ACELERATORIA JCQ 11/28/2002 
if @i_opcion = 'C' 
begin
    declare clientes cursor for  
    select op_operacion 
    from ca_operacion,
         ca_estado                    
    where op_cliente = @i_cliente  
    and op_estado = es_codigo
    and es_procesa = 'S'
    and  op_clausula_aplicada = 'N'
    and  op_tipo <> 'R'
    order by op_operacion
    for read only

    open clientes

    fetch clientes 
    into @w_operacionca

--   while @@fetch_status not in (-1,0)
    while @@fetch_status = 0
    begin
        if (@@fetch_status = -1)
        begin
            close clientes
            deallocate clientes
            select @w_error = 710004   -- Error en la lectura del cursor
        end
        exec @w_error  =  sp_clausula_aceleratoria_int
             @s_user         = @s_user,
             @s_term         = @s_term,
             @s_date         = @s_date,
             @s_ofi          = @s_ofi,
             @i_operacionca  = @w_operacionca,
             @i_en_linea     = @i_en_linea
       
        if  @w_error <> 0
        begin
            close clientes
            deallocate clientes
            goto ERROR
        end
              
        goto SIGUIENTE
       
        SIGUIENTE:
        fetch clientes 
        into @w_operacionca

    end -- CURSOR CLIENTES 
    close clientes
    deallocate clientes
end

commit tran

return 0

ERROR:

exec cobis..sp_cerror
     @t_debug = 'N',
     @t_from  = @w_sp_name,
     @i_num   = @w_error

return @w_error

go