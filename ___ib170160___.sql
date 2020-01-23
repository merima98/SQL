create database __ib170160__
go

use __ib170160__
go

create table Zaposlenici
(
ZaposlenikID int not null constraint pk_ZaposlenikID  primary key,
Ime nvarchar(30) not null,
Prezime nvarchar(30) not null,
Spol nvarchar(10) not null,
JMBG nvarchar(13) not null,
DatumRodjenja date not null default sysdatetime(),
Adresa nvarchar(100) not null,
Emil nvarchar(100) not null constraint uqEmail unique, 
KorisnickoIme nvarchar(60) not null,
Lozinka nvarchar(30) not null
);
go

create table Artikli
(
ArtikalID int not null constraint pk_ArtikalID primary key,
Naziv nvarchar(50) not null,
Cijena decimal not null,
StanjeNaSkladistu int not null
);
go

create table Prodaja --dodali smo pk, jer necemo moci prebacivati podatke, a takodjer je dobro znati koja je po redu prodaja.
(
ProdajID int identity (1,1) not null constraint pk_ProdajID  primary key,
ZaposlenikID int not null constraint fk_ZaposlenikID  foreign key references Zaposlenici(ZaposlenikID),
ArtikalID int not null constraint fk_ArtikalID  foreign key references Artikli(ArtikalID),
Datum date not null default sysdatetime(),
Kolicina decimal not null
);
go

--2
insert into Zaposlenici(ZaposlenikID, Ime, Prezime, Spol, JMBG, DatumRodjenja, Adresa, Emil, KorisnickoIme, Lozinka)
select e.EmployeeID,e.FirstName,e.LastName,
       IIF(e.TitleOfCourtesy='Mr.','M','Z'),
	   CONCAT(CONVERT(nvarchar, day(e.BirthDate)), CONVERT(nvarchar, MONTH(e.BirthDate)),YEAR(e.BirthDate)),
	   e.BirthDate,
	  CONCAT( e.Country,', ',e.City+', ',e.Address), 
	   CONCAT(e.FirstName, '[', SUBSTRING(CONVERT(nvarchar, YEAR(e.BirthDate)),2,2), ']@poslovna.ba'),
	   e.FirstName+'.'+e.LastName,
	   REVERSE(REPLACE(CONCAT(SUBSTRING(e.Notes,15,6), LEFT(e.Extension,2),DATEDIFF(DAY,e.BirthDate, e.HireDate)),' ','#'))
from  NORTHWND.dbo.Employees as e
where (e.TitleOfCourtesy='Mr.' or e.TitleOfCourtesy='Mrs.' or e.TitleOfCourtesy='Ms.' )and DATEDIFF(YEAR, e.BirthDate,GETDATE())>60

select * from Artikli

insert into Artikli(ArtikalID, Naziv, Cijena, StanjeNaSkladistu)
select distinct P.ProductID,P.ProductName, P.UnitPrice,sum(P.UnitsInStock)
from NORTHWND.dbo.Products as P
     inner join NORTHWND.dbo.[Order Details] as od
	 on od.ProductID=od.ProductID
	 inner join NORTHWND.dbo.Orders as o
	 on o.OrderID=od.OrderID
where YEAR(o.OrderDate)=1997 and (MONTH(o.OrderDate)=8 or MONTH(o.OrderDate)=9)
group by P.ProductID,P.ProductName, P.UnitPrice
order by P.ProductName asc

insert into Prodaja(ZaposlenikID, ArtikalID, Datum, Kolicina)
select distinct z.ZaposlenikID, od.ProductID,o.OrderDate, od.Quantity
from NORTHWND.dbo.[Order Details] as od
     inner join NORTHWND.dbo.Orders as o
	 on o.OrderID=od.OrderID
	 inner join Zaposlenici as z
	 on z.ZaposlenikID=o.EmployeeID
where YEAR(o.OrderDate)=1997 and(MONTH(o.OrderDate)=8 or MONTH(o.OrderDate)=9)  
go
--nema sanse da ispadne onoliko podataka koliko je zadato u rjesenju...


--3
alter table Artikli
add Kategorija nvarchar(50) null
go

update Artikli
set Kategorija='Hrana'
where ArtikalID%3=0
go

--smanjivanje broja godina
update Zaposlenici
set DatumRodjenja=CONVERT(date,CONCAT(YEAR(DatumRodjenja)-2, SUBSTRING(CONVERT(nvarchar, DatumRodjenja), 6,2),right( CONVERT(nvarchar,DatumRodjenja),2)))
where Spol='Z'
go
--azuriranje korisnickog imena
update Zaposlenici
set KorisnickoIme= Ime+'_['+SUBSTRING(CONVERT(nvarchar, YEAR(DatumRodjenja)),2,2)+']_'+Prezime
go


--5
select a.Naziv, a.StanjeNaSkladistu,  p.Kolicina, p.Kolicina-a.StanjeNaSkladistu[Potrebno naruciti]
from Artikli as a
     inner join Prodaja as p
	 on p.ArtikalID=a.ArtikalID
where p.Kolicina > a.StanjeNaSkladistu

--6
select z.Ime+' ' + z.Prezime, a.Naziv, ISNULL(a.Kategorija,'N/A'),concat(sum( p.Kolicina),' kom')[Ukupno prodata kolicina], concat(sum(a.Cijena*p.Kolicina), ' KM')[Ukupna zarada]
from Zaposlenici as z
inner join Prodaja as p
on p.ZaposlenikID = z.ZaposlenikID
inner join Artikli as a
on p.ArtikalID=a.ArtikalID
where z.Adresa like '%USA%'
group by z.Ime, z.Prezime, a.Naziv, a.Kategorija


--7
select z.Ime+' ' + z.Prezime, a.Naziv, ISNULL(a.Kategorija,'N/A'),concat(sum( p.Kolicina),' kom')[Ukupno prodata kolicina], concat(sum(a.Cijena*p.Kolicina), ' KM')[Ukupna zarada]
from Zaposlenici as z
inner join Prodaja as p
on p.ZaposlenikID = z.ZaposlenikID
inner join Artikli as a
on p.ArtikalID=a.ArtikalID
where z.Spol='Z' and (p.Datum >'1997-09-22' and p.Datum >'1997-08-22') and a.Kategorija is null and a.Naziv like'[CG]%'
group by z.Ime, z.Prezime, a.Naziv, a.Kategorija


--8
select z.Ime+' ' +z.Prezime, CONVERT(nvarchar,z.DatumRodjenja,104),z.Spol, COUNT(p.ProdajID)[Ukupan broj prodaja]
from Zaposlenici as z
inner join Prodaja as p
on p.ZaposlenikID = z.ZaposlenikID
group by z.Ime,z.Prezime, CONVERT(nvarchar,z.DatumRodjenja,104),z.Spol
order by 4 desc

--9 brisanje zaposelnika iz lonodona
delete from Prodaja
where ZaposlenikID = (select ZaposlenikID from Zaposlenici where Adresa like '%London%' )
delete from Zaposlenici

delete Zaposlenici
where Adresa like '%London%' 

--sada cemo uraditi backup baze

backup database __ib170160__
to disk='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\__ib170160__.bak'
go

backup database __ib170160__
to disk='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\__ib170160__.bak'
with differential
go