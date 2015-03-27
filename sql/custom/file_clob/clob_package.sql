DROP TABLE test_clob CASCADE CONSTRAINTS
/

CREATE TABLE test_clob (
      id           NUMBER(15)
    , file_name    VARCHAR2(1000)
    , xml_file     CLOB
    , timestamp    DATE
)
/

CREATE OR REPLACE DIRECTORY
    EXAMPLE_LOB_DIR
    AS
    '/u01/app/oracle/lobs'
/


CREATE OR REPLACE PROCEDURE Load_CLOB_From_XML_File
IS

    dest_clob   CLOB;
    src_clob    BFILE  := BFILENAME('EXAMPLE_LOB_DIR', 'DatabaseInventoryBig.xml');
    dst_offset  number := 1 ;
    src_offset  number := 1 ;
    lang_ctx    number := DBMS_LOB.DEFAULT_LANG_CTX;
    warning     number;

BEGIN

    DBMS_OUTPUT.ENABLE(100000);

    -- -----------------------------------------------------------------------
    -- THE FOLLOWING BLOCK OF CODE WILL ATTEMPT TO INSERT / WRITE THE CONTENTS
    -- OF AN XML FILE TO A CLOB COLUMN. IN THIS CASE, I WILL USE THE NEW 
    -- DBMS_LOB.LoadCLOBFromFile() API WHICH *DOES* SUPPORT MULTI-BYTE
    -- CHARACTER SET DATA. IF YOU ARE NOT USING ORACLE 9iR2 AND/OR DO NOT NEED
    -- TO SUPPORT LOADING TO A MULTI-BYTE CHARACTER SET DATABASE, USE THE
    -- FOLLOWING FOR LOADING FROM A FILE:
    -- 
    --     DBMS_LOB.LoadFromFile(
    --         DEST_LOB => dest_clob
    --       , SRC_LOB  => src_clob
    --       , AMOUNT   => DBMS_LOB.GETLENGTH(src_clob)
    --     );
    --
    -- -----------------------------------------------------------------------

    INSERT INTO test_clob(id, file_name, xml_file, timestamp) 
        VALUES(1001, 'DatabaseInventoryBig.xml', empty_clob(), sysdate)
        RETURNING xml_file INTO dest_clob;


    -- -------------------------------------
    -- OPENING THE SOURCE BFILE IS MANDATORY
    -- -------------------------------------
    DBMS_LOB.OPEN(src_clob, DBMS_LOB.LOB_READONLY);

    DBMS_LOB.LoadCLOBFromFile(
          DEST_LOB     => dest_clob
        , SRC_BFILE    => src_clob
        , AMOUNT       => DBMS_LOB.GETLENGTH(src_clob)
        , DEST_OFFSET  => dst_offset
        , SRC_OFFSET   => src_offset
        , BFILE_CSID   => DBMS_LOB.DEFAULT_CSID
        , LANG_CONTEXT => lang_ctx
        , WARNING      => warning
    );

    DBMS_LOB.CLOSE(src_clob);

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Loaded XML File using DBMS_LOB.LoadCLOBFromFile: (ID=1001).');

END;
/

CREATE OR REPLACE PROCEDURE Write_CLOB_To_XML_File
IS

  clob_loc          CLOB;
  buffer            VARCHAR2(32767);
  buffer_size       CONSTANT BINARY_INTEGER := 32767;
  amount            BINARY_INTEGER;
  offset            NUMBER(38);

  file_handle       UTL_FILE.FILE_TYPE;
  directory_name    CONSTANT VARCHAR2(80) := 'EXAMPLE_LOB_DIR';
  new_xml_filename  CONSTANT VARCHAR2(80) := 'DatabaseInventoryBig_2.xml';

BEGIN

    DBMS_OUTPUT.ENABLE(100000);

    -- ----------------
    -- GET CLOB LOCATOR
    -- ----------------
    SELECT xml_file INTO clob_loc
    FROM   test_clob
    WHERE  id = 1001;


    -- --------------------------------
    -- OPEN NEW XML FILE IN WRITE MODE
    -- --------------------------------
    file_handle := UTL_FILE.FOPEN(
        location     => directory_name,
        filename     => new_xml_filename,
        open_mode    => 'w',
        max_linesize => buffer_size);

    amount := buffer_size;
    offset := 1;

    -- ----------------------------------------------
    -- READ FROM CLOB XML / WRITE OUT NEW XML TO DISK
    -- ----------------------------------------------
    WHILE amount >= buffer_size
    LOOP

        DBMS_LOB.READ(
            lob_loc    => clob_loc,
            amount     => amount,
            offset     => offset,
            buffer     => buffer);

        offset := offset + amount;

        UTL_FILE.PUT(
            file      => file_handle,
            buffer    => buffer);

        UTL_FILE.FFLUSH(file => file_handle);

    END LOOP;

    UTL_FILE.FCLOSE(file => file_handle);

END;
/

 SELECT id, DBMS_LOB.GETLENGTH(xml_file) Length FROM test_clob;

        ID     LENGTH
---------- ----------
      1001      41113


host ls -l DatabaseInventory*





