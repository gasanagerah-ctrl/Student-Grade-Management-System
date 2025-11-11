# Student-Grade-Management-System

PROBLEM IDENTIFICATION

-A school needs a pl/sql program to store students names and grades for a specific courses,calculate avarage grade and display who passed or failed

-i approached the problem by implementing pl/sql features collections,records,GOTO.

collections:to store multiple student grades

records:to hold data for each student

GOTO: to skip to the end if invald data is found


PL/SQL CODE:

DECLARE
  -- Record type for student data
  TYPE student_rec IS RECORD (
    name VARCHAR2(30),
    grade NUMBER(3)
  );

  -- Collection (array) of student records
  TYPE student_table IS TABLE OF student_rec INDEX BY PLS_INTEGER;
  students student_table;

  total NUMBER := 0;
  avg_grade NUMBER;
  i NUMBER;

BEGIN
  -- Adding sample data
  students(1).name := 'Alice';
  students(1).grade := 80;

  students(2).name := 'Brian';
  students(2).grade := 65;

  students(3).name := 'Carine';
  students(3).grade := 90;

  -- Loop through students to calculate average
  FOR i IN 1..students.COUNT LOOP
    IF students(i).grade < 0 OR students(i).grade > 100 THEN
      DBMS_OUTPUT.PUT_LINE('Invalid grade found! Skipping calculation...');
      GOTO end_of_program;  -- Using GOTO
    END IF;

    total := total + students(i).grade;
  END LOOP;

  avg_grade := total / students.COUNT;

  DBMS_OUTPUT.PUT_LINE('Average grade: ' || avg_grade);
  DBMS_OUTPUT.PUT_LINE('--- Student Results ---');

  FOR i IN 1..students.COUNT LOOP
    IF students(i).grade >= 70 THEN
      DBMS_OUTPUT.PUT_LINE(students(i).name || ' passed.');
    ELSE
      DBMS_OUTPUT.PUT_LINE(students(i).name || ' failed.');
    END IF;
  END LOOP;

  <<end_of_program>>
  NULL;

END;
/
