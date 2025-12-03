/******************************************************************/
/*  Archivo:            busgrupal.sp                              */
/*  Stored procedure:   sp_busqueda_grupales                      */
/*  Base de datos:      cob_cartera                               */
/*  Producto:           Cartera                                   */
/*  Disenado por:       Adriana Giler                             */
/*  Fecha de escritura: 05-Jun-2019                               */
/******************************************************************/
/*                        IMPORTANTE                              */
/*  Este programa es parte de los paquetes bancarios propiedad de */
/*  'COBISCORP', representantes exclusivos para el Ecuador de la  */
/*  'NCR CORPORATION'.                                            */
/*  Su uso no autorizado queda expresamente prohibido asi como    */
/*  cualquier alteracion o agregado hecho por alguno de sus       */
/*  usuarios sin el debido consentimiento por escrito de la       */
/*  Presidencia Ejecutiva de MACOSA o su representante.           */
/******************************************************************/
/*                                 PROPOSITO                      */
/*   Este programa permite:                                       */
/*   - Obtener Operaciones grupales cuyas hijas estan pendientes  */
/*     de creacion y dispara el proceso que crea operaciones hija */
/******************************************************************/
/*                        MODIFICACIONES                          */
/*  FECHA              AUTOR            RAZON                     */
/*  18/10/2019       J-Calvillo      Se valida Rol 'D'            */
/******************************************************************/
use cob_cartera
go
if exists (select 1 from sysobjects where name = 'sp_busqueda_grupales')
   drop proc sp_busqueda_grupales
go

create proc sp_busqueda_grupales
   @s_sesn                 int          = null,
   @s_date                 datetime     = null,
   @t_trn                  int          = null,
   @s_user                 login        = null,
   @s_culture              varchar(10)  = null,
   @s_term                 varchar(30)  = null,
   @s_ssn                  int          = null,
   @s_org                  char(1)      = null,
   @s_srv                  varchar (30) = null,
   @s_ofi                  smallint     = null,
   @s_lsrv                 varchar (30) = null,
   @s_rol                  int          = null

   
as declare
   @w_sp_name              varchar(30),
   @w_return               int,
   @o_error                int,
   @w_mensaje              varchar(64),
   @w_oper_padre           int,
   @w_oper_min             int,
   @w_clte_error           int,
   @w_error                int,
   @w_mesaje               varchar(100),
   @w_count                int,
   @w_count_hija           int,
   @w_secuencia            int,
   @w_sec_hijas            varchar(200),
   @w_fecha_proceso        datetime,
   @w_ssn                  int,
   @w_oficina              smallint

select @w_sp_name = 'sp_busqueda_grupales',
       @w_return  = 0


select @w_fecha_proceso = fp_fecha
from cobis..ba_fecha_proceso

--OBTENIENDO DATOS DE OPERACIONES PADRES SIN HIJAS CREADAS
select @w_oper_min = 0

exec @s_sesn = ADMIN...rp_ssn

While 1=1
begin
    select @w_oper_padre = 0
  
    select @w_oper_padre = min(op_operacion)    
    from ca_operacion
    where op_estado_hijas  = 'I'
    and   op_grupal    = 'S'
    and   op_operacion > @w_oper_min
    
    select @w_oper_min = @w_oper_padre
    
    --Seteando variables de sistema
    select @w_oficina = op_oficina
    from ca_operacion
    where op_operacion = @w_oper_padre       
   
   if @w_oper_padre > 0
    begin
       exec @s_sesn = ADMIN...rp_ssn
       
       select  @s_user = 'ASIN_HIJA',
               @s_date = @w_fecha_proceso,
               @s_term = 'TERM1',
               @s_ofi  = @w_oficina,                   
               @s_srv  = 'CENTRAL'
               
        --INI AGI. Obtener Secuencia de las hijas
        select @w_count_hija = count(1)
        from ca_interf_hijas_tmp
        where iht_operacion = @w_oper_padre
        and iht_rol<>'D'  --Se descrimina si es desertor
        
        select @w_sec_hijas = ''
        
        select @w_count = 1
        
        while @w_count <= @w_count_hija 
        begin
            exec @w_secuencia = ADMIN...rp_ssn
            
            select @w_sec_hijas = @w_sec_hijas + convert(varchar,@w_secuencia)+"|"
            
            select @w_count = @w_count + 1
        end    
        --FIN AGI
        
        Begin Tran
            exec @w_return = sp_crear_operacion_grp
                 @s_user      = @s_user,  
                 @s_date      = @s_date,  
                 @s_term      = @s_term, 
                 @s_ofi       = @s_ofi,   
                 @t_trn       = @t_trn,   
                 @s_lsrv      = @s_lsrv,
                 @i_opcion    = 'I',  -- Ingreso de Operaciones Grupales
                 @i_operacion = @w_oper_padre,
                 @i_sec_hijas = @w_sec_hijas,
                 @o_clte_err  = @w_clte_error out ,
                 @o_mensaje   = @w_mensaje    out
                 
            if @w_return != 0
            begin
                Rollback Tran

                --Registrar la operacion Padre con Error
                update ca_operacion
                set op_estado_hijas = 'E'
                where op_operacion = @w_oper_padre

                if @@error != 0 
                begin
                    select @w_error = 725030
                    goto ERROR
                end
                            
                --Registra el log de Errores de la hija
                insert ca_interf_hijas_log (ihl_sesn,    ihl_user,       ihl_ofi,    ihl_fecha_proceso,
                                           ihl_cliente, ihl_operacion,  ihl_estado, ihl_detalle)
                values (@s_sesn,       @s_user,       @s_ofi, @s_date,
                       @w_clte_error, @w_oper_padre, 'E',    @w_mensaje )
                if @@error != 0 
                begin
                    select @w_error = 725031
                    goto ERROR
                end
               
            end   
            else
            begin
                --Registrar la operacion Padre como Procesada
                update ca_operacion
                set op_estado_hijas = 'P'
                where op_operacion = @w_oper_padre
                
                if @@error != 0 
                begin
                    select @w_error = 725030
                    goto ERROR
                end
            
                Commit Tran
            end
    end                       
    else
        break            
end

return 0

ERROR:
    exec cobis..sp_cerror
    @t_debug  ='N',
    @t_file   = null,
    @t_from   = @w_sp_name,
    @i_num    = @w_error

    return @w_error