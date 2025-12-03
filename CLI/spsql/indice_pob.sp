/********************************************************************/
/*  Archivo:                         indice_pob.sp                  */
/*  Stored procedure:                sp_indice_pob                  */
/*  Base de datos:                   cobis                          */
/*  Producto:                        Clientes                       */
/*  Disenado por:                    BDU                            */
/*  Fecha de escritura:              29-12-2022                     */
/********************************************************************/
/*                     IMPORTANTE                                   */
/*   Este programa es parte de los paquetes bancarios que son       */
/*   comercializados por empresas del Grupo Empresarial Cobiscorp,  */
/*   representantes exclusivos para comercializar los productos y   */
/*   licencias de COBISCORP TECHNOLOGIES S.L., sociedad constituida */
/*   y regida por las Leyes de la República de España y las         */
/*   correspondientes de la Unión Europea. Su copia, reproducción,  */
/*   alteración en cualquier sentido, ingeniería reversa,           */
/*   almacenamiento o cualquier uso no autorizado por cualquiera    */
/*   de los usuarios o personas que hayan accedido al presente      */
/*   sitio, queda expresamente prohibido sin el debido              */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada y por lo tanto, derivará en acciones legales civiles   */
/*   y penales en contra del infractor según corresponda.           */
/********************************************************************/
/*                          PROPOSITO                               */
/*  SP para realizar las operaciones de parametrizacion/ingreso de  */
/*  preguntas/respuestas de indice de pobreza                       */
/********************************************************************/
/*                        MODIFICACIONES                            */
/*      FECHA           AUTOR           RAZON                       */
/*      29/12/22        BDU        Emision Inicial                  */
/*      04/01/23        BDU        Se agrega funcionalidad para     */
/*                                 pantalla probalidad de indice    */
/*                                 de pobreza                       */
/*      16/01/23        BDU        Se agrega estado pregunta        */
/*      27/02/23        BDU        Se agrega registro de score      */
/*                                 total                            */
/*      10/03/22        OAL        S762912 se agrega preguntas      */
/*      23/03/22        BDU        S801301 Se guarda puntaje en     */
/*                                 cambio de fechas                 */
/*      22/08/22        BDU        R213196 Quitar preguntas can-    */
/*                                 celadas que no esten en uso      */
/*      09/09/23        BDU        R214440-Sincronizacion automatica*/
/*      22/01/24        BDU        R224055-Validar oficina app      */
/********************************************************************/
use cobis
go

set ANSI_NULLS off
go
set QUOTED_IDENTIFIER off
go

if exists (select 1 from sysobjects where name = 'sp_indice_pob')
   drop proc sp_indice_pob
go
CREATE PROCEDURE sp_indice_pob (
        @s_ssn                  int             = null,
        @s_user                 login           = null,
        @s_term                 varchar(32)     = null,
        @s_sesn                 int             = null,
        @s_culture              varchar(10)     = null,
        @s_date                 datetime        = null,
        @s_srv                  varchar(30)     = null,
        @s_lsrv                 varchar(30)     = null,
        @s_rol                  smallint        = NULL,
        @s_org_err              char(1)         = NULL,
        @s_error                int             = NULL,
        @s_sev                  tinyint         = NULL,
        @s_msg                  descripcion     = NULL,
        @s_org                  char(1)         = NULL,
        @s_ofi                  smallint        = NULL,
        @t_debug                char(1)         = 'N',
        @t_file                 varchar(14)     = null,
        @t_from                 varchar(30)     = null,
        @t_trn                  int             = null,
        @t_show_version         bit             = 0,     -- Mostrar la version del programa
        @i_operacion            char            = null,  -- Valor de la operacion a realizar
        @i_tipo                 char            = null,  -- Diferenciador de pregunta o respuesta
        @i_num_preg             int             = NULL,  -- CÃ³digo de la pregunta
        @i_preg                 varchar(30)     = NULL,  -- pregunta
        @i_desc_preg            varchar(256)    = NULL,  -- Descripcion de la pregunta
        @i_num_resp             int             = NULL,  -- CÃ³digo de la respuesta,
        @i_resp                 varchar(150)    = NULL,  -- respuesta
        @i_score_resp           int             = NULL,  -- score de la respuesta
        @i_estado               catalogo        = NULL,  -- Codigo del estado,
        @i_ente                 int             = NULL,  -- Codigo del ente
        @i_fecha_ini            datetime        = NULL,  -- Fecha inicio para PPI
        @i_sum_score            int             = null,  -- Score total del PPI para el cliente
        @i_is_app               char(1)         = 'N',  -- Inidica si viene desde la APP
        @o_preg                 int             = null out,
        @o_resp                 int             = null out,
        @o_fecha_fin            datetime        = null out,
        @o_fecha_fin_s          varchar(10)     = null out
        )
as
declare 
        @w_sp_name          varchar(32),
        @w_return           int,
        @w_date             date,
        @w_id               int,
        @w_fecha_proceso    date,
        @w_param_fecha      int,
        @w_grupo_nombre     varchar(200),
        @w_format_date      int,
        @w_prev_date        datetime,
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_ofi_app         smallint
        
declare @w_tabla_usuarios as table(
   id         int,
   pregunta   varchar(10),
   respuesta  varchar(10),
   score      varchar(10),
   estado     catalogo
)
select @w_sp_name     = 'sp_indice_pob',
       @w_format_date = 103

/*  'No corresponde codigo de transaccion' */
if @t_trn not in (172223, 172224, 172225, 172226) 
begin
   select @w_return = 1720075
   goto ERROR
end

select @w_fecha_proceso = fp_fecha 
from cobis.dbo.ba_fecha_proceso bfp 

select @w_prev_date = pe_fecha_ini
from cobis.dbo.cl_ppi_ente 
where pe_ente = @i_ente

select @w_param_fecha = pa_int 
from cobis.dbo.cl_parametro
where pa_nemonico = 'MVPPI'
and pa_producto = 'CLI'

if @i_is_app = 'S'
begin
   select @w_format_date = isnull(pa_int,103) 
     from cobis..cl_parametro 
    where pa_nemonico = ('FFEC') 
      and pa_producto = 'PAM'
end

select @i_fecha_ini = CONVERT(date,@i_fecha_ini,@w_format_date)
select @o_fecha_fin = DATEADD(MONTH, @w_param_fecha, @i_fecha_ini)
select @o_fecha_fin_s = CONVERT(date,@o_fecha_fin,@w_format_date)
select @o_fecha_fin = CONVERT(date,@o_fecha_fin,@w_format_date)
select @w_date = @o_fecha_fin
if @i_operacion = 'I'
begin
   if @i_tipo = 'P'
   begin
      exec cobis..sp_cseqnos
         @t_debug     = 'N',
         @t_file      = '',
         @t_from      = @w_sp_name,
         @i_tabla     = 'cl_indice_pob_preg',
         @o_siguiente = @o_preg out
         
      insert into cl_indice_pob_preg
      (ipp_num_preg,    ipp_pregunta,   ipp_descripcion,   ipp_estado, 
      ipp_usuario_crea, ipp_fecha_crea, ipp_usuario_modif, ipp_fecha_modif)
      values(
      @o_preg,          @i_preg,        @i_desc_preg,      @i_estado, 
      @s_user,          getdate(),      null,              null);
      if @@error <> 0
      begin
         select @w_return = 1720629
         goto ERROR
      end
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_preg
      (secuencial,   tipo_transaccion, clase,         fecha, 
       usuario,      terminal,         srv,           lsrv, 
       num_pregunta, pregunta,         descripcion,   estado, 
       usuario_crea, fecha_crea,       usuario_mod,   fecha_mod)
      VALUES(                                         
       @s_ssn,       @t_trn,           'N',           getdate(), 
       @s_user,      @s_term,          @s_srv,        @s_lsrv, 
       @i_num_preg,  @i_preg,          @i_desc_preg,  @i_estado, 
       @s_user,      getdate(),        null,          null);

      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end         
   end
   else if @i_tipo = 'R'
   begin
      exec cobis..sp_cseqnos
         @t_debug     = 'N',
         @t_file      = '',
         @t_from      = @w_sp_name,
         @i_tabla     = 'cl_indice_pob_respuesta',
         @o_siguiente = @o_resp out
         
      insert into cl_indice_pob_respuesta
      (ipr_numero_resp, ipr_num_preg,      ipr_respuesta, 
       ipr_score,       ipr_estado,        ipr_usuario_crea, 
       ipr_fecha_crea,  ipr_usuario_modif, ipr_fecha_modif)
      values(
       @o_resp,         @i_num_preg,        @i_resp, 
       @i_score_resp,   @i_estado,          @s_user, 
       getdate(),       null,               null);
      
      if @@error <> 0
      begin
         select @w_return = 1720630
         goto ERROR
      end
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_respuesta
     (secuencial,   tipo_transaccion, clase,       fecha, 
      usuario,      terminal,         srv,         lsrv, 
      num_pregunta, num_respuesta,    respuesta,   score, 
      estado,       usuario_crea,     fecha_crea,  usuario_mod, 
      fecha_mod)
     VALUES(
      @s_ssn,       @t_trn,           'N',         getdate(), 
      @s_user,      @s_term,          @s_srv,      @s_lsrv, 
      @i_num_preg,  @i_num_resp,      @i_resp,     @i_score_resp, 
      @i_estado,    @s_user,          getdate(),   null, 
      null)

      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end      
   end
   else if @i_tipo = 'H'
   begin
      if exists(select 1 from cl_ppi_ente where pe_ente = @i_ente)
      begin
         /*Insercion data de auditoria*/
         INSERT INTO ts_ppi_ente
        (secuencial,   tipo_transaccion, clase,        fecha, 
         usuario,      terminal,         srv,          lsrv, 
         ente,         fecha_ini,        fecha_fin,    usuario_ppi,                           
         fecha_ing,    fecha_mod)                      
        select                                        
         @s_ssn,       @t_trn,           'A',          getdate(), 
         @s_user,      @s_term,          @s_srv,       @s_lsrv, 
         pe_ente,      pe_fecha_ini,     pe_fecha_fin, pe_usuario, 
         pe_fecha_ing, pe_fecha_modif
         from cl_ppi_ente
         where pe_ente      = @i_ente
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end     
         
         update cl_ppi_ente
         set pe_fecha_ini   = @i_fecha_ini,
             pe_fecha_fin   = @w_date,
             pe_usuario     = @s_user,
             pe_fecha_modif = getdate()
         where pe_ente      = @i_ente
         
         if @@error <> 0 
         begin
            select @w_return = 1720639
            goto ERROR  
         end 
         
         /*Insercion data de auditoria*/
         INSERT INTO ts_ppi_ente
        (secuencial,   tipo_transaccion, clase,        fecha, 
         usuario,      terminal,         srv,          lsrv, 
         ente,         fecha_ini,        fecha_fin,    usuario_ppi,                           
         fecha_ing,    fecha_mod)                      
        VALUES(                                        
         @s_ssn,       @t_trn,           'D',          getdate(), 
         @s_user,      @s_term,          @s_srv,       @s_lsrv, 
         @i_ente,      @i_fecha_ini,     @w_date, @s_user, 
         getdate(),    null)
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end      
      end
      else
      begin
         INSERT INTO cobis.dbo.cl_ppi_ente
         (pe_ente,      pe_fecha_ini,   pe_fecha_fin,   pe_usuario, 
          pe_fecha_ing, pe_fecha_modif)
         VALUES(
          @i_ente,      @i_fecha_ini,   @w_date,   @s_user, 
          getdate(),    null);
         if @@error <> 0
         begin
            select @w_return = 1720637
            goto ERROR
         end
         /*Insercion data de auditoria*/
         INSERT INTO ts_ppi_ente
        (secuencial,   tipo_transaccion, clase,        fecha, 
         usuario,      terminal,         srv,          lsrv, 
         ente,         fecha_ini,        fecha_fin,    usuario_ppi,                           
         fecha_ing,    fecha_mod)                      
        VALUES(                                        
         @s_ssn,       @t_trn,           'N',          getdate(), 
         @s_user,      @s_term,          @s_srv,       @s_lsrv, 
         @i_ente,      @i_fecha_ini,     @w_date, @s_user, 
         getdate(),    null)
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end     
      end
      --Insertar el score del cliente
      if not exists(select 1 
                    from cl_puntaje_ppi_ente 
                    where ppe_ente = @i_ente) or
         not exists(select 1 
                    from cl_puntaje_ppi_ente 
                    where ppe_ente = @i_ente 
                    and ppe_fecha = (select max(ppe_fecha) 
                                     from cl_puntaje_ppi_ente 
                                     where ppe_ente = @i_ente)
                    and ppe_score = @i_sum_score) or
         (@w_prev_date is not null and (@w_prev_date <> @i_fecha_ini))
      begin
         insert into cl_puntaje_ppi_ente(ppe_fecha, ppe_ente, ppe_score)
         values (getdate(), @i_ente, @i_sum_score)
         if @@error <> 0
         begin
            select @w_return = 1720642
            goto ERROR  
         end
      end     
   end
   else if @i_tipo = 'G'
   begin
      if not exists(select 1 from cl_det_ppi_ente where dpe_ente = @i_ente and dpe_num_preg = @i_num_preg)
      begin
         INSERT INTO cobis.dbo.cl_det_ppi_ente
         (dpe_ente, dpe_num_preg, dpe_numero_resp, dpe_score)
         VALUES(@i_ente, @i_num_preg, @i_num_resp, @i_score_resp);
         if @@error <> 0 
         begin
            select @w_return = 1720638
            goto ERROR  
         end
         /*Insercion data de auditoria*/
        INSERT INTO ts_det_ppi_ente
        (secuencial,   tipo_transaccion, clase,         fecha, 
         usuario,      terminal,         srv,           lsrv, 
         ente,         num_pregunta,     num_respuesta, score)                      
        VALUES(                                        
         @s_ssn,       @t_trn,           'N',          getdate(), 
         @s_user,      @s_term,          @s_srv,       @s_lsrv, 
         @i_ente,      @i_num_preg,      @i_num_resp,  @i_score_resp)
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end         
      end
      else
      begin
         /*Insercion data de auditoria*/
        INSERT INTO ts_det_ppi_ente
        (secuencial,   tipo_transaccion, clase,            fecha, 
         usuario,      terminal,         srv,              lsrv, 
         ente,         num_pregunta,     num_respuesta,    score)                      
        select                                        
         @s_ssn,       @t_trn,           'A',              getdate(), 
         @s_user,      @s_term,          @s_srv,           @s_lsrv, 
         dpe_ente,     dpe_num_preg,     dpe_numero_resp,  dpe_score
         from cl_det_ppi_ente
         where dpe_ente     =  @i_ente
         and   dpe_num_preg =  @i_num_preg
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end 
         update cl_det_ppi_ente
         set dpe_numero_resp = @i_num_resp,
             dpe_score       = @i_score_resp
         where dpe_ente     =  @i_ente
         and   dpe_num_preg =  @i_num_preg
         if @@error <> 0
         begin
            select @w_return = 1720640
            goto ERROR  
         end 
        /*Insercion data de auditoria*/
        INSERT INTO ts_det_ppi_ente
        (secuencial,   tipo_transaccion, clase,         fecha, 
         usuario,      terminal,         srv,           lsrv, 
         ente,         num_pregunta,     num_respuesta, score)                     
        VALUES(                                        
         @s_ssn,       @t_trn,           'D',          getdate(), 
         @s_user,      @s_term,          @s_srv,       @s_lsrv, 
         @i_ente,      @i_num_preg,      @i_num_resp,  @i_score_resp)
        
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end 
      end
   end
end

if @i_operacion = 'U'
begin
   if @i_tipo = 'P'
   begin
      if not exists(select 1 from cl_indice_pob_preg where ipp_num_preg = @i_num_preg)
      begin
         select @w_return = 1720625
         goto ERROR
      end
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_preg
      (secuencial,   tipo_transaccion, clase,            fecha, 
       usuario,      terminal,         srv,              lsrv, 
       num_pregunta, pregunta,         descripcion,      estado, 
       usuario_crea, fecha_crea,       usuario_mod,      fecha_mod)
      select                                             
       @s_ssn,       @t_trn,           'A',              getdate(), 
       @s_user,      @s_term,          @s_srv,           @s_lsrv, 
       ipp_num_preg, ipp_pregunta,     ipp_descripcion,  ipp_estado, 
       null,         null,             @s_user,          getdate()
       from cl_indice_pob_preg
       where ipp_num_preg = @i_num_preg
      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end 
      select @w_date = getdate()
      UPDATE cl_indice_pob_preg
      SET ipp_descripcion   =  @i_desc_preg,
          ipp_pregunta      =  @i_preg,   
          ipp_estado        =  @i_estado, 
          ipp_usuario_modif =  @s_user, 
          ipp_fecha_modif   =  @w_date
      where ipp_num_preg = @i_num_preg
      
      if @@error <> 0 
      begin
         select @w_return = 1720631
         goto ERROR  
      end     
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_preg
      (secuencial,   tipo_transaccion, clase,         fecha, 
       usuario,      terminal,         srv,           lsrv, 
       num_pregunta, pregunta,         descripcion,   estado, 
       usuario_crea, fecha_crea,       usuario_mod,   fecha_mod)
      VALUES(                                         
       @s_ssn,       @t_trn,           'D',           getdate(), 
       @s_user,      @s_term,          @s_srv,        @s_lsrv, 
       @i_num_preg,  @i_preg,          @i_desc_preg,  @i_estado, 
       null,         null,             @s_user,       getdate())
      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end      

   end
   else if @i_tipo = 'R'
   begin
      if not exists(select 1 
                    from cl_indice_pob_respuesta 
                    where ipr_numero_resp = @i_num_resp
                    and   ipr_num_preg    = @i_num_preg)
      begin
         select @w_return = 1720626
         goto ERROR 
      end
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_respuesta
     (secuencial,   tipo_transaccion, clase,              fecha, 
      usuario,      terminal,         srv,                lsrv, 
      num_pregunta, num_respuesta,    respuesta,          score, 
      estado,       usuario_crea,     fecha_crea,         usuario_mod, 
      fecha_mod)                                          
     select                                               
      @s_ssn,       @t_trn,           'A',                getdate(), 
      @s_user,      @s_term,          @s_srv,             @s_lsrv, 
      @i_num_preg,  @i_num_resp,      ipr_respuesta,      ipr_score, 
      ipr_estado,   null,             null,               @s_user, 
      getdate()
      from cl_indice_pob_respuesta
      where ipr_num_preg    = @i_num_preg
      and   ipr_numero_resp = @i_num_resp

      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end 
      
      select @w_date = getdate()
      
      UPDATE cl_indice_pob_respuesta
      SET ipr_respuesta       = @i_resp, 
          ipr_score           = @i_score_resp, 
          ipr_estado          = @i_estado, 
          ipr_usuario_modif   = @s_user, 
          ipr_fecha_modif     = @w_date
      where ipr_numero_resp = @i_num_resp
      and   ipr_num_preg    = @i_num_preg

      if @@error <> 0 
      begin
         select @w_return = 1720632
         goto ERROR  
      end    
      /*Insercion data de auditoria*/
      INSERT INTO ts_indice_pob_respuesta
     (secuencial,   tipo_transaccion, clase,              fecha, 
      usuario,      terminal,         srv,                lsrv, 
      num_pregunta, num_respuesta,    respuesta,          score, 
      estado,       usuario_crea,     fecha_crea,         usuario_mod, 
      fecha_mod)                                          
     select                                               
      @s_ssn,       @t_trn,           'D',                getdate(), 
      @s_user,      @s_term,          @s_srv,             @s_lsrv, 
      @i_num_preg,  @i_num_resp,      ipr_respuesta,      ipr_score, 
      ipr_estado,   null,             null,               @s_user, 
      getdate()
      from cl_indice_pob_respuesta
      where ipr_num_preg    = @i_num_preg
      and   ipr_numero_resp = @i_num_resp
      if @@error <> 0 
      begin
         select @w_return = 1720036
         goto ERROR  
      end      
   end
end

if @i_operacion = 'D'
begin
   if @i_tipo = 'P'
   begin
      if not exists(select 1 from cl_indice_pob_preg where ipp_num_preg = @i_num_preg)
      begin
         select @w_return = 1720625
         goto ERROR
      end
      if exists(select 1
                from cobis.dbo.cl_det_ppi_ente 
                where dpe_num_preg = @i_num_preg
                )
      begin
         select @w_return = 1720641
         goto ERROR
      end
      if not exists(select 1 
                    from cl_indice_pob_respuesta 
                    where ipr_num_preg = @i_num_preg
                    and ipr_estado = 'V')
      begin
         /*Insercion data de auditoria*/
         INSERT INTO ts_indice_pob_preg
         (secuencial,   tipo_transaccion, clase,            fecha, 
          usuario,      terminal,         srv,              lsrv, 
          num_pregunta, pregunta,         descripcion,      estado, 
          usuario_crea, fecha_crea,       usuario_mod,      fecha_mod)
         select                                             
          @s_ssn,       @t_trn,           'E',              getdate(), 
          @s_user,      @s_term,          @s_srv,           @s_lsrv, 
          ipp_num_preg, ipp_pregunta,     ipp_descripcion,  ipp_estado, 
          null,         null,             @s_user,          getdate()
          from cl_indice_pob_preg
          where ipp_num_preg = @i_num_preg
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end      
         
         delete from cl_indice_pob_preg where ipp_num_preg = @i_num_preg
         if @@error <> 0 
         begin
            select @w_return = 1720633
            goto ERROR 
         end
         
      end
      else
      begin
         select @w_return = 1720636
         goto ERROR  
      end
   end
   else
   begin
      if exists(select 1
                from cobis.dbo.cl_det_ppi_ente 
                where dpe_numero_resp = @i_num_resp
                )
      begin
         select @w_return = 1720641
         goto ERROR
      end
      if exists(select 1 
                    from cl_indice_pob_respuesta 
                    where ipr_numero_resp = @i_num_resp
                    and   ipr_num_preg    = @i_num_preg)
      begin
         /*Insercion data de auditoria*/
         INSERT INTO ts_indice_pob_respuesta
         (secuencial,   tipo_transaccion, clase,              fecha, 
          usuario,      terminal,         srv,                lsrv, 
          num_pregunta, num_respuesta,    respuesta,          score, 
          estado,       usuario_crea,     fecha_crea,         usuario_mod, 
          fecha_mod)                                          
         select                                               
          @s_ssn,       @t_trn,           'E',                getdate(), 
          @s_user,      @s_term,          @s_srv,             @s_lsrv, 
          @i_num_preg,  @i_num_resp,      ipr_respuesta,      ipr_score, 
          ipr_estado,   null,             null,               @s_user, 
          getdate()
          from cl_indice_pob_respuesta
          where ipr_num_preg    = @i_num_preg
          and   ipr_numero_resp = @i_num_resp
         if @@error <> 0 
         begin
            select @w_return = 1720036
            goto ERROR  
         end      
         
         delete from cl_indice_pob_respuesta
         where ipr_num_preg    = @i_num_preg
         and   ipr_numero_resp = @i_num_resp
         if @@error <> 0 
         begin
            select @w_return = 1720634
            goto ERROR  
         end  
      end
      else
      begin
         select @w_return = 1720626
         goto ERROR  
      end
      
   end
end

if @i_operacion = 'Q'
begin
   if @i_tipo = 'P'
   begin
      select 'num_preg'    = ipp_num_preg,
             'pregunta'    = ipp_pregunta,
             'descripcion' = ipp_descripcion,
             'estado'      = ipp_estado
      from cl_indice_pob_preg
   end
   else if @i_tipo = 'R'
   begin
      select 'num_preg'    = ipr_num_preg,
             'num_resp'    = ipr_numero_resp,
             'respuesta'   = ipr_respuesta,
             'score'       = ipr_score,
             'estado'      = ipr_estado
      from cl_indice_pob_respuesta
      where ipr_num_preg = @i_num_preg
   end
   else if @i_tipo = 'H'
   begin
      if exists(select 1 from cl_cliente_grupo where cg_ente = @i_ente and cg_estado = 'V')
      begin
         select @w_grupo_nombre = convert(varchar, gr_grupo) + ' - ' + gr_nombre
         from cl_grupo,
              cl_cliente_grupo
         where cg_ente  = @i_ente
         and   cg_grupo = gr_grupo
         
         select 'grupo'              = @w_grupo_nombre,
                'fecha inicio'       = CONVERT(varchar, isnull(pe_fecha_ini, @w_fecha_proceso), 103),
                'fecha vencimiento'  = CONVERT(varchar, isnull(pe_fecha_fin, DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso)), 103)
         from cl_ppi_ente
         where pe_ente  = @i_ente
         union
         select 'grupo'              = @w_grupo_nombre,
                'fecha inicio'       = CONVERT(varchar,@w_fecha_proceso, 103),
                'fecha vencimiento'  = CONVERT(varchar,DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso), 103)
         where not exists(select 'grupo'              = @w_grupo_nombre,
                                 'fecha inicio'       = isnull(pe_fecha_ini, @w_fecha_proceso),
                                 'fecha vencimiento'  = isnull(pe_fecha_fin, DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso))
                          from cl_ppi_ente
                          where pe_ente  = @i_ente) 
      end
      else
      begin
         select 'grupo'              = '',
                'fecha inicio'       = CONVERT(varchar,isnull(pe_fecha_ini, @w_fecha_proceso), 103),
                'fecha vencimiento'  = CONVERT(varchar,isnull(pe_fecha_fin, DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso)),103)
         from cl_ppi_ente
         where pe_ente  = @i_ente
         union
         select 'grupo'              = '',
                'fecha inicio'       = CONVERT(varchar, @w_fecha_proceso, 103),
                'fecha vencimiento'  = CONVERT(varchar, DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso), 103)
         where not exists(select 'grupo'              = '',
                                 'fecha inicio'       = isnull(pe_fecha_ini, @w_fecha_proceso),
                                 'fecha vencimiento'  = isnull(pe_fecha_fin, DATEADD(MONTH, @w_param_fecha, @w_fecha_proceso))
                          from cl_ppi_ente
                          where pe_ente  = @i_ente)      

      end
   end
   else if @i_tipo = 'G'
   begin
      if (OBJECT_ID('tempdb.dbo.#cl_det_ppi','U')) is not null
      begin
         drop table #cl_det_ppi
      end  
      create table #cl_det_ppi(
      id                int              null,
      num_preg          int              null,
      pregunta          varchar(255)     null,
      num_resp          int              null,
      respuesta         varchar(255)     null,
      score             int              null,
      estadoRespuesta   catalogo         null,
      estado            catalogo         null
      )
      insert into #cl_det_ppi(id, num_preg, pregunta, estado)
      select ROW_NUMBER() OVER (ORDER BY ipp_num_preg ASC) AS No,     
             ipp_num_preg, 
             ipp_descripcion,
             ipp_estado
      from cobis.dbo.cl_indice_pob_preg ip
      where ipp_num_preg not in (select ipp_num_preg
                                 from cobis.dbo.cl_indice_pob_preg ip
                                 where ipp_num_preg not in (select DISTINCT dpe_num_preg 
                                                            from cobis.dbo.cl_det_ppi_ente
                                                            where dpe_ente = @i_ente)
                                 and ip.ipp_estado <> 'V')
      
      declare @resp      int, 
              @score     int, 
              @preg      int,
              @estado    catalogo,
              @resp_text varchar(255)
      declare cursor_detalle cursor read_only 
      for select dpe_num_preg, 
                 dpe_numero_resp,                
                 dpe_score,
                 cipr.ipr_respuesta 
      from cobis.dbo.cl_det_ppi_ente,
           cobis.dbo.cl_indice_pob_respuesta cipr 
      where dpe_ente = @i_ente
      and cipr.ipr_numero_resp  = dpe_numero_resp 
      
      open cursor_detalle
      fetch next from cursor_detalle into @preg, @resp, @score, @resp_text
      
      while @@fetch_status = 0
      begin   
        select @estado = ipr_estado
        from cl_indice_pob_respuesta
        where ipr_numero_resp = @resp
        update #cl_det_ppi
        set num_resp        = @resp,
            score           = @score,
            respuesta       = @resp_text,
            estadoRespuesta = @estado
        where num_preg = @preg
        if @@error <> 0 
        begin
           close cursor_detalle
           deallocate cursor_detalle
           return @@error
        end  
        fetch next from cursor_detalle into @preg, @resp, @score, @resp_text
      end
      close cursor_detalle
      deallocate cursor_detalle  
      select 'id' = id,
             'num_preg'         = num_preg,
             'preg'             = pregunta,
             'num_resp'         = convert(varchar, num_resp),
             'respuesta'        = isnull(respuesta, ''),
             'estadoRespuesta'  = isnull(estadoRespuesta, 'V'),
             'score'            = convert(varchar, isnull(score, 0)),
             'estado'           = estado
      from #cl_det_ppi
   end
   else if @i_tipo = 'S'
   begin
      select 'score'     = isnull(ipr_score, 0),
             'respuesta' = isnull(ipr_respuesta, ''),
             'estado'    = isnull(ipr_estado, 'V')
      from cl_indice_pob_respuesta
      where ipr_num_preg = @i_num_preg
      and   ipr_numero_resp = @i_num_resp
   end
   else if @i_tipo = 'A'
   begin
      select ipr_num_preg, ipr_numero_resp, ipr_respuesta, ipr_score
      from cobis..cl_indice_pob_respuesta p 
      where ipr_estado = 'V' 
      order by convert(varchar,ipr_numero_resp) asc
   end
end

select @w_sincroniza = pa_char
from cobis..cl_parametro
where pa_producto = 'CLI'
and pa_nemonico = 'HASIAU'

select @w_ofi_app = pa_smallint 
from cobis.dbo.cl_parametro cp 
where cp.pa_nemonico = 'OFIAPP'
and cp.pa_producto = 'CRE'

--Proceso de sincronizacion Clientes
if @i_operacion in ('I', 'U') and @i_tipo = 'G' and @i_ente is not null and @w_sincroniza = 'S' and @w_ofi_app <> @s_ofi
begin
   exec @w_return = cob_sincroniza..sp_sinc_arch_json
      @i_opcion     = 'I',
      @i_cliente    = @i_ente,
      @t_debug      = @t_debug
end

return 0

ERROR:
   exec sp_cerror
        @t_debug = @t_debug,
        @t_file  = @t_file,
        @t_from  = @w_sp_name,
        @i_num   = @w_return
      
      return @w_return
    
go
        