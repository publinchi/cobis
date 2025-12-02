/************************************************************************/
/*  Archivo:                rev_buro_list_negras.sp                    */
/*  Stored procedure:       sp_rev_buro_list_negras                    */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Geovanny Guaman                             */
/*  Fecha de Documentacion: 23/Abr/2019                                 */
/************************************************************************/
/*                          IMPORTANTE                                  */
/*  Este programa es parte de los paquetes bancarios propiedad de       */
/*  COBISCORP S.A.representantes exclusivos para el Ecuador de la       */
/*  AT&T                                                                */
/*  Su uso no autorizado queda expresamente prohibido asi como          */
/*  cualquier autorizacion o agregado hecho por alguno de sus           */
/*  usuario sin el debido consentimiento por escrito de la              */
/*  Presidencia Ejecutiva de COBISCORP o su representante               */
/************************************************************************/
/*                           PROPOSITO                                  */
/*  SP GENERADO POR EXTRACCION DE LA BB.DD. cob_credito                 */ 
/*                                                                      */
/*                                                                      */
/************************************************************************/
/*                         MODIFICACIONES                               */
/*  FECHA             AUTOR            RAZON                            */
/*  23/04/19          gguaman        Emision Inicial                    */
/* **********************************************************************/

use cob_credito
go

if exists(select 1 from sysobjects where name ='sp_rev_buro_list_negras')
    drop proc sp_rev_buro_list_negras
go


CREATE PROC sp_rev_buro_list_negras
         @s_ssn        int         = NULL,
	     @s_ofi        smallint    = NULL,
	     @s_user       login       = NULL,
         @s_date       datetime    = NULL,
	     @s_srv		   varchar(30) = NULL,
	     @s_term	   descripcion = NULL,
	     @s_rol		   smallint    = NULL,
	     @s_lsrv	   varchar(30) = NULL,
	     @s_sesn	   int 	       = NULL,
	     @s_org		   char(1)     = NULL,
		 @s_org_err    int 	       = NULL,
         @s_error      int 	       = NULL,
         @s_sev        tinyint     = NULL,
         @s_msg        descripcion = NULL,
         @t_rty        char(1)     = NULL,
         @t_trn        int         = NULL,
         @t_debug      char(1)     = 'N',
         @t_file       varchar(14) = NULL,
         @t_from       varchar(30) = NULL,
         --variables
		 @i_id_inst_proc int,    --codigo de instancia del proceso
		 @i_id_inst_act  INT        = NULL,    
	   	 @i_id_empresa   INT        = NULL, 
		 @o_id_resultado  smallint  = NULL out		 
		 		 
AS

declare @w_tramite          INT,
        @w_cliente          INT,
        @w_toperacion       catalogo,
        @w_resultado_ln     SMALLINT,
        @w_resultado_br     VARCHAR(100),
        @w_resultado        VARCHAR(100),
        @w_grupo            INT       
        

---Número de operacion
SELECT @w_tramite = io_campo_3
FROM   cob_workflow..wf_inst_proceso
WHERE  io_id_inst_proc= @i_id_inst_proc

SELECT @w_toperacion = op_toperacion
FROM cob_cartera..ca_operacion OP 
WHERE op_tramite = @w_tramite

-- Busqueda del cliente

SELECT @w_resultado    = 'NOK'
SELECT @w_resultado_br = 'MALO'
SELECT @w_resultado_ln = 3

CREATE TABLE #cliente_tmp(
cliente_tmp INT
)
     
PRINT '---->>OPERACION:'+@w_toperacion

IF(@w_toperacion = 'GRUPAL')
BEGIN
    select @w_grupo = tg_grupo
    from   cr_tramite_grupal
    WHERE  tg_tramite       =   @w_tramite
    
    INSERT INTO #cliente_tmp
    SELECT tg_cliente
    FROM   cr_tramite_grupal
    WHERE  tg_tramite       =   @w_tramite
    AND    tg_participa_ciclo <> 'N'
    AND    tg_monto > 0
    order by tg_cliente	
END 
ELSE
BEGIN
    INSERT INTO #cliente_tmp
    SELECT op_cliente
    FROM   cr_tramite , cob_cartera..ca_operacion
    WHERE  tr_tramite = @w_tramite
    AND    op_tramite = tr_tramite
    
    INSERT INTO #cliente_tmp	
    SELECT tr_alianza FROM cr_tramite 
    WHERE tr_tramite = @w_tramite
    AND   tr_alianza IS NOT NULL	
END	

DECLARE cliente_tmp CURSOR FOR 
SELECT  cliente_tmp
FROM   #cliente_tmp
FOR read only

OPEN cliente_tmp    
FETCH cliente_tmp INTO @w_cliente

WHILE @@fetch_status = 0
BEGIN   
    
    EXEC sp_li_negra_cliente
    @i_ente         = @w_cliente,
    @o_resultado    = @w_resultado_ln OUTPUT
        
    PRINT '---->>>ID CLIENTE:'+convert(VARCHAR(30),@w_cliente) + '---->>>RESULTADO LISTA NEGRA:'+convert(VARCHAR(30),@w_resultado_ln)

    IF @w_resultado_ln != 1
    BREAK;
    
    IF @w_resultado_ln = 1
    BEGIN        
        IF(@w_toperacion = 'GRUPAL')
        BEGIN
            EXEC sp_var_buro_credito_grupal
            @i_grupo     = @w_grupo,
            @i_cliente   = @w_cliente,
            @o_resultado = @w_resultado_br OUTPUT
            
            IF @w_resultado_br != 'BUENO'
			BEGIN
			    select @w_resultado_ln = 3 
			    BREAK;
			END	
        END 
        ELSE
        BEGIN
            EXEC sp_var_calif_buro_cred_int
            @i_ente      = @w_cliente,
            @o_resultado = @w_resultado_br OUTPUT
                    
            IF @w_resultado_br != 'BUENO'
			BEGIN
			    select @w_resultado_ln = 3 
			    BREAK;
			END	
        END	        
            PRINT '---->>>ID CLIENTE:'+convert(VARCHAR(30),@w_cliente) + '---->>>RESULTADO BURO:'+convert(VARCHAR(30),@w_resultado_br)
    END
    
    FETCH cliente_tmp INTO @w_cliente
    
END -- WHILE

DROP TABLE #cliente_tmp
   
IF  @w_resultado_ln = 1 AND @w_resultado_br = 'BUENO'
SELECT @w_resultado = 'OK'    	
-- Select para ver si existe la regla    
-- 1 no esta y 3 si esta
PRINT '---->>sp_revis_buro_list_negras - @w_resultado:'+convert(VARCHAR(30),@w_resultado)

IF @w_resultado = 'OK'
begin
	SELECT @o_id_resultado = 1 -- OK
	PRINT 'Estamos en el OK'
end
ELSE
begin
	SELECT @o_id_resultado = 2 -- DEVOLVER
	PRINT 'Estamos en el DEVOLVER'
end

RETURN 0

GO
