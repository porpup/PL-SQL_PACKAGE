SPOOL /tmp/oracle/projectPart8_spool.txt

SELECT
    to_char (sysdate, 'DD Month YYYY Year Day HH:MI:SS AM')
FROM
    dual;


/* Question 1: (use script 7clearwater)
Modify the package order_package (Example of lecture on PACKAGE) by adding 
function, procedure to verify the quantity on hand before insert a row in 
table order_line and to update also the quantity on hand of table inventory.
Test your package with different cases. */
CONNECT des02/des02

SET SERVEROUTPUT ON

CREATE OR REPLACE PACKAGE order_package IS
    global_inv_id NUMBER(6);
    global_quantity NUMBER(6);
    PROCEDURE create_new_order (current_c_id NUMBER, 
                                current_meth_pmt VARCHAR2, 
                                current_os_id NUMBER);

    PROCEDURE create_new_order_line (current_o_id NUMBER);

    FUNCTION qoh_update (p_inv_id NUMBER,
                        p_quantity NUMBER)
    RETURN BOOLEAN;
END;
/

CREATE SEQUENCE order_sequence START WITH 7;

CREATE OR REPLACE PACKAGE BODY order_package IS

    PROCEDURE create_new_order (current_c_id NUMBER,
                                current_meth_pmt VARCHAR2, 
                                current_os_id NUMBER) AS
    current_o_id NUMBER;
    BEGIN
        SELECT
            order_sequence.NEXTVAL
        INTO
            current_o_id
        FROM
            dual;
        INSERT INTO ORDERS 
        VALUES (current_o_id,
                sysdate,
                current_meth_pmt,
                current_c_id,
                current_os_id);
        create_new_order_line (current_o_id);
    COMMIT;
    END create_new_order;

    PROCEDURE create_new_order_line (current_o_id NUMBER) AS
    v_inv_qoh NUMBER;
    v_update_check BOOLEAN;
    BEGIN
        SELECT
            INV_QOH
        INTO
            v_inv_qoh
        FROM
            INVENTORY
        WHERE
            INV_ID = global_inv_id;
        v_update_check := qoh_update (global_inv_id, global_quantity);
        IF v_update_check = TRUE THEN
            INSERT INTO ORDER_LINE 
            VALUES (current_o_id, global_inv_id, global_quantity);
            UPDATE INVENTORY
            SET INV_QOH = (v_inv_qoh - global_quantity)
            WHERE
                INV_ID = global_inv_id;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Will be available VERY VERY VERY SOON');
        END IF;
    COMMIT;
    END create_new_order_line;

    FUNCTION qoh_update (p_inv_id NUMBER,
                        p_quantity NUMBER) 
    RETURN BOOLEAN AS
    v_inv_qoh NUMBER;
    BEGIN
        SELECT
            INV_QOH
        INTO
            v_inv_qoh
        FROM
            INVENTORY
        WHERE
            INV_ID = p_inv_id;
        IF v_inv_qoh >= p_quantity THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    COMMIT;        
    END qoh_update;

END;
/

BEGIN
    order_package.global_inv_id := 32;
    order_package.global_quantity := 2000;
END;
/ 

EXEC order_package.create_new_order(4, 'FAVOR', 6)

BEGIN
    order_package.global_inv_id := 31;
    order_package.global_quantity := 99;
END;
/

EXEC order_package.create_new_order(3, 'Cash', 1)



/* Question 2: (use script 7software)
Create a package with a procedure that accepts the consultant id, skill id, and a
letter to insert a new row into table consultant_skill.
After the record is inserted, display the consultant last and first name, 
skill description and the status of the certification as CERTIFIED or Not Yet Certified.
Do not forget to handle the errors such as: Consultant, skill does not exist and 
the certification is different than 'Y' or 'N'.
Test your package at least 2 times! */
CONNECT des04/des04

SET SERVEROUTPUT ON

CREATE OR REPLACE PACKAGE c_package IS
    PROCEDURE L8Q2 (p_c_id NUMBER,
                    p_skill_id NUMBER,
                    p_certification VARCHAR2);
END;
/


CREATE OR REPLACE PACKAGE BODY c_package IS
    PROCEDURE L8Q2 (p_c_id NUMBER,
                    p_skill_id NUMBER,
                    p_certification VARCHAR2) AS
    v_c_id CONSULTANT.C_ID%TYPE;
    v_skill_id SKILL.SKILL_ID%TYPE;
    v_certification CONSULTANT_SKILL.CERTIFICATION%TYPE;
    v_c_last CONSULTANT.C_LAST%TYPE;
    v_c_first CONSULTANT.C_FIRST%TYPE;
    v_skill_description SKILL.SKILL_DESCRIPTION%TYPE;
    v_flag NUMBER := 0;

    BEGIN
        IF p_certification IN ('Y', 'N') THEN
            SELECT
                SKILL_DESCRIPTION
            INTO
                v_skill_description
            FROM
                SKILL
            WHERE
                SKILL_ID = p_skill_id;
            v_flag := 1;

            SELECT
                C_ID,
                C_LAST,
                C_FIRST
            INTO
                v_c_id,
                v_c_last,
                v_c_first
            FROM
                CONSULTANT
            WHERE
                C_ID = p_c_id;
            v_flag := 2;

            SELECT
                CERTIFICATION
            INTO
                v_certification
            FROM
                CONSULTANT_SKILL
            WHERE
                C_ID = p_c_id AND
                SKILL_ID = p_skill_id;
            v_flag := 3; 
            DBMS_OUTPUT.PUT_LINE('The row with Consultant ID and Skill ID already EXIST!');

            IF v_certification = 'Y' THEN
                DBMS_OUTPUT.PUT_LINE('Consultant: ' || v_c_last || ' ' || v_c_first || CHR(10) ||
                                    v_skill_description || ': CERTIFIED');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Consultant: ' || v_c_last || ' ' || v_c_first || CHR(10) ||
                                    v_skill_description || ': NOT YET CERTIFIED');
            END IF;
        ELSE
            DBMS_OUTPUT.PUT_LINE('The certification is different than ''Y'' or ''N''.');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            IF v_flag = 0 THEN
                DBMS_OUTPUT.PUT_LINE('Skill does not exist.');
            ELSIF v_flag = 1 THEN
                DBMS_OUTPUT.PUT_LINE('Consultant does not exist.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Consultant, skill does not exist. I''m inserting one...');
                INSERT INTO CONSULTANT_SKILL
                VALUES (p_c_id,
                    p_skill_id,
                    p_certification);
                IF p_certification = 'Y' THEN
                    DBMS_OUTPUT.PUT_LINE('Consultant: ' || v_c_last || ' ' || v_c_first || CHR(10) ||
                                        v_skill_description || ': CERTIFIED');
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Consultant: ' || v_c_last || ' ' || v_c_first || CHR(10) ||
                                    v_skill_description || ': NOT YET CERTIFIED');
                END IF;
            END IF;
    COMMIT;
    END L8Q2;

END;
/

EXEC c_package.L8Q2 (100, 4, 'Y')

EXEC c_package.L8Q2 (100, 4, 'Y')

EXEC c_package.L8Q2 (100, 5, 'Z')

EXEC c_package.L8Q2 (199, 1, 'Y')

EXEC c_package.L8Q2 (100, 99, 'Y')


SPOOL OFF;