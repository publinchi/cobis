USE cob_cartera
GO


IF OBJECT_ID ('dbo.sp_desembolso_grupal') IS NOT NULL
    DROP PROCEDURE dbo.sp_desembolso_grupal
GO


/*************************************************************************/
/*   Archivo             :       sp_desembolso_grupal.sp                 */
/*   Stored procedure    :       sp_desembolso_grupal                    */
/*   Base de datos       :       cob_cartera                             */
/*   Producto            :       Cartera                                 */
/*   Disenado por        :       Fabian de la Torre                      */
/*   Fecha de escritura  :       Mar 2017                                */
/*************************************************************************/
/*                               IMPORTANTE                             */
/*   Este programa es parte de los paquetes bancarios propiedad de      */
/*   'COBISCORP'                                                        */
/*   Su uso no autorizado queda expresamente prohibido asi como         */
/*   cualquier alteracion o agregado hecho por alguno de sus            */
/*   usuarios sin el debido consentimiento por escrito de la            */
/*   Presidencia Ejecutiva de COBISCORP o su representante.             */
/*************************************************************************/
/*                             PROPOSITO                                 */
/*   Este programa genera la creacion de operaciones grupal              */
/*************************************************************************/
/*                          MODIFICACIONES                               */
/*   Jorge Salazar            22/Mar/2017    CGS-H105594                 */
/*   Luis Ponce               12/Abr/2017    Cambios Santander CR.Grupal */
/*   Jorge Salazar            19/May/2017    CGS-S112643                 */
/*   LGU                      13/Jul/2017    Ejecutar en dos partes      */
/*                                           1) Crear OP                 */
/*                                           2) Crear DES y LIQ          */
/*   LRE                      21/JUN/2019    Desembolso de operaciones   */
/*                                           Grupales TEC                */
/*   Kevin Rodríguez          16/Abr/2021    Admnistracion individual S  */
/*   Kevin Rodríguez          24/06/2022     Nuevo parámetro sp_liquid   */
/*************************************************************************/

create proc sp_desembolso_grupal
   @s_ssn              int          = null,
   @s_user             login,
   @s_rol              tinyint      = 3,
   @s_term             varchar(30),
   @s_date             datetime,
   @s_sesn             int          = null,
   @s_ofi              smallint,
   @s_srv	       varchar(30)  = null, 
   ---------------------------------------
   @i_anterior         cuenta       = null,
   @i_migrada          cuenta       = null,
   @i_tramite_grupal   int          = null,
   @i_oficina          smallint     = null,
   @i_reestructuracion varchar(1)   = null,
   @i_numero_reest     int          = null,
   @i_num_renovacion   int          = 0,
   @i_grupal           varchar(1)   = null,
   @i_tasa             float        = null,
   @i_en_linea         varchar(1)   = 'S',
   @i_externo          varchar(1)   = 'S',
   @i_desde_web        varchar(1)   = 'S',
   @i_salida           varchar(1)   = 'N',
   @i_fecha_ini        datetime     = null,
   @i_forma_pago       catalogo     = null,
   @i_forma_desembolso catalogo     = null,
   @i_formato_fecha    int          = 101,
   @i_etapa_flujo      varchar(10)  = 'FIN' -- LGU 2017-07-13: para ver en que momento se ccrea el DES y LIQ del prestamo
                                            -- (1) IMP: impresion: solo crear OP hijas
                                            -- (2) FIN: al final del flujo: crea DES y LIQ de OP hijas
   ---------------------------------------
as

declare
   @w_sp_name                varchar(64),
   @w_error                  int,
   @w_operacion              int,
   @w_tg_cuenta              cuenta,
   @w_nombre                 varchar(60),
   @w_tramite                int,
   @w_porc_garantia          float,
   @w_monto_garantia         money,
   @w_monto_total            money,
   @w_tg_grupo               int,
   @w_tg_cliente             int,
   @w_tg_monto               money,
   @w_tg_operacion           int,  -- LGU separcion del sp en dos partes: IMP y FIN
   @w_banco_generado         cuenta,
   @w_cta_grupal             cuenta,
   @w_tipo                   varchar(1),
   @w_toperacion             catalogo,
   @w_clase_cartera          catalogo,
   @w_sector                 catalogo,
   @w_moneda                 tinyint,
   @w_oficial                smallint,
   @w_banca                  catalogo,
   @w_filial                 tinyint,
   @w_servidor               varchar(30),
   @w_banco                  cuenta,
   @w_codigo_externo         varchar(64),
   @w_plazo                  smallint,
   @w_tplazo                 catalogo,
   @w_dias_plazo             smallint,
   @w_plazo_en_dias          smallint,
   @w_grupo_comentario       varchar(10),
   @w_operacion_grupal       int,
   @w_fecha_ini              datetime,
   @w_op_oficina             smallint,
   @w_op_destino             catalogo,
   @w_op_ciudad              int,
   --@w_forma_desembolso       catalogo,
   @w_op_banco_grupal        cuenta,
   @w_commit                 char(1),
   @w_fecha_proceso          datetime,
   @w_est_cancelado          int,
   @w_est_vigente            int,
   @w_tgarantia_liquida      descripcion,
   @w_tg_prestamo            varchar(32),
   @w_tg_ref_grupal          varchar(32),
   @w_admin_individual       char(1),
   @w_cliente                int,
   @w_grupo                  int,
   @w_ref_grupal             cuenta,
   @w_forma_pago             catalogo,
   @w_monto_base             money,
   @w_cuenta_grupo           cuenta,
   @w_cuenta                 cuenta,
   @w_monto                  money,
   @w_cliente_gr             int,
   @w_porc_participacion     float,
   @w_monto_prorrateado      money



-- VARIABLES INICIALES
select
@w_sp_name = 'sp_desembolso_grupal',
@w_commit  = 'N'

-- PARAMETRO GARANTIA LIQUIDA
select @w_tgarantia_liquida = pa_char
from cobis..cl_parametro
where pa_nemonico = 'GARLIQ'
and pa_producto = 'GAR'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end

-- PARAMETRO PORCENTAJE GARANTIA GRUPAL
select @w_porc_garantia = pa_float
from cobis..cl_parametro
where pa_nemonico = 'PGARGR'
and pa_producto = 'CCA'

if @@rowcount = 0 begin
   select @w_error = 101077
   goto ERROR
end

-- Obtener op_operacion prestamo grupal
print 'TRAMITE: ' +  cast(@i_tramite_grupal as varchar) 

select
@w_operacion_grupal = op_operacion,
@w_op_banco_grupal  = op_banco,
@w_fecha_ini        = op_fecha_ini,
@w_sector           = isnull(op_sector,'1'),
@w_clase_cartera    = isnull(op_clase,'1'),
@w_moneda           = isnull(op_moneda,0),
@w_plazo            = op_plazo,
@w_tplazo           = op_tplazo,
@w_toperacion       = op_toperacion,
@w_op_oficina       = op_oficina,
@w_op_destino       = op_destino,
@w_op_ciudad        = op_ciudad,
@w_cta_grupal       = op_cuenta, -- LPO Cuenta Grupal
@w_admin_individual   = op_admin_individual,   --LRE TEC 19/JUN/2019
@w_cliente            = op_cliente,            --LRE TEC 19/JUN/2019
@w_grupo              = op_grupo,              --LRE TEC 20/JUN/2019
@w_ref_grupal         = op_ref_grupal,         --LRE TEC 20/JUN/2019
@w_monto              = op_monto,              --LRE TEC 20/JUN/2019
@w_cuenta             = op_cuenta              --LRE TEC 21/JUN/2019
from ca_operacion
where op_tramite = @i_tramite_grupal

-- KDR 16Abr21: Se comenta seteo obligatorio de admin_individual N 
-- select @w_admin_individual = 'N' --LRE 28Ago19 Setear siempre administracion grupal

-- Plazo en dias
select @w_dias_plazo = td_factor
from ca_tdividendo
where td_tdividendo = @w_tplazo

select @w_plazo_en_dias = isnull(@w_plazo * @w_dias_plazo,0)

-- Inicializar acumulador montos garantias
select
@w_monto_total          = 0,
@w_monto_prorrateado    = 0     --LRE TEC 28/JUN/2019

-- Fecha Proceso de Cartera
select @w_fecha_proceso = fc_fecha_cierre
from cobis..ba_fecha_cierre
where fc_producto = 7 -- CARTERA

-- Obtener el Monto total del prestamo grupal
select
@w_tg_grupo    = tg_grupo,
@w_monto_total = sum(isnull(tg_monto_aprobado,0))
from cob_credito..cr_tramite_grupal
where tg_tramite = @i_tramite_grupal
and   tg_grupal  = 'S'
group by tg_grupo


select @w_fecha_ini = isnull(@i_fecha_ini, convert(varchar(10),@w_fecha_proceso,@i_formato_fecha))


-- Atomicidad en la transaccion
if @@trancount = 0 begin
   select @w_commit = 'S'
   begin tran
end


select @w_monto_base = ci_monto_ahorro 
from cob_cartera..ca_ciclo
where ci_operacion = @w_operacion_grupal
and   ci_grupo = @w_grupo


if @w_admin_individual = 'S'   --LRE TEC 19/JUN/2019
begin


 	select @w_monto_base = ci_monto_ahorro 
    from cob_cartera..ca_ciclo
    where ci_operacion = @w_operacion_grupal
    and   ci_grupo = @w_grupo


    select @w_monto_base = isnull(@w_monto_base, 0)

-- Cursor Tramite Grupal
select @w_tg_cliente = 0

while 1=1
begin

    select top 1
	@w_tg_grupo     = tg_grupo,
	@w_tg_cliente   = tg_cliente,
	@w_tg_monto     = tg_monto,    -- aqui esta el monto autorizado por la entidad
	@w_tg_cuenta    = tg_cuenta,
	@w_tg_operacion = tg_operacion, -- LGU: ejecutar sp en 2 partes: IMPRESION  DOC y FINAL
	@w_tg_prestamo  = tg_prestamo,
	@w_tg_ref_grupal= tg_referencia_grupal
    from cob_credito..cr_tramite_grupal
    where tg_tramite = @i_tramite_grupal
    and   tg_monto   > 0
    and   tg_grupal  = 'S'
    and   tg_cliente > @w_tg_cliente
    order by tg_cliente
	
    if @@rowcount = 0
    begin
        break
    end
print 'while Operacion' +  @w_tg_prestamo + 'cliente : ' + cast(@w_tg_cliente as varchar)

   if (@w_tg_cuenta is null) select @w_tg_cuenta = ea_cta_banco from cobis..cl_ente_aux where ea_ente = @w_tg_cliente
   
   /* SACAR SECUENCIALES SESIONES */
   exec @s_ssn = sp_gen_sec
   @i_operacion  = -1

   select
       @w_nombre  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre),
       @w_oficial = isnull(en_oficial,1),
       @w_banca   = isnull(en_banca,'1'),
       @w_filial  = isnull(en_filial,1)
   from cobis..cl_ente
   where en_ente = @w_tg_cliente
   --set transaction isolation level read uncommitted

   select @w_grupo_comentario = cast(@w_tg_grupo as varchar)

   select @w_operacion = null, @w_banco = null, @w_tramite = null

   set rowcount 0

    --///////////////////////////////////////////////////////////////////////////
    -- LGU: se ejecuta el DES y LIQ en la ultima etapa
    if (@w_tg_ref_grupal <>  @w_tg_prestamo)
    begin
print 'entro a procesar'
        -- recupero operacion, banco y tramite de la OP HIJA creada en la primera parte
        select  @w_operacion = @w_tg_operacion
        select
            @w_tramite = op_tramite,
            @w_banco   = op_banco
        from ca_operacion
        where op_operacion = @w_operacion

        select @w_cliente_gr = op_cliente
        from ca_operacion
        where op_banco = @w_tg_ref_grupal

        exec @w_error  = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '2.-x1'
           goto ERROR
        end

        exec @w_error      = sp_pasotmp
        @s_user            = @s_user,
        @s_term            = @s_term,
        @i_banco           = @w_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
	@i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_pasotmp'
        PRINT '3.-x1'
           goto ERROR
        end

        -- Montos de garantias individuales y garantia total
        --select @w_monto_garantia = @w_tg_monto * @w_porc_garantia / 100   --OJO VALIDAR QUE SE DEBE CARGAR EN EL CASO DE INDIVIDUALES


        exec @w_error     = sp_desembolso
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @i_nom_producto   = 'CCA',
        @i_producto       = @i_forma_desembolso, --LPO Se hereda a las operaciones hijas la Forma de desembolso del Prestamo Grupal
        @i_cuenta         = @w_tg_cuenta, --LPO Cuenta Individual en la cual se hara el desembolso de cada operacion
        @i_beneficiario   = @w_nombre,
        @i_ente_benef     = @w_cliente_gr, --@w_tg_cliente,
        @i_oficina_chg    = @s_ofi,
        @i_banco_ficticio = @w_operacion,
        @i_banco_real     = @w_banco,
        @i_fecha_liq      = @w_fecha_ini,
        @i_monto_ds       = @w_tg_monto,
        @i_moneda_ds      = @w_moneda,
        @i_tcotiz_ds      = 'COT',
        @i_cotiz_ds       = 1.0,
        @i_cotiz_op       = 1.0,
        @i_tcotiz_op      = 'COT',
        @i_moneda_op      = @w_moneda,
        @i_operacion      = 'I',
        @i_externo        = 'N'

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_desembolso'
        PRINT '4.-x1'
           goto ERROR
        end

        exec @w_error = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '5.-x1'
           goto ERROR
        end

        exec @w_error      = sp_pasotmp
        @s_user            = @s_user,
        @s_term            = @s_term,
        @i_banco           = @w_banco,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_pasotmp'
        PRINT '6.-x1'
           goto ERROR
        end

        exec @w_error     = sp_liquida
        @s_ssn            = @s_ssn,
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_rol            = @s_rol,
        @s_term           = @s_term,
        @i_banco_ficticio = @w_operacion,
        @i_banco_real     = @w_banco,
        @i_fecha_liq      = @w_fecha_ini,
        @i_externo        = 'N',
		@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
        @i_tasa           = @i_tasa,        --SRO Santander
        @o_banco_generado = @w_banco_generado out

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_liquida'
        PRINT '7.-x1'
           goto ERROR
        end

        exec @w_error  = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_banco

        if @w_error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '8.-x1'
           goto ERROR
        end

        --Actualizar el numero de ciclo del cliente --LPO
        update cobis..cl_ente
        set en_nro_ciclo = isnull(en_nro_ciclo,0) + 1
        where en_ente = @w_tg_cliente

        if @@error <> 0 begin
           --close cur_cr_tramite_grupal
           --deallocate cur_cr_tramite_grupal
           select @w_error = 70008003
        PRINT '10.-x1'
           goto ERROR
        end



        if @w_monto_base > 0
        begin

print 'MONTO MINIMO AHORRO ' + cast(@w_monto_base as varchar)
               --Prorratear el Monto de la Garant+‚-¡a liquida en funcion al monto de participaci+‚-¢n del miembro del grupo

               select @w_porc_participacion = round(((@w_tg_monto/@w_monto) * 100),2)
               select @w_monto_prorrateado  = round(((@w_monto_base * @w_porc_participacion)/100),2)
             
               print 'EN ADM IND.MOnto Gar: ' + cast(@w_monto_prorrateado as varchar) + 'Porc: ' + cast(@w_porc_participacion as varchar)

        	--Creacion de la garantia liquida
        	exec @w_error     = cob_custodia..sp_custodia_automatica
        	@s_ssn            = @s_ssn,
        	@s_date           = @s_date,
        	@s_user           = @s_user,
        	@s_term           = @s_term,
        	@s_ofi            = @s_ofi,
        	@t_trn            = 19090,
        	@t_debug          = 'N',
        	@i_operacion      = 'L',
        	@i_tipo_custodia  = @w_tgarantia_liquida,
        	@i_tramite        = @w_tramite,
        	@i_valor_inicial  = @w_monto_prorrateado,
        	@i_moneda         = @w_moneda,
        	@i_garante        = @w_tg_cliente,
        	@i_fecha_ing      = @s_date,
        	@i_cliente        = @w_tg_cliente,
        	@i_clase          = 'C',
        	@i_filial         = @w_filial,
        	@i_oficina        = @s_ofi,
        	@i_ubicacion      = 'DEFAULT',
        	@o_codigo_externo = @w_codigo_externo out

        	if @w_error <> 0 begin
	           select @w_sp_name = 'sp_custodia_automatica'
        		PRINT '11.1-x1'
		        goto ERROR
	        end
        end
        else
        begin
              print 'Cuenta Grupal no tiene Monto minimo de ahorro'
              select @w_error = 725047  
              goto ERROR

        end



        if not exists (select 1 from ca_en_fecha_valor where bi_operacion = @w_operacion)
        begin
           insert into ca_en_fecha_valor
           (bi_operacion, bi_banco, bi_fecha_valor, bi_user)
           values
           (@w_operacion, @w_banco, @w_fecha_ini,   @s_user)

           if @@error <> 0
           begin
              select @w_error = 710002
              goto ERROR
           end
        end

        PRINT '11.-x1 - '+ convert(VARCHAR, @w_tg_cliente)
end -- while

    --- ESTADOS DE CARTERA
    exec @w_error     = sp_estados_cca
    @o_est_cancelado  = @w_est_cancelado out

    if @w_error <> 0 begin
       select @w_sp_name = 'sp_estados_cca'
       PRINT '12.-x1'
       goto ERROR
    end


    update ca_operacion
    set op_estado       = @w_est_cancelado  --CANCELADO-- COLOCAR VARIABLE DE ESTADO DE CARTERA
    where op_operacion  = @w_operacion_grupal

    if @@error <> 0 begin
       select @w_error = 705036
       PRINT '13.-x1'
       goto ERROR
    end


    --Llamado al sp que actualiza los datos del Prestamo Grupal sumando la informacion de las Operaciones Individuales
    exec @w_error     = cob_cartera..sp_actualiza_grupal
         @i_banco     = @w_op_banco_grupal,
         @i_desde_cca = 'N' -- N = tablas definitivas

    if @w_error <> 0
    begin
       select @w_sp_name = 'sp_actualiza_grupal'
       PRINT '15.-x1'
       goto ERROR
    end
  end
end  --LRE TEC 19/JUN/2019
else
begin
   --ADMINISTRACION OPERACION PADRE
   /* SACAR SECUENCIALES SESIONES */
   /*exec @s_ssn = sp_gen_sec
   @i_operacion  = -1*/


   --exec @s_ssn = ADMIN...rp_ssn

   select
       @w_nombre  = rtrim(p_p_apellido)+' '+rtrim(p_s_apellido)+' '+rtrim(en_nombre),
       @w_oficial = isnull(en_oficial,1),
       @w_banca   = isnull(en_banca,'1'),
       @w_filial  = isnull(en_filial,1)
   from cobis..cl_ente
   where en_ente = @w_cliente

   select @w_grupo_comentario = cast(@w_grupo as varchar)
   select @w_operacion = null, @w_banco = null, @w_tramite = null

   set rowcount 0

    if (isnull(@w_ref_grupal,'') <>  isnull(@w_op_banco_grupal,'')) or
	   (@w_ref_grupal is not NULL)                       --Interciclos	   
    begin

        exec @w_error  = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_op_banco_grupal

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '2.-x1'
           goto ERROR
        end

        exec @w_error      = sp_pasotmp
        @s_user            = @s_user,
        @s_term            = @s_term,
        @i_banco           =  @w_op_banco_grupal,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_pasotmp'
        PRINT '3.-x1'
           goto ERROR
        end

        -- Montos de garantias individuales y garantia total
        select @w_monto_garantia = @w_tg_monto * @w_porc_garantia / 100
        

        exec @w_error     = sp_desembolso
        @s_ofi            = @s_ofi,
        @s_term           = @s_term,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @i_nom_producto   = 'CCA',
        @i_producto       = @i_forma_desembolso,       
        @i_cuenta         = @w_cuenta,           --Cuenta de Ahorros Grupal
        @i_beneficiario   = @w_nombre,
        @i_ente_benef     = @w_cliente,
        @i_oficina_chg    = @s_ofi,
        @i_banco_ficticio = @w_operacion_grupal,
        @i_banco_real     = @w_op_banco_grupal,
        @i_fecha_liq      = @w_fecha_ini,
        @i_monto_ds       = @w_monto,
        @i_moneda_ds      = @w_moneda,
        @i_tcotiz_ds      = 'COT',
        @i_cotiz_ds       = 1.0,
        @i_cotiz_op       = 1.0,
        @i_tcotiz_op      = 'COT',
        @i_moneda_op      = @w_moneda,
        @i_operacion      = 'I',
        @i_externo        = 'N'

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_desembolso'
        PRINT '4.-x1'
           goto ERROR
        end


        exec @w_error = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_op_banco_grupal

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '5.-x1'
           goto ERROR
        end

        exec @w_error      = sp_pasotmp
        @s_user            = @s_user,
        @s_term            = @s_term,
        @i_banco           = @w_op_banco_grupal,
        @i_operacionca     = 'S',
        @i_dividendo       = 'S',
        @i_amortizacion    = 'S',
        @i_cuota_adicional = 'S',
        @i_rubro_op        = 'S',
        @i_relacion_ptmo   = 'S',
        @i_nomina          = 'S',
        @i_acciones        = 'S',
        @i_valores         = 'S'

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_pasotmp'
        PRINT '6.-x1'
           goto ERROR
        end

        exec @w_error     = sp_liquida
        @s_ssn            = @s_ssn,
        @s_sesn           = @s_sesn,
        @s_user           = @s_user,
        @s_date           = @s_date,
        @s_ofi            = @s_ofi,
        @s_rol            = @s_rol,
        @s_term           = @s_term,
        @i_banco_ficticio = @w_operacion_grupal,
        @i_banco_real     = @w_op_banco_grupal,
        @i_fecha_liq      = @w_fecha_ini,
        @i_externo        = 'N',
		@i_desde_cartera  = 'N',          -- KDR No es ejecutado desde Cartera[FRONT]
        --@i_tasa           = @i_tasa,        --SRO Santander
        @o_banco_generado = @w_banco_generado out

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_liquida'
        PRINT '7.-x1'
           goto ERROR
        end

        exec @w_error  = sp_borrar_tmp
        @s_sesn   = @s_sesn,
        @s_user   = @s_user,
        @s_term   = @s_term,
        @i_banco  = @w_op_banco_grupal

        if @w_error <> 0 begin
           select @w_sp_name = 'sp_borrar_tmp'
        PRINT '8.-x1'
           goto ERROR
        end

        --Actualizar el numero de ciclo del cliente --LPO
        update cobis..cl_ente
        set en_nro_ciclo = isnull(en_nro_ciclo,0) + 1
        where en_ente = @w_cliente

        if @@error <> 0 begin
           select @w_error = 70008003
        PRINT '10.-x1'
           goto ERROR
        end


   if (@w_ref_grupal is NULL)
   begin


        --Consultar el Ahorro Esperado para enviar a crear la garantia liquida
		select @w_monto_base = ci_monto_ahorro 
        from cob_cartera..ca_ciclo
        where ci_operacion = @w_operacion_grupal
            and   ci_grupo = @w_grupo

        select @w_monto_base = isnull(@w_monto_base, 0)
		
        if @w_monto_base > 0
        begin
print 'MONTO MINIMO AHORRO ' + cast(@w_monto_base as varchar)
             
               --select @w_tgarantia_liquida = '110'

        	--Creacion de la garantia liquida
        	exec @w_error     = cob_custodia..sp_custodia_automatica
        	@s_ssn            = @s_ssn,
        	@s_date           = @s_date,
        	@s_user           = @s_user,
        	@s_term           = @s_term,
        	@s_ofi            = @s_ofi,
        	@t_trn            = 19090,
        	@t_debug          = 'N',
        	@i_operacion      = 'L',
        	@i_tipo_custodia  = @w_tgarantia_liquida,
        	@i_tramite        = @i_tramite_grupal,
        	@i_valor_inicial  = @w_monto_base,
        	@i_moneda         = @w_moneda,
        	@i_garante        = @w_cliente,
        	@i_fecha_ing      = @s_date,
        	@i_cliente        = @w_cliente,
        	@i_clase          = 'C',
        	@i_filial         = @w_filial,
        	@i_oficina        = @s_ofi,
        	@i_ubicacion      = 'DEFAULT',
        	@o_codigo_externo = @w_codigo_externo out

        	if @w_error <> 0 begin
	           select @w_sp_name = 'sp_custodia_automatica'
        		PRINT '11.-x1'
		        goto ERROR
	        end
        end
        else
        begin
              print 'Cuenta Grupal no tiene Monto minimo de ahorro'
              select @w_error = 725047
              goto ERROR

        end
    end 


        if not exists (select 1 from ca_en_fecha_valor where bi_operacion = @w_operacion)
        begin
           insert into ca_en_fecha_valor
           (bi_operacion, bi_banco, bi_fecha_valor, bi_user)
           values
           (@w_operacion_grupal, @w_op_banco_grupal, @w_fecha_ini,   @s_user)

           if @@error <> 0
           begin
              select @w_error = 710002
              goto ERROR
           end
        end

    --- ESTADOS DE CARTERA
    exec @w_error     = sp_estados_cca
      @o_est_vigente  = @w_est_vigente out

    if @w_error <> 0 begin
       select @w_sp_name = 'sp_estados_cca'
       PRINT '12.-x1'
       goto ERROR
    end


    update ca_operacion
    set op_estado       = @w_est_vigente  --PONER VIGENTE LA OPERACION GRUPAL
    where op_operacion  = @w_operacion_grupal

    if @@error <> 0 begin
       select @w_error = 705036
       PRINT '13.-x1'
       goto ERROR
    end


  end


end

if @w_commit = 'S' begin
   commit tran  -- Fin atomicidad de la transaccion
   select @w_commit = 'N'
end


return 0

ERROR:
if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

exec cobis..sp_cerror
@t_debug   = 'N',
@t_file    = null,
@t_from    = @w_sp_name,
@i_num     = @w_error

return @w_error


GO

