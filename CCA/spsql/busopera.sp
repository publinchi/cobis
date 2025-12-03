/************************************************************************/
/*   NOMBRE LOGICO:      busopera.sp                                    */
/*   NOMBRE FISICO:      sp_buscar_operaciones                          */
/*   BASE DE DATOS:      cob_cartera                                    */
/*   PRODUCTO:           Cartera                                        */
/*   DISENADO POR:       Fabian de la Torre                             */
/*   FECHA DE ESCRITURA: Ene. 98                                        */
/************************************************************************/
/*                     IMPORTANTE                                       */
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
/*   y penales en contra del infractor según corresponda.”.             */
/************************************************************************/
/*                                PROPOSITO                             */
/*   Buscar operaciones deacuerdo a criterio                            */
/************************************************************************/
/*                              MODIFICACIONES                          */
/*      FECHA           AUTOR           RAZON                           */
/*   13/Feb/2019   Adriana Giler. Inclusion de Where por Cod. Cliente   */
/*   10/May/2019   Adriana Giler. Inclusion Operaciones Grupales        */
/*   14/Jun/2019   Edison Cajas   Inclusion validacion Operaciones      */
/*                                Grupales                              */
/*   26/Jun/2019   Edison Cajas   Inclusion validacion Operaciones      */
/*                                Grupales                              */
/*   24/Jul/2019   Adriana Giler. No presentar Prestamos en CREDITO     */
/*   24/Jul/2019   Edison Cajas   Ajuste de estados                     */
/*   30/Jul/2019   Edison Cajas   Quitar operaciones Hijas para el      */
/*                                desembolso CAR-S269332-TEC            */
/*   07/Ago/2019   Edison Cajas   Quitar operaciones Hijas e Interciclos*/
/*                                Prorroga Cuota CAR-S273498-TEC        */
/*   08/Ago/2019   Lorena Regalado No consultar operaciones de Interci  */
/*                                 e hijas en la reversa de desembolso  */
/*   03/Oct/2019   Luis Ponce     No mostrar operaciones para pagos     */
/*                                grupales en individuales y visceversa */
/*   30/Dic/2019   Gerardo Barron     Mostrar operaciones No Vigentes   */
/*   13/May/2020   Luis Ponce     CDIG la @i_categoria = 10 maneja pagos*/
/*   02/Jul/2020   Luis Castellanos CDIG Tipo de dato int linea credito */
/*   16/Oct/2020   EMP-JJEC       Busqueda para desembolsos parciales   */
/*   04/May/2021   G. Fernandez   Estado de operaciones grupales        */
/*   06/Sep/2021   Ricardo R.     Consulta con prestamos para empleados */
/*   24/12/2023    K. Rodriguez   R220437 Ajustes busqueda traslados ofi*/
/*   29/05/2024    K. Rodriguez   R235763 Ajuste tabla tmp de resulset  */
/*   19/05/2025    Oscar Diaz     Error #262345                         */
/************************************************************************/

use cob_cartera
go
 
if exists(select 1 from sysobjects where name = 'sp_buscar_operaciones')
   drop proc sp_buscar_operaciones
go

create proc sp_buscar_operaciones
   @s_user              login       = null,
   @t_trn               INT         = NULL, --LPO Cambio de Servicios a Blis   
   @t_show_version      bit         = 0,
   @s_rol              	int         = null,
   @i_banco             cuenta      = null,
   @i_tramite           int         = null,
   @i_cliente           int         = null,
   @i_grupo             int         = null,
   @i_oficina           smallint    = null,
   @i_moneda            tinyint     = null,
   @i_oficial           int         = null,
   @i_fecha_ini         datetime    = null,
   @i_toperacion        catalogo    = null,
   @i_estado            descripcion = null,
   @i_migrada           cuenta      = null,
   @i_siguiente         int         = 0,
   @i_formato_fecha     int         = null,
   @i_condicion_est     tinyint     = null,
   @i_num_documento     varchar(30) = NULL,
   @i_web               char(1)     = 'N',
   @i_grupal            char(1)     = 'N',
   @i_categoria         int         = 0,
   @i_desempar          char(1)     = 'N',
   @i_filtro_adicional  char(1)     = 'N'   -- 'N': Sin flitro, 'T': Filtro busqueda Traslado Oficina, oficial

as
declare
   @w_sp_name        varchar(32),
   @w_opcion         int,
   @w_error          int,
   @w_estado         int,
   @w_redbusca       int,
   @w_oficina_matriz int,
   @w_truta          tinyint,
   @w_regional       SMALLINT,
   @w_en_ente        INT,
   @w_opruta         VARCHAR(10),
   @w_msg            varchar(100),
   @w_grupo          INT,
   @w_tipo_grupal    CHAR(1),
   
   @w_estado_grupal    INT,  --estado de la opereracion grupal
   @w_operacion_grupal INT   --operacion grupal
   

declare @w_estados_excluidos table (estado     tinyint)
declare @w_integrantes       table (ente       int)
declare @w_prestamos         table (operacion  int, tipo VARCHAR(10), estado_grp int)
declare @w_estados           table (banco cuenta, estado tinyint)
declare @w_estados_grupo     table (grupo int, operacion_grupal int, estado int)
declare @w_est_novigente tinyint, @w_est_vigente tinyint, @w_est_vencido   tinyint, @w_est_cancelado tinyint, @w_est_castigado tinyint,
        @w_est_diferido  tinyint, @w_est_anulado tinyint, @w_est_condonado tinyint, @w_est_suspenso  tinyint, @w_est_credito   tinyint

-- CAPTURA NOMBRE DE STORED PROCEDURE
select @w_sp_name = 'sp_buscar_operaciones'

if @t_show_version = 1
begin
   print 'Stored Procedure ' + @w_sp_name + ' Version 1.0.0.1'
   return 0
end
	
SELECT @w_opruta = ''
select @w_oficina_matriz = 900

exec cob_cartera..sp_estados_cca @o_est_novigente = @w_est_novigente out, @o_est_vigente   = @w_est_vigente   out, @o_est_vencido  = @w_est_vencido  out,
                                 @o_est_cancelado = @w_est_cancelado out, @o_est_castigado = @w_est_castigado out, @o_est_diferido = @w_est_diferido out,
                                 @o_est_anulado   = @w_est_anulado   out, @o_est_condonado = @w_est_condonado out, @o_est_suspenso = @w_est_suspenso out,
                                 @o_est_credito   = @w_est_credito   out

if @i_categoria = 0 begin
   insert into @w_estados_excluidos
   select es_codigo
   from cob_cartera..ca_estado
   where es_descripcion in ('CREDITO','ANULADO')--,'NO VIGENTE')  LGBC 31/12/2019
end

if @i_categoria = 2 begin
   insert into @w_estados_excluidos
   select es_codigo
   from cob_cartera..ca_estado
   where es_descripcion <> 'NO VIGENTE'
end

if @i_categoria = 3 begin
   insert into @w_estados_excluidos
   select es_codigo
   from cob_cartera..ca_estado
   where es_descripcion in ('NO VIGENTE', 'CREDITO')
end


if @i_categoria = 4 begin
   insert into @w_estados_excluidos values (@w_est_novigente) --  0 - NO VIGENTE
   insert into @w_estados_excluidos values (@w_est_anulado)   --  6 - ANULADO
   insert into @w_estados_excluidos values (@w_est_credito)   -- 99 - CREDITO
end

if @i_categoria = 5 begin
   insert into @w_estados_excluidos
   select es_codigo
   from cob_cartera..ca_estado
   where es_descripcion = 'CANCELADO'
end

--LPO CDIG la @i_categoria = 10 maneja pagos INICIO
if @i_categoria = 10 begin
   insert into @w_estados_excluidos values (@w_est_novigente) --  0 - NO VIGENTE
   insert into @w_estados_excluidos values (@w_est_anulado)   --  6 - ANULADO
   insert into @w_estados_excluidos values (@w_est_credito)   -- 99 - CREDITO
   insert into @w_estados_excluidos values (@w_est_cancelado) --  3 - CANCELADO
end
--LPO CDIG la @i_categoria = 10 maneja pagos FIN

if @i_condicion_est is null  select @i_condicion_est = 0

-- CONVERTIR EL ESTADO DESCRIPCION A ESTADO NUMERO
if @i_estado is not null begin

   IF ISNUMERIC(@i_estado) = 1
         select @w_estado = es_codigo from cob_cartera..ca_estado where  es_codigo = convert(INT,@i_estado)
   ELSE
         select @w_estado = es_codigo
         from   cob_cartera..ca_estado
         where  es_descripcion = @i_estado

end

if @i_siguiente <> 0 goto SIGUIENTE

-- BUSCAR OPCION DE BUSQUEDA
select @w_opcion = 1000

if @i_migrada                                  is not null  select @w_opcion = 7
if @i_oficina                                  is not null  select @w_opcion = 6
if @i_oficial                                  is not null  select @w_opcion = 5
if @i_grupo                                    is not null  select @w_opcion = 4
if @i_num_documento is not null or @i_cliente  is not null  select @w_opcion = 3
if @i_tramite                                  is not null  select @w_opcion = 2
if @i_banco                                    is not null  select @w_opcion = 1

if @w_opcion = 1000 begin --ESTO ES PARA QUE SIEMPRE HAYA UN CAMPO PRIMARIO
   select @w_error  = 708199
   select @w_msg    = 'ERROR- PARA BUSCAR INGRESE YA SEA: EL BANCO, EL TRAMITE, EL CLIENTE/GRUPO, OFICINA O EL NRO MIGRADO'
   goto ERROR
end


--Cambio por web
if @i_num_documento is not null select @i_cliente = convert(int,@i_num_documento)

-- BUSQUEDAS DE NUMERO DE OPERACIONES
if @w_opcion = 1  -- NRO PRESTAMOS
begin

    if exists(select 1                    --ODI_#262345
	  from ca_operacion,ca_ciclo
	 where op_operacion = ci_operacion
	   and op_grupal = 'S'
	   and op_ref_grupal is null
	   and op_banco = @i_banco)
    begin
         insert into @w_prestamos
         select distinct op_operacion,'GRUPAL',op_estado
          from ca_operacion,ca_ciclo
         where op_operacion = ci_operacion
           and op_grupal = 'S'
           and op_ref_grupal is null
           and op_banco = @i_banco
           and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
    end
	else
	if exists(select 1                   --ODI_#262345
	  from ca_operacion
	 where op_grupal = 'S'
	   and op_ref_grupal is null
	   and op_banco = @i_banco)
	begin
         insert into @w_prestamos
         select distinct op_operacion,'GRUPAL',op_estado
          from ca_operacion
         where op_grupal = 'S'
           and op_ref_grupal is null
           and op_banco = @i_banco
           and @i_categoria not in (2)	
	end
	
       insert into @w_prestamos
       select distinct op_operacion,'INTERCICLO',op_estado
         from ca_operacion,ca_det_ciclo
        where op_operacion = dc_operacion
          and op_banco = @i_banco
          and (op_grupal = 'N' or op_grupal is null)
          and op_ref_grupal is not null
          and dc_tciclo = 'I'
          and op_estado not in (select estado from @w_estados_excluidos)
          and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
                                           --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos
	
	

    insert into @w_prestamos
    select distinct op_operacion, 'INDIVIDUAL',op_estado
      from ca_operacion with(nolock)
     where op_banco = @i_banco
       and op_estado not in (select estado from @w_estados_excluidos)
       and (op_grupal = 'N' or op_grupal is null)
       and op_operacion not in (select dc_operacion from ca_det_ciclo)


    if exists(select 1                    --ODI_#262345
	  from ca_operacion with(nolock),ca_det_ciclo with(nolock)
        where op_operacion = dc_operacion
          and op_banco = @i_banco
          and op_grupal = 'S'
          and op_ref_grupal is not null
          and dc_tciclo = 'N')
    begin
	   insert into @w_prestamos
       select distinct op_operacion,'HIJA',op_estado
         from ca_operacion with(nolock),ca_det_ciclo with(nolock)
        where op_operacion = dc_operacion
          and op_banco = @i_banco
          and op_grupal = 'S'
          and op_ref_grupal is not null
          and dc_tciclo = 'N'
          and @i_categoria not in (2, 3, 6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
    end
	else 
	if exists(select 1                    --ODI_#262345
	            from ca_operacion with(nolock)
               where op_banco = @i_banco
                 and op_grupal = 'S'
                 and op_ref_grupal is not null)
    begin
	   insert into @w_prestamos
       select distinct op_operacion,'HIJA',op_estado
         from ca_operacion with(nolock)
        where op_banco = @i_banco
          and op_grupal = 'S'
          and op_ref_grupal is not null
          and @i_categoria not in (2, 3, 6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
    end  
		  

    /* LPO TEC DETERMINAR EL TIPO DE LA OPERACION */
    exec @w_error = sp_tipo_operacion
    @i_banco      = @i_banco,
    @o_tipo       = @w_tipo_grupal out
       
    if @w_error <> 0 goto ERROR
    
    --LPO CDIG la @i_categoria = 10 maneja pagos INICIO
    --IF @i_categoria = 4 AND @i_grupal = 'S' --LPO TEC Estoy en la Pantalla de Pagos Grupales entonces No mostrar operaciones Interciclos, Individuales ni Hijas
    IF @i_categoria = 10 AND @i_grupal = 'S' --LPO TEC Estoy en la Pantalla de Pagos Grupales entonces No mostrar operaciones Interciclos, Individuales ni Hijas
    --LPO CDIG la @i_categoria = 10 maneja pagos FIN
       IF @w_tipo_grupal <> 'G'             --LPO TEC Si no es una OP Grupal borrarla para No mostrar la operacion en pantalla.
          delete @w_prestamos      
    
    --LPO CDIG la @i_categoria = 10 maneja pagos INICIO    
    --IF @i_categoria = 4 AND @i_grupal = 'N' --LPO TEC Estoy en la Pantalla de Pagos Individuales entonces Solo mostrar operaciones Individuales e Interciclos
    IF @i_categoria = 10 AND @i_grupal = 'N' --LPO TEC Estoy en la Pantalla de Pagos Individuales entonces Solo mostrar operaciones Individuales e Interciclos    
    --LPO CDIG la @i_categoria = 10 maneja pagos FIN
       IF @w_tipo_grupal IN ('G','H')       --LPO TEC No mostrar operaciones operaciones Grupales e Hijas en pantalla.
          delete @w_prestamos
end

if @w_opcion = 2  -- NRO TRAMITE
begin

    if @i_grupal = 'S' begin

    if exists(select 1                    --ODI_#262345
	      from ca_operacion,ca_ciclo
         where op_operacion = ci_operacion
           and op_tramite = @i_tramite
           and op_grupal = 'S'
           and op_ref_grupal is null)
    begin
        insert into @w_prestamos
        select distinct op_operacion,'GRUPAL',op_estado
          from ca_operacion,ca_ciclo
         where op_operacion = ci_operacion
           and op_tramite = @i_tramite
           and op_grupal = 'S'
           and op_ref_grupal is null
           and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
    end
	else
    if exists(select 1                    --ODI_#262345
	      from ca_operacion
         where op_tramite = @i_tramite
           and op_grupal = 'S'
           and op_ref_grupal is null)
    begin
        insert into @w_prestamos
        select distinct op_operacion,'GRUPAL',op_estado
          from ca_operacion
         where op_tramite = @i_tramite
           and op_grupal = 'S'
           and op_ref_grupal is null
           and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso	
	end
	
	
   end else begin

       insert into @w_prestamos
       select distinct op_operacion,'INTERCICLO',op_estado
         from ca_operacion,ca_det_ciclo
        where op_operacion = dc_operacion
          and op_tramite = @i_tramite
          and (op_grupal = 'N' or op_grupal is null)
          and op_ref_grupal is not null
          and dc_tciclo = 'I'
          and op_estado not in (select estado from @w_estados_excluidos)
          and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
		                                   --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

       insert into @w_prestamos
       select distinct op_operacion, 'INDIVIDUAL',op_estado
         from ca_operacion with(nolock)
        where op_tramite = @i_tramite
          and op_estado not in (select estado from @w_estados_excluidos)
          and (op_grupal = 'N' or op_grupal is null)
          and op_operacion not in (select dc_operacion from ca_det_ciclo)

       if exists(select 1                    --ODI_#262345
	              from ca_operacion,ca_det_ciclo
                 where op_operacion = dc_operacion
                   and op_tramite = @i_tramite
                   and op_grupal = 'S'
                  and op_ref_grupal is not null
                  and dc_tciclo = 'N')
       begin
          insert into @w_prestamos
          select distinct op_operacion,'HIJA',op_estado
            from ca_operacion,ca_det_ciclo
           where op_operacion = dc_operacion
             and op_tramite = @i_tramite
             and op_grupal = 'S'
             and op_ref_grupal is not null
             and dc_tciclo = 'N'
             and @i_categoria not in (2, 3,6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
       end
	   else
       if exists(select 1                    --ODI_#262345
	              from ca_operacion
                 where op_tramite = @i_tramite
                   and op_grupal = 'S'
                  and op_ref_grupal is not null)
       begin
          insert into @w_prestamos
          select distinct op_operacion,'HIJA',op_estado
            from ca_operacion
           where op_tramite = @i_tramite
             and op_grupal = 'S'
             and op_ref_grupal is not null
             and @i_categoria not in (2, 3,6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
	   
	   end
    end
end


if @w_opcion = 3 begin  --por clilente

   if @i_grupal = 'S' begin

      if @i_cliente is not null begin
          insert into @w_prestamos    --ODI_#262345
          select distinct op_operacion,'GRUPAL',op_estado
            from ca_operacion with(nolock)
           where op_cliente = @i_cliente
             and op_grupal = 'S'
             and op_ref_grupal is null
             and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
      end

   end else begin
      if @i_cliente is not null begin
         insert into @w_prestamos
         select distinct op_operacion,'INTERCICLO',op_estado
           from ca_operacion with(nolock) ,ca_det_ciclo with(nolock)
          where op_cliente = @i_cliente
            and (op_grupal = 'N' or op_grupal is null)
            and op_ref_grupal is not null
            and op_estado not in (select estado from @w_estados_excluidos)
            and op_operacion = dc_operacion
            and dc_tciclo = 'I'
            and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
                                             --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

         insert into @w_prestamos
         select distinct op_operacion, 'INDIVIDUAL',op_estado
           from ca_operacion with(nolock)
          where op_cliente = @i_cliente
            and op_estado not in (select estado from @w_estados_excluidos)
            and (op_grupal = 'N' or op_grupal is null)
            and op_operacion not in (select dc_operacion from ca_det_ciclo)

         insert into @w_prestamos
         select distinct op_operacion,'HIJA',op_estado   --ODI_#262345
           from ca_operacion with(nolock)
          where op_grupal = 'S'
            and op_cliente = @i_cliente
            and op_ref_grupal is not null
            and @i_categoria not in (2, 3,6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso

      end

   end

end


if @w_opcion = 4 begin --por grupo

   if @i_grupal = 'S' begin

      if @i_grupo is not null begin
          insert into @w_prestamos
		  select distinct op_operacion,'GRUPAL',op_estado  --ODI_#262345
            from ca_operacion
           where op_grupo = @i_grupo
             and op_grupal = 'S'
             and op_ref_grupal is null 
			 and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			 
      end

   end else begin

      if @i_grupo is not null begin
            insert into @w_prestamos
            select distinct op_operacion,'INTERCICLO',op_estado
              from ca_operacion with(nolock),ca_det_ciclo with(nolock)
             where op_grupo = @i_grupo
               and (op_grupal = 'N' or op_grupal is null)
               and op_ref_grupal is not null
               and op_estado not in (select estado from @w_estados_excluidos)
               and op_operacion = dc_operacion
               and dc_tciclo = 'I'
               and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			                                    --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

                  insert into @w_prestamos
                  select distinct op_operacion, 'INDIVIDUAL',op_estado
                    from ca_operacion with(nolock)
                   where op_grupo = @i_grupo
                     and op_estado not in (select estado from @w_estados_excluidos)
                     and (op_grupal = 'N' or op_grupal is null)
                     and op_operacion not in (select dc_operacion from ca_det_ciclo)

              insert into @w_prestamos
			  select distinct op_operacion,'HIJA',op_estado  --ODI_#262345
                from ca_operacion with(nolock)
               where op_grupal = 'S'
                 and op_grupo = @i_grupo
                 and op_ref_grupal is not null
				 and @i_categoria not in (2, 3,6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
        end

   end

end


if @w_opcion = 5 begin --por oficial

   if @i_grupal = 'S' begin
          insert into @w_prestamos  --ODI_#262345
          select distinct op_operacion,'GRUPAL',op_estado
            from ca_operacion with(nolock)
           where op_oficial = @i_oficial
             and op_grupal = 'S'
             and op_ref_grupal is null
             and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso

   end else begin

        insert into @w_prestamos
        select distinct op_operacion,'INTERCICLO',op_estado
            from ca_operacion with(nolock),ca_det_ciclo with(nolock)
            where op_oficial = @i_oficial
            and (op_grupal = 'N' or op_grupal is null)
            and op_ref_grupal is not null
            and op_estado not in (select estado from @w_estados_excluidos)
            and op_operacion = dc_operacion
            and dc_tciclo = 'I'
            and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			                                 --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

                insert into @w_prestamos
                select distinct op_operacion, 'INDIVIDUAL',op_estado
                from ca_operacion with(nolock)
                where op_oficial = @i_oficial
                    and op_estado not in (select estado from @w_estados_excluidos)
                    and (op_grupal = 'N' or op_grupal is null)
                    and op_operacion not in (select dc_operacion from ca_det_ciclo)

              insert into @w_prestamos    --ODI_#262345
              select distinct op_operacion,'HIJA',op_estado
                from ca_operacion with(nolock) 
               where op_grupal = 'S'
                 and op_oficial = @i_oficial
                 and op_ref_grupal is not null
                 and @i_categoria not in (2, 3, 6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
   end

end



if @w_opcion = 6 begin --por oficina

   if @i_grupal = 'S' begin  
          insert into @w_prestamos  --ODI_#262345
          select distinct op_operacion,'GRUPAL',op_estado
            from ca_operacion
           where op_oficina = @i_oficina
             and op_grupal = 'S'
             and op_ref_grupal is null
             and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			 
   end else begin
        insert into @w_prestamos
        select distinct op_operacion,'INTERCICLO',op_estado
            from ca_operacion with(nolock),ca_det_ciclo with(nolock)
            where op_oficina = @i_oficina
            and (op_grupal = 'N' or op_grupal is null)
            and op_ref_grupal is not null
            and op_estado not in (select estado from @w_estados_excluidos)
            and op_operacion = dc_operacion
            and dc_tciclo = 'I'
            and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			                                 --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

                insert into @w_prestamos
                select distinct op_operacion, 'INDIVIDUAL',op_estado
                from ca_operacion with(nolock)
                where op_oficina = @i_oficina
                    and op_estado not in (select estado from @w_estados_excluidos)
                    and (op_grupal = 'N' or op_grupal is null)
                    and op_operacion not in (select dc_operacion from ca_det_ciclo)

              insert into @w_prestamos  --ODI_#262345
              select distinct op_operacion,'HIJA',op_estado
                from ca_operacion with(nolock)
               where op_grupal = 'S'
                 and op_oficina = @i_oficina
                 and op_ref_grupal is not null
                 and @i_categoria not in (2, 3, 6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso

   end

end

if @w_opcion = 7 begin --por migrada

   if @i_grupal = 'S' begin

          insert into @w_prestamos  --ODI_#262345
          select distinct op_operacion,'GRUPAL',op_estado
            from ca_operacion with(nolock)
           where op_migrada = @i_migrada
             and op_grupal = 'S'
             and op_ref_grupal is null
             and @i_categoria not in (2)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			 
   end else begin

        insert into @w_prestamos
        select distinct op_operacion,'INTERCICLO',op_estado
            from ca_operacion with(nolock),ca_det_ciclo with(nolock)
            where op_migrada = @i_migrada
            and (op_grupal = 'N' or op_grupal is null)
            and op_ref_grupal is not null
            and op_estado not in (select estado from @w_estados_excluidos)
            and op_operacion = dc_operacion
            and dc_tciclo = 'I'
            and @i_categoria not in (2,3,6)  --LRE 08/Ago/2019 Excluir de la reversa del desembolso
			                                 --EC - CAR-S273498-TEC - No consultar operaciones Hijas e Interciclos

            insert into @w_prestamos
            select distinct op_operacion, 'INDIVIDUAL',op_estado
            from ca_operacion with(nolock)
            where op_migrada = @i_migrada
                and op_estado not in (select estado from @w_estados_excluidos)
                and (op_grupal = 'N' or op_grupal is null)
                and op_operacion not in (select dc_operacion from ca_det_ciclo)

                insert into @w_prestamos  --ODI_#262345
              select distinct op_operacion,'HIJA',op_estado
                from ca_operacion with(nolock)
               where op_grupal = 'S'
                 and op_migrada = @i_migrada
                 and op_ref_grupal is not null
                 and @i_categoria not in (2, 3,6)  --EC - CAR-S269332-TEC - No consultar operaciones Hijas para el desembolso
				 
   end

end


if @i_grupal = 'S' begin

   insert into @w_estados_grupo  --ODI_#262345
   select op_grupo, op_operacion, min(op_estado)
   from  @w_prestamos, ca_operacion
   where operacion    = op_operacion
   group by op_grupo, op_operacion

   delete @w_prestamos        --ODI_#262345
   from  ca_operacion, @w_estados_grupo
   where op_grupo     = grupo
   and   op_operacion = operacion_grupal
   and   op_operacion = operacion
   and   estado_grp in (select estado from @w_estados_excluidos) --EC
end


-- LIMPIAR TABLA TEMPORAL
delete ca_buscar_operaciones_tmp where  bot_usuario = @s_user

if @i_desempar = 'N'
begin
	if exists (select 1 
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_rol_prestamos_empleados')
			and not exists (select 1
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_rol_prestamos_empleados'
			and c.estado = 'V'
			and c.codigo in (@s_rol))
	begin
		insert into ca_buscar_operaciones_tmp
		select @s_user,
		op_operacion,       op_moneda,              op_fecha_liq,
		op_lin_credito,     op_estado,              op_migrada,
		op_toperacion,      op_oficina,             op_oficial,
		op_cliente,         op_tramite,             op_banco,
		op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
		op_reajustable,     op_monto,               op_monto_aprobado,
		op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
		op_ref_exterior,    '',
		op_num_comex,
		op_tipo_linea,      op_nombre,              op_fecha_fin, tipo,
		op_grupo
		from   ca_operacion, @w_prestamos
		where op_operacion   = operacion
		and op_toperacion not in (
			select c.codigo
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_tipo_operacion_empleados'
			and c.estado = 'V'
		)
	end
	else
	begin
		insert into ca_buscar_operaciones_tmp
		select @s_user,
		op_operacion,       op_moneda,              op_fecha_liq,
		op_lin_credito,     op_estado,              op_migrada,
		op_toperacion,      op_oficina,             op_oficial,
		op_cliente,         op_tramite,             op_banco,
		op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
		op_reajustable,     op_monto,               op_monto_aprobado,
		op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
		op_ref_exterior,    '',
		op_num_comex,
		op_tipo_linea,      op_nombre,              op_fecha_fin, tipo,
		op_grupo
		from   ca_operacion, @w_prestamos
		where op_operacion   = operacion
	end
   
   --GFP Actualizacion de estado de Operacioens Grupales
	SELECT @w_operacion_grupal = min(bot_operacion)
	from ca_buscar_operaciones_tmp
	where bot_usuario =@s_user
	and  bot_tipo_grupo_cat = 'GRUPAL'
	
	while @w_operacion_grupal is not null
	begin
	    --GFP Obtener el estado del operacion grupal
		EXEC cob_cartera..sp_consulta_estado_grupal
		@i_operacion = @w_operacion_grupal,
		@o_estado_grupo = @w_estado_grupal OUTPUT
		--GFP Actualizacion de estado en ca_buscar_operaciones_tmp	
		update ca_buscar_operaciones_tmp
		set bot_estado= @w_estado_grupal
		WHERE bot_usuario = @s_user 
		and bot_operacion = @w_operacion_grupal
		-- GFP Recorre a la siguiente operacion grupal	
		SELECT @w_operacion_grupal = min(bot_operacion)
		from ca_buscar_operaciones_tmp
	    where bot_usuario =@s_user
	    and  bot_tipo_grupo_cat = 'GRUPAL'
		and  bot_operacion > @w_operacion_grupal
	end

end
else -- DESEMBOLSOS PARCIALES OPERACIONES QUE TENGAN SALDO POR DESEMBOLSAR
begin
	if exists (select 1 
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_rol_prestamos_empleados')
			and not exists (select 1
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_rol_prestamos_empleados'
			and c.estado = 'V'
			and c.codigo in (@s_rol))
	begin
		insert into ca_buscar_operaciones_tmp
		select @s_user,
		op_operacion,       op_moneda,              op_fecha_liq,
		op_lin_credito,     op_estado,              op_migrada,
		op_toperacion,      op_oficina,             op_oficial,
		op_cliente,         op_tramite,             op_banco,
		op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
		op_reajustable,     op_monto,               op_monto_aprobado,
		op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
		op_ref_exterior,    '',
		op_num_comex,
		op_tipo_linea,      op_nombre,              op_fecha_fin, tipo,
		op_grupo
		from  ca_operacion, @w_prestamos
		where op_operacion   = operacion
		and op_monto_aprobado > op_monto
		and op_toperacion not in (
			select c.codigo
			from cobis..cl_catalogo as c
			left join cobis..cl_tabla as t on t.codigo = c.tabla
			where t.tabla = 'ca_tipo_operacion_empleados'
			and c.estado = 'V'
		)
	end
	else
	begin
		insert into ca_buscar_operaciones_tmp
		select @s_user,
		op_operacion,       op_moneda,              op_fecha_liq,
		op_lin_credito,     op_estado,              op_migrada,
		op_toperacion,      op_oficina,             op_oficial,
		op_cliente,         op_tramite,             op_banco,
		op_fecha_reajuste,  op_tipo,                op_reajuste_especial,
		op_reajustable,     op_monto,               op_monto_aprobado,
		op_anterior,        op_fecha_ult_proceso,   op_codigo_externo,
		op_ref_exterior,    '',
		op_num_comex,
		op_tipo_linea,      op_nombre,              op_fecha_fin, tipo,
		op_grupo
		from  ca_operacion, @w_prestamos
		where op_operacion   = operacion
		and op_monto_aprobado > op_monto
	end
end

-- RETORNAR DATOS A FRONT END

SIGUIENTE:

if @i_oficina = @w_oficina_matriz  select @i_oficina = null
IF @i_web = 'N'
   set rowcount 20
else
  set rowcount 0

if object_id('tempdb..#busqueda_operaciones') is not null
   drop table #busqueda_operaciones
   
select
'usuario'        = @s_user,
'linCredito'     = substring(bot_toperacion,1,30),
'moneda'         = bot_moneda,
'nOperacion'     = bot_banco,
'montoOperacion' = round(convert(float, bot_monto),2), --LPO CDIG API redondeo a 2 decimales
'cliente'        = substring(bot_nombre,1,30),
'desembolso'     = convert(varchar(16),bot_fecha_ini, @i_formato_fecha),
'vencimiento'    = convert(varchar(10),bot_fecha_fin, @i_formato_fecha),
'regOficial'     = bot_oficial,
'oficina'        = bot_oficina,
'cupCredito'     = (select li_numero from cob_credito..cr_linea where li_num_banco = t.bot_lin_credito), --LCA CDIG obtener el li_numero que es INT , no el varchar  --bot_lin_credito,
'opMigrada'      = substring(bot_migrada,1,20),
'opAnterior'     = substring(bot_anterior,1,20),
'estado'         = substring(es_descripcion,1,20),
'tramite'        = convert(varchar(13),bot_tramite),
'codCli'         = bot_cliente,
'secuencial'     = bot_operacion,
'reajEspecial'   = bot_reajuste_especial,
'refRedescont'   = bot_nro_red,
'claseOper'      = bot_tipo,
'grupal'         = bot_grupo,
'categoria'      = bot_tipo_grupo_cat
into #busqueda_operaciones
from   ca_buscar_operaciones_tmp t, ca_estado --LCA CDIG se pone alias t
where  bot_usuario = @s_user
and    (bot_moneda         = @i_moneda         or @i_moneda         is null)
and    (bot_fecha_ini      = @i_fecha_ini      or @i_fecha_ini      is null)
and    (bot_estado         = @w_estado         or @w_estado         is null)
and    (bot_migrada        = @i_migrada        or @i_migrada        is null)
and    (bot_toperacion     = @i_toperacion     or @i_toperacion     is null)
and    (bot_oficina        = @i_oficina        or @i_oficina        is null)
and    (bot_oficial        = @i_oficial        or @i_oficial        is null)
and    (bot_tramite        = @i_tramite        or @i_tramite        is null)
and    (bot_banco          = @i_banco          or @i_banco          is null)
and    (bot_cliente        = @i_cliente        or @i_cliente          is null)
and    bot_estado = es_codigo
and    bot_operacion > @i_siguiente
order  by bot_operacion
	
if @i_filtro_adicional = 'T' -- Busqueda para traslados Masivos Oficial y Oficina
begin
     
   -- Eliminar OPs Hijas
   delete #busqueda_operaciones
   from ca_operacion with (nolock)
   where nOperacion = op_banco
   and op_grupal = 'S'
   and op_ref_grupal is not null
   
   -- Eliminar Padres si no tiene OPs hijas activas
   delete #busqueda_operaciones
   from ca_operacion with (nolock)
   where nOperacion = op_banco
   and op_grupal = 'S'
   and op_ref_grupal is null
   and not exists (select 1 
                   from ca_operacion with (nolock)
				   where op_grupal = 'S'
				   and op_ref_grupal = nOperacion
				   and op_estado not in (0,99,3,6))
				   
   if @i_grupal = 'S'
      delete #busqueda_operaciones
      from ca_operacion with (nolock)
      where nOperacion = op_banco
      and op_grupal = 'N'
   
end

-- Resulset final
select  
  linCredito      
, moneda          
, nOperacion       
, montoOperacion   
, cliente          
, desembolso      
, vencimiento      
, regOficial       
, oficina         
, cupCredito        
, opMigrada        
, opAnterior       
, estado          
, tramite         
, codCli           
, secuencial       
, reajEspecial    
, refRedescont    
, claseOper        
, grupal           
, categoria       
from #busqueda_operaciones
where usuario = @s_user
   
if @@rowcount = 0 begin
   select @w_error = 77539 --No existe informacion para los criterios consultados
   goto ERROR
end

set rowcount 0

return 0

ERROR:

set rowcount 0

IF @i_web = 'N' begin
   select
   'Lin.Crédito    '  = substring(bot_toperacion,1,30),
   'Moneda'            = bot_moneda,
   'No.Operación'     = bot_banco,
   'Monto Operación'  = convert(float, bot_monto),
   'Cliente'           = substring(bot_nombre,1,30),
   'Desembolso'        = convert(varchar(16),bot_fecha_ini, @i_formato_fecha),
   'Vencimiento'       = convert(varchar(10),bot_fecha_fin, @i_formato_fecha),
   'Reg/Oficial'       = bot_oficial,
   'Oficina'           = bot_oficina,
   'Cup.Crédito'      = 0, --LCA CDIG --bot_lin_credito
   'Op.Migrada'        = substring(bot_migrada,1,20),
   'Op.Anterior'       = substring(bot_anterior,1,20),
   'Estado'            = substring(es_descripcion,1,20),
   'Trámite'          = convert(varchar(13),bot_tramite),
   'Cod.Cli'           = bot_cliente,
   'Secuencial'        = bot_operacion,
   'Reaj.Especial'     = bot_reajuste_especial,
   'Ref.Redescont'     = bot_nro_red,
   'Clase Oper.'       = bot_tipo,
   'Grupal'            = bot_grupo,
   'Categoria'         = bot_tipo_grupo_cat
   from   ca_buscar_operaciones_tmp, ca_estado
   where  1=2

   --return 1


END

exec cobis..sp_cerror
@t_debug = 'N',
@t_file = null,
@t_from = 'sp_buscar_operaciones',
@i_num  = @w_error--, --701172,
--@i_msg = @w_msg
 
return @w_error
 
GO
