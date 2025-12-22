function format_name(name,    cnt, idx, name_tab, result) {
    cnt = split(name,name_tab,"_");
    delim = ""
    result = ""
    for (idx = 1; idx <= cnt; idx++) {
        part = name_tab[idx];
        result = result delim toupper(substr(part,1,1)) substr(part,2);
        delim = "_";
    }
    return result;
}


function unwrap(text,left,right,    len, llen, lpart, rlen, rpart) {
    len  = length(text);
    llen = length(left);
    lpart = substr(text,1,llen);
    if (lpart != left) {
        print "text [" text "] does not start with [" left "]";
        exit 1;
    }
    rlen = length(right);
    rpart = substr(text,len-(rlen-1),rlen);
    
    if (rpart != right) {
        print "text [" text "] does not end with [" right "]";
        exit 1;
    }
    return substr(text,llen+1,len-llen-rlen);
}


function has_sequence(table,column,seq_tab,seq_cnt,      name, idx) {
    name = "seq_" table "_" column;
    for (idx = 1; idx <= seq_cnt; idx++) {
        if (seq_tab[idx] == name) {
            return name;
        }
    }
    return "";
}


function get_type_size(type,       lpos, rpos, res)
{
    lpos = index(type,"(")
    if (lpos == 0) {
        res = "";
    }
    else {
        rpos = index(type,")");
        if ((rpos == 0) || (rpos < lpos)) {
            print "invalid type format [" type "]";
            exit 1;
        }
        res = substr(type,lpos+1,rpos-lpos-1)
    }
    return res;
}

function get_type_base(type,       lpos, res)
{
    lpos = index(type,"(")
    if (lpos == 0) {
        res = type;
    }
    else {
        res = substr(type,1,lpos-1)
    }
    return res;
}


function contains(array, element,     idx)
{
    for (idx in array) {
        if (array[idx] == element) {
            return 1;
        }
    }
    return 0;
}



BEGIN {
    in_table_def = 1;
    schema_count = 0;
    print "<?xml version='1.0'?>";
    print "<!DOCTYPE model SYSTEM 'model.dtd'>";
}


/^schemaconf#/ {
    kind     = $2;
    schema   = $3;
    writable = $4;

    schema_count++;
    schema_kind_tab[schema_count] = kind;
    schema_name_tab[kind]         = schema;
    schema_comment_tab[kind]      = "Schema für " format_name(kind) "-Daten";
    schema_writable_tab[kind]     = writable;
}
    
    
/^sequenceconf#id-type#/ {
    sequence_id_type = $3;
}

/^sequenceconf#id-max#/ {
    sequence_id_max = $3;
}
    

/^tablespaceconf#/ {
    tablespace_root = $2;
}


/^metadata$/ {
    section      = $1;
}


/^projekt#/ {
    project         = tolower($2);
}


/^version#/ {
    version         = $2;
}


/^check#/ {
    type            = tolower($2);
    expression      = $3;
    check_tab[type] = expression;
}


/^schema#/ {
    kind               = tolower($2);
    table_list         = tolower($3);

    schema_name = schema_name_tab[kind];
    cnt = split(table_list, table_tab, ",");
    for (idx = 1; idx <= cnt; idx++) {
        table                   = table_tab[idx];
        table_schema_tab[table] = schema_name;
    }
}


/^domains$/ {
    domain_count = 0;
    section      = $1;
}


/^domain#/ {
    domain_name                   = tolower($2);
    domain_type                   = tolower($3);
    domain_default                = $4;
    domain_nullable               = $5;
    domain_comment                = $6;
    if (domain_nullable == "") {
        domain_nullable = "NO";
    }
    domain_count++;
    domain_name_tab[domain_count]      = domain_name;
    domain_type_tab[domain_count]      = domain_type;
    domain_default_tab[domain_count]   = domain_default;
    domain_nullable_tab[domain_count]  = domain_nullable;
    domain_comment_tab[domain_count]   = domain_comment;
}



/^sequences$/ {
    sequence_count = 0;
    section = $1;
}

/^sequence#/ {
    sequence_table    = tolower($2);
    sequence_column   = tolower($3);

    sequence_name     = "seq_" sequence_table "_" sequence_column;

    sequence_count++;
    sequence_table_tab[sequence_count]    = sequence_table;
    sequence_column_tab[sequence_count]   = sequence_column;
    sequence_name_tab[sequence_count]     = sequence_name;
    sequence_comment_tab[sequence_count]  = "Sequence für PK der Tabelle " format_name(sequence_table);
}


/^tables$/ {
    section          = $1;
    print "  <tables>";
}



/^table#/ {
    table_id         = $2;
    table_name       = tolower($3);
    table_comment    = $4;
    column_count     = 0;
    id_tab[table_id] = table_name;
    primary_count    = 0;
    unique_count     = 0;
    in_table_def     = 1;
}


/^column#/ {
    column_name                        = tolower($2);
    column_type                        = tolower($3);
    column_default                     = $4;
    column_nullable                    = $5;
    column_comment                     = $6;
    if (column_nullable == "") {
        column_nullable = "NO";
    }
    column_count++;
    column_name_tab[column_count]     = column_name;
    column_type_tab[column_count]     = column_type;
    column_default_tab[column_count]  = column_default;
    column_nullable_tab[column_count] = column_nullable;
    column_comment_tab[column_count]  = column_comment;
}



/^primary#/ {
    primary_list   = tolower($2);
    primary_count  = split(primary_list,primary_tab,",")
    primary_list_tab[table_name] = primary_list;
}


/^unique#/ {
    unique_list   = tolower($2);
    unique_count  = split(unique_list,unique_tab,",")
}


/^references$/ {
    print "  </" section ">";
    section = $1;
    print "  <" section ">";
    foreign_count = 0;
}


/^foreign#/ {
    source_id   = $2;
    source_desc = $3;
    target_id   = $4;
    target_desc = $5;

    foreign_count++;

    source_table                     = id_tab[source_id];
    source_table_tab[foreign_count]  = source_table;
    source_schema_tab[foreign_count] = table_schema_tab[source_table];

    target_table                     = id_tab[target_id];
    target_table_tab[foreign_count]  = target_table
    target_schema_tab[foreign_count] = table_schema_tab[target_table];;
}



/^end/ {
    if (section == "metadata") {
        print "<model project='" project "' version='" version "'>"
        print "  <tablespaces>"
        for (idx = 1; idx <= schema_count; idx++) {
            kind = schema_kind_tab[idx];
            name = schema_name_tab[kind];
            location = tablespace_root "/" name;
            print "    <tablespace name='" name "' action='create'>";
            print "      <location>" location "</location>";
            print "    </tablespace>";
        }
        print "  </tablespaces>"
        print "  <schemas>"
        for (idx  = 1; idx <= schema_count; idx++) {
            kind      = schema_kind_tab[idx];
            name      = schema_name_tab[kind];
            writeable = schema_writable_tab[kind];
            comment   = schema_comment_tab[kind];
            print "    <schema name='" name "' auto='" writeable "' action='create'>";
            print "      <comment>" comment "</comment>";
            print "    </schema>";
        }
        print "  </schemas>";
    }
    else if (section == "domains") {
        domain_schema = table_schema_tab[section];

        print "  <domains>";
        for (idx = 1; idx <= domain_count; idx++) {
            domain_name       = domain_name_tab[idx];
            domain_type       = domain_type_tab[idx];
            domain_size       = get_type_size(domain_type)
            domain_type       = get_type_base(domain_type)
            domain_default    = domain_default_tab[idx]
            domain_nullable   = domain_nullable_tab[idx]
            domain_comment    = domain_comment_tab[idx];
            lc_name        = tolower(domain_name);
            domain_check      = check_tab[lc_name];
            if (domain_check != "") {
                domain_check      = unwrap(domain_check,"in (",")");
                gsub(", ",",",domain_check);
                cnt = split(domain_check,value_tab,",");
            }
            domain_definition = "name='" domain_name "' ";
            domain_definition = domain_definition "schema='" domain_schema "' ";
            domain_definition = domain_definition "type='" domain_type "' ";
            domain_definition = domain_definition "nullable='" domain_nullable "' "
            domain_definition = domain_definition "action='create'";
            if ((domain_default == "") && (domain_comment == "") && (domain_check == "") && (domain_size == "")) {
                print "    <domain " domain_definition "/>"
            }
            else {
                print "    <domain " domain_definition ">"
                if (domain_size != "") {
                    print "      <size>" domain_size "</size>"
                }
                if (domain_default != "") {
                    print "      <default>" domain_default "</default>"
                }
                if (domain_check != "") {
                    print "      <constraint name='chk_" lc_name "' type='any'>"
                    for (didx = 1; didx <= cnt; didx++) {
                        print "        <value>" value_tab[didx] "</value>"
                    }
                    print "      </constraint>"
                }
                if (domain_comment != "") {
                    print "      <comment>" domain_comment "</comment>"
                }
                print "    </domain>"
            }
        }
        print "  </domains>";
    }
    else if (section == "sequences") {
        sequence_schema = table_schema_tab[section];

        print "  <sequences>";
        for (idx = 1; idx <= sequence_count; idx++) {
            sequence_table    = sequence_table_tab[idx];
            sequence_column   = sequence_column_tab[idx];
            sequence_comment  = sequence_comment_tab[idx];
            sequence_name     = sequence_name_tab[idx];

            sequence_definition = "name='" sequence_name "' ";
            sequence_definition = sequence_definition "schema='" sequence_schema "' ";
            sequence_definition = sequence_definition "type='" sequence_id_type "' ";
            sequence_definition = sequence_definition "action='create'";
            print "    <sequence " sequence_definition ">";
            print "      <config start='1' min='1' max='" sequence_id_max "' increment='1' cycle='f'/>"
            print "      <comment>" sequence_comment "</comment>";
            print "    </sequence>";
        }
        print "  </sequences>";
    }
    else if ((section == "tables") && (in_table_def)) {
        in_table_def = 0;    
        table_schema            = table_schema_tab[table_name];
        dim_schema  = schema_name_tab["dim"];
        base_schema = schema_name_tab["base"];
        is_dim_table = (table_schema == dim_schema);
        table_definition = "name='" table_name "' " ;
        table_definition = table_definition "schema='" table_schema "' ";
        table_definition = table_definition "tablespace='" table_schema "' ";
        table_definition = table_definition "auto='NO' action='create'"
        print "    <table " table_definition ">"
        print "      <columns>"

        for (idx = 1; idx <= column_count; idx++) {
            column_name     = column_name_tab[idx];
            ispk_column = (index(primary_list_tab[table_name], column_name) != 0);
            
            column_type     = column_type_tab[idx];
            column_default  = column_default_tab[idx];
            if ((column_default == "") && is_dim_table && ispk_column) {
                column_default = "nextval('" base_schema ".seq_" table_name "_" column_name "'::regclass)";
            }
            
            column_nullable = column_nullable_tab[idx];
            column_comment  = column_comment_tab[idx];

            column_definition = "name='" column_name "' "
            column_definition = column_definition "type='" column_type "' "
            column_definition = column_definition "nullable='" column_nullable "' "
            column_definition = column_definition "auto='NO' action='create'"

            if ((column_default == "") && (column_comment == "") && (column_size == "")) {
                print "        <column " column_definition "/>"
            }
            else {
                print "        <column " column_definition ">"
                if (column_size != "") {
                    print "          <size>" column_size "</size>"
                }
                if (column_default != "") {
                    print "          <default>" column_default "</default>"
                }
                if (column_comment != "") {
                    print "          <comment>" column_comment "</comment>"
                }
                print "        </column>"
            }

        }
        print "      </columns>"

        if (unique_count != 0) {
            print "      <unique name='uk_" table_name "'>";
            for (idx = 1; idx <= unique_count; idx++) {
                print "        <key>" unique_tab[idx] "</key>";
            }
            print "      </unique>";
        }    

        print "      <primary name='pk_" table_name "'>";
        for (idx = 1; idx <= primary_count; idx++) {
                print "        <key>" primary_tab[idx] "</key>";
        }
        print "      </primary>";
        
        if (table_comment != "") {
            print "      <comment>" table_comment "</comment>";
        }
        print "    </table>";
    }
    else if (section == "references") {
        for (oidx = 1; oidx <= foreign_count; oidx++) {
            source_table  = source_table_tab[oidx];
            source_schema = source_schema_tab[oidx];
            target_table  = target_table_tab[oidx];
            target_schema = target_schema_tab[oidx];
            print "    <reference name='fk_" source_table "_" target_table "' action='create'>"
            print "      <source schema='" source_schema "' table='" source_table "'/>"
            print "      <target schema='" target_schema "' table='" target_table "'/>"
            print "      <foreign>";
            foreign_list = primary_list_tab[target_table];
            count = split(foreign_list,foreign_tab,",");
            for (iidx = 1; iidx <= count; iidx++) {
                print "        <key>" foreign_tab[iidx] "</key>";
            }
            print "      </foreign>";
            print "    </reference>"
        }
    }
}



END {
    print "  </" section ">";
    print "</model>";
}
