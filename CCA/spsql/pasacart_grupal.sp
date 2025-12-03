/************************************************************************/
/*  NOMBRE LOGICO:        pasacart_grupal.sp                            */
/*  NOMBRE FISICO:        sp_pasa_cartera_grupal                        */
/*  BASE DE DATOS:        cob_cartera                                   */
/*  PRODUCTO:             CARTERA                                       */
/*  DISENADO POR:         Kevin Rodriguez                               */
/*  FECHA DE ESCRITURA:   24/Junio/2021                                 */
/************************************************************************/
/*                                  IMPORTANTE                          */
/*   Este programa es parte de los paquetes bancarios que son           */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,      */
/*   representantes exclusivos para comercializar los productos y       */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida     */
/*   y regida por las Leyes de la República de España y las             */
/*   correspondientes de la Unión Europea. Su copia, reproducción,      */
/*   alteración en cualquier sentido, ingeniería reversa,               */
/*   almacenamiento o cualquier uso no autorizado por cualquiera        */
/*   de los usuarios o personas que hayan accedido al presente          */
/*   sitio, queda expresamente prohibido; sin el debido                 */
/*   consentimiento por escrito, de parte de los representantes de      */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto      */
/*   en el presente texto, causará violaciones relacionadas con la      */
/*   propiedad intelectual y la confidencialidad de la información      */
/*   tratada; y por lo tanto, derivará en acciones legales civiles      */
/*   y penales en contra del infractor según corresponda.               */
/************************************************************************/
/*                                   PROPOSITO                          */
/*   Pasar a cartera el tramite grupal de credito.                      */
/*                                                                      */
/************************************************************************/
/*                            CAMBIOS                                   */
/************************************************************************/
/*   FECHA        AUTOR                    RAZON                        */
/* 24/Jun/2021   Kevin Rodriguez      Version inicial                   */
/*   14/Jun/22   Dilan Morales      Se divide actulizacion de estado y  */
/*                                  numero de banco haciendo uso de     */
/*                                  @i_operacion = B o E.               */
/*   07/Jun/23   Kevin Rodríguez    S809862 Tipo Documento. tributario  */
/*   26/Sep/23   Kevin Rodríguez    S910674-R216163 Ajuste asignación   */
/*                                  Tipo Doc. tributario                */
/************************************************************************/

use cob_cartera
go

if exists (select 1 from sysobjects where name = 'sp_pasa_cartera_grupal')
   drop proc sp_pasa_cartera_grupal
go

create  proc sp_pasa_cartera_grupal (
@s_ofi                  SMALLINT = null,
@s_user                 login    = null,
@s_date                 DATETIME = NULL ,
@s_term                 descripcion = null,
@s_ssn                  INT      = null,
@i_operacion            char(1)  =null,
@i_tramite              INT,                     -- tramite grupal padre
@o_num_banco_padre      varchar(24) = null OUT
)
as declare
@w_sp_name           varchar(30),
@w_error             INT,
@w_banco_padre       cuenta,
@w_banco_hijo        cuenta,
@w_operacion_padre   INT,
@w_operacion_hijo    INT,
@w_estado_padre      TINYINT,
@w_estado_hijo       TINYINT,
@w_oficina_padre     smallint,
@w_oficina_hijo      smallint,
@w_cliente_hijo      int,
@w_tramite_hijo      int,
@w_est_novigente     smallint,
@w_est_credito       SMALLINT,
@w_es_grupal         char(1),
@w_cont              INT,
@w_tipo_doc_fiscal   varchar(3)

-- VARIABLES DE TRABAJO  
select @w_sp_name        = 'sp_pasa_cartera_grupal'

-- OBTENER ESTADOS DE CARTERA
exec @w_error = sp_estados_cca 
@o_est_novigente  = @w_est_novigente out,
@o_est_credito    = @w_est_credito   out

if @w_error <> 0 GOTO ERROR

-- Datos de la operacion Padre
select 
@w_operacion_padre = op_operacion,
@w_banco_padre     = op_banco,
@w_estado_padre    = op_estado,
@w_oficina_padre   = op_oficina
from  ca_operacion
where op_tramite = @i_tramite

if @@rowcount = 0
BEGIN
   select @w_error = 710022 -- No existe la operacion
   goto ERROR  
end


--Borrado de temporales si existan
IF exists(select 1 from ca_operacion_tmp where opt_operacion = @w_operacion_padre)
begin
    exec @w_error = sp_borrar_tmp
             @s_sesn   = @s_ssn,
             @s_user   = @s_user,
             @s_term   = @s_term,
             @i_banco  = @w_operacion_padre
             
    if @w_error != 0  goto ERROR
end
      

-- Verificar que sea una operacion grupal padre
exec @w_error = sp_tipo_operacion
     @i_banco  = @w_banco_padre,
     @o_tipo   = @w_es_grupal out

if @w_error <> 0 goto ERROR

IF @w_es_grupal <> 'G'
BEGIN
   select @w_error = 70203 -- ERROR: OPERACION NO EXISTE O NO ES UNA OPERACION GRUPAL
   goto ERROR   
END


IF @w_estado_padre NOT IN (@w_est_credito)
BEGIN
   select @w_error = 711094  -- Error, la operacion debe estar en estado Credito
   goto ERROR   
end


IF @i_operacion = 'B'
BEGIN 
    -- Generacion de nuevo numero de banco Padre
    exec @w_error = cob_cartera..sp_numero_oper
               @s_date        = @s_date,
               @i_oficina     = @w_oficina_padre,
               @i_operacionca = @w_operacion_padre, 
               @o_num_banco   = @w_banco_padre  out

    if @w_error != 0 
       begin
          select @w_error = 710074 -- Numero de operacion anterior no existe
          goto   ERROR
       end 

    update ca_operacion set 
    op_banco  = @w_banco_padre
    where op_tramite = @i_tramite 

    if @@error <> 0 
    begin
        select @w_error = 710002 -- Error en la actualizacion del registro
        goto ERROR
    END
    
    update ca_ciclo with (UpdLock)
    set ci_prestamo = @w_banco_padre
    where ci_operacion = @w_operacion_padre

    if @@error <> 0 
    begin
        select @w_error = 710002 -- Error en la actualizacion del registro
        goto ERROR
    END

END


IF @i_operacion = 'E'
BEGIN
    update ca_operacion set 
    op_estado = @w_est_novigente
    where op_tramite = @i_tramite

    if @@error <> 0 
    begin
        select @w_error = 710002 -- Error en la actualizacion del registro
        goto ERROR
    END
END


-- GeneraciOn de nuevo numero de banco a los hijos y
-- actualizacion de estado y nuevo numero banco hijos
select ca_operacion.* into #op_hijas FROM ca_operacion, cob_credito..cr_tramite_grupal  --PQU 02/09/2021
   WHERE tg_tramite = @i_tramite
   AND tg_operacion = op_operacion
   and tg_participa_ciclo = 'S'

if @@rowcount = 0
BEGIN
   select @w_error = 711095 -- Error, la operacion padre no tiene operaciones hijas asociadas
   goto ERROR  
end

select @w_cont = count(1) from #op_hijas

while  @w_cont > 0
BEGIN

    -- Datos de la operacion Hija
    SELECT TOP 1
        @w_banco_hijo     = op_banco,
        @w_operacion_hijo = op_operacion,
        @w_estado_hijo    = op_estado,
        @w_oficina_hijo   = op_oficina,
		@w_cliente_hijo   = op_cliente,
		@w_tramite_hijo   = op_tramite
    from #op_hijas

    IF @w_estado_hijo NOT IN (@w_est_credito)
    BEGIN
       select @w_error = 711094  -- Error, la operacion debe estar en estado Credito
       goto ERROR  
    END

    IF @i_operacion = 'B'
    BEGIN
        -- Generacion de nuevo numero de banco Hijo(s)
        exec @w_error = cob_cartera..sp_numero_oper
                   @s_date        = @s_date,
                   @i_oficina     = @w_oficina_hijo,
                   @i_operacionca = @w_operacion_hijo,
                   --@o_operacion   = @w_operacion_hijo out, 
                   @o_num_banco   = @w_banco_hijo  out
        
        if @w_error != 0 
        begin
            select @w_error = 710074 -- Numero de operacion anterior no existe
            goto   ERROR
        END
        
        update ca_operacion set 
        op_banco      = @w_banco_hijo,
        op_ref_grupal = @w_banco_padre
        where op_operacion = @w_operacion_hijo
        
        if @@error <> 0 
        begin
            select @w_error = 710002
            goto ERROR
        END
        
        update ca_det_ciclo with (UpdLock)
        set dc_referencia_grupal = @w_banco_padre
        where dc_operacion = @w_operacion_hijo
        
        if @@error <> 0 
        begin
            select @w_error = 710002
            goto ERROR
        END
    
    END
    
    IF @i_operacion = 'E'
    BEGIN
    
        update ca_operacion set 
        op_estado     = @w_est_novigente
        where op_operacion = @w_operacion_hijo
        
        if @@error <> 0 
        begin
            select @w_error = 710002
            goto ERROR
        END
    END
	
	-- Actualiza tipo de documento fiscal (Solo a operaciones que no han sido desembolsadas)
    exec sp_func_facturacion
    @i_operacion       = 'D', -- Identificar tipo documento tributario
    @i_opcion          = 0,
    @i_tramite         = @w_tramite_hijo,
    @o_tipo_doc_fiscal = @w_tipo_doc_fiscal out
	
    update ca_operacion_datos_adicionales
    set oda_tipo_documento_fiscal = @w_tipo_doc_fiscal
    where oda_operacion = @w_operacion_hijo
    
    if @@error <> 0
    begin
       select @w_error = 710002 -- Error en la actualizacion del registro
   	   goto ERROR
    end 

    delete #op_hijas where op_operacion = @w_operacion_hijo   
    SELECT @w_cont = count(1) from #op_hijas
    
END

DROP TABLE #op_hijas

-- Retorna el numero de banco padre
select @o_num_banco_padre = @w_banco_padre 

return 0

ERROR:

IF OBJECT_ID ('dbo.#op_hijas') IS NOT NULL
    DROP TABLE dbo.#op_hijas

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error
GO





