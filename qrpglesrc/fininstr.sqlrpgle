**free
//==================================================================
// Program: FININSTR
// Description: Financial Instruments Dictionary Maintenance
//==================================================================
ctl-opt dftactgrp(*no) actgrp(*new) option(*srcstmt:*nodebugio)
        main(Main);

//------------------------------------------------------------------
// Display File
//------------------------------------------------------------------
dcl-f FININSTD workstn sfile(LISTSFL:SFLRRN) indds(indicators)
                        usropn;

//------------------------------------------------------------------
// Indicator Data Structure
//------------------------------------------------------------------
dcl-ds indicators qualified;
  exit        ind pos(3);
  add         ind pos(6);
  cancel      ind pos(12);
  pageUp      ind pos(25);
  pageDown    ind pos(26);
  sflDsp      ind pos(31);
  sflDspCtl   ind pos(32);
  sflClr      ind pos(33);
  sflEnd      ind pos(34);
  msgSflEnd   ind pos(35);
  protectIsin ind pos(41);
  errIsin     ind pos(51);
  errShrtNam  ind pos(52);
  errIssuer   ind pos(53);
  errIssueDt  ind pos(54);
  errCountry  ind pos(55);
  errCurrency ind pos(56);
  errIssueSz  ind pos(57);
end-ds;

//------------------------------------------------------------------
// Data Structures
//------------------------------------------------------------------
dcl-ds instrument qualified;
  isin      char(12);
  shortName char(35);
  issuer    char(50);
  issueDate date;
  country   char(2);
  currency  char(3);
  issueSize packed(15:2);
end-ds;

//------------------------------------------------------------------
// Constants
//------------------------------------------------------------------
dcl-c PAGE_SIZE 12;
dcl-c MODE_ADD  'A';
dcl-c MODE_EDIT 'E';

//------------------------------------------------------------------
// Global Variables
//------------------------------------------------------------------
dcl-s gRunning   ind inz(*on);
dcl-s gTopIsin   char(12);
dcl-s gLastRRN   int(10);

//------------------------------------------------------------------
// Prototypes
//------------------------------------------------------------------
dcl-pr Main extpgm('FININSTR') end-pr;
dcl-pr LoadSubfile end-pr;
dcl-pr ProcessOptions end-pr;
dcl-pr AddInstrument end-pr;
dcl-pr EditInstrument end-pr;
dcl-pr DeleteInstrument end-pr;
dcl-pr ViewInstrument end-pr;
dcl-pr ClearSubfile end-pr;
dcl-pr ShowDetailWindow ind end-pr;
dcl-pr ShowConfirmWindow ind end-pr;
dcl-pr ShowViewWindow end-pr;
dcl-pr ValidateInput ind end-pr;
dcl-pr InsertRecord ind end-pr;
dcl-pr UpdateRecord ind end-pr;
dcl-pr DeleteRecord ind end-pr;
dcl-pr ReadRecord ind end-pr;
dcl-pr FormatDate char(10) end-pr;
dcl-pr ParseDate date end-pr;
dcl-pr SendMsg;
  msgId char(7) const;
end-pr;
dcl-pr ClearMsg end-pr;

//==================================================================
// Main Procedure
//==================================================================
dcl-proc Main;

  open FININSTD;
  gTopIsin = *blanks;

  LoadSubfile();

  dow gRunning;
    indicators.sflDsp = (gLastRRN > 0);
    indicators.sflDspCtl = *on;

    write LISTFTR;
    write MSGCTL;
    exfmt LISTCTL;

    ClearMsg();

    select;
      when indicators.exit;
        gRunning = *off;

      when indicators.add;
        AddInstrument();
        LoadSubfile();

      when indicators.pageUp or indicators.pageDown;
        // Handled by subfile paging

      other;
        ProcessOptions();
    endsl;
  enddo;

  close FININSTD;
  *inlr = *on;

end-proc;

//==================================================================
// Load Subfile
//==================================================================
dcl-proc LoadSubfile;

  dcl-s recCount int(10);

  ClearSubfile();

  exec sql declare instCursor cursor for
    select FIISIN, FISHRTNAM, FIISSUER, FIISSUEDT, FICOUNTRY, FICURRENCY
    from FININST
    where FIISIN >= :gTopIsin
    order by FIISIN;

  exec sql open instCursor;

  exec sql fetch next from instCursor
    into :SFISIN, :SFSHRTNAM, :SFISSUER, :instrument.issueDate,
         :SFCOUNTRY, :SFCURRCY;

  dow sqlcode = 0 and recCount < 9999;
    recCount += 1;
    SFLRRN = recCount;
    SFOPT = ' ';
    SFSHRTNAM = %subst(SFSHRTNAM:1:20);
    SFISSUER = %subst(SFISSUER:1:20);
    SFISSUEDT = %char(instrument.issueDate:*iso);
    write LISTSFL;

    exec sql fetch next from instCursor
      into :SFISIN, :SFSHRTNAM, :SFISSUER, :instrument.issueDate,
           :SFCOUNTRY, :SFCURRCY;
  enddo;

  exec sql close instCursor;

  gLastRRN = recCount;
  indicators.sflEnd = *on;

end-proc;

//==================================================================
// Process Options
//==================================================================
dcl-proc ProcessOptions;

  dcl-s rrn int(10);

  for rrn = 1 to gLastRRN;
    SFLRRN = rrn;
    chain SFLRRN LISTSFL;

    if SFOPT <> ' ';
      instrument.isin = SFISIN;

      select;
        when SFOPT = '2';
          EditInstrument();

        when SFOPT = '4';
          DeleteInstrument();

        when SFOPT = '5';
          ViewInstrument();
      endsl;

      SFOPT = ' ';
      update LISTSFL;
      LoadSubfile();
      leave;
    endif;
  endfor;

end-proc;

//==================================================================
// Add Instrument
//==================================================================
dcl-proc AddInstrument;

  dcl-s confirmed ind;

  DMODE = MODE_ADD;
  DFISIN = *blanks;
  DFSHRTNAM = *blanks;
  DFISSUER = *blanks;
  DFISSUEDT = %char(%date():*iso);
  DFCOUNTRY = *blanks;
  DFCURRCY = *blanks;
  DFISSUESZ = 0;

  indicators.protectIsin = *off;

  confirmed = ShowDetailWindow();

  if confirmed;
    if InsertRecord();
      SendMsg('INF0001');
    else;
      SendMsg('ERR0002');
    endif;
  endif;

end-proc;

//==================================================================
// Edit Instrument
//==================================================================
dcl-proc EditInstrument;

  dcl-s confirmed ind;

  if not ReadRecord();
    SendMsg('ERR0001');
    return;
  endif;

  DMODE = MODE_EDIT;
  DFISIN = instrument.isin;
  DFSHRTNAM = instrument.shortName;
  DFISSUER = instrument.issuer;
  DFISSUEDT = %char(instrument.issueDate:*iso);
  DFCOUNTRY = instrument.country;
  DFCURRCY = instrument.currency;
  DFISSUESZ = instrument.issueSize;

  indicators.protectIsin = *on;

  confirmed = ShowDetailWindow();

  if confirmed;
    if UpdateRecord();
      SendMsg('INF0002');
    else;
      SendMsg('ERR0003');
    endif;
  endif;

end-proc;

//==================================================================
// Delete Instrument
//==================================================================
dcl-proc DeleteInstrument;

  dcl-s confirmed ind;

  CFISIN = instrument.isin;

  confirmed = ShowConfirmWindow();

  if confirmed;
    if DeleteRecord();
      SendMsg('INF0003');
    else;
      SendMsg('ERR0004');
    endif;
  endif;

end-proc;

//==================================================================
// View Instrument
//==================================================================
dcl-proc ViewInstrument;

  if not ReadRecord();
    SendMsg('ERR0001');
    return;
  endif;

  VFISIN = instrument.isin;
  VFSHRTNAM = instrument.shortName;
  VFISSUER = instrument.issuer;
  VFISSUEDT = %char(instrument.issueDate:*iso);
  VFCOUNTRY = instrument.country;
  VFCURRCY = instrument.currency;
  VFISSUESZ = instrument.issueSize;

  ShowViewWindow();

end-proc;

//==================================================================
// Clear Subfile
//==================================================================
dcl-proc ClearSubfile;

  indicators.sflClr = *on;
  indicators.sflDspCtl = *on;
  write LISTCTL;
  indicators.sflClr = *off;

end-proc;

//==================================================================
// Show Detail Window
//==================================================================
dcl-proc ShowDetailWindow;

  dcl-pi *n ind end-pi;
  dcl-s done ind inz(*off);
  dcl-s confirmed ind inz(*off);

  dow not done;
    exfmt DETAILW;

    select;
      when indicators.exit or indicators.cancel;
        done = *on;
        confirmed = *off;

      other;
        if ValidateInput();
          done = *on;
          confirmed = *on;
        endif;
    endsl;
  enddo;

  // Clear error indicators
  indicators.errIsin = *off;
  indicators.errShrtNam = *off;
  indicators.errIssuer = *off;
  indicators.errIssueDt = *off;
  indicators.errCountry = *off;
  indicators.errCurrency = *off;
  indicators.errIssueSz = *off;

  return confirmed;

end-proc;

//==================================================================
// Show Confirm Window
//==================================================================
dcl-proc ShowConfirmWindow;

  dcl-pi *n ind end-pi;

  exfmt CONFIRMW;

  if indicators.exit or indicators.cancel;
    return *off;
  endif;

  return *on;

end-proc;

//==================================================================
// Show View Window
//==================================================================
dcl-proc ShowViewWindow;

  exfmt VIEWW;

end-proc;

//==================================================================
// Validate Input
//==================================================================
dcl-proc ValidateInput;

  dcl-pi *n ind end-pi;
  dcl-s valid ind inz(*on);
  dcl-s testDate date;

  // Clear error indicators
  indicators.errIsin = *off;
  indicators.errShrtNam = *off;
  indicators.errIssuer = *off;
  indicators.errIssueDt = *off;
  indicators.errCountry = *off;
  indicators.errCurrency = *off;
  indicators.errIssueSz = *off;

  // Validate ISIN
  if %trim(DFISIN) = *blanks;
    indicators.errIsin = *on;
    valid = *off;
  endif;

  // Validate Short Name
  if %trim(DFSHRTNAM) = *blanks;
    indicators.errShrtNam = *on;
    valid = *off;
  endif;

  // Validate Issuer
  if %trim(DFISSUER) = *blanks;
    indicators.errIssuer = *on;
    valid = *off;
  endif;

  // Validate Date format
  monitor;
    testDate = %date(DFISSUEDT:*iso);
  on-error;
    indicators.errIssueDt = *on;
    valid = *off;
  endmon;

  // Validate Country
  if %len(%trim(DFCOUNTRY)) <> 2;
    indicators.errCountry = *on;
    valid = *off;
  endif;

  // Validate Currency
  if %len(%trim(DFCURRCY)) <> 3;
    indicators.errCurrency = *on;
    valid = *off;
  endif;

  return valid;

end-proc;

//==================================================================
// Insert Record
//==================================================================
dcl-proc InsertRecord;

  dcl-pi *n ind end-pi;

  instrument.isin = DFISIN;
  instrument.shortName = DFSHRTNAM;
  instrument.issuer = DFISSUER;
  instrument.issueDate = %date(DFISSUEDT:*iso);
  instrument.country = DFCOUNTRY;
  instrument.currency = DFCURRCY;
  instrument.issueSize = DFISSUESZ;

  exec sql insert into FININST
    (FIISIN, FISHRTNAM, FIISSUER, FIISSUEDT, FICOUNTRY, FICURRENCY, FIISSUESZ)
    values (:instrument.isin, :instrument.shortName, :instrument.issuer,
            :instrument.issueDate, :instrument.country, :instrument.currency,
            :instrument.issueSize);

  return (sqlcode = 0);

end-proc;

//==================================================================
// Update Record
//==================================================================
dcl-proc UpdateRecord;

  dcl-pi *n ind end-pi;

  instrument.shortName = DFSHRTNAM;
  instrument.issuer = DFISSUER;
  instrument.issueDate = %date(DFISSUEDT:*iso);
  instrument.country = DFCOUNTRY;
  instrument.currency = DFCURRCY;
  instrument.issueSize = DFISSUESZ;

  exec sql update FININST
    set FISHRTNAM = :instrument.shortName,
        FIISSUER = :instrument.issuer,
        FIISSUEDT = :instrument.issueDate,
        FICOUNTRY = :instrument.country,
        FICURRENCY = :instrument.currency,
        FIISSUESZ = :instrument.issueSize
    where FIISIN = :instrument.isin;

  return (sqlcode = 0);

end-proc;

//==================================================================
// Delete Record
//==================================================================
dcl-proc DeleteRecord;

  dcl-pi *n ind end-pi;

  exec sql delete from FININST
    where FIISIN = :instrument.isin;

  return (sqlcode = 0);

end-proc;

//==================================================================
// Read Record
//==================================================================
dcl-proc ReadRecord;

  dcl-pi *n ind end-pi;

  exec sql select FIISIN, FISHRTNAM, FIISSUER, FIISSUEDT,
                  FICOUNTRY, FICURRENCY, FIISSUESZ
    into :instrument.isin, :instrument.shortName, :instrument.issuer,
         :instrument.issueDate, :instrument.country, :instrument.currency,
         :instrument.issueSize
    from FININST
    where FIISIN = :instrument.isin;

  return (sqlcode = 0);

end-proc;

//==================================================================
// Send Message
//==================================================================
dcl-proc SendMsg;

  dcl-pi *n;
    msgId char(7) const;
  end-pi;

  dcl-pr QMHSNDPM extpgm('QMHSNDPM');
    msgId      char(7)    const;
    msgFile    char(20)   const;
    msgData    char(256)  const;
    msgDataLen int(10)    const;
    msgType    char(10)   const;
    callStack  char(10)   const;
    stackEntry int(10)    const;
    msgKey     char(4);
    errorCode  char(256);
  end-pr;

  dcl-s msgKey char(4);
  dcl-s errorCode char(256) inz(*allx'00');

  QMHSNDPM(msgId:'FININSTMF IBMIAI1   ':' ':0:'*INFO':'*':0:msgKey:errorCode);

end-proc;

//==================================================================
// Clear Messages
//==================================================================
dcl-proc ClearMsg;

  dcl-pr QMHRMVPM extpgm('QMHRMVPM');
    callStack  char(10)   const;
    stackEntry int(10)    const;
    msgKey     char(4)    const;
    msgRmv     char(10)   const;
    errorCode  char(256);
  end-pr;

  dcl-s errorCode char(256) inz(*allx'00');

  QMHRMVPM('*':0:'    ':'*ALL':errorCode);

end-proc;
