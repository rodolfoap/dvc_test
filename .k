case "$1" in
	d)
		git checkout -b local-test-$(date +%Y%m%d.%H%M%S)
		dvc destroy -f
		rm -f metrics.yaml result?/dat* .dvcignore
		git add .; git commit -m "Resetting dvc";
	;;
	"")
		git reset --hard HEAD
		git clean -xdf
		git checkout master
		git reset --hard HEAD
		echo "Use 'k d' to checkout a new branch and delete dvc."
	;;
esac
