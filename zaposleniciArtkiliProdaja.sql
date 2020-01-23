create database _ib170160
go

use _ib170160
go

--1
create table Zaposelnici 
(
ZaposlenikID int not null constraint pkZaposlenikID primary key,
Ime nvarchar(30) not null,
Prezime nvarchar(30) not null,
Spol nvarchar(10)not null,
JMBG nvarchar(13) not null,
DatumRodjenja date default sysdatetime(),
Adresa nvarchar(100) not null,
Email nvarchar(100) not null constraint uqEmail unique,
KorisnickoIme nvarchar(60)not null,
Lozinka nvarchar(30)not null
);
go

create table Artikli
(
ArtikliID int not null constraint pk_ArtikliID primary key,
Naziv nvarchar(50)not null,
Cijena decimal not null,
StanjeNaSkladistu int not null
);
go

create table Prodaja 
(
ProdajaID int identity (1,1) not null constraint pk_ProdajaID primary key,
ZaposlenikID int not null constraint fk_ZaposlenikID foreign key references Zaposelnici(ZaposlenikID),
ArtikliID int not null constraint  fk_ArtikliID foreign key references Artikli(ArtikliID), 
Datum date default sysdatetime(),
Kolicina decimal not null
);
go


--u ovoj tabeli sam napravila spoljne kljuceve, ali sam takodjer postavila pk zaseban za ovu tabelu, jer nece dozvoliti prebacivanje podataka
--kako se zahtjevalo zadrzavanje identifikatora, to sam i uradila kod tabela Zaposlenici i Artikli


--2
insert into Zaposelnici(ZaposlenikID, Ime, Prezime, Spol, JMBG, DatumRodjenja, Adresa, Email, KorisnickoIme, Lozinka)
select E.EmployeeID, E.FirstName, E.LastName, IIF(E.TitleOfCourtesy='Mr.','M','Z'), CONCAT(DAY(E.BirthDate),MONTH(E.BirthDate),year(E.BirthDate)),
       E.BirthDate,
	   E.Country+', '+E.City+', '+ E.Address,
	   CONCAT(E.FirstName,'[', SUBSTRING(CONVERT(nvarchar,YEAR(E.BirthDate)),2,2),']@poslovna.ba'),
	   E.FirstName+'.'+E.LastName,
	   REVERSE(REPLACE(CONCAT(SUBSTRING(E.Notes,15,6),LEFT(E.Extension,2), DATEDIFF(day,E.BirthDate,E.HireDate)),' ','#'))
from NORTHWND.dbo.Employees as E
where (E.TitleOfCourtesy='Mrs.' or E.TitleOfCourtesy='Ms.'or E.TitleOfCourtesy='Mr.')and DATEDIFF(YEAR,E.BirthDate,GETDATE())>60
go


insert into Artikli(ArtikliID, Naziv, Cijena, StanjeNaSkladistu)
select distinct P.ProductID, P.ProductName, P.UnitPrice, P.UnitsInStock
from NORTHWND.dbo.Products as P
	 inner join NORTHWND.dbo.[Order Details] as OD
	 on OD.ProductID=P.ProductID
	 inner join NORTHWND.dbo.Orders as O
	 on O.OrderID=OD.OrderID
where YEAR(O.OrderDate)=1997 and(MONTH(O.OrderDate)=9 or MONTH(O.OrderDate)=8)
order by P.ProductName asc
go


insert into Prodaja( ZaposlenikID, ArtikliID, Datum, Kolicina)
select  distinct Z.ZaposlenikID, OD.ProductID, O.OrderDate,SUM( OD.Quantity)
from Zaposelnici as Z
     inner join NORTHWND.dbo.Orders as O 
	 on O.EmployeeID=Z.ZaposlenikID
	 inner join NORTHWND.dbo.[Order Details] as OD
	 on OD.OrderID=O.OrderID
where (MONTH(O.OrderDate)=8 or MONTH(O.OrderDate)=9) and YEAR(O.OrderDate)=1997
group by  O.OrderID,Z.ZaposlenikID, OD.ProductID, O.OrderDate
order by Z.ZaposlenikID  
go 
--99 zapisa

--3
alter table Artikli
add Kategorija nvarchar(50)
go

update Artikli
set Kategorija='Hrana'
where ArtikliID%3=0
go

update Artikli
set Kategorija=null
where ArtikliID%3!=0
go

update Zaposelnici
set DatumRodjenja = CONVERT(date, CONCAT( YEAR(DatumRodjenja)-2,'-', SUBSTRING(CONVERT(nvarchar,DatumRodjenja), 6,2) , '-',SUBSTRING(CONVERT(nvarchar,DatumRodjenja), 9,2)))
where Spol='Z'
go
--koristili smo ovo substring da bismo imali 08 a ne samo 8, npr ako je datum rodjenja 08.10.

--4
update Zaposelnici
set KorisnickoIme = Ime + '_['+SUBSTRING(CONVERT(nvarchar,YEAR(DatumRodjenja)),2,2)+']_'+Prezime
go

--5
select A.Naziv, A.StanjeNaSkladistu, P.Kolicina, P.Kolicina-A.StanjeNaSkladistu [Potrebno naruciti]
from Artikli as A
     inner join Prodaja as P 
	 on P.ArtikliID = A.ArtikliID
where P.Kolicina>A.StanjeNaSkladistu
go
--broj narucenih proizvoda kupimo iz tabele Prodaja

--6
select  Z.Ime+' ' +Z.Prezime [Ime i prezime],A.Naziv[Naziv proizvoda],isnull(A.Kategorija,'N/A') [Kategorija] ,SUM( P.Kolicina )[Ukupno prodata kolicina],sum( P.Kolicina*A.Cijena)[Ukupna zarada]
from Zaposelnici as Z
	inner join Prodaja as P
	on P.ZaposlenikID=Z.ZaposlenikID
	inner join Artikli as A
	on A.ArtikliID=P.ArtikliID
	inner join NORTHWND.dbo.Employees as E
	on Z.ZaposlenikID=E.EmployeeID
where E.Country='USA'
group by Z.Ime, Z.Prezime, A.Naziv, A.Kategorija
go
--67 zapisa.


--7
select  Z.Ime+' ' +Z.Prezime [Ime i prezime],P.Datum,A.Naziv[Naziv proizvoda],isnull(A.Kategorija,'N/A') [Kategorija] ,SUM( P.Kolicina )[Ukupno prodata kolicina],sum( P.Kolicina*A.Cijena)[Ukupna zarada]
from Zaposelnici as Z
	inner join Prodaja as P
	on P.ZaposlenikID=Z.ZaposlenikID
	inner join Artikli as A
	on A.ArtikliID=P.ArtikliID
where Z.Spol='Z' and (P.Datum > '1997-08-22' and P.Datum <'1997-09-22' ) and A.Naziv like '[CG]%' and A.Kategorija is null
group by Z.Ime, Z.Prezime, A.Naziv, A.Kategorija,P.Datum
go

--8
select Z.Ime+' ' +Z.Prezime[Ime i prezime], convert(varchar,Z.DatumRodjenja,104)[Datum rodjenja] , count(P.ZaposlenikID)[Prodaje]
from Zaposelnici as Z
     inner join Prodaja as P 
	 on P.ZaposlenikID=Z.ZaposlenikID
where MONTH(P.Datum)=8 and YEAR(P.Datum)=1997
group by Z.Ime, Z.Prezime, Z.DatumRodjenja
order by Prodaje desc
go


--9
alter table Prodaja nocheck constraint all
delete from Zaposelnici
where Adresa like '%London%'
alter table Prodaja check constraint all  --ovo ce na kraju ukinuti i povezanost tabele, ne znam kako da pobrisem a da ne ukidam povezanost tabela



