  CREATING TABLES TO BE USED: students, grade

### 2. database/tables.sql
```sql
-- Create Students table
CREATE TABLE students (
    student_id NUMBER PRIMARY KEY,
    student_name VARCHAR2(100) NOT NULL,
    email VARCHAR2(150)
);

-- Create Grades table
CREATE TABLE grades (
    grade_id NUMBER PRIMARY KEY,
    student_id NUMBER,
    course_code VARCHAR2(20),
    grade NUMBER(5,2),
    grade_date DATE,
    CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Create sequence for IDs
CREATE SEQUENCE student_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE grade_seq START WITH 1 INCREMENT BY 1;

INSERTING SOME RECORDS IN TABLES:


INSERT INTO students (student_id, student_name, email) VALUES (student_seq.NEXTVAL, 'John Smith', 'john.smith@college.edu');
INSERT INTO students (student_id, student_name, email) VALUES (student_seq.NEXTVAL, 'Sarah Johnson', 'sarah.johnson@college.edu');
INSERT INTO students (student_id, student_name, email) VALUES (student_seq.NEXTVAL, 'Michael Brown', 'michael.brown@college.edu');


INSERT INTO grades (grade_id, student_id, course_code, grade, grade_date) VALUES (grade_seq.NEXTVAL, 1, 'CS101', 85.5, SYSDATE);
INSERT INTO grades (grade_id, student_id, course_code, grade, grade_date) VALUES (grade_seq.NEXTVAL, 2, 'CS101', 92.0, SYSDATE);
INSERT INTO grades (grade_id, student_id, course_code, grade, grade_date) VALUES (grade_seq.NEXTVAL, 3, 'CS101', 45.0, SYSDATE);

.....DONT FORGET TO COMMIT

>>>>>>plsql/student grade package

CREATE OR REPLACE PACKAGE student_grade_pkg AS
    -- RECORD type for student information
    TYPE student_record IS RECORD (
        student_id NUMBER,
        student_name VARCHAR2(100),
        grade NUMBER(5,2),
        status VARCHAR2(20)
    );
    
    -- VARRAY collection for students
    TYPE student_varray IS VARRAY(100) OF student_record;
    
    -- Associative array (INDEX BY table)
    TYPE grade_table IS TABLE OF NUMBER INDEX BY VARCHAR2(100);
    
    -- Constants
    PASSING_GRADE CONSTANT NUMBER := 60.0;
    MAX_STUDENTS CONSTANT NUMBER := 100;
    
    -- Package variables
    g_total_students NUMBER := 0;
    g_class_average NUMBER := 0;
    
    -- Procedures and Functions
    PROCEDURE initialize_students;
    FUNCTION calculate_average RETURN NUMBER;
    PROCEDURE display_results;
    PROCEDURE classify_students;
    
END student_grade_pkg;
/

CREATE OR REPLACE PACKAGE BODY student_grade_pkg AS
    
    -- Global collections
    student_data student_varray := student_varray();
    student_grades grade_table;
    
    PROCEDURE initialize_students IS
        -- Cursor to fetch student data
        CURSOR student_cursor IS
            SELECT s.student_id, s.student_name, g.grade
            FROM students s
            JOIN grades g ON s.student_id = g.student_id
            WHERE g.course_code = 'CS101';
            
        v_counter NUMBER := 0;
        v_temp_record student_record;
        
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Initializing student data...');
        DBMS_OUTPUT.PUT_LINE('================================');
        
        FOR student_rec IN student_cursor LOOP
            v_counter := v_counter + 1;
            
            -- Populate record
            v_temp_record.student_id := student_rec.student_id;
            v_temp_record.student_name := student_rec.student_name;
            v_temp_record.grade := student_rec.grade;
            v_temp_record.status := 'NOT EVALUATED';
            
            -- Extend and add to VARRAY
            student_data.EXTEND;
            student_data(v_counter) := v_temp_record;
            
            -- Add to associative array
            student_grades(student_rec.student_name) := student_rec.grade;
            
            DBMS_OUTPUT.PUT_LINE('Added: ' || student_rec.student_name || ' - Grade: ' || student_rec.grade);
        END LOOP;
        
        g_total_students := v_counter;
        DBMS_OUTPUT.PUT_LINE('Total students initialized: ' || g_total_students);
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error initializing students: ' || SQLERRM);
    END initialize_students;
    
    FUNCTION calculate_average RETURN NUMBER IS
        v_total NUMBER := 0;
        v_count NUMBER := 0;
    BEGIN
        IF student_data.COUNT = 0 THEN
            RETURN 0;
        END IF;
        
        -- Calculate using VARRAY
        FOR i IN 1..student_data.COUNT LOOP
            v_total := v_total + student_data(i).grade;
            v_count := v_count + 1;
        END LOOP;
        
        g_class_average := ROUND(v_total / v_count, 2);
        RETURN g_class_average;
        
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            DBMS_OUTPUT.PUT_LINE('Error: Division by zero in average calculation');
            RETURN 0;
    END calculate_average;
    
    PROCEDURE classify_students IS
        v_index NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Classifying students...');
        DBMS_OUTPUT.PUT_LINE('================================');
        
        v_index := student_data.FIRST;
        
        <<classification_loop>>
        WHILE v_index IS NOT NULL LOOP
            -- Using GOTO for demonstration (normally not recommended)
            IF student_data(v_index).grade >= PASSING_GRADE THEN
                GOTO passed_student;
            ELSE
                GOTO failed_student;
            END IF;
            
            <<passed_student>>
            student_data(v_index).status := 'PASSED';
            DBMS_OUTPUT.PUT_LINE(student_data(v_index).student_name || ': PASSED - ' || student_data(v_index).grade);
            GOTO next_student;
            
            <<failed_student>>
            student_data(v_index).status := 'FAILED';
            DBMS_OUTPUT.PUT_LINE(student_data(v_index).student_name || ': FAILED - ' || student_data(v_index).grade);
            
            <<next_student>>
            v_index := student_data.NEXT(v_index);
        END LOOP classification_loop;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in classification: ' || SQLERRM);
    END classify_students;
    
    PROCEDURE display_results IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'FINAL RESULTS');
        DBMS_OUTPUT.PUT_LINE('================================');
        DBMS_OUTPUT.PUT_LINE('Class Average: ' || g_class_average);
        DBMS_OUTPUT.PUT_LINE('Passing Grade: ' || PASSING_GRADE);
        DBMS_OUTPUT.PUT_LINE('Total Students: ' || g_total_students);
        DBMS_OUTPUT.PUT_LINE('================================' || CHR(10));
        
        -- Display individual results using associative array
        DECLARE
            v_name VARCHAR2(100);
        BEGIN
            v_name := student_grades.FIRST;
            
            <<display_loop>>
            WHILE v_name IS NOT NULL LOOP
                DBMS_OUTPUT.PUT_LINE(RPAD(v_name, 20) || ': ' || 
                                   RPAD(student_grades(v_name), 6) || ' - ' ||
                                   CASE WHEN student_grades(v_name) >= PASSING_GRADE THEN 'PASSED' ELSE 'FAILED' END);
                v_name := student_grades.NEXT(v_name);
            END LOOP display_loop;
        END;
        
        DBMS_OUTPUT.PUT_LINE(CHR(10) || 'Summary:');
        DBMS_OUTPUT.PUT_LINE('Students passed: ' || student_grades.COUNT); -- This would need enhancement for actual count
        
    END display_results;
    
END student_grade_pkg;
/



CTREATED PROCEDURE

CREATE OR REPLACE PROCEDURE student_grade_analysis AS
    TYPE student_record IS RECORD (
        student_id NUMBER,
        student_name VARCHAR2(100),
        grade NUMBER(5,2)
    );
    
    TYPE student_varray IS VARRAY(5) OF student_record;
    
    student_data student_varray := student_varray();
    v_temp student_record;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Testing simple procedure...');
    
    student_data.EXTEND(2);
    
    -- Student 1
    v_temp.student_id := 1;
    v_temp.student_name := 'Test Student';
    v_temp.grade := 85.5;
    student_data(1) := v_temp;
    
    -- Student 2  
    v_temp.student_id := 2;
    v_temp.student_name := 'Another Student';
    v_temp.grade := 90.0;
    student_data(2) := v_temp;
    
    DBMS_OUTPUT.PUT_LINE('Student: ' || student_data(1).student_name);
    DBMS_OUTPUT.PUT_LINE('Student: ' || student_data(2).student_name);
    
    -- GOTO example
    GOTO demo_section;
    
    DBMS_OUTPUT.PUT_LINE('This will be skipped');
    
    <<demo_section>>
    DBMS_OUTPUT.PUT_LINE('GOTO worked!');
    
END student_grade_analysis;
/

SET SERVEROUTPUT ON;
EXECUTE student_grade_analysis;




