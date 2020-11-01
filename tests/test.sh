var=5
var2=7
echo $var
for i in $(seq 1 1 "$var")
do
	echo "test $i "
	sleep $var2
done
