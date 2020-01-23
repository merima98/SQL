create database novaBaza2
go

use novaBaza2
go
--1
create table Klijent
(
KlijentID int identity (1,1) not null constraint pk_KlijentID primary key,
JMBG nvarchar(13)not null constraint uq_JMBG unique,
Ime nvarchar(30) not null ,
Prezime nvarchar(30) not null ,
Adresa nvarchar(100)not null,
Telefon nvarchar(20) not null,
Email nvarchar(50) null constraint uq_Email unique,
Kompanija nvarchar(50) null,
);
go

create table Kredit
(
KreditID int not null identity (1,1) constraint pk_KreditID primary key,
Datum date not null,
Namjena nvarchar(50) not null,
Iznos decimal not null,
BrojRata int not null,
Osiguran bit not  null,
Opis nvarchar(max),
KlijentID int not null constraint fk_KlijentID foreign key references Klijent(KlijentID)
);
go

create table Otplate
(
OtplataID int not null identity(1,1) constraint pk_OtplataID  primary key,
Datum date not null,
Iznos decimal not null,
Rata int not null,
Opis nvarchar(max),
KreditID int not null constraint fk_KreditID foreign key references Kredit(KreditID) 
);
go

--2
insert into Klijent(JMBG, Ime, Prezime,	Adresa, Telefon,Email,Kompanija)
select top 10 REPLACE(RIGHT(C.rowguid,13),'-','1'),p	.FirstName, 
		      P.LastName, adresa.AddressLine1, phone.PhoneNumber,email.EmailAddress , 'FIT' 
from AdventureWorks2014.Sales.Customer as C
     inner join AdventureWorks2014.Person.Person as P
	 on P.BusinessEntityID = C.PersonID
	 inner join AdventureWorks2014.Person.BusinessEntityAddress as bea
	 on C.PersonID=bea.BusinessEntityID
	 inner join AdventureWorks2014.Person.Address as adresa
	 on bea.AddressID=adresa.AddressID
	 inner join AdventureWorks2014.Person.PersonPhone as phone
	 on phone.BusinessEntityID=P.BusinessEntityID
	 inner join AdventureWorks2014.Person.EmailAddress as email
	 on email.BusinessEntityID=P.BusinessEntityID
go


insert into Kredit(Datum, Namjena, Iznos, BrojRata, Osiguran, Opis,KlijentID)
values (sysdatetime(),'Namjena1',20003.50,24,1,'Kratak opis1',1),
       (sysdatetime(),'Namjena2',20003.50,24,1,'Kratak opis2',2),
	   (SYSDATETIME(),'Namjena3',40000.60,36,1,'Kratak opis3',3)
go

--4
create procedure usp_Otplate_Insert
@Datum date ,
@Iznos decimal,
@Rata int,
@Opis nvarchar(max),
@KreditID int
as
begin 
     insert into Otplate(Datum, Iznos, Rata, Opis,KreditID)
	 values (@Datum,@Iznos,@Rata,@Opis,@KreditID)
end
go

exec usp_Otplate_Insert  '2019-06-13',1000,1,'Lijeze prva rata gredita',1
go
exec usp_Otplate_Insert  '2019-07-13',1000,2,'Lijeze druga rata gredita',1
go
exec usp_Otplate_Insert  '2019-06-13',1000,1,'Lijeze prva rata gredita',2
go
exec usp_Otplate_Insert  '2019-07-13',1000,1,'Lijeze druga rata gredita',2
go
exec usp_Otplate_Insert  '2019-06-13',1000,1,'Lijeze prva rata gredita',3
go

--5
create view view_Krediti_Otplate
as
  select k.JMBG, k.Ime, k.Prezime, k.Adresa,k.Telefon,k.Email,
  kredit.Datum,kredit.Namjena,kredit.Iznos ,COUNT(o.OtplataID) as'Ukupno uplaceno rata',
  SUM(o.Iznos) as 'Do sada uplaceno ' 
  from Klijent as k
  inner join Kredit as kredit
  on k.KlijentID = kredit.KlijentID
  inner join Otplate as o
  on o.KreditID = kredit.KreditID
  group by k.JMBG, k.Ime, k.Prezime, k.Adresa,k.Telefon,k.Email,
  kredit.Datum,kredit.Namjena,kredit.Iznos
go

select * from view_Krediti_Otplate
go

--6
create procedure usp_Krediti_Otplate_SelectByJMBG
@JMBG nvarchar(13)
as
begin
     select * 
	 from view_Krediti_Otplate as kr
	 where kr.JMBG = @JMBG
end 
go

exec usp_Krediti_Otplate_SelectByJMBG '10D2BA9B369D0'
go

--7

create procedure usp_Otplate_Update
@OtplataID int,
@Datum date,
@Iznos decimal,
@Rata int, 
@Opis nvarchar(max),
@Kredit int 
as
begin
     update Otplate
	 set Datum = @Datum, Iznos=@Iznos, Rata=@Rata, Opis=@Opis
	 where OtplataID=@OtplataID and KreditID=@Kredit
end
go

exec usp_Otplate_Update 5,'2019-06-14',2000,2,'Doslo se do para, hehe',3
go

--8
create procedure usp_Krediti_Delete
@KreditID int
as
begin
     delete 
	 from Otplate
	 where KreditID=@KreditID

	 delete Kredit
	 where KreditID=@KreditID

end
go

exec  usp_Krediti_Delete 3
go

--9
create trigger tr_Otplate_IO_Delete
on Otplate
for delete
as 
  print 'Zabranjeno brisanje podataka! '
  rollback
go

delete Otplate
where OtplataID = 1  -->  ok je, radi

--10
backup database novaBaza2
to disk ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\novaBaza2.bak'