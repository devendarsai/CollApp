
create extension unaccent;
--


-- CONFIGURATION TABLE
CREATE TABLE LA_CONF (
	CONF_KEY VARCHAR(64) PRIMARY KEY NOT NULL,
	CONF_VALUE TEXT NOT NULL
);

-- USER
CREATE TABLE LA_USER (
	USER_ID SERIAL PRIMARY KEY NOT NULL,
	USER_PROVIDER VARCHAR(16) NOT NULL,
	USER_NAME VARCHAR(128) NOT NULL,
	USER_EMAIL VARCHAR(256),
	USER_ENABLED BOOLEAN,
	USER_DISPLAY_NAME VARCHAR(256),
	USER_EMAIL_NOTIFICATION BOOLEAN DEFAULT TRUE NOT NULL,
	USER_LAST_EMAIL_SENT TIMESTAMP DEFAULT NULL,
	USER_LAST_CHECKPOINT_COUNT INTEGER DEFAULT 0 NOT NULL,
	USER_LAST_CHECKED TIMESTAMP DEFAULT NULL,
    USER_MEMBER_SINCE TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
-- CONSTRAINTS
ALTER TABLE LA_USER ADD CONSTRAINT "UNIQUE_LA_USER_USER_NAME" UNIQUE(USER_PROVIDER, USER_NAME);

-- USER REMEMBER
CREATE TABLE LA_USER_REMEMBER (
	USER_REMEMBER_HASHED_TOKEN CHAR(64) NOT NULL,
	USER_REMEMBER_ID_FK INTEGER NOT NULL,
	USER_REMEMBER_LAST_USE TIMESTAMP NOT NULL,
	PRIMARY KEY(USER_REMEMBER_ID_FK, USER_REMEMBER_HASHED_TOKEN)
);
-- CONSTRAINTS
ALTER TABLE LA_USER_REMEMBER ADD FOREIGN KEY(USER_REMEMBER_ID_FK) REFERENCES LA_USER(USER_ID);

-- PROJECT
CREATE TABLE LA_PROJECT (
	PROJECT_ID SERIAL PRIMARY KEY NOT NULL,
	PROJECT_NAME VARCHAR(128) NOT NULL,
	PROJECT_SHORT_NAME VARCHAR(8) NOT NULL,
	PROJECT_ARCHIVED BOOLEAN DEFAULT FALSE NOT NULL,
	PROJECT_DESCRIPTION TEXT
);
ALTER TABLE LA_PROJECT ADD CONSTRAINT "UNIQUE_LA_PROJECT_SHORT_NAME" UNIQUE(PROJECT_SHORT_NAME);

-- BOARDS
CREATE TABLE LA_BOARD (
	BOARD_ID SERIAL PRIMARY KEY NOT NULL,
	BOARD_PROJECT_ID_FK INTEGER NOT NULL,
	BOARD_NAME VARCHAR(128) NOT NULL,
	BOARD_SHORT_NAME VARCHAR(8) NOT NULL,
	BOARD_ARCHIVED BOOLEAN DEFAULT FALSE NOT NULL,
	BOARD_DESCRIPTION TEXT
);
-- CONSTRAINTS
ALTER TABLE LA_BOARD ADD CONSTRAINT "UNIQUE_LA_BOARD_SHORT_NAME" UNIQUE(BOARD_SHORT_NAME);
ALTER TABLE LA_BOARD ADD FOREIGN KEY(BOARD_PROJECT_ID_FK) REFERENCES LA_PROJECT(PROJECT_ID);
-- INDEXES
CREATE INDEX "BOARD_PROJECT_ID_FK_IDX" ON LA_BOARD(BOARD_PROJECT_ID_FK);

-- BOARD COUNTERS
CREATE TABLE LA_BOARD_COUNTER (
	BOARD_COUNTER_ID_FK INTEGER PRIMARY KEY NOT NULL,
	BOARD_COUNTER_CARD_SEQUENCE INTEGER NOT NULL
);
ALTER TABLE LA_BOARD_COUNTER ADD FOREIGN KEY(BOARD_COUNTER_ID_FK) REFERENCES LA_BOARD(BOARD_ID);

-- BOARD DEFINITION, FOR STATISTICS AND MICROMANAGEMENT
CREATE TABLE LA_BOARD_COLUMN_DEFINITION (
	BOARD_COLUMN_DEFINITION_ID SERIAL PRIMARY KEY NOT NULL,
	BOARD_COLUMN_DEFINITION_PROJECT_ID_FK INTEGER NOT NULL,
	BOARD_COLUMN_DEFINITION_VALUE VARCHAR(24) NOT NULL,
	BOARD_COLUMN_DEFINITION_COLOR INTEGER NOT NULL
);
-- CONSTRAINTS:
ALTER TABLE LA_BOARD_COLUMN_DEFINITION ADD FOREIGN KEY(BOARD_COLUMN_DEFINITION_PROJECT_ID_FK) REFERENCES LA_PROJECT(PROJECT_ID);
ALTER TABLE LA_BOARD_COLUMN_DEFINITION ADD CONSTRAINT "BOARD_COLUMN_DEFINITION_VALUE" CHECK(BOARD_COLUMN_DEFINITION_VALUE IN ('OPEN', 'CLOSED', 'BACKLOG', 'DEFERRED'));
ALTER TABLE LA_BOARD_COLUMN_DEFINITION ADD CONSTRAINT "BOARD_COLUMN_DEFINITION_COLOR_UNIQUE" UNIQUE(BOARD_COLUMN_DEFINITION_PROJECT_ID_FK, BOARD_COLUMN_DEFINITION_COLOR);


-- BOARD COLUMN, FOR CATEGORIZING A CARD
CREATE TABLE LA_BOARD_COLUMN (
	BOARD_COLUMN_ID SERIAL PRIMARY KEY NOT NULL,
	BOARD_COLUMN_NAME VARCHAR(128) NOT NULL,
	BOARD_COLUMN_ORDER INTEGER NOT NULL,
	BOARD_COLUMN_LOCATION VARCHAR(16) NOT NULL,
	BOARD_COLUMN_BOARD_ID_FK INTEGER NOT NULL,
	BOARD_COLUMN_DEFINITION_ID_FK INTEGER NOT NULL
);
-- CONSTRAINTS:
ALTER TABLE LA_BOARD_COLUMN ADD FOREIGN KEY(BOARD_COLUMN_BOARD_ID_FK) REFERENCES LA_BOARD(BOARD_ID);
ALTER TABLE LA_BOARD_COLUMN ADD FOREIGN KEY(BOARD_COLUMN_DEFINITION_ID_FK) REFERENCES LA_BOARD_COLUMN_DEFINITION(BOARD_COLUMN_DEFINITION_ID);
ALTER TABLE LA_BOARD_COLUMN ADD CONSTRAINT "BOARD_COLUMN_LOCATION_VALUE" CHECK(BOARD_COLUMN_LOCATION IN ('BOARD', 'BACKLOG', 'ARCHIVE', 'TRASH'));
ALTER TABLE LA_BOARD_COLUMN ADD CONSTRAINT "BOARD_COLUMN_LOCATION_AND_NAME" CHECK(
CASE
	WHEN BOARD_COLUMN_LOCATION = 'BOARD' AND BOARD_COLUMN_NAME IN ('BACKLOG', 'ARCHIVE', 'TRASH') THEN FALSE
	ELSE TRUE
END);
-- INDEXES
CREATE INDEX "BOARD_COLUMN_BOARD_ID_FK_IDX" ON LA_BOARD_COLUMN(BOARD_COLUMN_BOARD_ID_FK);
CREATE INDEX "BOARD_COLUMN_DEFINITION_ID_FK_IDX" ON LA_BOARD_COLUMN(BOARD_COLUMN_DEFINITION_ID_FK);

-- BOARD STATISTICS
CREATE TABLE LA_BOARD_STATISTICS (
	BOARD_STATISTICS_TIME TIMESTAMP NOT NULL,
	BOARD_STATISTICS_BOARD_ID_FK INTEGER NOT NULL,
	BOARD_STATISTICS_COLUMN_DEFINITION_ID_FK INTEGER NOT NULL,
	BOARD_STATISTICS_LOCATION VARCHAR(16) NOT NULL,
	BOARD_STATISTICS_COUNT INTEGER NOT NULL
);
ALTER TABLE LA_BOARD_STATISTICS ADD FOREIGN KEY(BOARD_STATISTICS_BOARD_ID_FK) REFERENCES LA_BOARD(BOARD_ID);
ALTER TABLE LA_BOARD_STATISTICS ADD FOREIGN KEY(BOARD_STATISTICS_COLUMN_DEFINITION_ID_FK) REFERENCES LA_BOARD_COLUMN_DEFINITION(BOARD_COLUMN_DEFINITION_ID);
ALTER TABLE LA_BOARD_STATISTICS ADD CONSTRAINT "OARD_STATISTICS_LOCATION_VALUE" CHECK(BOARD_STATISTICS_LOCATION IN ('BOARD', 'BACKLOG', 'ARCHIVE', 'TRASH'));
-- INDEXES
CREATE INDEX "BOARD_STATISTICS_BOARD_ID_FK_IDX" ON LA_BOARD_STATISTICS(BOARD_STATISTICS_BOARD_ID_FK);

-- LATEST BOARD STATISTICS BY DAY
CREATE VIEW LA_BOARD_STATISTICS_DAYS AS (SELECT MAX(BOARD_STATISTICS_TIME) AS DAY FROM LA_BOARD_STATISTICS GROUP BY CAST(BOARD_STATISTICS_TIME AS DATE));

-- CARD
CREATE TABLE LA_CARD (
	CARD_ID SERIAL PRIMARY KEY NOT NULL,
	CARD_NAME VARCHAR(255) NOT NULL,
	CARD_NAME_TSVECTOR TSVECTOR NOT NULL,
	CARD_BOARD_COLUMN_ID_FK INTEGER NOT NULL,
	CARD_ORDER INTEGER NOT NULL,
	CARD_SEQ_NUMBER INTEGER NOT NULL,
	CARD_USER_ID_FK INTEGER NOT NULL,
	CARD_LAST_UPDATED TIMESTAMP NOT NULL,
	CARD_LAST_UPDATED_USER_ID_FK INTEGER NOT NULL
);
-- CONSTRAINTS:
ALTER TABLE LA_CARD ADD FOREIGN KEY(CARD_BOARD_COLUMN_ID_FK) REFERENCES LA_BOARD_COLUMN(BOARD_COLUMN_ID);
ALTER TABLE LA_CARD ADD FOREIGN KEY(CARD_USER_ID_FK) REFERENCES LA_USER(USER_ID);
ALTER TABLE LA_CARD ADD FOREIGN KEY(CARD_LAST_UPDATED_USER_ID_FK) REFERENCES LA_USER(USER_ID);
-- INDEXES
CREATE INDEX "CARD_BOARD_COLUMN_ID_FK_IDX" ON LA_CARD(CARD_BOARD_COLUMN_ID_FK);
CREATE INDEX "CARD_USER_ID_FK_IDX" ON LA_CARD(CARD_USER_ID_FK);
CREATE INDEX "CARD_LAST_UPDATED_USER_ID_FK_IDX" ON LA_CARD(CARD_LAST_UPDATED_USER_ID_FK);
-- TRIGGER:

CREATE FUNCTION la_card_vector_update() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.CARD_NAME_TSVECTOR = to_tsvector('pg_catalog.english', unaccent(NEW.CARD_NAME));
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.CARD_NAME <> OLD.CARD_NAME THEN
            NEW.CARD_NAME_TSVECTOR = to_tsvector('pg_catalog.english', unaccent(NEW.CARD_NAME));
        END IF;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER LA_CARD_NAME_INSERT_OR_UPDATE BEFORE INSERT OR UPDATE ON LA_CARD
	FOR EACH ROW EXECUTE PROCEDURE la_card_vector_update();
-- INDEX:
CREATE INDEX LA_CARD_NAME_TSVECTOR_IDX ON LA_CARD USING GIN(CARD_NAME_TSVECTOR);

CREATE TABLE LA_CARD_DATA (
	CARD_DATA_ID SERIAL PRIMARY KEY NOT NULL,
	CARD_DATA_CARD_ID_FK INTEGER NOT NULL,
	CARD_DATA_REFERENCE_ID INTEGER,
	CARD_DATA_DELETED BOOLEAN DEFAULT FALSE NOT NULL,
	CARD_DATA_TYPE VARCHAR(128) NOT NULL,
	CARD_DATA_CONTENT TEXT NOT NULL,
	CARD_DATA_CONTENT_TSVECTOR TSVECTOR NOT NULL,
	CARD_DATA_ORDER INTEGER NOT NULL
);
-- CONSTRAINTS:
ALTER TABLE LA_CARD_DATA ADD FOREIGN KEY(CARD_DATA_CARD_ID_FK) REFERENCES LA_CARD(CARD_ID);
ALTER TABLE LA_CARD_DATA ADD FOREIGN KEY(CARD_DATA_REFERENCE_ID) REFERENCES LA_CARD_DATA(CARD_DATA_ID);
ALTER TABLE LA_CARD_DATA ADD CONSTRAINT "CARD_DATA_TYPE_VALUE" CHECK(CARD_DATA_TYPE IN ('COMMENT', 'ACTION_LIST', 'ACTION_CHECKED', 'ACTION_UNCHECKED', 'FILE', 'COMMENT_HISTORY', 'DESCRIPTION', 'DESCRIPTION_HISTORY'));
ALTER TABLE LA_CARD_DATA ADD CONSTRAINT "CARD_DATA_ENSURE_REFERENCE_ID" CHECK(
CASE
	WHEN CARD_DATA_TYPE IN ('COMMENT','ACTION_LIST', 'DESCRIPTION') THEN CARD_DATA_REFERENCE_ID IS NULL
	WHEN CARD_DATA_TYPE IN ('ACTION_CHECKED', 'ACTION_UNCHECKED', 'COMMENT_HISTORY', 'DESCRIPTION_HISTORY') THEN CARD_DATA_REFERENCE_ID IS NOT NULL
	ELSE TRUE
END);
-- INDEXES
CREATE INDEX "CARD_DATA_CARD_ID_FK_IDX" ON LA_CARD_DATA(CARD_DATA_CARD_ID_FK);
CREATE INDEX "CARD_DATA_REFERENCE_ID_IDX" ON LA_CARD_DATA(CARD_DATA_REFERENCE_ID);
-- TRIGGER:

CREATE FUNCTION la_card_data_vector_update() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.CARD_DATA_CONTENT_TSVECTOR = to_tsvector('pg_catalog.english', unaccent(NEW.CARD_DATA_CONTENT));
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF NEW.CARD_DATA_CONTENT <> OLD.CARD_DATA_CONTENT THEN
            NEW.CARD_DATA_CONTENT_TSVECTOR = to_tsvector('pg_catalog.english', unaccent(NEW.CARD_DATA_CONTENT));
        END IF;
    END IF;
    RETURN NEW;
END
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER LA_CARD_DATA_INSERT_OR_UPDATE BEFORE INSERT OR UPDATE ON LA_CARD_DATA
	FOR EACH ROW EXECUTE PROCEDURE la_card_data_vector_update();
-- INDEX:
CREATE INDEX LA_CARD_DATA_CONTENT_TSVECTOR_IDX ON LA_CARD_DATA USING GIN(CARD_DATA_CONTENT_TSVECTOR);

-- DATA UPLOAD
CREATE TABLE LA_CARD_DATA_UPLOAD_CONTENT (
	DIGEST CHAR(64) NOT NULL,
	SIZE INTEGER NOT NULL,
	CONTENT BYTEA NOT NULL,
	CONTENT_TYPE VARCHAR(255) NOT NULL
);
ALTER TABLE LA_CARD_DATA_UPLOAD_CONTENT ADD CONSTRAINT "UNIQUE_LA_CARD_UPLOAD_CONTENT" UNIQUE(DIGEST);

CREATE TABLE LA_CARD_DATA_UPLOAD (
	CARD_DATA_ID_FK INTEGER NOT NULL,
	CARD_DATA_UPLOAD_CONTENT_DIGEST_FK CHAR(64) NOT NULL,
	ORIGINAL_NAME VARCHAR(255) NOT NULL,
	DISPLAYED_NAME VARCHAR(255) NOT NULL
);
ALTER TABLE LA_CARD_DATA_UPLOAD ADD FOREIGN KEY(CARD_DATA_ID_FK) REFERENCES LA_CARD_DATA(CARD_DATA_ID);
ALTER TABLE LA_CARD_DATA_UPLOAD ADD FOREIGN KEY(CARD_DATA_UPLOAD_CONTENT_DIGEST_FK) REFERENCES LA_CARD_DATA_UPLOAD_CONTENT(DIGEST);
-- INDEXES
CREATE INDEX "CARD_DATA_UPLOAD_CONTENT_DIGEST_FK_IDX" ON LA_CARD_DATA_UPLOAD(CARD_DATA_UPLOAD_CONTENT_DIGEST_FK);

-- CARD LABEL
CREATE TABLE LA_CARD_LABEL (
	CARD_LABEL_ID SERIAL PRIMARY KEY NOT NULL,
	CARD_LABEL_PROJECT_ID_FK INTEGER NOT NULL,
	CARD_LABEL_UNIQUE BOOLEAN DEFAULT FALSE NOT NULL,
	CARD_LABEL_TYPE VARCHAR(16) NOT NULL,
	CARD_LABEL_DOMAIN VARCHAR(16) NOT NULL,
	CARD_LABEL_NAME VARCHAR(32) NOT NULL,
	CARD_LABEL_COLOR INTEGER
);
ALTER TABLE LA_CARD_LABEL ADD CONSTRAINT "CARD_LABEL_TYPE_VALUE" CHECK(CARD_LABEL_TYPE IN ('NULL', 'STRING', 'TIMESTAMP', 'INT', 'CARD', 'USER', 'LIST'));
ALTER TABLE LA_CARD_LABEL ADD CONSTRAINT "CARD_LABEL_DOMAIN_VALUE" CHECK(CARD_LABEL_DOMAIN IN ('SYSTEM', 'USER'));
ALTER TABLE LA_CARD_LABEL ADD FOREIGN KEY(CARD_LABEL_PROJECT_ID_FK) REFERENCES LA_PROJECT(PROJECT_ID);
ALTER TABLE LA_CARD_LABEL ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_PROJECT_ID_FK_NAME" UNIQUE(CARD_LABEL_PROJECT_ID_FK, CARD_LABEL_NAME);
-- INDEXES
CREATE INDEX "CARD_LABEL_PROJECT_ID_FK_IDX" ON LA_CARD_LABEL(CARD_LABEL_PROJECT_ID_FK);

-- junction table label <-> list values
CREATE TABLE LA_CARD_LABEL_LIST_VALUE (
	CARD_LABEL_LIST_VALUE_ID SERIAL PRIMARY KEY NOT NULL,
	CARD_LABEL_ID_FK INTEGER NOT NULL,
    CARD_LABEL_LIST_VALUE_ORDER INTEGER NOT NULL,
	CARD_LABEL_LIST_VALUE VARCHAR(255)
);
ALTER TABLE LA_CARD_LABEL_LIST_VALUE ADD FOREIGN KEY(CARD_LABEL_ID_FK) REFERENCES LA_CARD_LABEL(CARD_LABEL_ID);
-- INDEXES
CREATE INDEX "LA_CARD_LABEL_LIST_VALUE_CARD_LABEL_ID_FK_IDX" ON LA_CARD_LABEL_LIST_VALUE(CARD_LABEL_ID_FK);
--

-- junction table label <-> card and card value
CREATE TABLE LA_CARD_LABEL_VALUE (
	CARD_LABEL_VALUE_ID SERIAL PRIMARY KEY NOT NULL,
	CARD_LABEL_VALUE_USE_UNIQUE_INDEX BOOLEAN DEFAULT NULL,
	CARD_LABEL_VALUE_DELETED BOOLEAN DEFAULT FALSE NOT NULL,
	CARD_ID_FK INTEGER NOT NULL,
	CARD_LABEL_ID_FK INTEGER NOT NULL,
	CARD_LABEL_VALUE_TYPE VARCHAR(16) NOT NULL,
	CARD_LABEL_VALUE_STRING VARCHAR(32),
	CARD_LABEL_VALUE_TIMESTAMP TIMESTAMP,
	CARD_LABEL_VALUE_INT INTEGER,
	CARD_LABEL_VALUE_CARD_FK INTEGER,
	CARD_LABEL_VALUE_USER_FK INTEGER,
	CARD_LABEL_VALUE_LIST_VALUE_FK INTEGER
);
ALTER TABLE LA_CARD_LABEL_VALUE ADD FOREIGN KEY(CARD_ID_FK) REFERENCES LA_CARD(CARD_ID);
ALTER TABLE LA_CARD_LABEL_VALUE ADD FOREIGN KEY(CARD_LABEL_ID_FK) REFERENCES LA_CARD_LABEL(CARD_LABEL_ID);
ALTER TABLE LA_CARD_LABEL_VALUE ADD FOREIGN KEY(CARD_LABEL_VALUE_CARD_FK) REFERENCES LA_CARD(CARD_ID);
ALTER TABLE LA_CARD_LABEL_VALUE ADD FOREIGN KEY(CARD_LABEL_VALUE_USER_FK) REFERENCES LA_USER(USER_ID);
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "CARD_LABEL_VALUE_TYPE_VALUE" CHECK(CARD_LABEL_VALUE_TYPE IN ('NULL', 'STRING', 'TIMESTAMP', 'INT', 'CARD', 'USER', 'LIST'));
--
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_VALUE_STRING" UNIQUE(CARD_ID_FK, CARD_LABEL_ID_FK, CARD_LABEL_VALUE_TYPE, CARD_LABEL_VALUE_STRING);
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_VALUE_CARD_FK" UNIQUE(CARD_ID_FK, CARD_LABEL_ID_FK, CARD_LABEL_VALUE_TYPE, CARD_LABEL_VALUE_CARD_FK);
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_VALUE_USER_FK" UNIQUE(CARD_ID_FK, CARD_LABEL_ID_FK, CARD_LABEL_VALUE_TYPE, CARD_LABEL_VALUE_USER_FK);
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_VALUE_LIST_VALUE_FK" UNIQUE(CARD_ID_FK, CARD_LABEL_ID_FK, CARD_LABEL_VALUE_TYPE, CARD_LABEL_VALUE_LIST_VALUE_FK);
ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "UNIQUE_LA_CARD_LABEL_VALUE_USE_UNIQUE_INDEX" UNIQUE(CARD_ID_FK, CARD_LABEL_ID_FK, CARD_LABEL_VALUE_USE_UNIQUE_INDEX);
--

ALTER TABLE LA_CARD_LABEL_VALUE ADD CONSTRAINT "CARD_LABEL_VALUE_ENSURE_TYPE" CHECK(
CASE
	WHEN CARD_LABEL_VALUE_TYPE = 'NULL' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'STRING' THEN
		CARD_LABEL_VALUE_STRING 	IS NOT NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'TIMESTAMP' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NOT NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'INT' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NOT NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'CARD' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NOT NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'USER' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_USER_FK	IS NOT NULL AND
        CARD_LABEL_VALUE_LIST_VALUE_FK	IS NULL
	WHEN CARD_LABEL_VALUE_TYPE = 'LIST' THEN
		CARD_LABEL_VALUE_STRING 	IS NULL AND
		CARD_LABEL_VALUE_TIMESTAMP 	IS NULL AND
		CARD_LABEL_VALUE_INT 		IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_CARD_FK	IS NULL AND
		CARD_LABEL_VALUE_LIST_VALUE_FK	IS NOT NULL
END);
-- INDEXES
CREATE INDEX "LA_CARD_LABEL_VALUE_CARD_ID_FK_IDX" ON LA_CARD_LABEL_VALUE(CARD_ID_FK);
CREATE INDEX "LA_CARD_LABEL_VALUE_CARD_LABEL_ID_FK_IDX" ON LA_CARD_LABEL_VALUE(CARD_LABEL_ID_FK);

-- EVENT
CREATE TABLE LA_EVENT (
	EVENT_ID SERIAL PRIMARY KEY NOT NULL,
	EVENT_CARD_ID_FK INTEGER NOT NULL,
	EVENT_USER_ID_FK INTEGER NOT NULL,
	EVENT_TYPE VARCHAR(32) NOT NULL,
	EVENT_TIME TIMESTAMP NOT NULL,
	EVENT_CARD_DATA_ID_FK INTEGER,
	EVENT_PREV_CARD_DATA_ID_FK INTEGER,
	EVENT_NEW_CARD_DATA_ID_FK INTEGER,
	EVENT_COLUMN_ID_FK INTEGER,
	EVENT_PREV_COLUMN_ID_FK INTEGER,
	EVENT_LABEL_NAME VARCHAR(32),
	EVENT_LABEL_TYPE VARCHAR(16) DEFAULT 'NULL' NOT NULL,
	EVENT_VALUE_INT INTEGER,
	EVENT_VALUE_STRING VARCHAR(255) NULL,
	EVENT_VALUE_TIMESTAMP TIMESTAMP NULL,
	EVENT_VALUE_CARD_FK INTEGER NULL,
	EVENT_VALUE_USER_FK INTEGER NULL
);
-- CONSTRAINTS;
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_CARD_ID_FK) REFERENCES LA_CARD(CARD_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_USER_ID_FK) REFERENCES LA_USER(USER_ID);
ALTER TABLE LA_EVENT ADD CONSTRAINT "EVENT_TYPE_VALUE" CHECK(EVENT_TYPE IN ('LABEL_CREATE', 'LABEL_DELETE', 'CARD_MOVE', 'CARD_CREATE', 'CARD_ARCHIVE', 'CARD_BACKLOG', 'CARD_TRASH', 'CARD_UPDATE', 'ACTION_LIST_CREATE', 'ACTION_LIST_DELETE',	'ACTION_ITEM_CREATE', 'ACTION_ITEM_DELETE', 'ACTION_ITEM_MOVE', 'ACTION_ITEM_CHECK', 'ACTION_ITEM_UNCHECK', 'COMMENT_CREATE', 'COMMENT_UPDATE', 'COMMENT_DELETE', 'FILE_UPLOAD', 'FILE_DELETE', 'DESCRIPTION_CREATE', 'DESCRIPTION_UPDATE'));
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_COLUMN_ID_FK) REFERENCES LA_BOARD_COLUMN(BOARD_COLUMN_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_PREV_COLUMN_ID_FK) REFERENCES LA_BOARD_COLUMN(BOARD_COLUMN_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_CARD_DATA_ID_FK) REFERENCES LA_CARD_DATA(CARD_DATA_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_PREV_CARD_DATA_ID_FK) REFERENCES LA_CARD_DATA(CARD_DATA_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_NEW_CARD_DATA_ID_FK) REFERENCES LA_CARD_DATA(CARD_DATA_ID);
ALTER TABLE LA_EVENT ADD CONSTRAINT "EVENT_LABEL_TYPE_VALUE" CHECK(EVENT_LABEL_TYPE IN ('NULL', 'STRING', 'TIMESTAMP', 'INT', 'CARD', 'USER'));
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_VALUE_CARD_FK) REFERENCES LA_CARD(CARD_ID);
ALTER TABLE LA_EVENT ADD FOREIGN KEY(EVENT_VALUE_USER_FK) REFERENCES LA_USER(USER_ID);


--ROLE+PERMISSION
CREATE TABLE LA_ROLE (
	ROLE_ID SERIAL PRIMARY KEY NOT NULL,
	ROLE_NAME VARCHAR(32) NOT NULL,
	ROLE_REMOVABLE BOOLEAN NOT NULL,
	ROLE_HIDDEN BOOLEAN DEFAULT FALSE NOT NULL,
	ROLE_READONLY BOOLEAN DEFAULT FALSE NOT NULL
);
ALTER TABLE LA_ROLE ADD CONSTRAINT "UNIQUE_LA_ROLE_ROLE_NAME" UNIQUE(ROLE_NAME);


-- table role <-> permission
CREATE TABLE LA_ROLE_PERMISSION (
	ROLE_ID_FK INTEGER NOT NULL,
	PERMISSION VARCHAR(64) NOT NULL
);
ALTER TABLE LA_ROLE_PERMISSION ADD FOREIGN KEY(ROLE_ID_FK) REFERENCES LA_ROLE(ROLE_ID);
ALTER TABLE LA_ROLE_PERMISSION ADD CONSTRAINT "UNIQUE_LA_ROLE_PERMISSION" UNIQUE(ROLE_ID_FK, PERMISSION);

-- junction table user <-> role for base role
CREATE TABLE LA_USER_ROLE (
	USER_ID_FK INTEGER NOT NULL,
	ROLE_ID_FK INTEGER NOT NULL
);
ALTER TABLE LA_USER_ROLE ADD FOREIGN KEY(USER_ID_FK) REFERENCES LA_USER(USER_ID);
ALTER TABLE LA_USER_ROLE ADD FOREIGN KEY(ROLE_ID_FK) REFERENCES LA_ROLE(ROLE_ID);
ALTER TABLE LA_USER_ROLE ADD CONSTRAINT "UNIQUE_LA_USER_ROLE" UNIQUE(USER_ID_FK, ROLE_ID_FK);


-- PROJECTS and PROJECT ROLE HANDLING

CREATE TABLE LA_PROJECT_ROLE (
	PROJECT_ROLE_ID SERIAL PRIMARY KEY NOT NULL,
	PROJECT_ROLE_NAME VARCHAR(32) NOT NULL,
	PROJECT_ID_FK INTEGER NOT NULL,
	PROJECT_ROLE_REMOVABLE BOOLEAN DEFAULT TRUE NOT NULL,
	PROJECT_ROLE_HIDDEN BOOLEAN DEFAULT FALSE NOT NULL,
	PROJECT_ROLE_READONLY BOOLEAN DEFAULT FALSE NOT NULL
);
ALTER TABLE LA_PROJECT_ROLE ADD CONSTRAINT "UNIQUE_LA_PROJECT_ROLE_NAME" UNIQUE(PROJECT_ID_FK, PROJECT_ROLE_NAME);
ALTER TABLE LA_PROJECT_ROLE ADD FOREIGN KEY(PROJECT_ID_FK) REFERENCES LA_PROJECT(PROJECT_ID);

CREATE TABLE LA_PROJECT_ROLE_PERMISSION (
	PROJECT_ROLE_ID_FK INTEGER NOT NULL,
	PERMISSION VARCHAR(64) NOT NULL
);
ALTER TABLE LA_PROJECT_ROLE_PERMISSION ADD FOREIGN KEY(PROJECT_ROLE_ID_FK) REFERENCES LA_PROJECT_ROLE(PROJECT_ROLE_ID);
ALTER TABLE LA_PROJECT_ROLE_PERMISSION ADD CONSTRAINT "UNIQUE_LA_PROJECT_ROLE_PERMISSION" UNIQUE(PROJECT_ROLE_ID_FK, PERMISSION);


-- junction table project <-> user <-> role
CREATE TABLE LA_PROJECT_USER_ROLE (
	PROJECT_ID_FK INTEGER NOT NULL,
	USER_ID_FK INTEGER NOT NULL,
	PROJECT_ROLE_ID_FK INTEGER NOT NULL
);
ALTER TABLE LA_PROJECT_USER_ROLE ADD FOREIGN KEY(PROJECT_ID_FK) REFERENCES LA_PROJECT(PROJECT_ID);
ALTER TABLE LA_PROJECT_USER_ROLE ADD FOREIGN KEY(USER_ID_FK) REFERENCES LA_USER(USER_ID);
ALTER TABLE LA_PROJECT_USER_ROLE ADD FOREIGN KEY(PROJECT_ROLE_ID_FK) REFERENCES LA_PROJECT_ROLE(PROJECT_ROLE_ID);
ALTER TABLE LA_PROJECT_USER_ROLE ADD CONSTRAINT "UNIQUE_LA_PROJECT_USER_ROLE" UNIQUE(PROJECT_ID_FK, USER_ID_FK, PROJECT_ROLE_ID_FK);

--

-- TRIGGERS FOR TIME STATS
CREATE FUNCTION la_card_update_last_updated() RETURNS trigger AS $$
    BEGIN
    	UPDATE LA_CARD SET CARD_LAST_UPDATED = NEW.EVENT_TIME, CARD_LAST_UPDATED_USER_ID_FK = NEW.EVENT_USER_ID_FK WHERE CARD_ID = NEW.EVENT_CARD_ID_FK;
    	RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION la_card_update_last_deleted() RETURNS trigger AS $$
    BEGIN
    	UPDATE LA_CARD SET CARD_LAST_UPDATED = NOW(), CARD_LAST_UPDATED_USER_ID_FK = OLD.EVENT_USER_ID_FK WHERE CARD_ID = OLD.EVENT_CARD_ID_FK;
    	RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRIG_CARD_TIME_STATS_INS AFTER INSERT ON LA_EVENT
	FOR EACH ROW EXECUTE PROCEDURE la_card_update_last_updated();

CREATE TRIGGER TRIG_CARD_TIME_STATS_DEL AFTER DELETE ON LA_EVENT
   	FOR EACH ROW EXECUTE PROCEDURE la_card_update_last_deleted();

-- VIEWS
CREATE VIEW LA_CARD_WITH_BOARD_ID AS (
	SELECT CARD_ID, CARD_NAME, CARD_BOARD_COLUMN_ID_FK, CARD_ORDER, CARD_USER_ID_FK, CARD_SEQ_NUMBER, BOARD_COLUMN_BOARD_ID_FK AS BOARD_ID, BOARD_COLUMN_LOCATION
	FROM LA_CARD INNER JOIN LA_BOARD_COLUMN ON LA_BOARD_COLUMN.BOARD_COLUMN_ID = LA_CARD.CARD_BOARD_COLUMN_ID_FK);

CREATE VIEW LA_CARD_DATA_FULL AS (
	SELECT CARD_DATA_ID, CARD_DATA_CARD_ID_FK, CARD_DATA_REFERENCE_ID, CARD_DATA_TYPE, CARD_DATA_CONTENT, CARD_DATA_ORDER, CARD_DATA_DELETED, EVENT_TIME, EVENT_TYPE, EVENT_PREV_CARD_DATA_ID_FK, EVENT_USER_ID_FK
	FROM LA_CARD_DATA INNER JOIN LA_EVENT ON LA_CARD_DATA.CARD_DATA_ID = LA_EVENT.EVENT_CARD_DATA_ID_FK);

CREATE VIEW LA_CARD_DATA_COUNT AS (
	SELECT BOARD_ID, CARD_ID, CARD_BOARD_COLUMN_ID_FK,CARD_DATA_TYPE,  COUNT(CARD_DATA_TYPE) AS CARD_DATA_TYPE_COUNT FROM LA_CARD_WITH_BOARD_ID  INNER JOIN LA_CARD_DATA ON LA_CARD_DATA.CARD_DATA_CARD_ID_FK = CARD_ID
	WHERE CARD_DATA_DELETED = FALSE
	GROUP BY BOARD_ID, CARD_ID, CARD_BOARD_COLUMN_ID_FK, CARD_DATA_TYPE
);


CREATE VIEW LA_CARD_DATA_UPLOAD_CONTENT_LIGHT AS (
	SELECT EVENT_USER_ID_FK, EVENT_TIME, CARD_DATA_ID, CARD_DATA_CARD_ID_FK, CARD_DATA_REFERENCE_ID, CARD_DATA_CONTENT, CARD_DATA_DELETED, DISPLAYED_NAME, SIZE, CONTENT_TYPE
	FROM LA_CARD_DATA INNER JOIN LA_CARD_DATA_UPLOAD ON LA_CARD_DATA.CARD_DATA_ID = LA_CARD_DATA_UPLOAD.CARD_DATA_ID_FK
	INNER JOIN LA_CARD_DATA_UPLOAD_CONTENT ON LA_CARD_DATA_UPLOAD.CARD_DATA_UPLOAD_CONTENT_DIGEST_FK = LA_CARD_DATA_UPLOAD_CONTENT.DIGEST
	INNER JOIN LA_EVENT ON EVENT_CARD_DATA_ID_FK = CARD_DATA_ID
	WHERE CARD_DATA_TYPE = 'FILE' AND EVENT_TYPE = 'FILE_UPLOAD' AND CARD_DATA_DELETED = FALSE);

CREATE VIEW LA_CARD_FULL AS (
	SELECT LA_CARD.CARD_ID AS CARD_ID, LA_CARD.CARD_NAME AS CARD_NAME, LA_CARD.CARD_SEQ_NUMBER AS CARD_SEQ_NUMBER, LA_CARD.CARD_BOARD_COLUMN_ID_FK AS CARD_BOARD_COLUMN_ID_FK, LA_CARD.CARD_ORDER AS CARD_ORDER, LA_EVENT.EVENT_TIME AS CREATE_TIME, LA_EVENT.EVENT_USER_ID_FK AS CREATE_USER,
	LA_CARD.CARD_LAST_UPDATED AS LAST_UPDATE_TIME, LA_CARD.CARD_LAST_UPDATED_USER_ID_FK AS LAST_UPDATE_USER, PROJECT_SHORT_NAME, PROJECT_ID, BOARD_SHORT_NAME, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_LOCATION FROM LA_CARD
	INNER JOIN LA_EVENT ON LA_CARD.CARD_ID = LA_EVENT.EVENT_CARD_ID_FK AND LA_EVENT.EVENT_TYPE = 'CARD_CREATE'
	INNER JOIN LA_BOARD_COLUMN ON LA_BOARD_COLUMN.BOARD_COLUMN_ID = LA_CARD.CARD_BOARD_COLUMN_ID_FK
	INNER JOIN LA_BOARD ON LA_BOARD_COLUMN.BOARD_COLUMN_BOARD_ID_FK = LA_BOARD.BOARD_ID
	INNER JOIN LA_PROJECT ON LA_PROJECT.PROJECT_ID = LA_BOARD.BOARD_PROJECT_ID_FK
	INNER JOIN LA_BOARD_COLUMN_DEFINITION ON LA_BOARD_COLUMN.BOARD_COLUMN_DEFINITION_ID_FK = LA_BOARD_COLUMN_DEFINITION.BOARD_COLUMN_DEFINITION_ID);

CREATE VIEW LA_ASSIGNED_CARD AS (
	SELECT LA_CARD.CARD_ID AS ASSIGNED_CARD_ID, LA_CARD.CARD_LAST_UPDATED AS ASSIGNED_EVENT_TIME, CARD_LABEL_VALUE_USER_FK AS ASSIGNED_USER_ID, BOARD_COLUMN_DEFINITION_VALUE AS ASSIGNED_CARD_STATUS FROM LA_CARD
	INNER JOIN LA_CARD_LABEL_VALUE ON LA_CARD_LABEL_VALUE.CARD_ID_FK = LA_CARD.CARD_ID
	INNER JOIN LA_CARD_LABEL ON LA_CARD_LABEL.CARD_LABEL_ID = LA_CARD_LABEL_VALUE.CARD_LABEL_ID_FK
	INNER JOIN LA_BOARD_COLUMN ON LA_BOARD_COLUMN.BOARD_COLUMN_ID = LA_CARD.CARD_BOARD_COLUMN_ID_FK
	INNER JOIN LA_BOARD_COLUMN_DEFINITION ON LA_BOARD_COLUMN.BOARD_COLUMN_DEFINITION_ID_FK = LA_BOARD_COLUMN_DEFINITION.BOARD_COLUMN_DEFINITION_ID
	WHERE LA_CARD_LABEL.CARD_LABEL_DOMAIN = 'SYSTEM' AND LA_CARD_LABEL.CARD_LABEL_NAME = 'ASSIGNED'
	AND LA_CARD_LABEL_VALUE.CARD_LABEL_VALUE_DELETED = FALSE
);

CREATE VIEW LA_ASSIGNED_CARD_PROJECT AS (
	SELECT LA_CARD.CARD_ID AS ASSIGNED_CARD_ID, LA_CARD.CARD_LAST_UPDATED AS ASSIGNED_EVENT_TIME, CARD_LABEL_VALUE_USER_FK AS ASSIGNED_USER_ID, BOARD_COLUMN_DEFINITION_VALUE AS ASSIGNED_CARD_STATUS, LA_PROJECT.PROJECT_SHORT_NAME AS ASSIGNED_PROJECT_SHORT_NAME FROM LA_CARD
	INNER JOIN LA_CARD_LABEL_VALUE ON LA_CARD_LABEL_VALUE.CARD_ID_FK = LA_CARD.CARD_ID
	INNER JOIN LA_CARD_LABEL ON LA_CARD_LABEL.CARD_LABEL_ID = LA_CARD_LABEL_VALUE.CARD_LABEL_ID_FK
	INNER JOIN LA_BOARD_COLUMN ON LA_BOARD_COLUMN.BOARD_COLUMN_ID = LA_CARD.CARD_BOARD_COLUMN_ID_FK
	INNER JOIN LA_BOARD_COLUMN_DEFINITION ON LA_BOARD_COLUMN.BOARD_COLUMN_DEFINITION_ID_FK = LA_BOARD_COLUMN_DEFINITION.BOARD_COLUMN_DEFINITION_ID
	INNER JOIN LA_PROJECT ON LA_BOARD_COLUMN_DEFINITION.BOARD_COLUMN_DEFINITION_PROJECT_ID_FK = LA_PROJECT.PROJECT_ID
	WHERE LA_CARD_LABEL.CARD_LABEL_DOMAIN = 'SYSTEM' AND LA_CARD_LABEL.CARD_LABEL_NAME = 'ASSIGNED'
	AND LA_CARD_LABEL_VALUE.CARD_LABEL_VALUE_DELETED = FALSE
);

CREATE VIEW LA_BOARD_COLUMN_INFO AS (
	SELECT PROJECT_ID, PROJECT_NAME, BOARD_ID, BOARD_NAME, BOARD_SHORT_NAME, BOARD_COLUMN_ID, BOARD_COLUMN_NAME, BOARD_COLUMN_LOCATION, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR
    FROM LA_BOARD_COLUMN INNER JOIN LA_BOARD ON BOARD_COLUMN_BOARD_ID_FK = BOARD_ID
    INNER JOIN LA_PROJECT ON BOARD_PROJECT_ID_FK = PROJECT_ID
    INNER JOIN LA_BOARD_COLUMN_DEFINITION ON BOARD_COLUMN_DEFINITION_ID = BOARD_COLUMN_DEFINITION_ID_FK
);

CREATE VIEW LA_BOARD_COLUMN_FULL AS (
	SELECT BOARD_COLUMN_ID, BOARD_COLUMN_NAME, BOARD_COLUMN_ORDER, BOARD_COLUMN_LOCATION, BOARD_COLUMN_BOARD_ID_FK, BOARD_COLUMN_DEFINITION_ID, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR
	FROM LA_BOARD_COLUMN INNER JOIN LA_BOARD_COLUMN_DEFINITION ON BOARD_COLUMN_DEFINITION_ID_FK = BOARD_COLUMN_DEFINITION_ID
);



-- DEFAULT DATA
-- ANONYMOUS USER DEFAULT ROLES AND PERMISSION
INSERT INTO LA_USER(USER_PROVIDER, USER_NAME) VALUES ('system', 'anonymous');
INSERT INTO LA_ROLE(ROLE_NAME, ROLE_REMOVABLE, ROLE_HIDDEN, ROLE_READONLY) VALUES('ANONYMOUS', FALSE, TRUE, TRUE);
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ANONYMOUS'), 'READ');
-- ADMIN AND DEFAULT ROLES AND PERMISSION
INSERT INTO LA_ROLE(ROLE_NAME, ROLE_REMOVABLE, ROLE_HIDDEN, ROLE_READONLY) VALUES('ADMIN', FALSE, FALSE, TRUE);
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'ADMINISTRATION');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'SEARCH');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_PROFILE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'PROJECT_ADMINISTRATION');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_PROJECT');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_BOARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_BOARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_BOARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_COLUMN');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'RENAME_COLUMN');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'MOVE_COLUMN');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'MOVE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_CARD_COMMENT');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'READ');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_CARD_COMMENT');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_CARD_COMMENT');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'TOGGLE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'MOVE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'ORDER_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'MANAGE_LABEL_VALUE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'CREATE_FILE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'DELETE_FILE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'ADMIN'), 'UPDATE_FILE');


INSERT INTO LA_ROLE(ROLE_NAME, ROLE_REMOVABLE) VALUES('DEFAULT', FALSE);
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'READ');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'SEARCH');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'UPDATE_PROFILE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'UPDATE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'MOVE_CARD');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'DELETE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'UPDATE_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'DELETE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'TOGGLE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'UPDATE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'MOVE_ACTION_LIST_ITEM');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'ORDER_ACTION_LIST');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_FILE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'UPDATE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'DELETE_LABEL');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'MANAGE_LABEL_VALUE');
INSERT INTO LA_ROLE_PERMISSION(ROLE_ID_FK, PERMISSION) VALUES
	((SELECT ROLE_ID FROM LA_ROLE WHERE ROLE_NAME = 'DEFAULT'), 'CREATE_CARD_COMMENT');

-- DEFAULT PROJECT
--
INSERT INTO LA_PROJECT(PROJECT_NAME, PROJECT_SHORT_NAME) VALUES ('Default','DEFAULT');
-- DEFAULT ANON ROLE
INSERT INTO LA_PROJECT_ROLE(PROJECT_ROLE_NAME, PROJECT_ID_FK, PROJECT_ROLE_HIDDEN, PROJECT_ROLE_READONLY, PROJECT_ROLE_REMOVABLE) VALUES('ANONYMOUS', (SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), TRUE, TRUE, FALSE);
INSERT INTO LA_PROJECT_ROLE_PERMISSION(PROJECT_ROLE_ID_FK, PERMISSION) VALUES (LASTVAL(), 'READ');
-- DEFAULT LABELS FOR Default PROJECT
INSERT INTO LA_CARD_LABEL(CARD_LABEL_PROJECT_ID_FK, CARD_LABEL_UNIQUE, CARD_LABEL_TYPE, CARD_LABEL_DOMAIN, CARD_LABEL_NAME, CARD_LABEL_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), FALSE, 'USER', 'SYSTEM', 'ASSIGNED', 0);
INSERT INTO LA_CARD_LABEL(CARD_LABEL_PROJECT_ID_FK, CARD_LABEL_UNIQUE, CARD_LABEL_TYPE, CARD_LABEL_DOMAIN, CARD_LABEL_NAME, CARD_LABEL_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), TRUE, 'TIMESTAMP', 'SYSTEM', 'DUE_DATE', 0);
INSERT INTO LA_CARD_LABEL(CARD_LABEL_PROJECT_ID_FK, CARD_LABEL_UNIQUE, CARD_LABEL_TYPE, CARD_LABEL_DOMAIN, CARD_LABEL_NAME, CARD_LABEL_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), TRUE, 'LIST', 'SYSTEM', 'MILESTONE', 0);
INSERT INTO LA_CARD_LABEL_LIST_VALUE(CARD_LABEL_ID_FK, CARD_LABEL_LIST_VALUE_ORDER,CARD_LABEL_LIST_VALUE) VALUES ((SELECT CARD_LABEL_ID FROM LA_CARD_LABEL WHERE CARD_LABEL_NAME = 'MILESTONE' AND CARD_LABEL_PROJECT_ID_FK = (SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT')), 0, 'Unplanned');
INSERT INTO LA_CARD_LABEL(CARD_LABEL_PROJECT_ID_FK, CARD_LABEL_UNIQUE, CARD_LABEL_TYPE, CARD_LABEL_DOMAIN, CARD_LABEL_NAME, CARD_LABEL_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), FALSE, 'USER', 'SYSTEM', 'WATCHED_BY', 0);
--DEFAULT COLUMN DEFINITION FOR Default PROJECT
INSERT INTO LA_BOARD_COLUMN_DEFINITION (BOARD_COLUMN_DEFINITION_PROJECT_ID_FK, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), 'OPEN', 14242639);
INSERT INTO LA_BOARD_COLUMN_DEFINITION (BOARD_COLUMN_DEFINITION_PROJECT_ID_FK, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), 'CLOSED', 6076508);
INSERT INTO LA_BOARD_COLUMN_DEFINITION (BOARD_COLUMN_DEFINITION_PROJECT_ID_FK, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), 'BACKLOG', 4361162);
INSERT INTO LA_BOARD_COLUMN_DEFINITION (BOARD_COLUMN_DEFINITION_PROJECT_ID_FK, BOARD_COLUMN_DEFINITION_VALUE, BOARD_COLUMN_DEFINITION_COLOR) VALUES ((SELECT PROJECT_ID FROM LA_PROJECT WHERE PROJECT_SHORT_NAME = 'DEFAULT'), 'DEFERRED', 15773006);