/************************************************************************/
/*  Archivo:                var_experiencia_crediticia.sp               */
/*  Stored procedure:       sp_var_experiencia_crediticia               */
/*  Base de Datos:          cob_credito                                 */
/*  Producto:               Credito                                     */
/*  Disenado por:           Jose Ortiz                                  */
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
/*  23/04/19          Jose Ortiz       Emision Inicial                  */
/* **********************************************************************/
use cob_credito
go

if exists (select 1 from sysobjects where name = 'sp_var_experiencia_crediticia' and type = 'P')
   drop proc sp_var_experiencia_crediticia
go


create proc sp_var_experiencia_crediticia(
	@t_debug       		char(1)        = 'N',
	@t_from        		varchar(30)    = null,
	@s_ssn              INT            = null,
	@s_user             varchar(30)    = null,
	@s_sesn             INT            = null,
	@s_term             varchar(30)    = null,
	@s_date             DATETIME       = null,
	@s_srv              varchar(30)    = null,
	@s_lsrv             varchar(30)    = null,
	@s_ofi              SMALLINT       = null,
	@t_file             varchar(14)    = null,
	@s_rol              smallint       = null,
	@s_org_err          char(1)        = null,
	@s_error            int            = null,
	@s_sev              tinyint        = null,
	@s_msg              descripcion    = null,
	@s_org              char(1)        = null,
	@s_culture         	varchar(10)    = 'NEUTRAL',
	@t_rty              char(1)        = null,
	@t_trn				int            = null,
	@t_show_version     BIT            = 0,
    @i_id_cliente    	int            ,--codigo del cliente,
    @o_resultado    	VARCHAR(2)      out

    
)
as
declare	@w_sp_name 				       varchar(64),
		@w_error				       int,
		@w_secuencial                  INT,
        @w_fecha_apertura_cuenta       DATETIME ,
        @w_fecha_consulta              DATETIME,
        @w_num_dias                    INT,
        @w_cad                         varchar(30),
        @w_fecha_cierre_cuenta_c_c   DATETIME ,
        @w_fecha_consulta_c_c          DATETIME,
        @w_num_dias_c_c                INT,
        @w_cad_c_c                     varchar(30),
        @w_param_cc_abiertas           INT ,
        @w_param_cc_cerradas           INT
		
select @w_sp_name 	= 'sp_var_experiencia_crediticia'

 
	if @i_id_cliente is null
	begin
		select @w_error = 2109003 
		exec   @w_error  = cobis..sp_cerror
			   @t_debug  = 'N',
			   @t_file   = '',
			   @t_from   = @w_sp_name,
			   @i_num    = @w_error
		return @w_error
	
	end

SELECT @o_resultado='N'

select @w_param_cc_abiertas = pa_int 
  from cobis..cl_parametro
 where pa_nemonico = 'NDCCAB'
 
 if @w_param_cc_abiertas is null
	begin
		select @w_error = 2109004 
		exec   @w_error  = cobis..sp_cerror
			   @t_debug  = 'N',
			   @t_file   = '',
			   @t_from   = @w_sp_name,
			   @i_num    = @w_error
		return @w_error
	
	end
 
 select @w_param_cc_cerradas = pa_int 
  from cobis..cl_parametro
 where pa_nemonico = 'NDCCCE'
 
 if @w_param_cc_cerradas is null
	begin
		select @w_error = 2109005 
		exec   @w_error  = cobis..sp_cerror
			   @t_debug  = 'N',
			   @t_file   = '',
			   @t_from   = @w_sp_name,
			   @i_num    = @w_error
		return @w_error
	
	end
--declaro tabla que almacena las cuentas abiertas del cliente
declare @w_cuentas_abiertas			table(secuencial_c_a INT IDENTITY ,
                                          ib_fecha_c_a DATETIME  ,   
                                          bc_fecha_apertura_cuenta_c_a varchar(8)  ,
                                          bc_id_cliente_c_a INT  )
                                          

                                          

insert into @w_cuentas_abiertas
select DISTINCT ib_fecha ,bc_fecha_apertura_cuenta ,bc_id_cliente
from cob_credito..cr_buro_cuenta,cob_credito..cr_interface_buro
where bc_id_cliente=ib_cliente
and bc_fecha_cierre_cuenta is  null 
and bc_nombre_otorgante not in ( select c.valor from
                                 cobis..cl_tabla t,cobis..cl_catalogo c
                                 where  t.tabla  = 'cr_tipo_negocio'
                                 and t.codigo = c.tabla
                                 )
and bc_id_cliente=@i_id_cliente 


--select * from @w_cuentas_abiertas


select @w_secuencial= 0
  while 1=1
  begin
  
    select top 1 @w_secuencial=secuencial_c_a 
     from @w_cuentas_abiertas
     where secuencial_c_a  > @w_secuencial 
     order by secuencial_c_a asc
    IF @@ROWCOUNT = 0
    BREAK
  
  --Encuentro la fecha de consulta de buro
    select top 1 @w_fecha_consulta=ib_fecha_c_a 
     from @w_cuentas_abiertas
     where secuencial_c_a = @w_secuencial 
   
  --Cadena para convertir fecha de apertura en DateTime
    select top 1 @w_cad=bc_fecha_apertura_cuenta_c_a
     from @w_cuentas_abiertas
     where secuencial_c_a = @w_secuencial 
   
    select @w_cad = substring(@w_cad, 1, 2) + '/' + substring(@w_cad, 3, 2) + '/' + substring(@w_cad, 5, 4)
    
    PRINT'Cad fecha apertura' + convert(VARCHAR(50),@w_cad)
   -- select @w_cad
  
    select @w_fecha_apertura_cuenta=Convert (DATETIME,@w_cad,103)
  
    --select @w_fecha_apertura_cuenta
  
     PRINT'Fecha_apertura_cuenta' + convert(varchar(50),@w_fecha_apertura_cuenta)
     PRINT'Fecha_consulta' + convert(varchar(50),@w_fecha_consulta)
   
    select @w_num_dias=datediff(dd,@w_fecha_apertura_cuenta, @w_fecha_consulta)
   
     PRINT'Num dias cuentas Abiertas' + convert(varchar(50), @w_num_dias)
   
   
    if(@w_num_dias>@w_param_cc_abiertas)
      begin
      
      select @o_resultado='S'

       return 0
       
      end
  
  end--fin while cuentas abiertas
  
  PRINT'Resultado cuentas abiertas'+ convert(VARCHAR(50),@o_resultado)
  
  --Declaro tabla temporal para la cuentas cerradas de un cliente.
  declare @w_cuentas_cerradas				table(secuencial_c_c INT IDENTITY ,
                                            ib_fecha_c_c DATETIME  ,   
                                            bc_fecha_cierre_cuenta_c_c varchar(8)  ,
                                            bc_id_cliente_c_c INT )  
                                            
  ---Inserto la cuentas cerradas del cliente
  insert into @w_cuentas_cerradas
  select DISTINCT ib_fecha ,bc_fecha_cierre_cuenta ,bc_id_cliente
    from cob_credito..cr_buro_cuenta,cob_credito..cr_interface_buro
    where bc_id_cliente=ib_cliente
    and bc_fecha_cierre_cuenta is not null 
    and bc_nombre_otorgante not in ( select c.valor from
                                      cobis..cl_tabla t,cobis..cl_catalogo c
                                      where  t.tabla  = 'cr_tipo_negocio'
                                      and t.codigo = c.tabla
                                   )
  and bc_id_cliente=@i_id_cliente 
  
  --imprimo cuentas cerradas
  --select * from @w_cuentas_cerradas
  
  
  select @w_secuencial= 0
   while 1=1
     begin
     
       select top 1 @w_secuencial=secuencial_c_c 
        from @w_cuentas_cerradas
        where secuencial_c_c  > @w_secuencial 
        order by secuencial_c_c asc
       IF @@ROWCOUNT = 0
       BREAK
     
       --Encuentro la fecha de consulta de buro
       select top 1 @w_fecha_consulta_c_c=ib_fecha_c_c 
        from @w_cuentas_cerradas
        where secuencial_c_c = @w_secuencial 
        
       --Cadena para convertir fecha de cierre en DateTime
       select top 1 @w_cad_c_c=bc_fecha_cierre_cuenta_c_c
        from @w_cuentas_cerradas
        where secuencial_c_c = @w_secuencial 

      
       select @w_cad_c_c = substring(@w_cad_c_c, 1, 2) + '/' + substring(@w_cad_c_c, 3, 2) + '/' + substring(@w_cad_c_c, 5, 4)
        
        PRINT'Cad Fecha Cierre' + convert(varchar(50),@w_cad_c_c)
        
       --select @w_cad_c_c
     
       select  @w_fecha_cierre_cuenta_c_c=Convert (DATETIME,@w_cad_c_c,103)
     
       --select  @w_fecha_cierre_cuenta_c_c
     
        PRINT' Fecha_cierre_cuenta cerradas' + convert(VARCHAR(50), @w_fecha_cierre_cuenta_c_c)
        PRINT'Fecha_consulta cuentas cerradas' + convert(VARCHAR(50),@w_fecha_consulta_c_c)
      
       select @w_num_dias_c_c=datediff(dd, @w_fecha_cierre_cuenta_c_c, @w_fecha_consulta_c_c)
      
        PRINT'Num dias cuentas Cerradas' + convert(VARCHAR(50), @w_num_dias_c_c)
      
      
        IF(@w_num_dias_c_c<@w_param_cc_cerradas)
         begin
         
          select @o_resultado='S'

          return 0
        
         end
     
     end--Fin while cuentas cerradas

   PRINT'RESULTADO EXPERIENCIA CREDITICIA'+ convert(VARCHAR(50),@o_resultado)

if @t_debug = 'S'
begin
	print '@w_resultado: ' + convert(varchar, @o_resultado )	
end
	
if @o_resultado is null
begin
	select @w_error = 6904007 --No existieron resultados asociados a la operacion indicada   
	exec   @w_error  = cobis..sp_cerror
			@t_debug  = 'N',
			@t_file   = '',
			@t_from   = @w_sp_name,
			@i_num    = @w_error
	return @w_error
end
return 0

GO
