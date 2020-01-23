create database _Merima_IB170160
go

use _Merima_IB170160
go

--1

create table Proizvodi
(
ProizvodID int not null constraint pk_ProizvodID  primary key,
Sifra nvarchar(25) not null constraint uq_Sifra unique, 
Naziv nvarchar(50) not null ,
Kategorija nvarchar(50) not null ,
Cijena decimal not null
);
go

create table Narudzba
(
NarudzbaID int not null constraint pk_NarudzbaID  primary key,
BrojNarudzbe nvarchar(25) not null constraint uq_BrojNarudzbe  unique, 
Datum date not null,
Ukupno decimal not null
);
go

create table StavkeNarudzbe
(
ProizvodID int not null constraint fk_PorizvodID  foreign key references Proizvodi(ProizvodID),
NarudzbaID  int not null constraint fk_NarudzbaID  foreign key references Narudzba(NarudzbaID),
Kolicina int not null,
Cijena decimal not null,
Popust decimal not null,
Iznos decimal not null,
constraint pk_StavkeNarud primary key(ProizvodID,NarudzbaID)
);
go

--2

insert into Proizvodi(ProizvodID, Sifra, Naziv, Kategorija, Cijena)
select distinct P.ProductID, P.ProductNumber, P.Name,pc.ProductCategoryID, P.ListPrice
from AdventureWorks2014.Production.Product as P
     inner join AdventureWorks2014.Production.ProductSubcategory as ps
	 on	P.ProductSubcategoryID=ps.ProductSubcategoryID
	 inner join AdventureWorks2014.Production.ProductCategory as pc
	 on pc.ProductCategoryID=ps.ProductCategoryID
	 inner join AdventureWorks2014.Sales.SalesOrderDetail as sod
	 on sod.ProductID=P.ProductID
	 inner join AdventureWorks2014.Sales.SalesOrderHeader as soh
	 on soh.SalesOrderID=sod.SalesOrderID
where YEAR(soh.ShipDate)=2014



insert into Narudzba(NarudzbaID, BrojNarudzbe, Datum, Ukupno)
select distinct  soh.SalesOrderID, soh.SalesOrderNumber , soh.OrderDate, soh.TotalDue
from AdventureWorks2014.Sales.SalesOrderHeader as soh
where YEAR(soh.OrderDate)=2014
go

insert into StavkeNarudzbe(ProizvodID, NarudzbaID, Kolicina, Cijena, Popust, Iznos)
select distinct sod.ProductID, sod.SalesOrderID, sod.OrderQty, sod.UnitPrice, sod.UnitPriceDiscount, sod.LineTotal
from AdventureWorks2014.Sales.SalesOrderDetail as sod
     inner join AdventureWorks2014.Sales.SalesOrderHeader as soh
	 on soh.SalesOrderID=sod.SalesOrderID
where YEAR(soh.OrderDate)=2014
go

--3
create table Skladista 
(
SkladisteID int identity (1,1) not null constraint pk_SkladisteID primary key, 
Naziv nvarchar(30) not null
);
go
create table SkladistaProizvodi
(
SkladisteID int not null constraint fk_SkladisteID foreign key references Skladista(SkladisteID),
ProizvodID int not null constraint fk_ProizvodID foreign key references Proizvodi(ProizvodID),
Kolicina int not null,
constraint pk_SklaPro primary key (SkladisteID,ProizvodID)
);
go

--4

insert into Skladista(Naziv)
values ('Skladiste1'),
       ('Skladiste2'),
	   ('Skladiste3')

select * from SkladistaProizvodi

insert into SkladistaProizvodi(SkladisteID, ProizvodID, Kolicina)
select 1, ProizvodID , 0
from Proizvodi 
go 

insert into SkladistaProizvodi(SkladisteID, ProizvodID, Kolicina)
select 2, ProizvodID , 0
from Proizvodi 
go 

insert into SkladistaProizvodi(SkladisteID, ProizvodID, Kolicina)
select 3, ProizvodID , 0
from Proizvodi 
go 

--5

create procedure IzmjenaSkldista
@ProizvodID int null,
@Skladiste int null ,
@kolicina int null
as
begin
     update SkladistaProizvodi
	 set Kolicina+=@kolicina
	 where SkladisteID=@Skladiste and @ProizvodID=ProizvodID
end
go

exec IzmjenaSkldista 707,1,201
go

--6

create nonclustered index SifraNaziv
on Proizvodi(Sifra,Naziv)
go

select * from Proizvodi
go

--7
create trigger ZabranaBrisanja
on Proizvodi
instead of delete
as

begin 
print 'Zabranjeno brisanje! '
rollback transaction
end

delete from Proizvodi
where Naziv like '[L]%'

--8

create view PregledProizvoda
as
select p.Sifra[Sifra proizvoda], p.Naziv[Naziv proizvoda], p.Cijena[Cijena proizvoda],SUM( sn.Kolicina)[Ukupna prodaja], SUM(sn.Cijena)[Ukupna zarada]
from Proizvodi as P 
     inner join StavkeNarudzbe as sn
	 on sn.ProizvodID=P.ProizvodID
	 inner join Narudzba as n
	 on sn.NarudzbaID= n.NarudzbaID
group by p.Sifra, p.Naziv, p.Cijena
go

select * from PregledProizvoda
go

--9
create procedure UnosenjeSifre_proizvod
@sifra nvarchar(20) null
as
begin
     select [Ukupna prodaja],  [Ukupna zarada]
	 from PregledProizvoda
	 where [Sifra proizvoda]= @sifra

end
go

exec UnosenjeSifre_proizvod 'HL-U509-R'
go

--10
/*
11.	U svojoj bazi podataka kreirati novog korisnika za login student te mu dodijeliti odgovarajuću
 permisiju kako bi mogao izvršavati prethodno kreiranu proceduru.
*/
--prethodno je potrebno kreirati login 
create login Student101
with password='10245',
default_database = _Merima_IB170160

--kreiranje usera
create user Student_FIT for login Student101
go

grant execute on UnosenjeSifre_proizvod to  Student_FIT 
go

--prvo navodimo nad cim, pa tek onda usera navodimo...
backup database _Merima_IB170160
to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\_Merima_IB170160.bak'
go

backup database _Merima_IB170160
to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\_Merima_IB170160.bak'
with differential
go