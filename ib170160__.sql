create database merima_ib170160_
go

use merima_ib170160_
go


--1
create table Studenti
(
StudentID int identity(1,1) not null constraint pk_StudentID primary key,
BrojDosijea nvarchar(10) not null constraint uq_BrojDosijea unique,
Ime nvarchar(35) not null,
Prezime nvarchar(35) not null,
GodinaStudija int not null,
NacinStudiranja nvarchar(10) not null default 'Redovan',
Email nvarchar(50)null
);
go

create table Predmeti
(
PredmetID int identity (1,1) not null constraint pk_PredmetID primary key, 
Naziv nvarchar(100)not null,
Oznaka nvarchar(10) not null constraint uq_Oznaka unique
);
go

create table Ocjena
(
StudentID int not null constraint fk_StudentID foreign key references Studenti(StudentID),
PredmetID int not null constraint fk_PredmetID foreign key references Predmeti(PredmetID),
Ocjena int not null,
Bodovi decimal not null,
DatumPolaganja date not null,
constraint pk_Ocjena primary key(StudentID,PredmetID)
);
go

--2
insert into Predmeti(Naziv, Oznaka)
values ('Baze podataka 2', 'BP2'),
       ('Programiranj 3 ','PR3'),
	   ('Analiza i dizajn softvera','ADS')
go

insert into Studenti(BrojDosijea, Ime,Prezime,GodinaStudija, Email)
select top 10 C.AccountNumber, p.FirstName,p.LastName,2,email.EmailAddress
from AdventureWorks2014.Sales.Customer as C
     inner join AdventureWorks2014.Person.Person as p
	 on p.BusinessEntityID=C.PersonID 
	 inner join AdventureWorks2014.Person.EmailAddress as email
	 on email.BusinessEntityID = p.BusinessEntityID
go

--3
create procedure UpisOcjena
as
begin
	 insert into Ocjena(StudentID, PredmetID, Ocjena, Bodovi, DatumPolaganja)
	 values (1,1,10,96.4,SYSDATETIME()),
	        (1,2,10,96.4,SYSDATETIME()),
			(1,3,10,97.5,SYSDATETIME()),
			(2,3,10,97.5,SYSDATETIME()),
			(5,3,10,97.5,SYSDATETIME())
end
go

exec UpisOcjena
go

--4
--prebaceno

--5
--a
create nonclustered index PersonFirstNameLastName_incTitle
on Person.Person(FirstName,LastName)
include (Title)
go

--b
select*
from Person.Person
where FirstName like 'K%'
go

--c
create clustered index CreditCard_CreditCardID
on Sales.CreditCard(CreditCardID)
go
--d
create nonclustered index CreditCard_CardNumber_incExpMonth_ExpYear
on Sales.CreditCard(CardNumber)
include (ExpMonth,ExpYear)
go

--6
create view OsobeKartica
as
  select P.LastName [Ime], P.LastName[Prezime], CC.CardNumber[Broj kartice], CC.CardType[Tip kartice]
  from Person.Person as P
  inner join Sales.PersonCreditCard as PC
  on P.BusinessEntityID = PC.BusinessEntityID
  inner join Sales.CreditCard as CC
  on PC.CreditCardID=CC.CreditCardID
where P.Title is null and CC.CardType = 'Vista'
go

select* from OsobeKartica
go

--7
backup database merima_ib170160_
to disk='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\merima_ib170160_.bak'
go

backup database merima_ib170160_
to disk='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\merima_ib170160_.bak'
with differential
go

--8
create login Student_br2
with password = 'student123',
default_database=merima_ib170160_

create user Merima for login Student_br2

--9

create procedure PretragaPregleda
@Ime nvarchar(30)=null,
@Prezime nvarchar(30)=null,
@BrojKartice nvarchar(30)=null
as
begin
     select *
	 from OsobeKartica as o
	 where (o.[Broj kartice]=@BrojKartice or @BrojKartice is null) and
	       (o.Ime=@Ime or @Ime is null) and
		    (o.Prezime = @Prezime or @Prezime is null)
end
go

exec PretragaPregleda  --nema parametara -> svi podaci
go

exec PretragaPregleda null,'Tang',null  --> prezime
go


exec PretragaPregleda 'Li','Li',null  -->ime i prezime
go


exec PretragaPregleda 'Li','Li','11117091935623'  -->ime i prezime o kartica
go


--10
--prije brisanja
select * from Sales.PersonCreditCard  
select * from Sales.CreditCard
create procedure Brisanje
@BrojKartice nvarchar(30)
as
begin
	 delete 
	 from Sales.PersonCreditCard 
	 where @BrojKartice in (select C.CardNumber from Sales.CreditCard as C  )

	 delete Sales.CreditCard
	 where @BrojKartice=CardNumber
end
go

exec Brisanje  '11114404600042'
go
--poslije brisanja
select * from Sales.PersonCreditCard  --0
select * from Sales.CreditCard -- 19117


