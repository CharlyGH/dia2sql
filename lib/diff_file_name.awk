BEGIN {
}

/./ {
    oldfile = $1;
    newfile = $2;

    oldparts = split(oldfile, oldtab, "_");    
    newparts = split(newfile, newtab, "_");    

    if (oldparts != newparts) {
        print "file names " oldfile " and " newfile " have different structure" >"/dev/stderr";
        exit 1;
    }
    for (idx = 1; idx <= oldparts; idx++) {
        if (oldtab[idx] != newtab[idx]) {
            commonparts = idx - 1;
            break;
        }
    }
    if (commonparts == 0) {
        print "file names " oldfile " and " newfile " don't have common prefix" >"/dev/stderr";
        exit 1;
    }
    
    output = oldfile;

    for (idx = commonparts + 1; idx <= newparts; idx++) {
        output = output "_" newtab[idx];
    }
    print output
}

END {
}
