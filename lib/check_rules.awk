function find_index(table, element, maxidx,      idx) {
    for (idx = 1; idx < maxidx; idx++) {
        if (table[idx] == element) {
            return idx;
        }
    }
    return 0;
}



function find_successors(source,     successors, target_strg, target_tab, count, idx, target, src, succ) {
    target_strg = successor_tab[source];
    if (target_strg == "") {
        successors = source
    }
    else {
        count = split(target_strg, target_tab, "#")
        for (idx = 1; idx <= count; idx++) {
            target = target_tab[idx];
            if (successors == "") {
                successors = find_successors(target);
            }
            else {
                successors = successors "|" find_successors(target);
            }
        }
    }
    return successors;
}


function contains (tab, el,     idx) {
    for (idx in tab) {
        if (tab[idx] == el) {
            return 1;
        }
    }
    return 0;
}


function unique(raw_tab, unique_tab,      sidx, tidx, el) {
    tidx = 0;
    for (sidx in raw_tab) {
        el = raw_tab[idx];
        if (! contains(unique_tab, el)) {
            unique_tab[++tidx] = el;
        }
    }
}


function to_string(tab, delim,     idx, el, strg) {
    for (idx in tab) {
        el = tab[idx];
        if (strg == "") {
            strg = el;
        }
        else {
            strg = strg delim el;
        }
    }
    return strg;
}


function occurs(tab, src_el,   idx, tgt_el, res) {
    res = 0;
    for (idx in tab) {
        tgt_el = tab[idx];
        if (tgt_el == src_el) {
            res++;
        }
    }
    return res;
}


BEGIN {
    in_table_list        = 0;
    table_name           = "";
    const_table_count    = 0;
    dim_table_count      = 0;
    fact_table_count     = 0;
    const_column_count   = 0;
    dim_column_count     = 0;
    fact_column_count    = 0;
    error_count          = 0;
    in_references_list   = 0; 
}


# rule 11: check tablenames: no duplicate table names allowed
# rule 21: table name must be defined in Const, Dim- or Fact-schema 
# rule 22: redundant table kind definitions must match
# rule 23: table kind must be Const, Dim or Fact
# rule 31: column definition must be inside table definition
# rule 32: no column name should match valid_from or valid_to
# rule 41: primary key definition must be inside table definition
# rule 42: primary key for const or dim table must be single column
# rule 43: primary key for const dim table must be of type Id_Type
# rule 44: primary key for const dim tables must be unique in model
# rule 51: check position of references
# rule 61: check position of foreign
# rule 71: all tables must have primary key
# rule 81: column names must be unique in all const and dim tables of model
# rule 82: all tables for schema Const must be defined
# rule 83: all tables for schema Dim must be defined
# rule 84: all tables for schema Fact must be defined


/^schema#/ {
    table_kind = $2;
    table_list = $3;

    if ((table_kind != "Const") && (table_kind != "Dim") && (table_kind != "Fact")) {
        next
    }
    cnt = split(table_list, table_tab, ",");
    table_kind_count[table_kind] = cnt
    
    for (idx = 1; idx <= cnt; idx++) {
        tab_name = table_tab[idx];
        kind = table_kind_tab[tab_name];
        # rule 11
        rule_count[11] = 1;
        if (kind != "") {
            error_count++;
            msg = FNR ": duplicate tablename ["  tab_name "]";
            error_table[error_count] = msg;
        }
        table_kind_tab[tab_name] = table_kind;
    }
}

/^tables/ {
    in_table_list = 1;
}



/^table#/ {
    table_id   = $2;
    table_name = $3;
    table_kind = $4;

    kind = table_kind_tab[table_name];
    table_id_tab[table_id] = table_name;

    # rule 21
    rule_count[21] = 1;
    if (kind == "") {
        error_count++;
        msg = FNR ": table ["  table_name "] is not in table_kind_tab";
        error_table[error_count] = msg;
    }

    # rule 22
    rule_count[22] = 1;
    if (kind != table_kind) {
        error_count++;
        msg = FNR ": table kind for [" table_name "], expected [" kind "] but [" table_kind "] was found";
        error_table[error_count] = msg;
    }

    # rule 23
    rule_count[23] = 1;
    if (table_kind == "Const") {
        const_table_count++;
    } else if (table_kind == "Dim") {
        dim_table_count++;
    } else if (table_kind == "Fact") {
        fact_table_count++;
    } else {
        error_count++;
        msg = FNR ": unknown table kind [" table_kind "] for table [" table_name "]";
        error_table[error_count] = msg;
    }
}


/^column#/ {
    column_name = $2;
    column_type = $3;

    # rule 31
    rule_count[31] = 1;
    if (table_name == "") {
        error_count++;
        msg = FNR ": column definition outside table definition";
        error_table[error_count] = msg;
    }

    # rule 32
    rule_count[32] = 1;
    if ((column_name == valid_from) || (column_name == valid_to)) {
        error_count++;
        msg = FNR ": column name should no be [" valid_from "] or [" valid_to "]";
        error_table[error_count] = msg;
    }
    
    if (table_kind == "Const") {
        const_column_count++;
        const_column_tab[const_column_count] = column_name;
        const_table_tab[const_column_count]  = table_name;
        const_type_tab[column_name]   = column_type;
    } else if (table_kind == "Dim") {
        dim_column_count++;
        dim_column_tab[dim_column_count] = column_name;
        dim_table_tab[dim_column_count]  = table_name;
        dim_type_tab[column_name]   = column_type;
    } else if (table_kind == "Fact") {
        fact_column_count++;
        fact_column_tab[fact_column_count] = column_name;
        fact_table_tab[fact_column_count]  = table_name;
    }
}


/^primary#/ {
    primary_key = $2;

    # rule 41
    rule_count[41] = 1;
    if (table_name == "") {
        error_count++;
        msg = FNR ": primary key definition outside table definition";
        error_table[error_count] = msg;
    }
    cnt = split(primary_key,pk_tab,",");
    if (table_kind == "Const") {
        # rule 42
        rule_count[42] = 1;
        if (cnt > 1) {
            error_count++;
            msg = FNR ": multi column primary key for [" table_kind "] table [" table_name "]";
            error_table[error_count] = msg;
        }

        column_type = const_type_tab[primary_key]
        # rule 43
        rule_count[43] = 1;
        if (column_type != "Id_Type") {
            error_count++;
            msg = FNR ": type of pk [" primary_key "] for [" table_name "] is [" column_type "], not Id_type";
            error_table[error_count] = msg;
        }
    }
    else if (table_kind == "Dim") {
        # rule 42
        rule_count[42] = 1;
        if (cnt > 1) {
            error_count++;
            msg = FNR ": multi column primary key for [" table_kind "] table [" table_name "]";
            error_table[error_count] = msg;
        }

        column_type = dim_type_tab[primary_key]
        # rule 43
        rule_count[43] = 1;
        if (column_type != "Id_Type") {
            error_count++;
            msg = FNR ": type of pk [" primary_key "] for [" table_name "] is [" column_type "], not Id_type";
            error_table[error_count] = msg;
        }
    }
    else {
        next;
    }

    if (table_kind == "Const") {
        for (idx = 1; idx <= cnt; idx++) {
            pk_column = pk_tab[idx];
            other_table = const_primary_tab[pk_column];
            # rule 44
            rule_count[44] = 1;
            if (other_table != "") {
                error_count++;
                msg = FNR ": column pk_column is primary key for [" other_table "] and [" table_name "]";
                error_table[error_count] = msg;
            }
        }
        const_primary_tab[pk_column] = table_name;
    }
    else if (table_kind == "Dim") {
        for (idx = 1; idx <= cnt; idx++) {
            pk_column = pk_tab[idx];
            other_table = dim_primary_tab[pk_column];
            # rule 44
            rule_count[44] = 1;
            if (other_table != "") {
                error_count++;
                msg = FNR ": column pk_column is primary key for [" other_table "] and [" table_name "]";
                error_table[error_count] = msg;
            }
        }
        dim_primary_tab[pk_column] = table_name;
    }
}



/^references/ {
    # rule 51
    rule_count[51] = 1;
    if (in_table_list) {
        error_count++;
        msg = FNR ": found references inside table definition list";
        error_table[error_count] = msg;
    }
    in_table_list = 0;
    in_references_list = 1; 
}


/^foreign#/ {
    # rule 61
    rule_count[61] = 1;
    if (! in_references_list) {
        error_count++;
        msg = FNR ": found foreign key outdide references list";
        error_table[error_count] = msg;
    }
    source_id = $2;
    target_id = $4;
    source_name =  table_id_tab[source_id];
    target_name =  table_id_tab[target_id];
    successor = successor_tab[source_name]; 
    if (successor == "")
        successor_tab[source_name] = target_name;
    else
        successor_tab[source_name] = successor "#" target_name;
}



/^end/ {
    if ((in_table_list == 1) && (table_name == "")) {
        in_table_list = 0;
    }
    
    # rule 71
    rule_count[71] = 1;
    if ((table_name != "") && (primary_key == "")) {
        error_count++;
        msg = FNR ": table [" table_name "] has no primary key";
        error_table[error_count] = msg;
    }
    primary_key = "";
    table_name = "";

    if (in_references_list) {
        count = asorti(successor_tab, sort_index_tab)
        for (idx = 1; idx <= count; idx++) {
            source = sort_index_tab[idx];
            successor_strg = find_successors(source);
            succ_count = split(successor_strg, succ_tab, "|");
            tidx = 0;
            delete unique_tab;
            for (sidx in succ_tab) {
                el = succ_tab[sidx];
                if (! contains(unique_tab, el)) {
                    unique_tab[++tidx] = el;
                }
            }
            for (sidx in unique_tab) {
                succ = unique_tab[sidx];
                num = occurs(succ_tab, succ);
                # rule 72
                rule_count[72] = 1;
                if (num > 1) {
                    error_count++;
                    msg = FNR ": table [" succ "] occures [" num "] times as successor of [" source "]";
                    error_table[error_count] = msg;
                }
            }
        }
    }
}


END {
    if (verbose) {
        const_msg = "found " const_column_count " column definitions in " const_table_count " const table definitions";
        dim_msg   = "found " dim_column_count " column definitions in " dim_table_count " dim table definitions";
        fact_msg  = "found " fact_column_count " column definitions in " fact_table_count " fact table definitions";
        print const_msg       >"/dev/stderr";
        print dim_msg         >"/dev/stderr";
        print fact_msg        >"/dev/stderr";
    }

    for (column_idx = 1; column_idx < column_count; column_idx++) {
        column_name = dim_column_tab[column_count];
        table_name  = dim_table_tab[column_count];
        fnd_idx = find_index(dim_column_tab, column_name, column_idx);
        # rule 81
        rule_count[81] = 1;
        if (fnd_idx) {
            msg = "found column [" column-name "] in table [" table_name_tab[fnd_idx] "] and [" table_name"]";
            error_table[error_count] = msg;
        }
    }

    # rule 82
    rule_count[82] = 1;
    const_tables_expected = table_kind_count["Const"]
    if (const_table_count != const_tables_expected) {
        error_count++;
        msg = "found [" const_table_count "] table definitions but [" const_tables_expected "] are expected";
        error_table[error_count] =  msg;
    }
    
    # rule 83
    rule_count[82] = 1;
    dim_tables_expected = table_kind_count["Dim"]
    if (dim_table_count != dim_tables_expected) {
        error_count++;
        msg = "found [" dim_table_count "] table definitions but [" dim_tables_expected "] are expected";
        error_table[error_count] = msg;
    }
    
    # rule 84
    rule_count[83] = 1;
    fact_tables_expected = table_kind_count["Fact"]
    if (fact_table_count != fact_tables_expected) {
        error_count++;
        msg = "found [" fact_table_count "] table definitions but [" fact_tables_expected "] are expected";
        error_table[error_count] = msg;
    }

    print length(rule_count) " rules checked, found " error_count " errors"
    if (verbose) {
        for (error_idx = 1; error_idx <= error_count; error_idx++) { 
            print error_table[error_idx]   >"/dev/stderr";
        }
    }
    ret = 0;
    if (error_count > 0) {
        ret = 1;
    }
    exit ret;
}

