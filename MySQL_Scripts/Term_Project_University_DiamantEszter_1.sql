Drop schema if exists University;
CREATE SCHEMA University;
USE University;

-- Create table Dep_Info
DROP TABLE if exists Dep_Info;
CREATE TABLE Dep_Info
	(department_ID VARCHAR(15) NOT NULL,
    department_name varchar(100) NOT NULL,
    DOE datetime NOT NULL,
    primary key(department_id));
   
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Department_Information_cor.csv'
	into table Dep_Info
    fields terminated by ";"
    lines terminated by '\r\n'
    ignore 1 lines
    (department_ID, department_name, DOE);

-- Create table Employee_Info
DROP TABLE if exists Employee_Info;
CREATE TABLE Employee_Info
	(employee_id VARCHAR(15) NOT NULL,
    DOB datetime NOT NULL,
    DOJ datetime NOT NULL,
    department_id varchar(15) not null,
    primary key(employee_id),
    foreign key(department_id) references dep_info(department_id));
   
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/employee_information_cor.csv'
	into table Employee_Info
    fields terminated by ";"
    lines terminated by '\r\n'
    ignore 1 lines
    (employee_ID, DOB, DOJ, department_ID);
    
-- Create table Student_Counc
DROP TABLE if exists Student_Counc;
CREATE TABLE Student_Counc
	(student_id VARCHAR(15) NOT NULL,
    DOA datetime NOT NULL,
    DOB datetime NOT NULL,
    department_id varchar(15) not null,
    department_admission varchar(15) not null,
    primary key(student_id, department_id),
    foreign key(department_id) references dep_info(department_id));
   
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Student_Counceling_Information_cor.txt'
	into table student_Counc
    fields terminated by ";"
    lines terminated by '\r\n'
    ignore 1 lines
    (Student_ID, DOA, DOB, department_id, Department_Admission);

-- -- Create table Student_Perf
-- no primary key because it would be a duplicate
DROP TABLE if exists Student_Perf;
CREATE TABLE Student_Perf
	(student_id VARCHAR(15) NOT NULL,
    semester_name varchar(5) NOT NULL,
    paper1 integer,
    paper2 integer,
    paper3 integer,
    paper4 integer,
    paper5 integer,
    paper6 integer,
    paper7 integer,
    foreign key(student_id) references student_counc(student_id));
   
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Student_Performance_Data.csv'
	into table Student_Perf
    fields terminated by ";"
    lines terminated by '\r\n'
    ignore 1 lines
    (Student_ID, semester_name, @v_paper1, @v_paper2, @v_paper3, @v_paper4, @v_paper5, @v_paper6, @v_paper7)
    set
    paper1 = nullif(@v_paper1, ''),
    paper2 = nullif(@v_paper2, ''),
    paper3 = nullif(@v_paper3, ''),
    paper4 = nullif(@v_paper4, ''),
    paper5 = nullif(@v_paper5, ''),
    paper6 = nullif(@v_paper6, ''),
    paper7 = nullif(@v_paper7, '');


-- ------------ --
--  JOIN TABLES --
-- ------------ --

-- ------------------
-- create join table results_details in stored procedure
drop procedure if exists jointables_results_details;

delimiter //

create procedure jointables_results_details()
Begin
	drop table if exists results_details;

	create table  results_details as
	select t1.student_id, t1.semester_name, t1.paper1, t1.paper2, t1.paper3, t1.paper4, t1.paper5, t1.paper6, t1.paper7,
			t2.DOA, t2.DOB as DOB_student, t2.department_id,
			t3.department_name, t3.DOE
			from student_perf t1 
			right join student_counc t2
			on t1.student_id = t2.student_id
			right join dep_info t3
			on t2.department_id = t3.department_ID;
	
end //

delimiter ;

call jointables_results_details();


-- ----------------------------------
-- create join table dep_employee_details in stored procedure

drop procedure if exists jointables_dep_employee_details;

delimiter //
create procedure jointables_dep_employee_details()
begin
	drop table if exists dep_employee_details;
    
    create table dep_employee_details as
		select a1.employee_id, a1.DOB as DOB_employee, a1.DOJ, a1.department_id,
		a2.department_name, a2.DOE
		from employee_info a1
        left join dep_info a2
        on a1.department_id = a2.department_id;
end //

delimiter ;

call jointables_dep_employee_details();


-- ----- --
-- VIEWS --
-- ----- --


-- ------------------
-- Average results in each departments (ID and name) with the number of students in descending orders based on average grades:
drop view if exists dep_results_students;
create view dep_results_students as
	select department_id, department_name, ((ifnull(paper1, 0) + ifnull(paper2, 0) + ifnull(paper3, 0) + ifnull(paper4, 0) + ifnull(paper5, 0) + ifnull(paper6, 0) + ifnull(paper7, 0)) / 7) as avg_grades, 
		count(student_id)/6 as number_of_students 
		from results_details 
		group by department_name 
		order by avg_grades desc;


-- -------------------------
-- number of teachers teaching in each department ascending based on the establishement date:
drop view if exists dep_age_employees;

create view dep_age_employees as 
	select department_id, department_name, 
		round(datediff(current_date, (DOE))/365, 0)  as age_of_dep, 
		count(employee_id) as number_of_employees 
		from dep_employee_details 
		group by department_name 
		order by age_of_dep asc;
 
select * from dep_age_employees;

-- ----------------------------------    
-- the average results of each paper in each semester
drop view if exists grades_summary;
create view grades_summary as
	select semester_name, 
		round(sum(ifnull(paper1, 0))/count(paper1), 2) as paper1_avg,
        round(sum(ifnull(paper2, 0))/count(paper2), 2) as paper2_avg,
        round(sum(ifnull(paper3, 0))/count(paper3), 2) as paper3_avg,
        round(sum(ifnull(paper4, 0))/count(paper4), 2) as paper4_avg,
        round(sum(ifnull(paper5, 0))/count(paper5), 2) as paper5_avg,
        round(sum(ifnull(paper6, 0))/count(paper6), 2) as paper6_avg,
        round(sum(ifnull(paper7, 0))/count(paper7), 2) as paper7_avg,
        round((sum(ifnull(paper1, 0))/count(paper1) + 
        sum(ifnull(paper2, 0))/count(paper2) +
        sum(ifnull(paper3, 0))/count(paper3) +
        sum(ifnull(paper4, 0))/count(paper4) +
        sum(ifnull(paper5, 0))/count(paper5) +
        sum(ifnull(paper6, 0))/count(paper6) +
        sum(ifnull(paper7, 0))/count(paper7)) / 7, 2) as total_avg
		from results_details group by semester_name;

select * from grades_summary;

-- Number of papers not submited, worst paper
drop view if exists missing_papers;
create view missing_papers as
	select department_id,
			department_name,
		sum(case when paper1 is null then 1 else 0 end) as missing_paper1,
		sum(case when paper2 is null then 1 else 0 end) as missing_paper2, 
		sum(case when paper3 is null then 1 else 0 end) as missing_paper3, 
		sum(case when paper4 is null then 1 else 0 end) as missing_paper4,
		sum(case when paper5 is null then 1 else 0 end) as missing_paper5,
		sum(case when paper6 is null then 1 else 0 end) as missing_paper6,
		sum(case when paper7 is null then 1 else 0 end) as missing_paper7,
		(sum(case when paper1 is null then 1 else 0 end) +
		sum(case when paper2 is null then 1 else 0 end) + 
		sum(case when paper3 is null then 1 else 0 end) +
		sum(case when paper4 is null then 1 else 0 end) +
		sum(case when paper5 is null then 1 else 0 end) +
		sum(case when paper6 is null then 1 else 0 end) +
		sum(case when paper7 is null then 1 else 0 end)) as total_missing_papers
	from results_details
	group by department_name
	order by total_missing_papers desc;

select * from missing_papers;
    
-- Materialized Views
-- 1. Which department has highest number of missing papers in which semester? (I have set the limit to 2 because there two departments with the same total missing papers)
select department_name, total_missing_papers
        from missing_papers 
        order by total_missing_papers desc 
        limit 2;

-- 2. Which semester was the easiest considering the result?
select semester_name, total_avg 
	from grades_summary
    order by total_avg asc
    limit 1;

-- 3. What is the average grades for departments starting with I and C?
select department_id, department_name, avg_grades
	from dep_results_students
    where department_name like 'H%' or department_name like 'I%';



-- ------------------------
-- Triggers
-- Triggers for ID-s if they are typed in lower cases

-- -------
-- 1. trigger for table Dep_Info (one for new entry, one for updates)
drop trigger if exists trigger_dep_info;

create trigger trigger_dep_info
before insert on dep_info
for each row
set new.department_ID = upper(new.department_ID);


drop trigger if exists trigger_up_dep_info;

create trigger trigger_up_dep_info
before update on dep_info
for each row
set new.department_ID = upper(new.department_ID);

-- -------
-- 2. trigger for table Employee_Info
drop trigger if exists trigger_employee_info;

create trigger trigger_employee_info
before insert on employee_info
for each row
set new.department_id = upper(new.department_id),
	new.employee_id = upper(new.employee_id);


drop trigger if exists trigger_up_employee_info;

create trigger trigger_up_employee_info
before update on employee_info
for each row
set new.department_id = upper(new.department_id),
	new.employee_id = upper(new.employee_id);

-- -----
-- 3. trigger for table Student_Counc
drop trigger if exists trigger_student_counc;

create trigger trigger_student_counc
before insert on student_counc
for each row
set new.department_ID = upper(new.department_ID),
	new.student_id = upper(new.student_id),
    new.department_admission = upper(new.department_admission);


drop trigger if exists trigger_up_student_counc;

create trigger trigger_up_student_counc
before update on student_counc
for each row
set new.department_ID = upper(new.department_ID),
	new.student_id = upper(new.student_id),
    new.department_admission = upper(new.department_admission);

-- ----
-- 4. trigger for table Student_Perf
drop trigger if exists trigger_student_perf;

create trigger trigger_student_perf
before insert on student_perf
for each row
set new.student_id = upper(new.student_id);


drop trigger if exists trigger_up_student_perf;

create trigger trigger_up_student_perf
before update on student_perf
for each row
set new.student_id = upper(new.student_id);


