# IBMi-AI

An application for maintaining a dictionary of financial instruments

The financial instruments dictionary has the following attributes:
* ISIN code – uniquely identifies the instrument
* instrument short name
* issuer name
* issue date
* country of issue
* issue currency
* issue size

The financial instruments dictionary is stored in a database.

## Program

A program running in the 5250 terminal is available for browsing. It presents the list of instruments in a subfile format. The list is sorted by ISIN code. The following columns are displayed in the list:
* ISIN code
* instrument short name
* issuer name
* issue date
* country of issue
* issue currency

The user can browse the list by scrolling down and up using PgUp and PgDn.

## Options

The following **actions** are available in the program:
* F3=Exit – Exit the program
* F6=Add – Create a new instrument in the dictionary

For each selected item in the list, the following **options** are available:
* 2=Edit – Edit the instrument in the dictionary, without the ability to change the ISIN code
* 4=Delete – Remove the instrument from the dictionary
* 5=Details – Display all details of the instrument

Information about the list of available **actions** is displayed in the line below the list of instruments. Information about the list of available **options** is displayed in the line above the list of instruments.

## Infrastructure

* Server: IBM Power
* System: IBM i 7.5
* Database: IBM DB2 for IBM i
