-- Financial Instruments Dictionary Table
-- Table: FININST

CREATE OR REPLACE TABLE FININST (
    FIISIN       CHAR(12)      NOT NULL WITH DEFAULT '',
    FISHRTNAM    CHAR(35)      NOT NULL WITH DEFAULT '',
    FIISSUER     CHAR(50)      NOT NULL WITH DEFAULT '',
    FIISSUEDT    DATE          NOT NULL WITH DEFAULT CURRENT_DATE,
    FICOUNTRY    CHAR(2)       NOT NULL WITH DEFAULT '',
    FICURRENCY   CHAR(3)       NOT NULL WITH DEFAULT '',
    FIISSUESZ    NUMERIC(15, 2) NOT NULL DEFAULT 0,
    PRIMARY KEY (FIISIN)
);

LABEL ON TABLE FININST IS 'Financial Instruments Dictionary';

LABEL ON COLUMN FININST (
    FIISIN     IS 'ISIN Code',
    FISHRTNAM  IS 'Short Name',
    FIISSUER   IS 'Issuer Name',
    FIISSUEDT  IS 'Issue Date',
    FICOUNTRY  IS 'Country',
    FICURRENCY IS 'Currency',
    FIISSUESZ  IS 'Issue Size'
);

LABEL ON COLUMN FININST (
    FIISIN     TEXT IS 'ISIN Code - Unique Identifier',
    FISHRTNAM  TEXT IS 'Instrument Short Name',
    FIISSUER   TEXT IS 'Issuer Name',
    FIISSUEDT  TEXT IS 'Issue Date',
    FICOUNTRY  TEXT IS 'Country of Issue (ISO 2-letter)',
    FICURRENCY TEXT IS 'Issue Currency (ISO 3-letter)',
    FIISSUESZ  TEXT IS 'Issue Size in Currency'
);
