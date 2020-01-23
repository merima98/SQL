create database najnovija
go

use najnovija
go


--1
create table Proizvodi
(
ProizvodID int identity (1,1) constraint pk_ProizvodID  primary key,
Sifra nvarchar(10) not null  constraint uq_Sifra unique,
Naziv nvarchar(50) not null,
Cijena decimal not null
);
go


create table Skladiste 
(
SkladisteID int identity (1,1) not null constraint pk_SkladisteID primary key,
Naziv nvarchar(50) not null,
Oznaka nvarchar(10) not null  constraint uq_Oznaka  unique,
Lokacija nvarchar(50) not null
);
go

create table SkladistePorizvodi
(
ProizvodID int not null constraint fk_ProizvodID  foreign key references Proizvodi(ProizvodID),
SkladisteID int not null constraint fk_SkladisteID   foreign key references Skladiste(SkladisteID),
Stanje decimal not null
);
go

--2
insert into Skladiste(Naziv, Oznaka, Lokacija)
values ('Skladiste 1 ','Oznaka1','Lokacija1'),
       ('Skladiste 2 ','Oznaka2','Lokacija2'),
	   ('Skladiste 3 ','Oznaka3','Lokacija3')

select * from Proizvodi

insert  into Proizvodi(Sifra, Naziv, Cijena)
select TOP 10 P.ProductNumber, P.Name, P.ListPrice
from AdventureWorks2014.Production.Product as P
     inner join AdventureWorks2014.Production.ProductSubcategory as Ps
	 on Ps.ProductSubcategoryID=P.ProductSubcategoryID
	 inner join AdventureWorks2014.Production.ProductCategory as PC
	 on Ps.ProductCategoryID=PC.ProductCategoryID
where PC.Name = 'Bikes'
order by (select sum(sod.OrderQty) from AdventureWorks2014.Sales.SalesOrderDetail as sod) desc

insert into SkladistePorizvodi(ProizvodID, SkladisteID, Stanje)
select P.ProizvodID , 1, 100
from Proizvodi as P
go

insert into SkladistePorizvodi(ProizvodID, SkladisteID, Stanje)
select P.ProizvodID , 2, 100
from Proizvodi as P
go

insert into SkladistePorizvodi(ProizvodID, SkladisteID, Stanje)
select P.ProizvodID , 3, 100
from Proizvodi as P
go

--3
create procedure IzmjenaStanja
@Skladiste int,
@Proizvod int,
@Stanje decimal
as
begin
	update SkladistePorizvodi
	set Stanje+=@Stanje
	where ProizvodID=@Proizvod and SkladisteID=@Skladiste
end
go

exec IzmjenaStanja 1,9,15
go

--4

create nonclustered index SifraNaziv_incCijena
on Proizvodi(Sifra,Naziv)
include (Cijena)
go

select * 
from Proizvodi
where Naziv like '%Silver%'
go

alter index SifraNaziv_incCijena
on Proizvodi disable
go

--5

create view PrikazProizvoda
as
select P.Sifra[Sifra prizvoda], P.Naziv[Naziv  proizvoda], P.Cijena [Cijena proizvoda], s.Oznaka[Skladiste - oznaka], s.Naziv [Skladiste-naziv], s.Lokacija[Skladiste-lokacija], sp.Stanje[Skladiste-stanje]
     from Proizvodi as P 
	 inner join SkladistePorizvodi as sp
	 on sp.ProizvodID=P.ProizvodID
	 inner join Skladiste as s
	 on s.SkladisteID=sp.SkladisteID
go
select* from PrikazProizvoda
go

--6

create procedure StanjeSkladista_sifraProizvoda
@SifraP nvarchar(25)
as
begin
     select p.Sifra,p.Naziv,p.Cijena,SUM(sp.Stanje)[Ukupno stanje]
	 from Proizvodi as p
	 inner join SkladistePorizvodi as sp
	 on p.ProizvodID=sp.ProizvodID
	 where p.Sifra like  @SifraP and @SifraP is not  null
	 group by p.Sifra,p.Naziv,p.Cijena
end
go
select * from Proizvodi

exec StanjeSkladista_sifraProizvoda 'BK-M82S-38'
go

--7

create procedure UpisProizvoda
@Sifra nvarchar(20),
@Naziv nvarchar(50),
@Cijena decimal 
as
begin
     insert into Proizvodi(Sifra, Naziv, Cijena)
	 values (@Sifra,@Naziv,@Cijena)

	 insert into SkladistePorizvodi(ProizvodID, SkladisteID, Stanje)
	 values ((select ProizvodID from Proizvodi where @Naziv=Naziv),1,0),
	        ((select ProizvodID from Proizvodi where @Naziv=Naziv),2,0),
			((select ProizvodID from Proizvodi where @Naziv=Naziv),3,0)

end
go

exec UpisProizvoda 'A5-8569','Biciklo',152
go

--8

create procedure Brisanje
@Sifra nvarchar(25)
as
begin
     delete 
	 from SkladistePorizvodi
	 where ProizvodID in (select ProizvodID from Proizvodi where Sifra=@Sifra and @Sifra is not null)
	 

	 delete Proizvodi
	 where Sifra = @Sifra and @Sifra is not null

end
go


exec Brisanje 'A5-8569'
go

--9



create procedure PretragaPregleda
@Sifra nvarchar(20) = null,
@Oznaka nvarchar(30)=null,
@Lokacija nvarchar(20) = null
as

begin
     select * 
	 from PrikazProizvoda as prikaz
	 where (prikaz.[Sifra prizvoda] = @Sifra or @Sifra is null) and (prikaz.[Skladiste - oznaka]=@Oznaka or @Oznaka is null) and
	       (prikaz.[Skladiste-lokacija] = @Lokacija or @Lokacija is null)
end
go

exec PretragaPregleda   --niti jedan -> daje sve vrijednosti
go

exec PretragaPregleda  'BK-M68S-38'  --oznaka
go

exec PretragaPregleda  null, null,'Lokacija1'  --lokacija
go


exec PretragaPregleda  null, 'Oznaka1',null  --oznaka
go

exec PretragaPregleda  'BK-M68S-38', 'Oznaka1','Lokacija1'  --svi parametri  -> samo jedan podatak kao rezultat
go


--10

backup database najnovija
to disk ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\najnovija.bak'

backup database najnovija
to disk ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\najnovija.bak'
with differential