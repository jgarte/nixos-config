if [ -z $1 ]; then
    echo "Dockerfile missing"
    exit 1
fi

# TODO: add options such as help displaying
# TODO: templatize yaml config (in nix)
# see github for all the references
@dockerBinary@ run --rm -i -v $(realpath $1):/tmp/Dockerfile hadolint/hadolint hadolint /tmp/Dockerfile