USE gaul_2013 
GO 

CREATE TABLE [dbo].[geometry_columns]( 
  [f_table_catalog] varchar(128) NOT NULL, 
  [f_table_schema] varchar(128) NOT NULL, 
  [f_table_name] varchar(256) NOT NULL, 
  [f_geometry_column] varchar(256) NOT NULL, 
  [coord_dimension] int NOT NULL, 
  [srid] int NOT NULL, 
  [geometry_type] varchar(30) NOT NULL 
  CONSTRAINT [PK_geometry_columns] PRIMARY KEY CLUSTERED 
([f_table_catalog] ASC, [f_table_schema] ASC, [f_table_name] ASC, [f_geometry_column] ASC) 
   ) 


CREATE TABLE [dbo].[spatial_ref_sys]( 
  [srid] int NOT NULL, 
  [auth_name] varchar(256) NULL, 
  [auth_srid] int NULL, 
  [srtext] varchar(2048) NULL, 
  [proj4text] varchar(2048) NULL, 
  CONSTRAINT [PK_spatial_ref_sys] PRIMARY KEY CLUSTERED 
([srid] ASC) 
   ) 


INSERT INTO [dbo].[spatial_ref_sys] 
           ([srid], [auth_name], [auth_srid], [srtext], [proj4text]) 
     VALUES 
           (32768 
           ,NULL 
           ,NULL 
           ,'PROJCS["unnamed",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9108"]],AUTHORITY["EPSG","4269"]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["standard_parallel_1",29.5],PARAMETER["standard_parallel_2",45.5],PARAMETER["latitude_of_center",23],PARAMETER["longitude_of_center",-96],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]]'
           ,'+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs') 


INSERT INTO [dbo].[geometry_columns] 
           ([f_table_catalog], [f_table_schema], [f_table_name], [f_geometry_column], [coord_dimension], [srid], [geometry_type]) 
     VALUES 
           ('DB_Deer', 'dbo', 'tblPts', 'SQL_Shape', 2, 32768, 'POINT') 
           