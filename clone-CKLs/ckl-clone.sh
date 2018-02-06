if [ $# -eq 0 ]; then
    echo "Script requires two arguments: ./clone-ckls.sh <comps> <golden>"
    echo "   <comps> is a list of hostnames"
    echo "   <golden> is a folder containing the files"
    exit 1
fi

comps="$1"
golden="$2"

mkdir results

< $comps xargs -I% bash -c 'mkdir ./results/% && cp -r ./'"$golden"'/* ./results/%'
< $comps xargs -IcurrentHost bash -c 'find ./results/currentHost -iname "*$golden*" -exec rename '"$golden"' currentHost {} \;'
< $comps xargs -IcurrentHost bash -c 'find ./results/currentHost -type f -exec sed -i 's/"$golden"/'currentHost'/' {} \;'
