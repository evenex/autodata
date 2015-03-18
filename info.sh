HEADER="--autodata--"
echo "$HEADER"
echo ""
./info/info

DASHES=$(seq 2 $(echo "$HEADER" | wc -c))

PENDING_FIXES=$(grep -rn '\<FIXME\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13  | wc -l)
if [ "$PENDING_FIXES" -gt "0" ]
then
	if [ "$PENDING_FIXES" -eq "1" ]
	then
		TITLE="$PENDING_FIXES PENDING FIX:"
	else
		TITLE="$PENDING_FIXES PENDING FIXES:"
	fi
	DASHES=$(seq 2 $(echo $TITLE | wc -c))

	printf '=%0.s' $DASHES
	echo ""
	echo $TITLE
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<FIXME\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d  '\t'
fi
BUGS=$(grep -rn '\<BUG\>' ./source/ | grep -v OUTSIDE | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$BUGS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$BUGS" -eq "1" ]
	then
		TITLE="$BUGS BUG:"
	else
		TITLE="$BUGS BUGS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<BUG\>' ./source/ | grep -v OUTSIDE | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
OUTSIDE_BUGS=$(grep -rn '\<OUTSIDE BUG\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$OUTSIDE_BUGS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$OUTSIDE_BUGS" -eq "1" ]
	then
		TITLE="$OUTSIDE_BUGS OUTSIDE BUG:"
	else
		TITLE="$OUTSIDE_BUGS OUTSIDE BUGS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<OUTSIDE BUG\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
PENDING_TASKS=$(grep -rn '\<TODO\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$PENDING_TASKS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$PENDING_TASKS" -eq "1" ]
	then
		TITLE="$PENDING_TASKS PENDING TASK:"
	else
		TITLE="$PENDING_TASKS PENDING TASKS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<TODO\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
PENDING_REFACTORS=$(grep -rn '\<REFACTOR\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$PENDING_REFACTORS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$PENDING_REFACTORS" -eq "1" ]
	then
		TITLE="$PENDING_REFACTORS PENDING REFACTOR:"
	else
		TITLE="$PENDING_REFACTORS PENDING REFACTORS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<REFACTOR\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
PENDING_REVIEWS=$(grep -rn '\<REVIEW\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$PENDING_REVIEWS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$PENDING_REVIEWS" -eq "1" ]
	then
		TITLE="$PENDING_REVIEWS PENDING REVIEW:"
	else
		TITLE="$PENDING_REVIEWS PENDING REVIEWS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<REVIEW\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
MARKED_LINES=$(grep -rn '\<XXX\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$MARKED_LINES" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$MARKED_LINES" -eq "1" ]
	then
		TITLE="$MARKED_LINES MARKED LINE:"
	else
		TITLE="$MARKED_LINES MARKED LINES:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<XXX\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
HACKS=$(grep -rn '\<HACK\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$HACKS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$HACKS" -eq "1" ]
	then
		TITLE="$HACKS HACK:"
	else
		TITLE="$HACKS HACKS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<HACK\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
TEMPORARY_SECTIONS=$(grep -rn '\<TEMP\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | wc -l)
if [ "$TEMPORARY_SECTIONS" -gt "0" ]
then
	printf '=%0.s' $DASHES
	echo ""
	if [ "$TEMPORARY_SECTIONS" -eq "1" ]
	then
		TITLE="$TEMPORARY_SECTIONS TEMPORARY SECTION:"
	else
		TITLE="$TEMPORARY_SECTIONS TEMPORARY SECTIONS:"
	fi
	echo $TITLE
	DASHES=$(seq 2 $(echo $TITLE | wc -c))
	printf '=%0.s' $DASHES
	echo ""
	grep -rn '\<TEMP\>' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'
fi
printf '=%0.s' $DASHES
echo "
MAIN LOCATED AT:"
grep -rn '^\s*void\s*main\s*()' ./source/ | grep -v Binary | grep -v freetype-gl | grep -v ode[-]0[.]13 | tr -d '\t'


DASHES=$(seq 2 $(echo "$HEADER" | wc -c))
printf '=%0.s' $DASHES
echo ""
