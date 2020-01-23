create database bazaPodataka1
go
--postavljanje na defaultne postavke, potrebno je postaviti n d disk, ali ga nemam, pa ne mogu...

use bazaPodataka1
go

--2
create table Kandidati
(
KandidatID int not null identity(1,1) constraint pk_KandidatID primary key,
Ime nvarchar(30) not null,
Prezime nvarchar(30) not null,
JMBG nvarchar(13) not null constraint uq_JMBG unique,
DatumRodjenja date not null,
MjestoRodjenja nvarchar(30),
Telefon nvarchar(20),
Email nvarchar(50) constraint uq_Email unique
);
go

create table Testovi
(
TestID int not null identity (1,1) constraint pk_TestID primary key,
Datum datetime not null,
Naziv nvarchar(50) not null,
Oznaka nvarchar(10) not null constraint uq_Oznaka unique,
Oblast nvarchar(50) not null,
MaxBrojBodova int 
);
go

create table RezultatiTesta(
KandidatID int not null constraint fk_KandidatID  foreign key references Kandidati(KandidatID),
TestID int not null constraint fk_TestID  foreign key references Testovi(TestID),
Polozio bit not null,
OsvojeniBodovi decimal not null,
Napomena nvarchar(max)
);
go

--3
insert into Kandidati(Ime, Prezime, JMBG, DatumRodjenja, MjestoRodjenja, Telefon, Email)
select  top 10 p.FirstName, p.LastName, 
        REPLACE(RIGHT(c.rowguid,13),'-','0'),c.ModifiedDate, adresa.City, phone.PhoneNumber,
		email.EmailAddress
from AdventureWorks2014.Sales.Customer as c
     inner join AdventureWorks2014.Person.Person as p
	 on p.BusinessEntityID = c.PersonID
	 inner join AdventureWorks2014.Person.BusinessEntityAddress as bea
	 on p.BusinessEntityID= bea.BusinessEntityID
	 inner join AdventureWorks2014.Person.Address as adresa
	 on adresa.AddressID=bea.AddressID
	 inner join AdventureWorks2014.Person.PersonPhone as phone
	 on phone.BusinessEntityID=p.BusinessEntityID
	 inner join AdventureWorks2014.Person.EmailAddress as email
	 on email.BusinessEntityID = p.BusinessEntityID
go

insert into Testovi(Datum,Naziv, Oznaka, Oblast, MaxBrojBodova)
values ('2019-06-15','Programiranje 1','PR I','Dvodimenzijalni nizovi',100), 
       ('2019-06-15','Programiranje 2','PR II','Rad sa pokazivacima',100),
	   ('2019-06-15','Programiranje 3','PR III','try - catch',100)
go

--4
create procedure usp_RezultatiTesta_Insert
@KandidatId int,
@TestId int,
@Polozio bit,
@Poeni decimal,
@Napomena nvarchar(max)
as
begin
     insert into RezultatiTesta(KandidatID, TestID, Polozio, OsvojeniBodovi, Napomena)
	 values (@KandidatId,@TestId,@Polozio,@Poeni, @Napomena)

end
go
exec usp_RezultatiTesta_Insert 1,2,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 1,3,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 1,1,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 2,1,1,88, 'Super'
go
exec usp_RezultatiTesta_Insert 2,2,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 3,2,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 2,3,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 3,2,1,100, 'Svaka cast'
go
exec usp_RezultatiTesta_Insert 3,1,1,100, 'Svaka cast'
go

--5
create view view_Rezultati_Testiranja
as
  select kan.Ime[Ime], kan.Prezime[Prezime], kan.JMBG[JMBG], kan.Telefon[Telefon],kan.Email[Email],
         t.Naziv[Naziv testa],t.Oznaka[Oznaka testa], t.Oblast[Oblast tesza], t.MaxBrojBodova, rt.Polozio, rt.OsvojeniBodovi , rt.OsvojeniBodovi/t.MaxBrojBodova*100[Procenat]
  from Kandidati  as kan
  inner join RezultatiTesta as rt
  on rt.KandidatID=kan.KandidatID
  inner join Testovi as t
  on rt.TestID = t.TestID
  go

  select  * from view_Rezultati_Testiranja
  go

  --6
 create procedure usp_RezultatiTesta_SelectByOznaka
@Oznakatesta nvarchar(10),
@Polozio bit
as
begin
     select * 
	 from view_Rezultati_Testiranja as v
	 where v.Polozio =@Polozio and v.[Oznaka testa] =@Oznakatesta
end
go

exec usp_RezultatiTesta_SelectByOznaka 'PR II',1
go

--7
create procedure usp_RezultatiTesta_Update
@KandidatID int, 
@TestID int, 
@Polozio bit,
@Poeni decimal,
@Napomena nvarchar(200)
as
begin 
     update RezultatiTesta
	 set Polozio=@Polozio , OsvojeniBodovi=@Poeni, Napomena=@Napomena
	 where KandidatID=@KandidatID  and TestID=@TestID
end
go

exec usp_RezultatiTesta_Update 2,1,1,100,'Ovaj put ste se stvarno potrudili. :)'
go

--8
create procedure usp_Testovi_Delete
@TestID int
as
begin 
     delete 
	 from RezultatiTesta
	 where TestID = (select TestID from Testovi where TestID=@TestID)

	 delete Testovi
	 where TestID=@TestID
end
go

exec usp_Testovi_Delete 2
go

--9
create trigger Brisanje 
on RezultatiTesta
for delete 
as
  print 'Zabranjeno brisanje! '
  rollback

delete RezultatiTesta
where TestID=2

--10
backup database bazaPodataka1
to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\bazaPodataka1.bak'
go
