
CREATE TABLE LA_LIST_VALUE_METADATA (
	LVM_LABEL_LIST_VALUE_ID_FK INTEGER NOT NULL,
	LVM_KEY VARCHAR(24) NOT NULL,
	LVM_VALUE VARCHAR(255) NOT NULL
);

ALTER TABLE LA_LIST_VALUE_METADATA ADD FOREIGN KEY(LVM_LABEL_LIST_VALUE_ID_FK) REFERENCES LA_CARD_LABEL_LIST_VALUE(CARD_LABEL_LIST_VALUE_ID) ON DELETE CASCADE;
ALTER TABLE LA_LIST_VALUE_METADATA ADD CONSTRAINT UNIQUE_LVM_FK_KEY UNIQUE(LVM_LABEL_LIST_VALUE_ID_FK, LVM_KEY);