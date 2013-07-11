#!/bin/sh

admin_dbcommand() 
{
COMMAND=$1
$PSQL -U $DBADMIN -c "$COMMAND"
RC=$?
return $RC
}



user_dbcommand() 
{
COMMAND=$1
$PSQL -U $TESTDBUSER -c "$COMMAND" "${TESTDBNAME}"
RC=$?
return $RC
}




assert()
{
if [ $1 != 0 ] ; then
echo "Bad rc: " $1
exit $1
fi
return 0
}

