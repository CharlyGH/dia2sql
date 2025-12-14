BEGIN {
    in_table_def = 0;
}

/^diagram#/ {
    print $0;
}


/^metadata/ || /^domains/ || /^sequences/ || /^tables/ || /^references/{
    section = $1;
    sec_cnt = 0;
}


/^projekt#/ || /^version#/ || /^check#/ || /^domain#/ || /^sequence#/ {
    sec_cnt++;
    line_tab[sec_cnt] = $0;
}


/^schema#/ {
    sec_cnt++;
    line_tab[sec_cnt] = $0;
    schema_code = $2;
    table_list  = $3;
    cnt = split(table_list, table_tab, ",");
    for (idx = 1; idx <= cnt; idx++) {
        table_name = table_tab[idx];
        table_schema_tab[table_name] = schema_code;
#        print "S:" table_name " --> " schema_code; 
    }
}


/^table#/ {
    id      = $2;
    table   = $3;
    schema  =  table_schema_tab[table];
    full_table_name = schema "#" table;
    full_name_by_id_tab[id] = full_table_name;
    table_info_tab[full_table_name] = $0
    col_cnt = 0;
    in_table_def = 1;
}


/^column#/ {
    col_cnt++;
    col_key = sprintf("%s#%03d", full_table_name, col_cnt);
    col_tab[col_key] = $0;
    tab_size_tab[full_table_name] = col_cnt;
}


/^primary#/ {
    pk_tab[full_table_name] = $0;
}


/^unique#/ {
    uk_tab[full_table_name] = $0;
}


/^foreign#/ {
    src_id = $2;
    tgt_id = $4;
    fk_key = full_name_by_id_tab[src_id] "#" full_name_by_id_tab[tgt_id];
    fk_tab[fk_key] = $0;
}


/^end/ {
    if (!in_table_def) {
        print section;
    }
    if ((section == "metadata") || (section == "domains") || (section == "sequences")) {
        for (sec_idx = 1; sec_idx <= sec_cnt; sec_idx++) {
            print line_tab[sec_idx];
        }
        print "end";
    }
    else if (section == "tables") {
        if (! in_table_def) {
            tab_cnt = asorti(table_info_tab, table_srt_tab);
            for (tab_idx = 1; tab_idx <= tab_cnt; tab_idx++) {
                full_table_name = table_srt_tab[tab_idx];
                print table_info_tab[full_table_name];
                col_cnt = tab_size_tab[full_table_name];
                for (col_idx = 1; col_idx <= col_cnt; col_idx++) {
                    col_key = sprintf("%s#%03d", full_table_name, col_idx);
                    print col_tab[col_key];
                }
                if (uk_tab[full_table_name] != "") {
                    print uk_tab[full_table_name];
                }
                print pk_tab[full_table_name];
                print "end";
            }
            print "end";
        }
    }
    else if (section == "references") {
        fk_cnt = asorti(fk_tab, fk_srt_tab);
        for (fk_idx = 1; fk_idx <= fk_cnt; fk_idx++) {
            print fk_tab[fk_srt_tab[fk_idx]];
        }
        print "end";
    }
    else {
        print "unknown section " section >"/dev/stderr"
    }
    in_table_def = 0;
}



END {
}
