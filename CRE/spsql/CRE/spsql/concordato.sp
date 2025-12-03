/***********************************************************************/
/*    Archivo:                          concordato.sp                  */
/*    Stored procedure:                 sp_concordato                  */
/*    Base de Datos:                    cob_credito                    */
/*    Disenado por:                     M. Davila                      */
/*    Producto:                         CONSOLIDADOR                   */
/*    Fecha de Documentacion:           29/Jun/1998                    */
/***********************************************************************/
/*                          IMPORTANTE                                 */
/*    Este programa es parte de los paquetes bancarios propiedad de    */
/*    'MACOSA',representantes exclusivos para el Ecuador de la         */
/*    AT&T                                                             */
/*    Su uso no autorizado queda expresamente prohibido asi como       */
/*    cualquier autorizacion o agregado hecho por alguno de sus        */
/*    usuario sin el debido consentimiento por escrito de la           */
/*    Presidencia Ejecutiva de MACOSA o su representante               */
/***********************************************************************/
/*                          PROPOSITO                                  */
/*    Este stored procedure nos permitirÿ modificar la                 */
/*    situaci½n de un cliente, y registrarlo en la tablas              */
/*      cr_concordato, cobis..cl_ente y cr_estados_concordato          */
/*                                                                     */
/***********************************************************************/

use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_concordato')
    drop proc sp_concordato
go
create proc sp_concordato (
   @s_date                 datetime    = null,
   @s_user                 login       = null,
   @s_ssn                  int         = null,
   @s_sesn                 int         = null,
   @s_term                 descripcion = null,
   @s_srv                  varchar(30) = null,
   @s_lsrv                 varchar(30) = null,
   @s_ofi                  smallint    = null,
   @i_operacion            char(1)     = null,
   @t_trn                  smallint    = null,
   @t_rty                  char(1)     = null,
   @i_cliente              int         = null,
   @i_situacion            catalogo    = null,
   @i_estado               catalogo    = null,
   @i_fecha                datetime    = null,
   @i_fecha_fin            datetime    = null,
   @i_cumplimiento         char(1)     = null,
   @i_modo                 tinyint     = null,
   @i_situacion_anterior   catalogo    = null,
   @i_acta_cas             catalogo    = null,
   @i_fecha_cas            datetime    = null,
   @i_causal               catalogo    = null,
   @i_user                 login       = null,
   @i_en_linea             char(1)     = 'S',
   @o_msg                  varchar(100)= null   out
)

as

declare
   @w_error             int,
   @w_sp_name           varchar(32),   /* NOMBRE STORED PROCEDURE */
   @w_existe            tinyint,
   @w_secuencial        int,
   @w_nombre            varchar(254),
   @w_situacion         catalogo,
   @w_desc_situacion    descripcion,
   @w_desc_estado       descripcion,
   @w_fecha             datetime,
   @w_fecha_fin         datetime,
   @w_cumplimiento      char(1),
   @w_estado            catalogo,
   @w_sitc              catalogo,
   @w_esth              catalogo,
   @w_esta              catalogo,
   @w_estado_ant        catalogo,
   @w_situac_ant        catalogo,
   @w_fini_ant          datetime,
   @w_ffin_ant          datetime,
   @w_rficod            catalogo,   --SBU situacion cliente
   @w_rfmcod            catalogo,
   @w_rfidesc           varchar(255),
   @w_rfmdesc           varchar(255),
   @w_refinh            char(1),
   @w_refmer            char(1),
   @w_sit_cli           catalogo,
   @w_acta_cas          catalogo,
   @w_fecha_cas         datetime,
   @w_causal            catalogo,
   @w_desc_causal       descripcion,
   @w_sitpc             varchar(30),
   @w_sitcs             varchar(30),
   @w_cn_situac_ant     catalogo,
   @w_cn_estado_ant     catalogo,
   @w_cn_fini_ant       datetime,
   @w_cn_ffin_ant       datetime,
   @w_cn_cumplimiento   char,
   @w_cn_situacant_ant  catalogo,
   @w_cn_fmodif_ant     datetime,
   @w_cn_acta_ant       catalogo,
   @w_cn_fcas_ant       datetime,
   @w_cn_causal         catalogo,
   @w_contador          int,
   @w_mensaje           varchar(255),
   @w_codigo_externo    varchar(64),
   @w_rowcount          int,
   @w_commit            char(1)


/* INICIAR VARIABLES DE TRABAJO */
select 
@w_sp_name = 'sp_concordato',
@w_existe  = 0,
@w_refinh  = 'N',
@w_refmer  = 'N',
@w_commit  = 'N'


/* SELECCION DE PARAMETROS */
select @w_sitc = pa_char
from cobis..cl_parametro
where pa_nemonico  = 'SITC'
and pa_producto    = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2110297
   goto ERRORFIN
end

select @w_esta = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTA'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2110298

   goto ERRORFIN
end

select @w_esth = pa_char
from cobis..cl_parametro
where pa_nemonico = 'ESTH'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2110299 --NO SE ENCUENTRA EL PARAMETRO GENERAL esth DE CREDITO
   goto ERRORFIN
end

select @w_sitpc = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITPC'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2110300 --'NO SE ENCUENTRA EL PARAMETRO GENERAL sitpc DE CREDITO'
   goto ERRORFIN
end

/* SELECCION DE PARAMETROS */
select @w_sitcs = pa_char
from cobis..cl_parametro
where pa_nemonico = 'SITCS'
and pa_producto = 'CRE'
select @w_rowcount = @@rowcount

if @w_rowcount = 0 begin
   select @w_error = 2110301 --'NO SE ENCUENTRA EL PARAMETRO GENERAL sitcs DE CREDITO'
   goto ERRORFIN
end

/* CHEQUEO DE LA EXISTENCIA DE LOS CAMPOS */
if exists (select 1 from cr_concordato where cn_cliente = @i_cliente)
   select @w_existe = 1
else
   select @w_existe = 0


/* VERIFICAR SI SITUACION AMERITA GENERAR REFERENCIA INHIBITORIA */
select 
@w_rficod = codigo_sib,
@w_rfidesc = descripcion_sib
from cr_corresp_sib
where codigo = @i_situacion
and   tabla = 'T14'

if @@rowcount <> 0  select @w_refinh = 'S'



/* VERIFICAR SI SITUACION AMERITA GENERAR REFERENCIA DE MERCADO */
select 
@w_rfmcod = codigo_sib,
@w_rfmdesc = descripcion_sib
from cr_corresp_sib
where codigo = @i_situacion
and   tabla  = 'T15'

if @@rowcount <> 0  select @w_refmer = 'S'



/**************************/
/* SE REALIZARA UN INSERT O UN UPDATE DEPENDIENDO SI EL REGISTRO EXISTE */
/* O NO EN LA TABLA cr_concordato  */
/**************************/
if @i_operacion = 'I' begin

   if @@trancount = 0 begin
      begin tran
      select @w_commit = 'S'
   end

   if @w_existe = 1  begin /* SI EXISTE HACEMOS EL UPDATE */

      select
      @w_situac_ant = cn_situacion,
      @w_estado_ant = cn_estado,
      @w_fini_ant   = cn_fecha,
      @w_ffin_ant   = cn_fecha_fin,
      @w_causal     = cn_causal
      from cr_concordato
      where cn_cliente = @i_cliente

      if (@w_situac_ant <> @i_situacion) and (@w_situac_ant = @w_sitc) and (@s_date < @w_ffin_ant)
      begin
         select @w_error = 2110302 --'CONCORDATO ANTERIOR NO HA FINALIZADO (CASTIGO)'
         goto ERRORFIN
      end

      if (@w_estado_ant = @w_esth) and (@w_ffin_ant > @i_fecha) and (@i_estado = @w_esta)
      begin
         select @w_error = 2110303 --'CONCORDATO ANTERIOR NO HA FINALIZADO (HOMOLOGADO)'
         goto ERRORFIN
      end

      if @i_estado is not null begin
      
         if @w_estado_ant <> @i_estado begin
         
            if (@i_estado = @w_esta) and (@w_estado_ant = @w_esth) and (@w_ffin_ant is null)
            begin
               select @w_error = 2110304 --'NO EXISTE FECHA DE FIN DE ESTADO HOMOLOGADO'
               goto ERRORFIN
            end

            if (@i_estado = @w_esta) and (@w_estado_ant = @w_esth) and (@w_ffin_ant > @i_fecha)
            begin
               select @w_error = 2110305 --'FECHA DE FIN DE ESTADO HOMOLOGADO POSTERIOR AL ESTADO ADMITIDO'
               goto ERRORFIN
            end

            if (@i_fecha < @w_fini_ant) begin
               select @w_error = 2110306 --'FECHA DE INICIO DEL NUEVO ESTADO MENOR QUE LA DEL ESTADO ANTERIOR'
               goto ERRORFIN
            end

            select @w_secuencial = max(ec_secuencial) + 1
            from cr_estados_concordato
            where ec_cliente = @i_cliente
            
            select @w_secuencial = isnull(@w_secuencial,1)
            
            /*INSERTAMOS EL REGISTRO EN LA TABLA cr_estados_concordato */
            insert into cr_estados_concordato (
            ec_cliente,   ec_secuencial,  ec_estado,
            ec_fecha,     ec_fecha_fin,  ec_usuario)
            values (
            @i_cliente,  @w_secuencial,   @i_estado,
            @i_fecha,    @i_fecha_fin,    @s_user)
            
            if @@error <> 0 begin
                select @w_error = 2110307 --'ERROR AL INSERTAR REGISTRO (cr_estados_concordato)'
                goto ERRORFIN
            end

         end else begin  --@w_estado_ant = @i_estado

            select @w_secuencial = max(ec_secuencial)
            from cr_estados_concordato
            where ec_cliente = @i_cliente
            
            select @w_secuencial = isnull(@w_secuencial,0)
         
            if @w_secuencial > 1 begin
               select @w_fini_ant = ec_fecha
               from cr_estados_concordato
               where ec_cliente    = @i_cliente
               and   ec_secuencial = @w_secuencial - 1

               if (@i_fecha < @w_fini_ant) begin
                  select @w_error = 2110306 --'FECHA DE INICIO DEL NUEVO ESTADO MENOR QUE LA DEL ESTADO ANTERIOR (2)'
                  goto ERRORFIN
               end
            end

            update cr_estados_concordato set
            ec_fecha     = @i_fecha,
            ec_fecha_fin = @i_fecha_fin
            where ec_cliente    = @i_cliente
            and   ec_secuencial = @w_secuencial

            if @@error <> 0 begin
               select @w_error = 2110307 --'ERROR AL ACTUALIZAR REGISTRO (cr_estado_concordato)'
               goto ERRORFIN
            end
         end
      end

      /*Selecci¢n de los datos anteriores*/
      select
      @w_cn_situac_ant    = cn_situacion,
      @w_cn_estado_ant    = cn_estado,
      @w_cn_fini_ant      = cn_fecha,
      @w_cn_ffin_ant      = cn_fecha_fin,
      @w_cn_cumplimiento  = cn_cumplimiento,
      @w_cn_situacant_ant = cn_situacion_ant,
      @w_cn_fmodif_ant    = cn_fecha_modif,
      @w_cn_acta_ant      = cn_acta_cas,
      @w_cn_fcas_ant      = cn_fecha_cas,
      @w_cn_causal        = cn_causal
      from cr_concordato
      where cn_cliente = @i_cliente


      /* SE ACTUALIZA EL REGISTRO EN LA TABLA cr_concordato */
      update cr_concordato set
      cn_situacion        = @i_situacion,
      cn_estado           = @i_estado,
      cn_fecha            = @i_fecha,
      cn_fecha_fin        = @i_fecha_fin,
      cn_cumplimiento     = @i_cumplimiento,
      cn_situacion_ant    = @i_situacion_anterior, --SBU 10/ago/2001
      cn_fecha_modif      = @s_date,
      cn_acta_cas         = @i_acta_cas,
      cn_fecha_cas        = @i_fecha_cas,
      cn_causal           = @i_causal
      where cn_cliente    = @i_cliente

      if @@error <> 0 begin
         select @w_error = 2110308 --'ERROR AL ACTUALIZAR REGISTRO (cr_estado)'
         goto ERRORFIN
      end


      /**** TRANSACCION DE SERVICIO ***/
      insert into ts_concordato
      values (@s_ssn, @t_trn, 'P',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_concordato', @s_lsrv,
      @s_srv,
      @i_cliente, @w_cn_situac_ant, @w_cn_estado_ant, @w_cn_fini_ant,
      @w_cn_ffin_ant, @w_cn_cumplimiento, @w_cn_situacant_ant ,@w_cn_fmodif_ant,
      @w_cn_acta_ant, @w_cn_fcas_ant, @w_cn_causal
      )

      if @@error <> 0  begin
         select @w_error = 2110291 --'ERROR EN INSERCION DE TRANSACCION DE SERVICIO (1)'
         goto ERRORFIN
      end

      /**** TRANSACCION DE SERVICIO ***/
      insert into ts_concordato
      values (@s_ssn, @t_trn, 'A',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_concordato', @s_lsrv,
      @s_srv,
      @i_cliente, @i_situacion, @i_estado, @i_fecha,
      @i_fecha_fin, @i_cumplimiento, @i_situacion_anterior, @s_date,
      @i_acta_cas, @i_fecha_cas, @i_causal
        )

      if @@error <> 0 begin
         select @w_error = 2110291 --'ERROR EN INSERCION DE TRANSACCION DE SERVICIO (2)'
         goto ERRORFIN
      end

      
   end else begin /* CASO CONTRARIO SE REALIZA UN INSERT EN LA TABLA cr_concordato */
   
   
      insert into cr_concordato values (
      @i_cliente,             @i_situacion,    @i_estado,
      @i_fecha,               @i_fecha_fin,    @i_cumplimiento,
      @i_situacion_anterior,  @s_date,         @i_acta_cas,
      @i_fecha_cas,           @i_causal)

      if @@error <> 0  begin
         select @w_error = 2110309 --'ERROR EN INSERCION DEL CONCORDATO (cr_concordato)'
         goto ERRORFIN
      end

      /**** TRANSACCION DE SERVICIO ***/
      insert into ts_concordato
      values (@s_ssn, @t_trn, 'N',
      @s_date, @s_user, @s_term,
      @s_ofi, 'cr_concordato', @s_lsrv,
      @s_srv,
      @i_cliente, @i_situacion, @i_estado,
      @i_fecha, @i_fecha_fin, @i_cumplimiento,
      @i_situacion_anterior, @s_date, @i_acta_cas,
      @i_fecha_cas, @i_causal
      )

      if @@error <> 0  begin
         select @w_error = 2110291 --'ERROR EN INSERCION DE TRANSACCION DE SERVICIO (3)'
         goto ERRORFIN
      end


      if @i_estado is not null begin
      
         /* SE CALCULA EL MAXIMO SECUENCIAL PARA EL CLIENTE */
         select @w_secuencial = max (ec_secuencial) + 1
         from cr_estados_concordato
         where ec_cliente = @i_cliente

         select @w_secuencial = isnull(@w_secuencial,1)

         /*INSERTAMOS EL REGISTRO EN LA TABLA cr_estados_concordato */
         insert into cr_estados_concordato (
         ec_cliente,   ec_secuencial,  ec_estado,
         ec_fecha,     ec_fecha_fin,   ec_usuario)
         values (
         @i_cliente,  @w_secuencial,   @i_estado,
         @i_fecha,    @i_fecha_fin,    @s_user)

         if @@error <> 0 begin
            select @w_error = 2110307 --'ERROR EN INSERCION DEL ESTADO DEL CONCORDATO (cr_estados_concordato)'
            goto ERRORFIN
         end
      end

   end

   /* ACTUALIZAR LA SITUACION DEL CLIENTE (EN COBIS CLIENTES) */
   if isnull(@i_situacion,'') <> isnull(@i_situacion_anterior,'')  begin
   
      update cobis..cl_ente set
      en_situacion_cliente = isnull(@i_situacion, en_situacion_cliente)
      where en_ente = @i_cliente

      if @@error <> 0 begin
         select @w_error = 2110310 --'ERROR AL ACTUALIZAR REGISTRO (cl_ente)'
         goto ERRORFIN
      end

      if @w_refmer = 'S' begin
      
         exec @w_error = sp_estado_cliente
         @s_date         = @s_date,
         @s_user         = @s_user,
         @s_ssn          = @s_ssn,
         @s_term         = @s_term,
         @s_srv          = @s_srv,
         @i_cliente      = @i_cliente,
         @i_mala_ref     = 'N',
         @i_refcod       = @w_rfmcod,
         @i_refdesc      = @w_rfmdesc

         if @w_error <> 0 begin
            goto ERRORFIN
         end
         
      end

      if @w_refinh = 'S' begin
      
         exec @w_error = sp_estado_cliente
         @s_date         = @s_date,
         @s_user         = @s_user,
         @s_ssn          = @s_ssn,
         @s_term         = @s_term,
         @s_srv          = @s_srv,
         @i_cliente      = @i_cliente,
         @i_mala_ref     = 'S',
         @i_refcod       = @w_rficod,
         @i_refdesc      = @w_rfidesc

         if @w_error <> 0 begin
            goto ERRORFIN
         end
      end
   end

   
   -- ejecucion sp_historial_situacion Req. 214
   exec @w_error = cob_credito..sp_historial_situacion
   @s_user         = @s_user,
   @s_date         = @s_date,
   @t_trn          = 21299,
   @i_operacion    = 'I',
   @i_cliente      = @i_cliente,
   @i_situacion    = @i_situacion,
   @i_causal       = @i_causal

   if @w_error <> 0 begin
      select @w_error = 2110311 --'ERROR AL REGISTRAR EL HISTORICO DE SITUACION (sp_historial_situacion)'
      goto ERRORFIN
   end


   /* MARCAR A LAS GARANTIAS DEL CLIENTE COMO NO ADECUADAS */
   /* TEC - JES
   if @i_situacion = @w_sitcs begin

      declare cur_garantia cursor for
      select cg_codigo_externo
      from cob_custodia..cu_cliente_garantia
      where cg_ente         = @i_cliente
      and   cg_tipo_garante = 'J'

      open cur_garantia
      fetch cur_garantia into @w_codigo_externo

      while @@fetch_status = 0  begin
      
         exec @w_error = cob_custodia..sp_cambio_clase
         @s_date            = @s_date,
         @s_user            = @s_user,
         @s_ofi             = @s_ofi,
         @s_term            = @s_term,
         @i_codigo_externo  = @w_codigo_externo,
         @i_adecuada_noadec = 'O'
         
         if @w_error <> 0 begin
            select @o_msg = 'ERROR AL CAMBIAR LA CLASE DE LA GARANTIA (sp_cambio_clase)'
            close cur_garantia
            deallocate cur_garantia
            goto ERRORFIN
         end


         fetch cur_garantia into @w_codigo_externo
      end
      close cur_garantia
      deallocate cur_garantia
   end
   */

   if @w_commit = 'S' begin
      commit tran
      select @w_commit = 'N'
   end
   
end

/*************************/
/* CONSULTA OPCION QUERY */
/* TRAE TODOS LOS DATOS DEL REGISTRO cr_concordato Y DATOS DE LA TABLA */
/* cr_estados_concordato */
/*************************/

if @i_operacion = 'Q' begin

   select
   @w_nombre = en_nomlar,
   @w_sit_cli = en_situacion_cliente
   from cobis..cl_ente
   where en_ente = @i_cliente


   select
   @w_situacion     = cn_situacion,
   @w_fecha         = cn_fecha,
   @w_fecha_fin     = cn_fecha_fin,
   @w_cumplimiento  = cn_cumplimiento,
   @w_estado        = cn_estado,
   @w_acta_cas     = cn_acta_cas,
   @w_fecha_cas       = cn_fecha_cas,
   @w_causal       = cn_causal
   from cr_concordato
   where cn_cliente = @i_cliente

   select @w_situacion = isnull(@w_situacion,@w_sit_cli) --SBU situacion cliente

   if @w_situacion is not null
   begin
      select @w_desc_situacion = a.valor
      from cobis..cl_catalogo a
      where a.tabla = (select b.codigo
                    from cobis..cl_tabla b
                    where  b.tabla = 'cl_situacion_cliente')
      and a.codigo = @w_situacion

   end

   if @w_estado is not null
   begin
   select @w_desc_estado = a.valor
   from cobis..cl_catalogo a
   where a.tabla = (select b.codigo
                    from cobis..cl_tabla b
                    where  b.tabla = 'cr_est_concordato')
      and a.codigo = @w_estado

   end


   /*DESCRIPCION DEL CAUSAL*/

   if @w_causal is not null
   begin
      select @w_desc_causal = a.valor
      from cobis..cl_catalogo a
      where a.tabla = (select b.codigo
            from cobis..cl_tabla b
            where b.tabla = 'cr_causal_situacion')
           and a.codigo = @w_causal

   end


   /* VALORES A RETORNAR */
   select
   @w_nombre,
   @w_situacion,
   @w_desc_situacion,
   @w_estado,
   @w_desc_estado,
   convert (char(10),@w_fecha,103),
   convert (char(10),@w_fecha_fin,103),
   @w_cumplimiento,
   @w_acta_cas,
   convert (char(10),@w_fecha_cas,103),
   @w_causal,
   @w_desc_causal

   select
   --'Secuencial'  = ec_secuencial, MVG 990202 6.3
   'Estado'        = ec_estado,
   'Descripcion'   = c.valor,
   'Fecha inicio'  = convert(char(10),ec_fecha,103),
   'Fecha final'   = convert(char(10),ec_fecha_fin,103)
   from cr_estados_concordato, cobis..cl_catalogo c, cobis..cl_tabla t
   where  ec_cliente = @i_cliente
   and c.codigo = ec_estado
   and t.codigo = c.tabla
   and t.tabla  = 'cr_est_concordato'
   order by ec_secuencial desc
end


/* Consulta del estado del Concordato para habilitacion de campos */

if @i_operacion = 'V' begin
   if @i_modo = 0  begin
      if @w_sitc = @i_situacion
        select 'S'
      else
        select 'N'
   end

   if @i_modo = 1 begin
      if @w_esth = @i_estado
         select 'S'
      else
        select 'N'
   end
end

return 0

ERRORFIN:

if @w_commit = 'S' begin
   rollback tran
   select @w_commit = 'N'
end

if @i_en_linea = 'S' begin
   exec cobis..sp_cerror
   @t_from  = @w_sp_name,
   @i_num   = @w_error
end

return @w_error
go


