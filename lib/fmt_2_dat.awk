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



function get_example_value(column, type, cons, runid,        ret) {
    if ((type == "integer") || (type == "bigint")) {
        ret = runid;
    }
    else if (type == "double precision") {
        ret = runid + 0.12;
    }
    else if (type == "text") {
        ret = "'" format_name(column) "-" runid "'";
    }
    else if (type == "character") {
        if (cons != "") {
            ret = cons;
        }
        else {
            ret = "'X'";
        }
    }
    else if ((type == "date")) {
        ret = "'31.12." (2000 + runid) "'::date";
    }
    else {
        print "undefined type [" type "] for column [" column "]";
        exit 1;
    }
    return ret;
}


function get_example_expression(column, type, cons,       ret) {
    if ((type == "integer") || (type == "bigint")) {
        ret = "dd.rownum::integer";
    }
    else if (type == "double precision") {
        ret = "dd.rownum::float + 0.123";
    }
    else if (type == "text") {
        ret = "concat('" format_name(column) "-', dd.rownum::text)";
    }
    else if (type == "character") {
        if (cons != "") {
            ret = cons;
        }
        else {
            ret = "'X'";
        }
    }
    else if ((type == "date")) {
        ret = "'31.12.2000'::date + dd.rownum::integer";
    }
    else {
        print "undefined type [" type "] for column [" column "]";
        exit 1;
    }
    return ret;
}


function get_qualified_name_part(qualified_name, num,       cnt, name_tab, res) {
    res = "";
    if (qualified_name != "") {
        cnt = split(qualified_name, name_tab, ":");
        if (cnt != 3) {
            print "invalid qualified name [" qualified_name "]" >"/dev/stderr"
            exit 1;
        }
        res = name_tab[num];
    }
    return res;
}



/^S#/ {
    schema_name = $2;
    schema_kind = $3;
}


/^T#/ {
    table_name = $2;
    reference  = $3;
    ccnt  = 0;
    delete col_name_tab;
    delete col_type_tab;
    delete col_dflt_tab;
    in_table = 1;
}


/^C#/ {
    column_name  = $2;
    column_type  = $3;
    column_dflt  = $4;
    column_cons  = $5;
    column_keys  = $6;
    column_refe  = $7;
    ccnt++;
    col_name_tab[ccnt]  = column_name;
    col_type_tab[ccnt]  = column_type;
    col_dflt_tab[ccnt]  = column_dflt;
    col_cons_tab[ccnt]  = column_cons;
    col_keys_tab[ccnt]  = column_keys;
    col_refe_tab[ccnt]  = column_refe;
}


/^end/ {
    if (in_table == 0) {
        next;
    }
    else {
        in_table = 0;
    }
    if (truncate && (pass == "truncate")) {
        print "truncate table " schema_name "." table_name " cascade;"
        print "";
    }
    deli = "";
    name_list = "";
    for (cidx = 1; cidx <= ccnt; cidx++) {
        column_name  = col_name_tab[cidx];
        column_dflt  = col_dflt_tab[cidx];
        if (column_dflt != "") {
            continue;
        }
        name_list = name_list deli column_name;
        if (deli == "") {
            deli = ", "
        }
    }
    if (reference == "") {
        for (lidx = 1; lidx <= lines; lidx++) {
            deli = "";
            line = "";
            for (cidx = 1; cidx <= ccnt; cidx++) {
                column_name  = col_name_tab[cidx];
                column_type  = col_type_tab[cidx];
                column_dflt  = col_dflt_tab[cidx];
                column_cons  = col_cons_tab[cidx];
                column_refe  = col_refe_tab[cidx];
                if (column_dflt != "") {
                    continue;
                }
                value   = get_example_value(column_name, column_type, column_cons, lidx);
                line    = line deli value;
                if (deli == "") {
                    deli = ", "
                }
            }
            value_list = line;
            statement_p1 = "insert into " schema_name "." table_name " (" name_list ")"
            statement_p2 = "       values (" value_list ");"
            if (pass == "insert") {
                print statement_p1;
                print statement_p2;
                print "";
            }
        }
    }
    else { # reference !
        val_deli = "";
        src_deli = "";
        value_list = "";
        src_tab_list = "";
        src_col_list = "";
        ridx = 0;
        for (cidx = 1; cidx <= ccnt; cidx++) {
            column_name  = col_name_tab[cidx];
            column_type  = col_type_tab[cidx];
            column_dflt  = col_dflt_tab[cidx];
            column_cons  = col_cons_tab[cidx];
            column_refe  = col_refe_tab[cidx];
            if (column_dflt != "") {
                continue;
            }
            if (column_refe != "") {
                ref_schema = get_qualified_name_part(column_refe, 1);
                ref_table  = get_qualified_name_part(column_refe, 2);
                ref_column = get_qualified_name_part(column_refe, 3);
                ridx++;
                dalias = "rt" ridx;
                value =  "dd." ref_column;
                
                src_col = dalias "." ref_column;
                src_col_list = src_col_list src_col ", ";
                
                src_tab =  ref_schema "." ref_table " " dalias;
                src_tab_list = src_tab_list src_deli src_tab
                src_deli = "\n" "       cross join ";
            }
            else {
                value   = get_example_expression(column_name, column_type, column_cons);
            }
            value_list  = value_list val_deli value;
            if (val_deli == "") {
                val_deli = ",\n       ";
            }
        }
        statement_p1 = "insert into " schema_name "." table_name " (" name_list ")"
        statement_p2 = "with source_data as" "\n" "    (select " src_col_list "row_number() over() rownum"
        statement_p3 = "       from " src_tab_list ")"
        statement_p4 = "select " value_list "\n" "  from source_data dd;"
        if (pass == "insert") {
            print statement_p1;
            print statement_p2;
            print statement_p3;
            print statement_p4;
            print "";
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


