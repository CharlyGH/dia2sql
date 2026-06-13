<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn str">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>


  <xsl:include href="functions.xslt"/>

  <xsl:param name="project"/>

  <xsl:include href="configuration.xslt"/>

  <xsl:variable name="base-schema"  select="fcn:get-config-value('base')"/>
  <xsl:variable name="const-schema" select="fcn:get-config-value('const')"/>
  <xsl:variable name="dim-schema"   select="fcn:get-config-value('dim')"/>
  <xsl:variable name="fact-schema"  select="fcn:get-config-value('fact')"/>
  <xsl:variable name="hist-schema"  select="fcn:get-config-value('hist')"/>

  <xsl:variable name="schema-list">
    <xsl:for-each select="exslt:node-set($global-config)/project/item[contains(@info,'able')]">
      <xsl:value-of select="concat($q,fcn:replace-first(@value,'{}',$project),$q,
                            fcn:if-then-else(position(),'=',last(),'',','))"/>
    </xsl:for-each>
  </xsl:variable>
  
    <xsl:variable name="space">
    <xsl:text>                               </xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="bigtab">
    <xsl:text>                </xsl:text>
  </xsl:variable>

  
  <xsl:variable name="space-size" select="string-length($space)" />

  <xsl:variable name="lt" select="'&lt;'"/>
  <xsl:variable name="gt" select="'&gt;'"/>
  <xsl:variable name="sk" select="';'"/>
  <xsl:variable name="gtab" select="'  '"/>
  
  <xsl:variable name="sqlnl" select="' chr(10)'"/>
  <xsl:variable name="nl2" select="concat($nl,$nl)"/>
  <xsl:variable name="nl3" select="concat($nl,$nl,$nl)"/>
  
  <xsl:variable name="empty-end" select="concat('/',$gt,$q,')')"/>
  <xsl:variable name="end-tag" select="concat($gt,$q,',')"/>

  
  <fcn:function name="fcn:empty-tag">
    <xsl:param name="tab"/>
    <xsl:param name="node"/>
    <fcn:result>
      <xsl:value-of select="concat('select ',$q,$tab,$lt,$node,$gt,$q,$sk)"/>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:tag-start">
    <xsl:param name="tab"/>
    <xsl:param name="node"/>
    <fcn:result>
      <xsl:value-of select="concat('select concat(',$q,$tab,$lt,$node)"/>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:end-tag">
    <xsl:param name="tab"/>
    <xsl:param name="node"/>
    <fcn:result>
      <xsl:value-of select="concat($sqlnl,',',$q,$tab,$lt,'/',$node,$gt,$q)"/>
    </fcn:result>
  </fcn:function>
  
  
  <fcn:function name="fcn:attribute">
    <xsl:param name="name"/>
    <xsl:param name="alias"/>
    <xsl:variable name="column" select="fcn:replace($name,'-','_')"/>
    <fcn:result>
      <xsl:value-of select="concat(' ',$name,'=',$dq,$q,', ',$alias,'.',$column,', ',$q,$dq)"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:attribute-list">
    <xsl:param name="name-list"/>
    <xsl:param name="alias"/>
    <xsl:variable name="prefix" select="concat($nl,'             ')"/>
    <xsl:variable name="result">
      <xsl:for-each select="str:tokenize($name-list,',')">
        <xsl:value-of select="concat(fcn:if-then-else(position(),'=',1,'',$prefix),fcn:attribute(text(),$alias))"/>
      </xsl:for-each>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="concat('',$result)"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:text-tag">
    <xsl:param name="tab"/>
    <xsl:param name="name"/>
    <xsl:param name="alias"/>
    <xsl:variable name="column" select="fcn:replace($name,'-','_')"/>
    <fcn:result>
      <xsl:value-of select="concat($tab,$sqlnl,',',$q,$tab,$lt,$name,$gt,$q,', ',$alias,'.',
                            $column,', ',$q,$lt,'/',$name,$gt,$q,',')"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:text-tag-list">
    <xsl:param name="tab"/>
    <xsl:param name="name-list"/>
    <xsl:param name="alias"/>
    <xsl:variable name="result">
      <xsl:for-each select="str:tokenize($name-list,',')">
        <xsl:value-of select="concat(fcn:if-then-else(position(),'=',1,'',$nl),fcn:text-tag($tab,text(),$alias))"/>
      </xsl:for-each>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="concat('',$result)"/>
    </fcn:result>
  </fcn:function>
  


  <fcn:function name="fcn:from-clause">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="alias"/>
    <fcn:result>
      <xsl:value-of select="concat('  from ',$schema,'.',$table,' ',$alias)"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:where-clause">
    <xsl:param name="alias"/>
    <xsl:param name="name"/>
    <xsl:param name="op"/>
    <xsl:param name="value"/>
    <fcn:result>
      <xsl:value-of select="concat(' where ',$alias,'.',$name,' ',$op,' ',$q,$value,$q)"/>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:where-in-list">
    <xsl:param name="alias"/>
    <xsl:param name="name"/>
    <fcn:result>
      <xsl:value-of select="concat(' where ',$alias,'.',$name,' in (',$schema-list,')')"/>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:order-by-list">
    <xsl:param name="alias"/>
    <xsl:param name="name-list"/>
    <xsl:variable name="value-list">
      <xsl:for-each select="str:tokenize($name-list,',')">
        <xsl:value-of select="concat($alias,'.',text(),fcn:if-then-else(position(),'=',last(),'',', '))"/>
      </xsl:for-each>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="concat(' order by ',$value-list,$sk)"/>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:get-alias">
    <xsl:param name="name"/>
    <xsl:param name="delimiter" select="'_'"/>
    <xsl:variable name="prefix" select="substring($name,1,1)"/>
    <xsl:variable name="rest" select="substring-after($name,$delimiter)"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="contains($name,$delimiter)">
          <xsl:value-of select="concat($prefix,fcn:get-alias($rest,$delimiter))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$prefix"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  

  
  <xsl:template name="select-table">
    <xsl:param name="tab"/>
    <xsl:param name="alias"/>
    <xsl:param name="key"/>
    <xsl:param name="keys"/>
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="filter"/>
    <xsl:param name="sort-list"/>
    <xsl:param name="column-list"/>
    <xsl:param name="child-list"/>
    <xsl:variable name="ntab" select="concat($tab,$gtab)"/>
    <xsl:variable name="nntab" select="concat($ntab,$gtab)"/>
    <xsl:value-of select="concat(fcn:empty-tag($tab,$keys),$nl2)"/>
    <xsl:value-of select="fcn:tag-start($ntab,$key)"/>
    <xsl:value-of select="fcn:attribute-list($column-list,$alias)"/>
    <xsl:value-of select="concat($end-tag,$nl)"/>
    <xsl:value-of select="concat(fcn:text-tag-list($nntab,$child-list,$alias),$nl)"/>
    <xsl:value-of select="concat($nntab,fcn:end-tag($ntab,$key),')',$nl)"/>
    <xsl:value-of select="concat(fcn:from-clause($schema,$table,$alias),$nl)"/>
    <xsl:value-of select="concat(fcn:where-in-list($alias,$filter),$nl)"/>
    <xsl:value-of select="concat(fcn:order-by-list($alias,$sort-list),$nl2)"/>
    <xsl:value-of select="concat(fcn:empty-tag($tab,concat('/',$keys)),$nl3)"/>
  </xsl:template>

  
  <xsl:template match="empty">
    <xsl:variable name="tab" select="''"/>
    <xsl:variable name="ntab" select="concat($tab,$gtab)"/>
    <xsl:value-of select="concat('select ',$q,$lt,'?xml version=',$dq,'1.0',$dq,'?',$gt,$q,';',$nl)"/>
    <xsl:value-of select="concat('select ',$q,$lt,'!DOCTYPE database SYSTEM ',$dq,'database.dtd',$dq,$gt,$q,';',$nl2)"/>
    <xsl:value-of select="concat(fcn:empty-tag($tab,'database'),$nl2)"/>
    <xsl:apply-templates select="tablespaces">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="schemas">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="domains">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="sequences">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="tables">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="columns">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="uniques">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="unique-columns">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="primaries">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="primary-columns">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="triggers">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="foreigns">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="foreign-columns">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="functions">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="function-defs">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="metadata">
      <xsl:with-param name="tab" select="$ntab"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat(fcn:empty-tag($tab,'/database'),$nl2)"/>
  </xsl:template>


  <xsl:template match="tablespaces">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'ts'"/>
      <xsl:with-param name="key"         select="'tablespace'"/>
      <xsl:with-param name="keys"        select="'tablespaces'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_tablespaces'"/>
      <xsl:with-param name="filter"      select="'tablespace_name'"/>
      <xsl:with-param name="sort-list"   select="'tablespace_name'"/>
      <xsl:with-param name="column-list" select="'tablespace-name'"/>
      <xsl:with-param name="child-list"  select="'tablespace-location'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="schemas">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'s'"/>
      <xsl:with-param name="key"         select="'schema'"/>
      <xsl:with-param name="keys"        select="'schemas'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_schemas'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'schema_name'"/>
      <xsl:with-param name="column-list" select="'schema-name'"/>
      <xsl:with-param name="child-list"  select="'schema-comment'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="domains">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'d'"/>
      <xsl:with-param name="key"         select="'domain'"/>
      <xsl:with-param name="keys"        select="'domains'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_domains'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'domain_name'"/>
      <xsl:with-param name="column-list" select="'domain-name,type-name,is-nullable'"/>
      <xsl:with-param name="child-list"  select="'default-value,domain-comment'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="sequences">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'s'"/>
      <xsl:with-param name="key"         select="'sequence'"/>
      <xsl:with-param name="keys"        select="'sequences'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_sequences'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'sequence_name'"/>
      <xsl:with-param name="column-list"
                      select="'sequence-name,sequence-type,start-value,min-value,max-value,increment-by'"/>
      <xsl:with-param name="child-list" select="'sequence-comment'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="tables">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'t'"/>
      <xsl:with-param name="key"         select="'table'"/>
      <xsl:with-param name="keys"        select="'tables'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_tables'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'schema_name,table_name'"/>
      <xsl:with-param name="column-list" select="'table-name,schema-name,tablespace-name'"/>
      <xsl:with-param name="child-list"  select="'table-comment'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="columns">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'c'"/>
      <xsl:with-param name="key"         select="'column'"/>
      <xsl:with-param name="keys"        select="'columns'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_table_columns'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'schema_name,table_name,position'"/>
      <xsl:with-param name="column-list"
                      select="concat('column-name,table-name,schema-name,domain-name,data-type,',
                              'precision,scale,is-nullable,is-pk,position')"/>
      <xsl:with-param name="child-list" select="'default-value,column-comment'"/>
    </xsl:call-template>
  </xsl:template>


  <xsl:template match="uniques">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'uk'"/>
      <xsl:with-param name="key"         select="'unique'"/>
      <xsl:with-param name="keys"        select="'uniques'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_unique_keys'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'constraint_name'"/>
      <xsl:with-param name="child-list"  select="'key-column-name-list'"/>
      <xsl:with-param name="column-list" select="'constraint-name,schema-name,table-name'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="primaries">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'pk'"/>
      <xsl:with-param name="key"         select="'primary'"/>
      <xsl:with-param name="keys"        select="'primaries'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_primary_keys'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'constraint_name'"/>
      <xsl:with-param name="child-list"  select="'key-column-name-list'"/>
      <xsl:with-param name="column-list" select="'constraint-name,schema-name,table-name'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="unique-columns">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'uc'"/>
      <xsl:with-param name="key"         select="'unique-column'"/>
      <xsl:with-param name="keys"        select="'unique-columns'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_unique_key_columns'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'constraint_name,position'"/>
      <xsl:with-param name="child-list"  select="''"/>
      <xsl:with-param name="column-list" select="'constraint-name,schema-name,table-name,column-name,position'"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="primary-columns">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'pc'"/>
      <xsl:with-param name="key"         select="'primary-column'"/>
      <xsl:with-param name="keys"        select="'primary-columns'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_primary_key_columns'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'constraint_name,position'"/>
      <xsl:with-param name="child-list"  select="''"/>
      <xsl:with-param name="column-list" select="'constraint-name,schema-name,table-name,column-name,position'"/>
    </xsl:call-template>  </xsl:template>

  
  <xsl:template match="triggers">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'tr'"/>
      <xsl:with-param name="key"         select="'trigger'"/>
      <xsl:with-param name="keys"        select="'triggers'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_triggers'"/>
      <xsl:with-param name="filter"      select="'trigger_schema'"/>
      <xsl:with-param name="sort-list"   select="'trigger_name'"/>
      <xsl:with-param name="column-list"
                      select="concat('trigger-name,trigger-schema,event-action,event-schema,event-table,',
                              'event-order,action-statement,action-level,action-timing,function-name,function-schema')"/>
      <xsl:with-param name="child-list" select="''"/>
    </xsl:call-template>
  </xsl:template>

  
  <xsl:template match="foreigns">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'fk'"/>
      <xsl:with-param name="key"         select="'foreign'"/>
      <xsl:with-param name="keys"        select="'foreigns'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_foreign_keys'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'schema_name,table_name,ref_schema_name,ref_table_name'"/>
      <xsl:with-param name="column-list"
                      select="'constraint-name,schema-name,table-name,ref-schema-name,ref-table-name,ref-constraint-name'"/>
      <xsl:with-param name="child-list" select="'column-name-list,ref-column-name-list'"/>
    </xsl:call-template>
  </xsl:template>
  
  
  <xsl:template match="foreign-columns">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'fc'"/>
      <xsl:with-param name="key"         select="'foreign-column'"/>
      <xsl:with-param name="keys"        select="'foreign-columns'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_foreign_key_columns'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'constraint_name,position'"/>
      <xsl:with-param name="column-list"
                      select="concat('constraint-name,schema-name,table-name,column-name,position,ref-constraint-name,',
                              'ref-schema-name,ref-table-name,ref-column-name,ref-position')"/>
      <xsl:with-param name="child-list"  select="''"/>
    </xsl:call-template>
  </xsl:template>

 
  <xsl:template match="functions">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'fu'"/>
      <xsl:with-param name="key"         select="'function'"/>
      <xsl:with-param name="keys"        select="'functions'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_functions'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'function_name'"/>
      <xsl:with-param name="column-list"
                      select="'function-name,schema-name,result-type,function-type,volatility,language'"/>
      <xsl:with-param name="child-list"  select="'argument-types'"/>
    </xsl:call-template>
  </xsl:template>
  
  
  <xsl:template match="function-defs">
    <xsl:param name="tab"/>
    <xsl:call-template name="select-table">
      <xsl:with-param name="tab"         select="$tab"/>
      <xsl:with-param name="alias"       select="'fd'"/>
      <xsl:with-param name="key"         select="'function-def'"/>
      <xsl:with-param name="keys"        select="'function-defs'"/>
      <xsl:with-param name="schema"      select="'dba'"/>
      <xsl:with-param name="table"       select="'all_function_definitions'"/>
      <xsl:with-param name="filter"      select="'schema_name'"/>
      <xsl:with-param name="sort-list"   select="'function_name'"/>
      <xsl:with-param name="column-list" select="'function-name,schema-name'"/>
      <xsl:with-param name="child-list"  select="'function-definition'"/>
    </xsl:call-template>
  </xsl:template>
  
  
  <xsl:template match="metadata">
    <xsl:param name="tab"/>
    <xsl:variable name="ntab"        select="concat($tab,$gtab)"/>
    <xsl:variable name="nntab"       select="concat($ntab,$gtab)"/>
    <xsl:variable name="alias"       select="'m'"/>
    <xsl:variable name="key"         select="'metadata'"/>
    <xsl:variable name="column-list" select="'project,version'"/>
    <xsl:value-of select="fcn:tag-start($tab,$key)"/>
    <xsl:value-of select="fcn:attribute-list($column-list,$alias)"/>
    <xsl:value-of select="concat($end-tag,$nl)"/>
    <xsl:value-of select="concat(fcn:text-tag-list($nntab,'',$alias),$nl)"/>
    <xsl:value-of select="concat($nntab,fcn:end-tag($ntab,$key),')',$nl)"/>
    <xsl:value-of select="concat(fcn:from-clause($base-schema,$key,$alias),';',$nl3)"/>
  </xsl:template>

  
</xsl:stylesheet> 
