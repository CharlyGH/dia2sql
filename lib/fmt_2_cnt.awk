BEGIN {
    first = 1;
    print "select sum(cnt) total";
    print "  from ("
}


/^S#/ {
    schema_name = $2;
}


/^T#/ {
    table_name = $2;
    qualified_table_name = schema_name "." table_name;
    if (first) {
        first = 0;
    }
    else {
        print "        union";
    }
    print "        select '" qualified_table_name "' name, count(*) cnt";
    print "          from "  qualified_table_name

}



END {
    print "    )";
    print ";";
}


