/*************************************************************************/
/*   Archivo:              migra_custodia.sp                             */
/*   Stored procedure:     sp_migra_custodia                             */
/*   Base de datos:        cob_custodia                                  */
/*   Producto:             Garantias                                     */
/*   Disenado por:         TEAM SENTINEL PRIME                           */
/*   Fecha de escritura:   Marzo 2019                                    */
/*************************************************************************/
/*                                  IMPORTANTE                           */
/*   Esta aplicacion es parte de los paquetes bancarios propiedad        */
/*   de MACOSA S.A.                                                      */
/*   Su uso no autorizado queda expresamente prohibido asi como          */
/*   cualquier alteracion o agregado hecho por alguno de sus             */
/*   usuarios sin el debido consentimiento por escrito de MACOSA         */
/*   Este programa esta protegido por la ley de derechos de autor        */
/*   y por las  convenciones  internacionales de  propiedad inte-        */
/*   lectual.  Su uso no  autorizado dara  derecho a  MACOSA para        */
/*   obtener  ordenes de  secuestro o retencion y  para perseguir        */
/*   penalmente a los autores de cualquier infraccion.                   */
/*************************************************************************/
/*                             MODIFICACION                              */
/*    FECHA               AUTOR                     RAZON                */
/*    Marzo/2019          TEAM SENTINEL PRIME       emision inicial      */
/*                                                                       */
/*************************************************************************/

USE cob_custodia
go

IF OBJECT_ID('dbo.sp_migra_custodia') IS NOT NULL
    DROP PROCEDURE dbo.sp_migra_custodia
go
create procedure dbo.sp_migra_custodia as

--LPO CDIG Se comenta porque este sp no debe ser parte de la versi�n y porque  Cobis Language no soporta sentencias como checkpoint INICIO
/*
declare
	@tipo		 int,
	@tipo_varchar    varchar(64),
	@numero		 varchar(10),
	@oficina         int,
	@oficina_cont	 int,
	@ano 		 int,
	@dia_jul_sec 	 int,
	@cu_migrada 	 varchar(64),
	--@cu_migrada_int  int,
	@cu_migrada1 	 varchar(64),
	@oficina1	 varchar(3),
	@cu_custodia	 varchar(64),
	@cu_custodia_int int,
	@num_sec	 int,
	@status		 int,
	@fecha_ingreso	 datetime,
	@monto		 float,
	@saldo		 float,
	@moneda		 float,
	@descripcion	 varchar(80),
--ojo
	@poliza		 float,
	@poliza2	 varchar(30),
	@donde		 varchar(10),
	@posee		 varchar(1),
	@prox_inspec	 datetime,
	@cliente	 int,
	@nombre		 varchar(90),
	@status_cobis 	 varchar(1),
	@error		 varchar(200),
	@bloque		 int,
        @oficial	 int

	truncate table cu_custodia_mig
	truncate table cu_cliente_garantia_mig
	truncate table cu_errores_mig
	
	declare fcursor cursor for
	select tipo,numero,oficina,ano,dia_jul,num_sec,status,fecha_ingreso,monto,saldo,moneda,descripcion,
               poliza,donde,prox_inspecc,cliente 
        from garmaes
	open fcursor

	select @cu_migrada=''
	select @cu_migrada1=''
	select @bloque=0
	
        fetch fcursor into
	@tipo,@numero,@oficina,@ano,@dia_jul_sec,@num_sec,@status,@fecha_ingreso,@monto,@saldo,@moneda,
	@descripcion,@poliza,@donde,@prox_inspec,@cliente
 	
	while @@FETCH_STATUS != 2
	begin 
		if @bloque=3000
		begin
			--dump tran cob_custodia 
			--with no_log
			ALTER DATABASE cob_custodia SET RECOVERY SIMPLE;
			
			CHECKPOINT;
			
			DBCC SHRINKFILE ('LogicalNameOfLogFile', FileSizeInMegabytes);
			
			ALTER DATABASE cob_custodia SET RECOVERY FULL;

			select @bloque=0
		end

		select @cu_migrada=''		
		select @cu_migrada=right('00'+convert(varchar(2),@tipo),2) + @numero


		if @tipo=0
			goto error

		if @status=11 or @status=05 or @status=21
			goto error

		if @tipo in (05,29)
			select @tipo_varchar='2101'
		
		if @tipo in (06,07)
			select @tipo_varchar='2102'

		if @tipo in (08,09)
			select @tipo_varchar='2103'

		if @tipo in (10)
			select @tipo_varchar='2104'

		if @tipo in (11,12)
			select @tipo_varchar='2405'

		if @tipo in (31,32)
			select @tipo_varchar='120'

		if @tipo in (03,04)
			select @tipo_varchar='A16'

		if @tipo in (24,25)
			select @tipo_varchar='310'

		
		if @tipo in (22,23,27,28)
			select @tipo_varchar='340'

		if @tipo in (21)
			select @tipo_varchar='350'

		if @tipo in (01)
			select @tipo_varchar='370'
		
		if @tipo in (34)
			select @tipo_varchar='152'

		if @tipo in (35)
			select @tipo_varchar='151'
		
		if @tipo in (14)
			select @tipo_varchar='2112'

		if @tipo in (16,17)
		begin
			select @tipo_varchar='910'
		 	select @monto=0
			select @saldo=0
		end

		if @tipo in (13,15)
			select @tipo_varchar='920'

		if @tipo in (36)
			select @tipo_varchar='950'

		if @tipo in (18,19)
			select @tipo_varchar='960'
			



		if @poliza>0 
			select @posee='S'
	--	else
	--		select @posee='n'
		
		select @nombre =isnull(en_nomlar,' '),
		       @oficial=en_oficial
		from cobis..cl_ente 
	        where en_ente=@cliente
	--	select @cu_custodia=convert(varchar(3),@num_sec)+convert(varchar(4),@ano)+convert(varchar(4),@dia_jul_sec)	

		--verificaciones para hacer las homologaciones de los estado de sistema actual a cobis
		if @status=1 or @status=3 or @status=4 
		begin
				select @status_cobis='V'	
		end
		else
		begin		
			if @status=2
				select @status_cobis='C'	
			else
			begin
				if @status=0
					select @status_cobis='P'	
				else
					select @status_cobis='A'	
			end
		end
		if @moneda=0
		begin 
			select @monto=@monto/25000
			select @saldo=@saldo/25000
		end

		select @poliza2=convert(varchar(30),@poliza)

		if @oficina=40
	         	select @oficina_cont=50
		else
			select @oficina_cont=@oficina

                insert into cu_custodia_mig
		   (cu_filial,cu_migrada,cu_sucursal,cu_tipo,cu_custodia,cu_estado,cu_fecha_ingreso,
                    cu_valor_inicial,cu_valor_actual,cu_moneda,cu_descripcion,cu_poliza,cu_inspeccionar,
                    cu_ciudad_prenda,cu_posee_poliza,cu_fecha_reg,cu_fecha_prox_insp,cu_propietario,
                    cu_codigo_externo,cu_oficina,cu_oficina_contabiliza) 
		values
                   (1,@cu_migrada,@oficina,@tipo_varchar,1,@status_cobis,@fecha_ingreso,@monto,@saldo,
                    0,@descripcion,@poliza2,'S',@donde,@posee,@fecha_ingreso,@prox_inspec,@nombre,
		    'no existe',@oficina,@oficina_cont)
	
		insert into cu_cliente_garantia_mig 
	        (cg_filial,cg_migrada,cg_sucursal,cg_tipo_cust,cg_custodia,cg_ente,cg_principal,
		 cg_codigo_externo,cg_nombre,cg_oficial) 
		values(1,@cu_migrada,@oficina,@tipo_varchar,1,@cliente,'S',' ',@nombre,@oficial)
	

		goto siguiente

		error:
		   select @error='Error al insertar la garantia '+@cu_migrada+' porque corresponde al tipo de garantia no admitido ' + convert(varchar(6),@tipo)
	           insert into cu_errores_mig
		   values  (@cu_migrada,10,@error)
	
		siguiente:
		select @bloque=@bloque+1        	
		fetch fcursor into
		@tipo,@numero,@oficina,@ano,@dia_jul_sec,@num_sec,@status,@fecha_ingreso,@monto,@saldo,
		@moneda,@descripcion,@poliza,@donde,@prox_inspec,@cliente
 	
		select @cu_migrada1=@cu_migrada		
	end
	close fcursor
	deallocate fcursor

*/ --LPO CDIG Se comenta porque este sp no debe ser parte de la versi�n y porque  Cobis Language no soporta sentencias como checkpoint FIN

return 0
GO
