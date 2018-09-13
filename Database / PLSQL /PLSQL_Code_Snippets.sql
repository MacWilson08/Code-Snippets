/* 
Original Author:    Rachel Wilson
          Title:    PLSQL Code Snippets
      File Name:    PLSQL_Code_Snippets.sql    
    Description:    PL/SQL Code Snippets to help do searches for information in an ORACLE db. 

          Notes:    N/A
*/


-- Gets tables and columns that contain a specific value in a row  
WITH  char_cols AS
  (SELECT /*+materialize */ table_name, column_name
   FROM   cols
   WHERE  data_type IN ('CHAR', 'VARCHAR2'))
SELECT DISTINCT SUBSTR (:val, 1, 11) "Searchword",
       SUBSTR (table_name, 1, 14) "Table",
       SUBSTR (column_name, 1, 14) "Column"
FROM   char_cols,
       TABLE (xmlsequence (dbms_xmlgen.getxmltype ('select "'
       || column_name
       || '" from "'
       || table_name
       || '" where upper("'
       || column_name
       || '") like upper(''%'
       || :val
       || '%'')' ).extract ('ROWSET/ROW/*') ) ) t
ORDER  BY "Table";

-- Find all Users and Applications, even if they are granted access to schema(s) through a role
-- It's possible this will need to be rewritten if we have a role that's granted a role that's granted a role, etc.... 
 WITH USERS_OF_SCHEMA AS
    ( SELECT DISTINCT dtp1.OWNER, dtp1.GRANTEE, 'Direct Access' AS ROLE, COALESCE(du1.PROFILE, 'ROLE') ACCESS_TYPE
        FROM dba_tab_privs dtp1
        LEFT 
        JOIN dba_users du1
          ON dtp1.GRANTEE = du1.USERNAME 
--       WHERE dtp1.OWNER = 'FORM_17A_FLNG'
    ),
      USERS_OF_ROLES AS
    ( SELECT uos.OWNER, drp.GRANTEE, drp.GRANTED_ROLE AS ROLE, COALESCE(du2.PROFILE, 'ROLE') ACCESS_TYPE
        FROM USERS_OF_SCHEMA uos
        JOIN dba_role_privs drp
          ON drp.GRANTED_ROLE = uos.GRANTEE
        JOIN dba_users du2
          ON du2.USERNAME = drp.GRANTEE
    ),
      UNFILTERED_FINAL AS
    ( SELECT uos.OWNER, uos.GRANTEE, uos.ROLE, uos.ACCESS_TYPE
        FROM USERS_OF_SCHEMA uos
       WHERE uos.ACCESS_TYPE <> 'ROLE'
       UNION
      SELECT uor.OWNER, uor.GRANTEE, uor.ROLE, uor.ACCESS_TYPE
        FROM USERS_OF_ROLES uor
    )
SELECT COUNT(uf.GRANTEE) USER_COUNT, uf.OWNER AS OWNER
  FROM UNFILTERED_FINAL uf
 WHERE uf.ACCESS_TYPE = 'FINRA_APPL'
 GROUP
    BY uf.OWNER;
