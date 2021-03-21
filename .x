execute(){
	dvc repro
}
case "$1" in
	c)
		#dvc add result{1,2,3,4}/dat
		dvc push
		acommit
	;;
	e)
		vi -p params.yaml [0-9]-*
		execute
	;;
	"")
		execute
	;;
esac
