<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="fcn exslt str">

  <xsl:output method="xml"
              omit-xml-declaration="no"
              indent="yes"
              version="1.0"
              doctype-system="model.dtd"
              />

  <xsl:include href="functions.xslt"/>  

  <xsl:variable name="project">
    <xsl:value-of select="fcn:to-lower-case(/diagram/metadata/metaitem[@name = 'projekt']/@type)"/>
  </xsl:variable>

  <xsl:variable name="version">
    <xsl:value-of select="fcn:to-lower-case(/diagram/metadata/metaitem[@name = 'version']/@type)"/>
  </xsl:variable>

  <xsl:include href="configuration.xslt"/>
  


  <xsl:param name="sort-file"/>


  <fcn:function name="fcn:get-table-name">
    <xsl:param name="id"/>
    <xsl:variable name="result" select="/diagram/tables/table[@id = $id]/@name"/> 
    <fcn:result>
      <xsl:value-of select="$result"/> 
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-primary-key">
    <xsl:param name="id"/>
    <xsl:variable name="result">
      <xsl:apply-templates select="/diagram/tables/table[@id = $id]/primary/key" mode="foreign"/>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="concat($result,' ')"/> 
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-schema-name">
    <xsl:param name="table"/>
    <xsl:variable name="raw-schema" select="/diagram/metadata/metaitem/metadetail[@name = $table]/../@type"/>
    <xsl:variable name="schema" select="fcn:get-config-value(fcn:to-lower-case($raw-schema))"/>
    <xsl:variable name="result" select="fcn:replace-first($schema,'{}',$project)"/> 
    <fcn:result>
      <xsl:value-of select="$result"/> 
    </fcn:result>
  </fcn:function>

  
  <xsl:template match="diagram">
    <xsl:element name="model">
      <xsl:attribute name="project">
        <xsl:value-of select="$project"/>
      </xsl:attribute>
      <xsl:attribute name="version">
        <xsl:value-of select="$version"/>
      </xsl:attribute>
      <xsl:element name="tablespaces">
        <xsl:apply-templates select="exslt:node-set($global-config)/project/item[@info = 'readable' or @info = 'writable']"
                             mode="tablespace">
          <xsl:sort select="@value"/>
        </xsl:apply-templates>
      </xsl:element>
      <xsl:element name="schemas">
        <xsl:apply-templates select="exslt:node-set($global-config)/project/item[@info = 'readable' or @info = 'writable']"
                             mode="schema">
          <xsl:sort select="@value"/>
        </xsl:apply-templates>
      </xsl:element>
      <xsl:element name="domains">
        <xsl:apply-templates select="domains/domain"/>
      </xsl:element>
      <xsl:element name="sequences">
        <xsl:apply-templates select="sequences/sequence">
          <xsl:sort select="concat(@table,'_id')"/>
        </xsl:apply-templates>
      </xsl:element>
      <xsl:variable name="schema-list" select="'(Const,Dim,Fact)'"/>
      <xsl:element name="tables">
        <xsl:apply-templates select="metadata/metaitem[@name = 'schema' and contains($schema-list,@type)]" mode="table">
          <xsl:sort select="@type"/>
        </xsl:apply-templates>
      </xsl:element>

      <exslt:document href="{$sort-file}" method="xml" indent="yes" omit-xml-declaration="no">
        <xsl:element name="sortrefs">
          <xsl:apply-templates select="references/reference"/>
        </xsl:element>
      </exslt:document>

      <xsl:element name="references">
        <xsl:apply-templates select="document($sort-file)/sortrefs" mode="copy">
        </xsl:apply-templates>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="item" mode="tablespace">
    <xsl:variable name="tablespace-name" select="fcn:replace-first(@value,'{}',$project)"/>
    <xsl:variable name="tablespace-root" select="fcn:get-config-value('tablespace-root')"/>
    <xsl:variable name="location"        select="concat($tablespace-root,'/',$tablespace-name)"/>
    <xsl:element name="tablespace">
      <xsl:attribute name="name">
        <xsl:value-of select="$tablespace-name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="location">
        <xsl:value-of select="$location"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="item" mode="schema">
    <xsl:variable name="schema-name"    select="fcn:replace-first(@value,'{}',$project)"/>
    <xsl:variable name="schema-comment" select="concat('Schema für ',fcn:to-capital-case(@name),'-Daten')"/>
    <xsl:variable name="auto"           select="fcn:if-then-else(@info,'=','writable','NO','YES')"/>
    <xsl:element name="schema">
      <xsl:attribute name="name">
        <xsl:value-of select="$schema-name"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="comment">
        <xsl:value-of select="$schema-comment"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>



  <xsl:template match="domain">
    <xsl:variable name="name"    select="fcn:to-lower-case(@name)"/>
    <xsl:variable name="schema"  select="concat('base_',fcn:to-lower-case($project))"/>
    <xsl:variable name="type"    select="fcn:to-lower-case(@type)"/>
    <xsl:variable name="nullable"  select="fcn:if-then-else(@nullable,'=','true','YES','NO')"/>
    <xsl:variable name="action" select="'create'"/>
    <xsl:variable name="default" select="default/text()"/>
    <xsl:variable name="comment" select="comment/text()"/>
    <xsl:element name="domain">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="$nullable"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="$action"/>
      </xsl:attribute>
      <xsl:if test="string-length($default) != 0">
        <xsl:element name="default">
          <xsl:value-of select="$default"/>
        </xsl:element>
      </xsl:if>
      <xsl:element name="comment">
        <xsl:value-of select="$comment"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="sequence">
    <xsl:variable name="src-schema"  select="concat('base_',fcn:to-lower-case(@schema))"/>
    <xsl:variable name="tgt-schema"  select="concat('base_',fcn:to-lower-case($project))"/>
    <xsl:variable name="table"       select="@table"/>
    <xsl:variable name="type"        select="fcn:get-config-value('id-type')"/>
    <xsl:variable name="max"         select="fcn:get-config-value('id-max')"/>
    <xsl:variable name="primary"     select="/diagram/tables/table[@name = $table]/primary/key/@name"/>
    <xsl:variable name="name"        select="concat('seq_',fcn:to-lower-case($primary))"/>
    <xsl:variable name="cycle"       select="'f'"/>
    <xsl:element name="sequence">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$tgt-schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="config">
        <xsl:attribute name="start">
          <xsl:value-of select="1"/>
        </xsl:attribute>
        <xsl:attribute name="min">
          <xsl:value-of select="1"/>
        </xsl:attribute>
        <xsl:attribute name="max">
          <xsl:value-of select="$max"/>
        </xsl:attribute>
        <xsl:attribute name="increment">
          <xsl:value-of select="1"/>
        </xsl:attribute>
        <xsl:attribute name="cycle">
          <xsl:value-of select="$cycle"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="comment">
        <xsl:value-of select="concat('Sequence für PK der Tabelle ',$table)"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="metaitem" mode="table">
    <xsl:variable name="key"   select="fcn:to-lower-case(@type)"/>
    <xsl:variable name="value" select="fcn:get-config-value($key)"/>
    <xsl:variable name="schema" select="fcn:replace-first($value,'{}',$project)"/>
    <xsl:apply-templates select="metadetail" mode="table">
      <xsl:sort select="@name"/>
      <xsl:with-param name="schema" select="$schema"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="metadetail" mode="table">
    <xsl:param name="schema"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:apply-templates select="/diagram/tables/table[@name = $name]">
      <xsl:with-param name="schema" select="$schema"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="table">
    <xsl:param name="schema"/>
    <xsl:variable name="name" select="fcn:to-lower-case(@name)"/>
    <xsl:variable name="tablespace" select="$schema"/>
    <xsl:variable name="auto" select="'NO'"/>
    <xsl:variable name="action" select="'create'"/>
    <xsl:element name="table">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="tablespace">
        <xsl:value-of select="$tablespace"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="$action"/>
      </xsl:attribute>
      <xsl:element name="columns">
        <xsl:apply-templates select="columns/column"/>
      </xsl:element>
      <xsl:apply-templates select="unique">
        <xsl:with-param name="table" select="$name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="primary">
        <xsl:with-param name="table" select="$name"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column">
    <xsl:variable name="name"      select="fcn:to-lower-case(@name)"/>
    <xsl:variable name="type"      select="fcn:to-lower-case(@type)"/>
    <xsl:variable name="nullable"  select="fcn:if-then-else(@nullable,'=','true','YES','NO')"/>
    <xsl:variable name="auto" select="'NO'"/>
    <xsl:variable name="action" select="'create'"/>
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="$nullable"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="$action"/>
      </xsl:attribute>
      <xsl:element name="comment">
        <xsl:value-of select="comment"/>
      </xsl:element>    
    </xsl:element>    
  </xsl:template>


  <xsl:template match="unique">
    <xsl:param name="table"/>
    <xsl:variable name="name" select="concat('uk_',$table)"/>
    <xsl:element name="unique">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="key"/>
    </xsl:element>        
  </xsl:template>


  <xsl:template match="primary">
    <xsl:param name="table"/>
    <xsl:variable name="name" select="concat('pk_',$table)"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="key"/>      
    </xsl:element>        
  </xsl:template>


  <xsl:template match="comment">
    <xsl:element name="comment">
      <xsl:value-of select="text()"/>
    </xsl:element>        
  </xsl:template>


  <xsl:template match="key">
    <xsl:variable name="name"      select="fcn:to-lower-case(@name)"/>
    <xsl:element name="key">
      <xsl:value-of select="$name"/>
    </xsl:element>        
  </xsl:template>



  <xsl:template match="key" mode="foreign">
    <xsl:variable name="name"      select="fcn:to-lower-case(@name)"/>
    <xsl:value-of select="concat($name,' ')"/>
  </xsl:template>


  <xsl:template match="reference">
    <xsl:variable name="src-id"     select="from/@id"/> 
    <xsl:variable name="tgt-id"     select="to/@id"/>
    <xsl:variable name="src-table"  select="fcn:get-table-name($src-id)"/> 
    <xsl:variable name="tgt-table"  select="fcn:get-table-name($tgt-id)"/>
    <xsl:variable name="src-schema" select="fcn:get-schema-name($src-table)"/> 
    <xsl:variable name="tgt-schema" select="fcn:get-schema-name($tgt-table)"/> 
    <xsl:variable name="tgt-key"    select="fcn:get-primary-key($tgt-id)"/>
    <xsl:variable name="name"       select="concat('fk_',fcn:to-lower-case($src-table),'_',fcn:to-lower-case($tgt-table))"/>
    <xsl:variable name="action"     select="'create'"/>
    <xsl:variable name="sortkey"    select="concat($src-schema,'#',$src-table,'#',$tgt-schema,'#',$tgt-table)"/>

    <xsl:element name="reference">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="$action"/>
      </xsl:attribute>
      <xsl:attribute name="sortkey">
        <xsl:value-of select="fcn:to-lower-case($sortkey)"/>
      </xsl:attribute>
      <xsl:element name="source">
        <xsl:attribute name="schema">
          <xsl:value-of select="fcn:to-lower-case($src-schema)"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="fcn:to-lower-case($src-table)"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="target">
        <xsl:attribute name="schema">
          <xsl:value-of select="fcn:to-lower-case($tgt-schema)"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="fcn:to-lower-case($tgt-table)"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="foreign">
        <xsl:for-each select="exslt:node-set(str:tokenize($tgt-key))">
          <xsl:element name="key">
            <xsl:value-of select="text()"/>
          </xsl:element>
        </xsl:for-each>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  
  <xsl:template match="sortrefs" mode="copy">
    <xsl:apply-templates select="reference" mode="copy">
      <xsl:sort select="@sortkey"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="reference" mode="copy">
    <xsl:element name="reference">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="@action"/>
      </xsl:attribute>
      <xsl:apply-templates select="source" mode="copy"/>
      <xsl:apply-templates select="target" mode="copy"/>
      <xsl:apply-templates select="foreign" mode="copy"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="source" mode="copy">
    <xsl:element name="source">
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="@table"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="target" mode="copy">
    <xsl:element name="target">
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="@table"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="foreign" mode="copy">
    <xsl:element name="foreign">
      <xsl:apply-templates select="key" mode="copy"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="key" mode="copy">
    <xsl:element name="key">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>

  
</xsl:stylesheet> 
