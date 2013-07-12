#!/bin/sh

. ./test-db-config.sh
. ./test-db-funcs.sh


FIND=/usr/bin/find
PERL=/usr/bin/perl

if [ $CREATETESTDB = 1 ] ; then

echo "Creating test environment for LittleORM"

admin_dbcommand "CREATE USER ${TESTDBUSER}"
assert $?

admin_dbcommand "ALTER USER ${TESTDBUSER} WITH PASSWORD '${TESTDBPASS}'"
assert $?


admin_dbcommand "CREATE DATABASE ${TESTDBNAME} OWNER=${TESTDBUSER}"
assert $?

# db created, fill it

echo
echo - DB CREATED, FILLING -------------------------------------------
echo

user_dbcommand "\i ./test-db-fill.sql"
assert $?

fi

# db created and filled

echo
echo - DB FILLED, RUNNING SCRIPTS ------------------------------------
echo


cd scripts/run/
assert $?

STATUS_CODE=0
for ORM_TEST_SCRIPT in $( $FIND . -type f -name '*.pl' ) ; do

echo ${ORM_TEST_SCRIPT}
$PERL ${ORM_TEST_SCRIPT}
STATUS_CODE=$(($STATUS_CODE+$?))

done

# outta here


if [ $STATUS_CODE != 0 ] ; then
echo
echo - THERE WERE ERRORS! --------------------------------------------
echo
fi

if [ $DROPTESTDB = 1 ] ; then

echo
echo - SCRIPTS RUN COMPLETED, CLEANUP --------------------------------
echo


admin_dbcommand "DROP DATABASE ${TESTDBNAME}"
assert $?

admin_dbcommand "DROP USER ${TESTDBUSER}"
assert $?

fi

echo "Normal exit"

