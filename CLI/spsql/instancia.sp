/********************************************************************/
/*    NOMBRE LOGICO:        sp_instancia                            */
/*    NOMBRE FISICO:        instancia.sp                            */
/*    PRODUCTO:             CLIENTES                                */
/*    Disenado por:         RIGG                                    */
/*    Fecha de escritura:   30-Abr-2019                             */
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
/*   sitio, queda expresamente prohibido; sin el debido             */
/*   consentimiento por escrito, de parte de los representantes de  */
/*   COBISCORP TECHNOLOGIES S.L. El incumplimiento de lo dispuesto  */
/*   en el presente texto, causará violaciones relacionadas con la  */
/*   propiedad intelectual y la confidencialidad de la información  */
/*   tratada; y por lo tanto, derivará en acciones legales civiles  */
/*   y penales en contra del infractor según corresponda.”.         */
/********************************************************************/
/*                           PROPOSITO                              */
/*      Este stored procedure procesa:                              */
/*      insercion en cl_instancia                                   */
/*      borrado en cl_instancia                                     */
/*      query de instancia en funcion de su codigo unico            */
/*****************************************************************  */
/*                        MODIFICACIONES                            */
/*   FECHA          AUTOR    RAZON                                  */
/*   30/04/19       RIGG     Versiónn Inicial Te Creemos            */
/*   05/05/20       DGA      Ajuste borrado relaciones              */
/*   16/06/20       MBA      Estandarizacion sp y seguridades       */
/*   15/10/20       MBA      Uso de la variable @s_culture          */
/*   14/05/21       COB      Se agrega nueva validacion al eliminar */
/*   24/04/23       EBA      Se actualiza el estado civil del       */
/*                           conyugue cuando llega desde la app     */
/*   10/07/23       EBA      B850916 Se obtiene el valor Soltero    */
/*                           del catalogo estado civil              */
/*   09/09/23       BDU      R214440-Sincronizacion automatica      */
/*   22/01/24       BDU      R224055-Validar oficina app            */
/********************************************************************/

use cobis
go

set ANSI_NULLS off
GO
set QUOTED_IDENTIFIER off
GO

if exists (select * from sysobjects where name = 'sp_instancia')
        drop procedure sp_instancia
go
create procedure sp_instancia(
   @s_ssn          int         = null,
   @s_user         login       = null,
   @s_term         varchar(32) = null,
   @s_date         datetime    = null,
   @s_srv          varchar(30) = null,
   @s_lsrv         varchar(30) = null,
   @s_rol          smallint    = NULL,
   @s_ofi          smallint    = NULL,
   @s_org_err      char(1)     = NULL,
   @s_error        int         = NULL,
   @s_sev          tinyint     = NULL,
   @s_msg          descripcion = NULL,
   @s_org          char(1)     = NULL,
   @s_culture      varchar(10) = 'NEUTRAL',
   @t_trn          int         = NULL,
   @t_debug        char (1)    = 'N',
   @t_file         varchar(14) = null,
   @t_from         varchar(30) = null,
   @t_show_version bit         = 0,
   @i_operacion    char(1),            -- Opcion con que se ejecuta el programa
   @i_relacion     int         = null, -- Codigo de la relacion que es instancia
   @i_derecha      int         = null, -- Codigo del cliente que va a la derecha de la relacion
   @i_izquierda    int         = null, -- Codigo del cliente que va a la izquierda de la relacion
   @i_lado         char (1)    = null, -- Mensaje de la relacion que es aplicado
   @i_secuencial   int         = null,
   @i_is_app       char(1)     = 'N'
)
as
declare @w_sp_name                    varchar (30),
        @w_sp_msg                     varchar(132),
        @w_null                       int,
        @w_fecha_ini                  datetime,
        @w_ente_i                     int,
        @w_ente_d                     int,
        @w_relacion_ca                int, --Relacion de tipo Conyuge
        @w_estado_civil_i             varchar(10),
        @w_estado_civil_d             varchar(10),
        @w_grupo                      int,
        @w_relacion_pa                int, --Relacion de tipo Padre
        @w_relacion_hi                int, --Relacion de tipo Hijo
        @w_num                        int,
        @w_param                      int, 
        @w_diff                       int,
        @w_date                       datetime,
        @w_bloqueo                    char(1),
        @w_default_estado_civil       catalogo,
        -- R214440-Sincronizacion automatica
        @w_sincroniza      char(1),
        @w_error           int,
        @w_ofi_app         smallint


/* captura nombre de stored procedure  */
select @w_sp_name = 'sp_instancia'
select @w_sp_msg = ''

/*--VERSIONAMIENTO--*/
if @t_show_version = 1
begin
  select @w_sp_msg = CONCAT('Stored procedure ' , @w_sp_name)
  select @w_sp_msg = CONCAT(@w_sp_msg , ' Version 4.0.0.1')
  print  @w_sp_msg
  return 0
end
/*--FIN DE VERSIONAMIENTO--*/

---- EJECUTAR SP DE LA CULTURA ---------------------------------------
exec cobis..sp_ad_establece_cultura
@o_culture = @s_culture out

if @i_operacion in ('I', 'D')
begin
   /* VALIDACIONES LISTAS NEGRAS PARA EL CLIENTE */
   if @i_izquierda is not null and @i_izquierda <> 0
   begin
      select @w_bloqueo = en_estado from cobis..cl_ente where en_ente = @i_izquierda
      if @w_bloqueo = 'S'
      begin
         exec sp_cerror
         @t_debug  = @t_debug,
         @t_file   = @t_file,
         @t_from   = @w_sp_name,
         @i_num    = 1720604
         return 1720604
      end
   end 
end

select @w_relacion_ca = (select pa_tinyint from cobis..cl_parametro
                         where pa_nemonico = 'CONY' and pa_producto='CLI')

select @w_relacion_pa = (select pa_tinyint from cobis..cl_parametro
                         where pa_nemonico = 'PAD' and pa_producto='CLI')

select @w_relacion_hi = (select pa_tinyint from cobis..cl_parametro
                         where pa_nemonico = 'HIJ' and pa_producto='CLI')

if @i_lado = 'C'
begin

   if exists (select 1 from cobis..cl_instancia
              where  in_ente_i   = @i_izquierda
              and    in_ente_d   = @i_derecha
              and    in_relacion = @w_relacion_ca)
   begin
      goto VALIDATE_SINC
   end

   select @i_relacion = @w_relacion_ca,
          @i_lado     = 'I'

end

/*  Insert  */
if (@i_operacion ='I')
begin
   if (@t_trn = 172029)
   begin
      /* Verificar que no se relacione a si mismo */
      if(@i_derecha = @i_izquierda )
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720189
         return 1720189
      end

      /* Validar que la relacion sea con una persona fisica */
      if exists( select 1 from cl_ente where en_ente = @i_derecha and en_subtipo = 'C' )
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720190
         return 1720190
      end

      /* Verificar que existan los entes relacionados */
      select  @w_null = NULL
      from  cl_ente
      where  en_ente in (@i_derecha, @i_izquierda)
      if (@@rowcount <> 2)
      begin
         /*  No existe ente  */
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720191
         return 1
      end

      /* Verificar que exista la relacion generica */
      if (@i_relacion < 2 and @i_relacion > 6) /* SCA */
      begin
         select  @w_null = NULL
         from    cl_relacion
         where   re_relacion = @i_relacion
         if (@@rowcount <> 1)
         begin
            /*  No existe ente  */
            exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
                 @t_from = @w_sp_name,
                 @i_num  = 1720192
         return 1
      end
   end

   /* Verificar que no exista instancias duplicadas */
   select  @w_null     = NULL
   from   cl_instancia
   where  in_ente_i    = @i_izquierda
   and    in_ente_d    = @i_derecha
   and    in_relacion  = @i_relacion
   if (@@rowcount = 1)
   begin
      /*  Relacion entre entes ya existe  */
      exec cobis..sp_cerror
           @t_debug= @t_debug,
           @t_file = @t_file,
           @t_from = @w_sp_name,
           @i_num  = 1720193
      return 1
   end

   select @w_estado_civil_i = p_estado_civil FROM cobis..cl_ente WHERE en_ente = @i_izquierda
   select @w_estado_civil_d = p_estado_civil FROM cobis..cl_ente WHERE en_ente = @i_derecha

   if (@i_relacion = @w_relacion_ca) /* Es CONYUGE */
   begin

      if @w_estado_civil_i not in (select c.codigo
                                   from cl_catalogo c, cl_tabla t
                                   where t.tabla  = 'cl_ecivil_conyuge'
                                   and c.tabla = t.codigo)
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720526
         return 1720526
      end

      /* Verificar que no tenga una relacion CONY existente */
      if exists( select 1 from cl_instancia it
                 inner join cl_relacion re on re.re_relacion = it.in_relacion
                 where re.re_relacion = @i_relacion
                 and in_ente_i = @i_izquierda)
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720525
         return 1720525
      end

      if exists( select 1 from cl_instancia it
                 inner join cl_relacion re on re.re_relacion = it.in_relacion
                 where re.re_relacion = @i_relacion
                 and in_ente_d = @i_derecha)
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720195
         return 1720195
      end
   end /* Es CONYUGE */

   /* Verifica que el conyuge tenga estado civil casado*/
   if (@i_relacion = @w_relacion_ca)
   begin
    if (@w_estado_civil_i <> @w_estado_civil_d)
    begin
        select @w_default_estado_civil = codigo
        from cobis..cl_catalogo 
        where tabla = (select codigo from cl_tabla where tabla = 'cl_ecivil')
        and valor like 'SO%'
        
        if (@i_is_app = 'S' and @w_estado_civil_d = @w_default_estado_civil)
        begin
            update cobis..cl_ente
            set    p_estado_civil = @w_estado_civil_i
            where en_ente = @i_derecha
        end
        else
        begin
       /*  Por favor regularice el estado civil del Conyuge  */
           exec cobis..sp_cerror
                @t_debug= @t_debug,
                @t_file = @t_file,
                @t_from = @w_sp_name,
                @i_num  = 1720196
           return 1
        end
    end
   end

   /*  Insercion  */
   begin tran
      insert into cl_instancia (in_relacion, in_ente_i,           in_ente_d,
                                in_lado,     in_fecha)
                      values   (@i_relacion, @i_izquierda,        @i_derecha,
                                @i_lado,     @s_date/*getdate()*/)
      if (@@error <> 0)
      begin
         /*  Error en creacion de instancia de relacion  */
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720197
         return 1
      end
      /*  Insercion de la relacion reciproca  */
      /* Cambio de relacion HIJO a PADRE */
      if(@i_relacion = @w_relacion_hi) -- HIJO
      begin
         select @i_relacion = @w_relacion_pa
      end
      else if (@i_relacion = @w_relacion_pa) -- PADRE
      begin
         select @i_relacion = @w_relacion_hi
      end

      if (@i_lado = 'I')
      select @i_lado = 'D'
      else
      select @i_lado = 'I'

      insert into cl_instancia (in_relacion, in_ente_d,           in_ente_i,
                                in_lado,     in_fecha)
                        values (@i_relacion, @i_izquierda,        @i_derecha,
                                @i_lado,     @s_date/*getdate()*/)
      if (@@error <> 0)
      begin
         /*  Error en creacion de instancia de relacion  */
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720197
         return 1
      end
   commit tran
   goto VALIDATE_SINC
end
else
begin
   exec sp_cerror
        @t_debug      = @t_debug,
        @t_file       = @t_file,
        @t_from       = @w_sp_name,
        @i_num        = 1720075
        /*  'No corresponde codigo de transaccion' */
   return 1
end

end

/*  Delete  */
if (@i_operacion = 'D')
begin
if (@t_trn = 172030)
begin
   if exists (select 1 from cl_ente
              where en_ente = @i_izquierda
              and p_estado_civil = 'CA'
              or p_estado_civil= 'UN')
   begin
      if ((select pa_tinyint
           from cl_parametro
           where pa_nemonico = 'CONY'
           and pa_producto = 'CLI') = @i_relacion)
      begin
         exec cobis..sp_cerror
              @t_debug= @t_debug,
              @t_file = @t_file,
              @t_from = @w_sp_name,
              @i_num  = 1720510
         return 1720510
      end
   end

        select  @w_fecha_ini = in_fecha
        from    cl_instancia
        where   in_relacion  = @i_relacion
        and     in_ente_i    = @i_izquierda
        and     in_ente_d    = @i_derecha
        if (@@rowcount <> 1)
        begin
               /* exec cobis..sp_cerror
                        @t_debug= @t_debug,
                        @t_file = @t_file,
                        @t_from = @w_sp_name,
                        @i_num  = 101098*/
                    goto VALIDATE_SINC
                --return 101098
        end
        begin tran

                if not exists (select 1 from cl_instancia, cl_at_instancia
                                 where
                                 in_relacion  = @i_relacion
                                   and
                                    in_ente_i    = @i_izquierda
                                   and  in_ente_d    = @i_derecha
                                   and  ai_relacion  = in_relacion
                                   and  ai_ente_i    = in_ente_i
                                   and  ai_ente_d    = in_ente_d
                                   and  ai_secuencial <> @i_secuencial)
                begin
                        delete  cl_instancia
                         where
                         in_relacion  = @i_relacion
                           and
                            in_ente_i    = @i_izquierda
                           and  in_ente_d    = @i_derecha
                        if (@@error <> 0)
                        begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                        end

                        insert into cl_his_relacion (hr_secuencial,hr_relacion, hr_ente_i, hr_ente_d,
                                                     hr_fecha_ini, hr_fecha_fin)
                                        values      (@s_ssn, @i_relacion, @i_izquierda, @i_derecha,
                                                     @w_fecha_ini, @s_date)
                        if (@@error <> 0)
                        begin
                                exec cobis..sp_cerror
                                        @t_debug= @t_debug,
                                        @t_file = @t_file,
                                        @t_from = @w_sp_name,
                                        @i_num  = 1720199
                                        return 1720199
                        end
                        delete  cl_instancia
                         where  in_ente_i = @i_derecha
                           and  in_ente_d = @i_izquierda
                           and  in_relacion = @i_relacion
                       if (@@error <> 0)
                       begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720200
                          return 1720200
                        end

                        if (@@error = 0)
                        begin
                                insert into cl_his_relacion (hr_secuencial, hr_relacion,
                                                     hr_ente_i, hr_ente_d,
                                                     hr_fecha_ini, hr_fecha_fin)
                                        values      (@s_ssn, @i_relacion,
                                                     @i_derecha, @i_izquierda,
                                                     @w_fecha_ini, @s_date)
                                if (@@error <> 0)
                                begin
                                        exec cobis..sp_cerror
                                                @t_debug= @t_debug,
                                                @t_file = @t_file,
                                                @t_from = @w_sp_name,
                                                @i_num  = 1720201
                                        return 1720201
                                end
                        end

                end /*if not exists */
                else
                begin /* Si existe */
                      delete  cl_instancia
                       where
                       in_relacion  = @i_relacion
                        and
                         in_ente_i    = @i_izquierda
                        and  in_ente_d    = @i_derecha
                      if (@@error <> 0)
                      begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720202
                          return 1720202
                      end

                      insert into cl_his_relacion (hr_secuencial,hr_relacion, hr_ente_i, hr_ente_d,
                                                   hr_fecha_ini, hr_fecha_fin)
                                      values      (@s_ssn, @i_relacion, @i_izquierda, @i_derecha,
                                                   @w_fecha_ini, @s_date)
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720203
                         return 1720203
                      end
                      delete  cl_instancia
                       where  in_ente_i = @i_derecha
                        and  in_ente_d = @i_izquierda
                        and  in_relacion = @i_relacion
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                      end

                      if (@@error = 0)
                      begin
                             insert into cl_his_relacion (hr_secuencial, hr_relacion,
                                                  hr_ente_i, hr_ente_d,
                                                hr_fecha_ini, hr_fecha_fin)
                                     values      (@s_ssn, @i_relacion,
                                                  @i_derecha, @i_izquierda,
                                                  @w_fecha_ini, @s_date)
                            if (@@error <> 0)
                            begin
                               exec cobis..sp_cerror
                                  @t_debug= @t_debug,
                                  @t_file = @t_file,
                                  @t_from = @w_sp_name,
                                  @i_num  = 1720197
                               return 1720197
                            end
                      end

               /* borrar atributos asociados */
                if (@i_secuencial is null)
                begin
                       Delete cl_at_instancia
                        where
                        ai_relacion = @i_relacion
                          and
                          ai_ente_i   = @i_izquierda
                          and ai_ente_d   = @i_derecha
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1720204
                      end
                end
                else
                begin
                       Delete cl_at_instancia
                        where
                        ai_relacion = @i_relacion
                          and
                          ai_ente_i   = @i_izquierda
                          and ai_ente_d   = @i_derecha
                          and ai_secuencial = @i_secuencial
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1720204
                      end

                end

               /* borrar atributos asociados (Reciproco) */
                if (@i_secuencial is null)
                begin
                       Delete cl_at_instancia
                        where
                        ai_relacion = @i_relacion
                          and
                          ai_ente_i   = @i_derecha
                          and ai_ente_d   = @i_izquierda
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1
                      end
                end
                else
                begin
                       Delete cl_at_instancia
                        where
                        ai_relacion = @i_relacion
                          and
                          ai_ente_i   = @i_derecha
                          and ai_ente_d   = @i_izquierda
                          and ai_secuencial = @i_secuencial
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1
                      end

                end
             end /* Fin Si existe */

        commit tran
        
        goto VALIDATE_SINC
end
else
begin
        exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
           @t_from       = @w_sp_name,
           @i_num        = 1720075

        return 1
end

end


--Eliminar todas las relaciones

if (@i_operacion = 'A')
begin
if (@t_trn = 172030)
begin
        select  @w_fecha_ini = in_fecha
          from  cl_instancia
         where  in_ente_i    = @i_izquierda

        if (@@rowcount < 1)
        begin
               /* exec cobis..sp_cerror
                        @t_debug= @t_debug,
                        @t_file = @t_file,
                        @t_from = @w_sp_name,
                        @i_num  = 101098*/
                    goto VALIDATE_SINC
                --return 101098
        end
        begin tran

                if not exists (select 1 from cl_instancia, cl_at_instancia
                                 where  in_ente_i    = @i_izquierda
                                   and  ai_relacion  = in_relacion
                                   and  ai_ente_i    = in_ente_i
                                   and  ai_ente_d    = in_ente_d
                                   and  ai_secuencial <> @i_secuencial)
                begin
                        /* Extraigo grupo para eliminacion */
                        select @w_grupo = cg_grupo from cobis..cl_cliente_grupo where cg_ente = @i_izquierda and cg_estado <> 'C'

                        delete  cl_instancia
                        where  in_ente_i    = @i_izquierda
                        AND    in_ente_d in (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @w_grupo)


                        if (@@error <> 0)
                        begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                        end

                        /* Historico de Relaciones
                        insert into cl_his_relacion (hr_secuencial,hr_relacion, hr_ente_i, hr_ente_d,
                                                     hr_fecha_ini, hr_fecha_fin)
                                        values      (@s_ssn, @i_relacion, @i_izquierda, @i_derecha,
                                                     @w_fecha_ini, @s_date)
                        if @@error <> 0
                        begin
                                exec cobis..sp_cerror
                                        @t_debug= @t_debug,
                                        @t_file = @t_file,
                                        @t_from = @w_sp_name,
                                        @i_num  = 103062
                                return 103062
                        end*/

                        delete  cl_instancia
                         where  in_ente_d = @i_izquierda
                         and    in_ente_i in (select cg_ente from cobis..cl_cliente_grupo where cg_grupo = @w_grupo)

                       if (@@error <> 0)
                       begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                        end

                        /* Historico de Relaciones
                        if @@error = 0
                        begin
                                insert into cl_his_relacion (hr_secuencial, hr_relacion,
                                                     hr_ente_i, hr_ente_d,
                                                     hr_fecha_ini, hr_fecha_fin)
                                        values      (@s_ssn, @i_relacion,
                                                     @i_derecha, @i_izquierda,
                                                     @w_fecha_ini, @s_date)
                                if @@error <> 0
                                begin
                                        exec cobis..sp_cerror
                                                @t_debug= @t_debug,
                                                @t_file = @t_file,
                                                @t_from = @w_sp_name,
                                                @i_num  = 103061
                                        return 103061
                                end
                        end*/

                end /*if not exists */
                else
                begin /* Si existe */
                      delete  cl_instancia
                       where in_ente_i    = @i_izquierda

                      if (@@error <> 0)
                      begin
                          exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                      end

                      /* Historico de Relaciones
                      insert into cl_his_relacion (hr_secuencial,hr_relacion, hr_ente_i, hr_ente_d,
                                           hr_fecha_ini, hr_fecha_fin)
                                      values      (@s_ssn, @i_relacion, @i_izquierda, @i_derecha,
                                                   @w_fecha_ini, @s_date)
                      if @@error <> 0
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 103062
                         return 103062
                      end*/

                      delete  cl_instancia
                       where  in_ente_d = @i_izquierda

                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                          @t_debug= @t_debug,
                          @t_file = @t_file,
                          @t_from = @w_sp_name,
                          @i_num  = 1720198
                          return 1720198
                      end

                      /* Historico de Relaciones
                      if @@error = 0
                      begin
                             insert into cl_his_relacion (hr_secuencial, hr_relacion,
                                                  hr_ente_i, hr_ente_d,
                                                  hr_fecha_ini, hr_fecha_fin)
                                     values      (@s_ssn, @i_relacion,
                                                  @i_derecha, @i_izquierda,
                                                  @w_fecha_ini, @s_date)
                            if @@error <> 0
                            begin
                               exec cobis..sp_cerror
                                  @t_debug= @t_debug,
                                  @t_file = @t_file,
                                  @t_from = @w_sp_name,
                                  @i_num  = 103061
                               return 103061
                            end
                      end*/

               /* borrar atributos asociados */
                if (@i_secuencial is null)
                begin
                       Delete cl_at_instancia
                        where ai_ente_i   = @i_izquierda

                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1720204
                      end
                end
                else
                begin
                       Delete cl_at_instancia
                        where ai_ente_i   = @i_izquierda
                          and ai_secuencial = @i_secuencial
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1720204
                      end

                end

               /* borrar atributos asociados (Reciproco) */
                if (@i_secuencial is null)
                begin
                       Delete cl_at_instancia
                        where ai_ente_d   = @i_izquierda

                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1
                      end
                end
                else
                begin
                       Delete cl_at_instancia
                        where ai_ente_d   = @i_izquierda
                          and ai_secuencial = @i_secuencial
                      if (@@error <> 0)
                      begin
                         exec cobis..sp_cerror
                            @t_debug= @t_debug,
                            @t_file = @t_file,
                            @t_from = @w_sp_name,
                            @i_num  = 1720204
                         return 1
                      end

                end
             end /* Fin Si existe */

        commit tran
        goto VALIDATE_SINC

end
else
begin
        exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
           @t_from       = @w_sp_name,
           @i_num        = 1720075

        return 1
end

end




/*  Query  */
if (@i_operacion = 'Q')
begin

if (@t_trn = 172028)
begin

        select  in_relacion,
                re_izquierda,
                re_derecha,
                in_ente_i,
                concat(x.en_nombre, ' ', x.p_p_apellido),
                in_ente_d,
                concat(y.en_nombre, ' ', y.p_p_apellido)
                in_lado
          from  cl_instancia,
                cl_relacion,
                cl_ente x,
                cl_ente y
         where  in_relacion = @i_relacion
           and  in_ente_i   = @i_izquierda
           and  in_ente_d   = @i_derecha
           and  re_relacion = in_relacion
           and  x.en_ente   = in_ente_i
           and  y.en_ente   = in_ente_d

       if (@@rowcount <> 1)
       begin
         /*  No existe instancia de relacion  */
         exec cobis..sp_cerror
                 @t_debug= @t_debug,
                 @t_file = @t_file,
                 @t_from = @w_sp_name,
                 @i_num  = 1720205
         return 1
       end

      goto VALIDATE_SINC

end
else
begin
        exec sp_cerror
           @t_debug      = @t_debug,
           @t_file       = @t_file,
           @t_from       = @w_sp_name,
           @i_num        = 1720075,
           @s_culture    = @s_culture
           /*  'No corresponde codigo de transaccion' */
        return 1
end

VALIDATE_SINC:
begin
   select @w_sincroniza = pa_char
   from cobis..cl_parametro
   where pa_producto = 'CLI'
   and pa_nemonico = 'HASIAU'
   
   select @w_ofi_app = pa_smallint 
   from cobis.dbo.cl_parametro cp 
   where cp.pa_nemonico = 'OFIAPP'
   and cp.pa_producto = 'CRE'
   
   --Proceso de sincronizacion Clientes
   if @i_relacion = @w_relacion_ca and @i_izquierda is not null  --sincroniza casado
   and @w_sincroniza = 'S'
   and @w_ofi_app <> @s_ofi
   begin
      exec @w_error = cob_sincroniza..sp_sinc_arch_json
         @i_opcion     = 'I',
         @i_cliente    = @i_izquierda,
      @t_debug         = @t_debug
   end
   return 0
end

end
go

