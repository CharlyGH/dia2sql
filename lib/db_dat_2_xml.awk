function unwrap(text,left,right,    len, llen, lpart, rlen, rpart) {
    len  = length(text);
    llen = length(left);
    lpart = substr(text,1,llen);
    fail_on_error(lpart != left, "text [" text "] does not start with [" left "]");
    rlen = length(right);
    rpart = substr(text,len-(rlen-1),rlen);
    
    fail_on_error(rpart != right, "text [" text "] does not end with [" right "]");
    return substr(text,llen+1,len-llen-rlen);
}
    

function check_contains(text, find, pos,      idx) {
    idx = index(text, find);
    fail_on_error(idx == 0, "token [" find "] not found in [" text "]");

    fail_on_error((pos != 0) && (idx != pos), "token [" find "] not found in [" text "] at position [" pos "]");
}

function get_type_size(type,       lpos, rpos, res)
{
    lpos = index(type,"(")
    if (lpos == 0) {
        res = "";
    }
    else {
        rpos = index(type,")");
        fail_on_error((rpos == 0) || (rpos < lpos), "invalid type format [" type "]");
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


function array_contains (array, key,       idx) {
    for (idx in array) {
        if (array[idx] == key) {
            return 1;
        }
    }
    return 0;
}

#
# starts_with("abcijkxyz","abc") -> 4
#
function starts_with(strg, left,      llen, ret) {
    llen = length(left);
    ret = 0;
    if (substr(strg,1,llen) == left) {
        ret = llen + 1;
    }
    return ret;
}


#
# ends_with("abcijkxyz","xyz") -> 7
#
function ends_with(strg, right,      slen, rlen, ret) {
    slen = length(strg);
    rlen = length(right);
    ret = slen - rlen + 1;
    if (substr(strg, slen - rlen + 1) != right) {
        ret = 0;
    }
    return ret;
}


#
# substring_between("abcijkxyz","xyz") -> "ijk"
#
function substring_between(strg, left, right,        lpos, rpos, ret)
{
    lpos = starts_with(strg, left);
    rpos = ends_with(strg, right);

    if ((lpos > 0) && (rpos > 0)) {
        ret = substr(strg,lpos,rpos - lpos);
    }
    return ret;
}


function fail_on_error(cond, message) {
    if (cond) {
        print "ERROR: " message > "/dev/stderr";
        exit 1;
    }
}


function check_trigger_line(line_text, line_no, src_schema, func_name, tgt_schema, table,
                            expect, field_list, field_tab, cnt) {
    result = "";
    if (line_no == 1) {
        expect = "create or replace function " src_schema "." func_name "()";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 2) {
        expect = " returns trigger";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 3) {
        expect = " language plpgsql";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 4) {
        expect = "as $function$";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 5) {
        expect = "  begin";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 6) {
        expect = "    insert into " tgt_schema "." table;
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");        
    }
    if (line_no == 7) {
        field_list = substring_between(line_text, "      (", ")");
        cnt = split(field_list, field_tab, ", ");
        fail_on_error(field_tab[1] != columnconf_tab[1], "found unexpected column name [" field_tab[1] "]");
        for (idx = 1; idx <= cnt; idx++) {
            result = result "                <field name='" field_tab[idx] "' hist='"
            result = result "" ((idx == 1) ? "YES" : "NO") "'/>" ((idx == cnt) ? "" : "\n");
        }
    }
    if (line_no == 8) {
        expect = "      select ";
        fail_on_error(substr(line_text,1,length(expect)) != expect,
                      "line #" line_no "\n received [" substr(line_text,1,length(expect)) "]\n expected [" expect "]");
    }
    if (line_no == 9) {
        expect = "        from " src_schema "." table " as t";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");
    }
    if (line_no == 10) {
        expect = "       where t." table "_id = old." table "_id;";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");
    }
    if (line_no == 11) {
        expect = "  return new;";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");
    }
    if (line_no == 12) {
        expect = "  end;";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");
    }
    if (line_no == 13) {
        expect = "$function$";
        fail_on_error(line_text != expect, "line #" line_no "\n received [" line_text "]\n expected [" expect "]");
    }
    return result;
}




BEGIN {
    print "<?xml version='1.0'?>"
    print "<!DOCTYPE model SYSTEM 'model.dtd'>"
    first_table = 1;
    in_column_list = 0;
    schema_idx = 0;
    columnconf_cnt = 0;
}


/^columnconf#/ {
    column_name = $2;
    
    columnconf_cnt++;
    columnconf_tab[columnconf_cnt] = column_name;
}


/^schemaconf#/ {
    schema_type = $2;
    schema_name = $3;
    auto        = $4;

    schema_conf_tab[schema_name] = auto;

    if (schema_type == "base") {
        base_schema = schema_name;
    }
    if (schema_type == "hist") {
        hist_schema = schema_name;
    }
}

/^project#/ {
    project = $2;
    version = $3;
    print "<model project='" project "' version='" version "'>"
}

/^schemas/ {
    current_node    = $1;
    print "  <schemas>"
}


/^schema#/ {
    schema          = $2;
    schema_comment  = $3;

    schema_auto = schema_conf_tab[schema];
    
    if (schema_comment != "") {
        print "    <schema name='" schema "' auto='" schema_auto "' action='create'>";
        print "      <comment>" schema_comment "</comment>";
        print "    </schema>";
    }
    else {
        print "    <schema name='" schema "' auto='" schema_auto "' action='create'/>";
    }
}


/^tablespaces/ {
    current_node = $1;
    print "  <" current_node ">"
}


/^(sequences|domains)/ {
    current_node = $1;
    print "  <" current_node ">"
}


/^tablespace#/ {
    tablespace = $2;
    location   = $3;
    print "    <tablespace name='" tablespace "' action='create'>"
    print "      <location>" location "</location>"
    print "    </tablespace>"
    
}


/^sequence#/ {
    sequence  = $2;
    schema    = $3;
    type      = $4;
    start     = $5;
    min       = $6;
    max       = $7;
    increment = $8;
    cycle     = $9;
    comment   = $10;
    if (comment == "") {
        print "    <sequence name='" sequence "'>"
    }
    else {
        print "    <sequence name='" sequence "' schema='" schema "' type='" type "' action='create'>"
        print "      <config start='" start "' min='" min"' max='" max "' increment='" increment "' cycle='" cycle "'/>"
        print "      <comment>" comment "</comment>"
        print "    </sequence>"
    }
}


/^domain#/ {
    domain    = $2;
    schema    = $3;
    dom_type  = $4;
    dom_size  = get_type_size(dom_type)
    dom_type  = get_type_base(dom_type)
    is_nbl    = $5;
    dflt      = $6;
    chk_name  = $7;
    chk_text  = $8;
    comment   = $9;
    
    if (index (dflt, "'") == 0) {
        dflt = tolower(dflt)
    }
    print "    <domain name='" domain "' schema='" schema "' type='" dom_type "' nullable='" is_nbl "' action='create'>"
    if (dom_size != "") {
        print "      <size>" dom_size "</size>"
    }
    if (dflt != "") {
        print "      <default>" dflt "</default>"
    }
    if (chk_text != "") {
        
        check_contains(chk_text,"CHECK",1)

        chk_text = substr(chk_text,7);
        len = length(chk_text);

        chk_text = unwrap(chk_text,"(",")");

        gsub("::text", "", chk_text);
        gsub("::bpchar", "", chk_text);
        delim = " = ANY ";
        check_contains(chk_text, delim, 0);
        n = split(chk_text,part, delim);
        field  = part[1];
        list = unwrap(part[2],"(ARRAY[","])");
    
        val_cnt = split(list,val_tab,", ");
        print "      <constraint name='" chk_name "' type='any'>";
        for (cnt = 1; cnt <= val_cnt; cnt++) {
            print "        <value>" val_tab[cnt] "</value>";
        }
        print "      </constraint>";
      
    }
    if (comment != "") {
        print "      <comment>" comment "</comment>"
    }
    print "    </domain>"
}


/^tables$/ {
    print "  <tables>";
    current_node    = $1;
}


/^table#/ {
    if (current_node != "metadata") {
        current_node  = $1;
    }
    table         = $2;
    schema        = $3;
    tablespace    = $4;
    table_comment = $5;


    table_auto = schema_conf_tab[schema];
    print "    <table name='" table "' schema='" schema "' tablespace='" tablespace "' auto='" table_auto "' action='create'>";
    print "      <columns>";
    in_column_list = 1;
    in_trigger_list = 0;
}


/^column#/ {
    column   = $2;
    col_type = $3;
    col_size = get_type_size(col_type)
    col_type = get_type_base(col_type)
    nlble    = $4;
    dflt_val = $5;
    comment  = $6;

    if (index (dflt_val, "'") == 0) {
        dflt_val = tolower(dflt_val)
    }

    if (table_auto == "YES") {
        column_auto = "YES";
    }
    else if (array_contains(columnconf_tab,column)) {
        column_auto = "YES";
    }
    else {
        column_auto = "NO";
    }

    if ((comment == "") && (dflt_val == "") && (col_size == "")) {
        print "        <column name='" column "' type='" col_type "' nullable='" nlble "' auto='" column_auto "' action='create'/>"
    }
    else {
        print "        <column name='" column "' type='" col_type "' nullable='" nlble "' auto='" column_auto "' action='create'>"
        if (col_size != "") {
            print "              <size>" col_size "</size>"
        }
        if (dflt_val != "") {
            print "          <default>" dflt_val "</default>"
        }
        if (comment != "") {
            print "          <comment>" comment "</comment>"
        }
        print "        </column>"
    }
}


/^unique#/ {
    name     = $2;
    key_list = $3;

    if (in_column_list) {
        print "      </columns>";
        in_column_list = 0;
    }
    if (has_reference) {
        print "      </references>";
        has_reference = 0;
    }
    print "      <unique name='" name "'>"
    cnt = split(key_list,key_tab,",")
    for (idx = 1; idx <= cnt; idx++) {
        print "        <key>" key_tab[idx] "</key>"
    }
    print "      </unique>"
}


/^primary#/ {
    name     = $2;
    key_list = $3;

    if (in_column_list) {
        print "      </columns>";
        in_column_list = 0;
    }
    if (has_reference) {
        print "      </references>";
        has_reference = 0;
    }
    print "      <primary name='" name "'>"
    cnt = split(key_list,key_tab,",")
    for (idx = 1; idx <= cnt; idx++) {
        print "        <key>" key_tab[idx] "</key>"
    }
    print "      </primary>"
}


/^references/ {
    current_node = $1;
    print "  <" current_node ">"
}




/^reference#/ {
    name          = $2;
    source_schema = $3;
    source_table  = $4;
    source_key    = $5;
    target_schema = $6;
    target_table  = $7;
    target_key    = $8;

    print "    <reference name='" name "' action='create'>"
    print "      <source schema='" source_schema "' table='" source_table "'/>"
    print "      <target schema='" target_schema "' table='" target_table "'/>"
    print "      <foreign>";
    print "        <key>" source_key "</key>"
    print "      </foreign>";
    print "    </reference>"
}


/^check#/ {
    name    = $2;
    text    = $3;

    check_contains(text,"CHECK",1)

    text = substr(text,7);
    len = length(text);

    text = unwrap(text,"(",")");

    gsub("::text", "", text);
    gsub("::bpchar", "", text);
    delim = " = ANY ";
    check_contains(text, delim, 0);
    n = split(text,part, delim);
    field  = part[1];
    list = unwrap(part[2],"(ARRAY[","])");
    
    val_cnt = split(list,val_tab,", ");
    print "      <constraint name='" name "' field='" field "' type='any'>";
    for (cnt = 1; cnt <= val_cnt; cnt++) {
        print "        <value>" val_tab[cnt] "</value>";
    }
    print "      </constraint>";
}


/^trigger#/ {
    name        = $2;
    action      = $3;
    statement   = $4;
    level       = $5;
    timing      = $6;
    table       = $7;
    func_name   = $8;
    column_list = $9

    gsub(",", ", ", column_list);
    if (in_trigger_list == 0) {
        in_trigger_list = 1;
        print "      <triggers>"
    }
    trigger_line = 0;
    print "        <trigger table-name='" table "' trigger-name='" name "' function-name='" func_name "'>"
    print "          <definition action='" action "' level='" level "' timing='" timing"'>"
    print "            <statement>" statement "</statement>"
    print "            <column-list>" column_list "</column-list>"
    print "          </definition>"
}


/^function#/ {
    func_name  = $2;
    language   = $3;
    comment    = $4;
}


/^definition#/ {
    def_name   = $2;
    fail_on_error(def_name != func_name, "function name [" func_name "] does not match definition name [" def_name "]");

    buffer = "";
}



/^def#/ {
    fail_on_error(in_trigger_list == 0,"found trigger code outdide trigger definition");

    line = $2;
    if (trigger) {
        trigger_line++;
        result = check_trigger_line(line, trigger_line, tablespace, func_name, hist_schema, table);
        if (result != "") {
            buffer = result;
        }
    }
    else {
        if (buffer == "") {
            buffer = line;
        }
        else {
            buffer = buffer "\n" line;
        }
    }
}


/^metadata/ {
    current_node = $1;
    print "  <" current_node ">"
}


/^data#/ {
    project = $2;
    version = $3;
    
    print "    </table>";
    print "    <insert schema='" base_schema "' table='metadata'>";
    print "      <project>" project "</project>";
    print "      <version>" version "</version>";
    print "    </insert>";
    print "    <commit/>";

}

/^###/ {
    if (trigger) {
        print "          <fields>";
        print buffer;
        print "          </fields>";
    }
    else {
        print "          <function>" buffer "</function>";        
    }
    print "        </trigger>";
}        


/^end/ {
    if (in_trigger_list == 1) {
        in_trigger_list = 0;
        print "      </triggers>"
    }
    if (current_node == "table") {
        if (table_comment != "") {
            print "      <comment>" table_comment "</comment>"
        }
        print "    </" current_node ">"
        current_node = "none";
    }
    else if ((current_node == "tablespaces") || (current_node == "schemas")) {
        print "  </" current_node ">"
        current_node = "none";
    }
    else if (current_node == "none") {
        current_node = "tables";
        print "  </" current_node ">"
        current_node = "none";
    }
    else if (current_node != "") {
        print "  </" current_node ">"
        current_node = "none";
    }
}


END {
    schema_comment = schema_comment_tab[old_tablespace];
    if (schema_comment != "") {
        print "  <comment>" schema_comment "</comment>"
    }
    print "</model>"    
}


