BEGIN {
    if (((pass == "insert") && (!truncate)) || (pass == "truncate")) {
        print "begin;"
        print "";
    }
}

function format_name(name,    name_tab, cnt, idx, del, part, res) {
    cnt = split(name, name_tab, "_")
    del = "";
    for (idx = 1; idx <= cnt; idx++) {
        part = name_tab[idx];
        res = res del toupper(substr(part,1,1)) substr(part,2);
        if (del == "") {
            del = "_";
        }
    }
    return res;
}



function get_example_value(column, type, check, runid,   ret) {
    if (check != "") {
        ret = check;
    }
    else if ((type == "int") || (type == "bigint")) {
        ret = runid;
    }
    else if (type == "double precision") {
        ret = runid + 0.12;
    }
    else if (type == "text") {
        ret = "'" format_name(column) "-" runid "'";
    }
    else if (type == "character") {
        ret = "'X'";
    }
    else if ((type == "date")) {
        ret = "'31.12." (2000 + runid) "'";
    }
    else {
        print "undefined type [" type "] for column [" column "]";
        exit 1;
    }
    return ret;
}

/^D#/ {
    default_unused = 1;
}

/^R#/ {
    reference_unused = 1;
}

/^S#/ {
    schema = $2;
}


/^T#/ {
    table = $2;
    ccnt  = 0;
    delete col_tab
    delete typ_tab
}


/^C#/ {
    column = $2;
    type   = $3;
    check  = $4;
    col_tab[ccnt]  = column;
    typ_tab[ccnt]  = type;
    chk_tab[ccnt]  = check;
    ccnt++;
}


/^end/ {
    if (truncate && (pass == "truncate")) {
        print "truncate table " schema "." table " cascade;"
        print "";
    }
    deli = "";
    line = "";
    for (cidx = 0; cidx < ccnt; cidx++) {
        column  = col_tab[cidx];
        line    = line deli column;
        if (deli == "") {
            deli = ", "
        }
    }
    name_list = line;
    for (lidx = 0; lidx < lines; lidx++) {
        deli = "";
        line = "";
        for (cidx = 0; cidx < ccnt; cidx++) {
            column  = col_tab[cidx];
            type    = typ_tab[cidx];
            check   = chk_tab[cidx];
            value   = get_example_value(column, type, check, lidx);
            line    = line deli value;
            if (deli == "") {
                deli = ", "
            }
        }
        value_list = line;
        statement = "insert into " schema "." table " (" name_list ") values (" value_list ");"
        if (pass == "insert") {
            print statement;
        }
    }
    if (pass == "insert") {
        print "";
    }
}



END {
    if (pass == "insert") {
        print "commit;"
        print ""
    }
}


