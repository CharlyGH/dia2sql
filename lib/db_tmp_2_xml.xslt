<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn str">

  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="model.dtd"
              />


  <xsl:include href="functions.xslt"/>

  <xsl:param name="project"/>

  <xsl:include href="configuration.xslt"/>

  <xsl:variable name="base-schema"  select="fcn:get-config-value('base')"/>
  <xsl:variable name="const-schema" select="fcn:get-config-value('const')"/>
  <xsl:variable name="dim-schema"   select="fcn:get-config-value('dim')"/>
  <xsl:variable name="fact-schema"  select="fcn:get-config-value('fact')"/>
  <xsl:variable name="hist-schema"  select="fcn:get-config-value('hist')"/>

  <xsl:variable name="valid-from"   select="fcn:get-config-value('valid-from')"/>
  <xsl:variable name="valid-to"     select="fcn:get-config-value('valid-to')"/>


  <fcn:function name="fcn:get-schema-auto">
    <xsl:param name="schema"/>  
    <xsl:variable name="info" select="fcn:get-config-info('',$schema)"/>
    <xsl:variable name="auto" select="fcn:if-then-else($info,'=','writable','NO','YES')"/>
    <fcn:result>
      <xsl:value-of select="$auto"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-column-auto">
    <xsl:param name="schema"/>
    <xsl:param name="column"/>
    <xsl:variable name="auto">
      <xsl:choose>
        <xsl:when test="$schema = $hist-schema or $column = $valid-from or $column = $valid-to">
          <xsl:value-of select="'YES'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'NO'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <fcn:result>
      <xsl:value-of select="$auto"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-field-type">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="field"/>
    <xsl:variable name="primary-list"
                  select="/database/primaries/primary[@schema-name = $schema and
                          @table-name = $table]/key-column-name-list/text()"/>
    <xsl:variable name="position" select="fcn:find($primary-list,$field,',')"/>
    <xsl:variable name="result" select="fcn:if-then-else($position,'=',0,'other','primary')"/>
    <fcn:result>
      <xsl:value-of select="$result"/> 
    </fcn:result>
  </fcn:function>

<!--
    <xsl:message terminate="no">
      <xsl:value-of select="concat('schema=',$schema,'  table=',$table,'  field=',$field,
                            '  primary-list=',$primary-list,'  position=',$position,'  result=',$result)"/>
    </xsl:message>
-->


  <xsl:template match="database">
    <xsl:element name="model">
      <xsl:attribute name="project">
        <xsl:value-of select="metadata/@project"/>
      </xsl:attribute>
      <xsl:attribute name="version">
        <xsl:value-of select="metadata/@version"/>
      </xsl:attribute>
      <xsl:element name="tablespaces">
        <xsl:apply-templates select="tablespaces/tablespace"/>
      </xsl:element>
      <xsl:element name="schemas">
        <xsl:apply-templates select="schemas/schema"/>
      </xsl:element>
      <xsl:element name="domains">
        <xsl:apply-templates select="domains/domain"/>
      </xsl:element>
      <xsl:element name="sequences">
        <xsl:apply-templates select="sequences/sequence"/>
      </xsl:element>
      <xsl:element name="tables">
        <xsl:apply-templates select="tables/table[@table-name != 'metadata']"/>
      </xsl:element>
      <xsl:element name="references">
        <xsl:apply-templates select="foreigns/foreign"/>
      </xsl:element>
      <xsl:element name="functions">
        <xsl:apply-templates select="functions/function"/>
      </xsl:element>
      <xsl:element name="metadata">
        <xsl:apply-templates select="metadata"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  


  <xsl:template match="tablespace">
    <xsl:element name="tablespace">
      <xsl:attribute name="name">
        <xsl:value-of select="@tablespace-name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="location">
        <xsl:value-of select="tablespace-location"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="schema">
    <xsl:variable name="schema" select="@schema-name"/>
    <xsl:variable name="auto" select="fcn:get-schema-auto($schema)"/>
    <xsl:element name="schema">
      <xsl:attribute name="name">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:if test="string-length(schema-comment) != 0">
        <xsl:element name="comment">
          <xsl:value-of select="schema-comment"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="domain">
    <xsl:variable name="schema" select="fcn:get-config-value('base')"/>
    <xsl:element name="domain">
      <xsl:attribute name="name">
        <xsl:value-of select="@domain-name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type-name"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="@is-nullable"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:if test="string-length(default-value) != 0">
        <xsl:element name="default">
          <xsl:value-of select="default-value"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="string-length(domain-comment) != 0">
        <xsl:element name="comment">
          <xsl:value-of select="domain-comment"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="sequence">
    <xsl:variable name="schema" select="fcn:get-config-value('base')"/>
    <xsl:element name="sequence">
      <xsl:attribute name="name">
        <xsl:value-of select="@sequence-name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@sequence-type"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="config">
        <xsl:attribute name="start">
          <xsl:value-of select="@start-value"/>
        </xsl:attribute>
        <xsl:attribute name="min">
          <xsl:value-of select="@min-value"/>
        </xsl:attribute>
        <xsl:attribute name="max">
          <xsl:value-of select="@max-value"/>
        </xsl:attribute>
        <xsl:attribute name="increment">
          <xsl:value-of select="@increment-by"/>
        </xsl:attribute>
        <xsl:attribute name="cycle">
          <xsl:value-of select="'f'"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:if test="string-length(sequence-comment) != 0">
        <xsl:element name="comment">
          <xsl:value-of select="sequence-comment"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="table">
    <xsl:variable name="schema"  select="@schema-name"/>
    <xsl:variable name="table"   select="@table-name"/>
    <xsl:variable name="auto"    select="fcn:get-schema-auto($schema)"/>
    <xsl:variable name="unique"
                  select="/database/uniques/unique[@schema-name = $schema and @table-name = $table]/@constraint-name"/>
    <xsl:variable name="primary"
                  select="/database/primaries/primary[@schema-name = $schema and @table-name = $table]/@constraint-name"/>
    <xsl:variable name="trigger"
                  select="/database/triggers/trigger[@event-schema = $schema and @event-table = $table]/@trigger-name"/>
<!--
    <xsl:message terminate="no">
      <xsl:value-of select="concat('schema=',$schema,'  table=',$table,'  trigger=',$trigger,$nl)"/>
    </xsl:message>
-->
    <xsl:element name="table">
      <xsl:attribute name="name">
        <xsl:value-of select="$table"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
     <xsl:attribute name="tablespace">
        <xsl:value-of select="@tablespace-name"/>
      </xsl:attribute>
     <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
     <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="columns">
        <xsl:apply-templates select="/database/columns/column[@schema-name = $schema and @table-name = $table]"
                             mode="table"/>
      </xsl:element>
      <xsl:if test="string-length($unique) != 0">
        <xsl:apply-templates select="/database/uniques/unique[@schema-name = $schema and @table-name = $table]"/>
      </xsl:if>
      <xsl:if test="string-length($primary) != 0">
        <xsl:apply-templates select="/database/primaries/primary[@schema-name = $schema and @table-name = $table]"/>
      </xsl:if>
      <xsl:if test="string-length($trigger) != 0">
        <xsl:element name="triggers">
          <xsl:apply-templates select="/database/triggers/trigger[@event-schema = $schema and @event-table = $table]"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="string-length(table-comment) != 0">
        <xsl:element name="comment">
          <xsl:value-of select="table-comment"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="column" mode="table">
    <xsl:variable name="schema" select="@schema-name"/>
    <xsl:variable name="column" select="@column-name"/>
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$column"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@domain-name"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="@is-nullable"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="fcn:get-column-auto($schema,$column)"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:if test="string-length(default-value) != 0">
        <xsl:element name="default">
          <xsl:value-of select="fcn:to-lower-case(default-value)"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="string-length(column-comment) != 0">
        <xsl:element name="comment">
          <xsl:value-of select="column-comment"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="unique">
    <xsl:variable name="schema" select="@schema-name"/>
    <xsl:variable name="table" select="@table-name"/>
    <xsl:variable name="unique" select="@constraint-name"/>
    <xsl:element name="unique">
      <xsl:attribute name="name">
        <xsl:value-of select="$unique"/>
      </xsl:attribute>
      <xsl:apply-templates select="/database/unique-columns/unique-column[@constraint-name = $unique
                                   and @schema-name = $schema and @table-name = $table]"/>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="unique-column">
    <xsl:variable name="column" select="@column-name"/>
    <xsl:element name="key">
      <xsl:value-of select="$column"/>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="primary">
    <xsl:variable name="schema" select="@schema-name"/>
    <xsl:variable name="table" select="@table-name"/>
    <xsl:variable name="primary" select="@constraint-name"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$primary"/>
      </xsl:attribute>
      <xsl:apply-templates select="/database/primary-columns/primary-column[@constraint-name = $primary
                                   and @schema-name = $schema and @table-name = $table]"/>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="primary-column">
    <xsl:variable name="column" select="@column-name"/>
    <xsl:element name="key">
      <xsl:value-of select="$column"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="trigger">
    <xsl:variable name="trigger" select="@trigger-name"/>
    <xsl:variable name="schema" select="@trigger-schema"/>
    <xsl:variable name="function" select="@function-name"/>
    <xsl:variable name="language"
                  select="/database/functions/function[@schema-name = $schema and @function-name = $function]/@language"/>
    <xsl:variable name="event-schema" select="@event-schema"/>
    <xsl:variable name="event-table" select="@event-table"/>
    <xsl:element name="trigger">
      <xsl:attribute name="name">
        <xsl:value-of select="$trigger"/>
      </xsl:attribute>
      <xsl:element name="definition">
        <xsl:attribute name="action">
          <xsl:value-of select="fcn:to-lower-case(@event-action)"/>
        </xsl:attribute>
        <xsl:attribute name="level">
          <xsl:value-of select="fcn:to-lower-case(@action-level)"/>
        </xsl:attribute>
        <xsl:attribute name="timing">
          <xsl:value-of select="fcn:to-lower-case(@action-timing)"/>
        </xsl:attribute>
        <xsl:attribute name="language">
          <xsl:value-of select="$language"/>
        </xsl:attribute>
        <xsl:element name="call">
          <xsl:attribute name="name">
            <xsl:value-of select="$function"/>
          </xsl:attribute>
          <xsl:attribute name="schema">
            <xsl:value-of select="$schema"/>
          </xsl:attribute>
        </xsl:element>
        <xsl:element name="fields">
          <xsl:apply-templates select="/database/columns/column[@schema-name = $event-schema and @table-name = $event-table]"
                               mode="trigger"/>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column" mode="trigger">
    <xsl:variable name="schema" select="@schema-name"/>
    <xsl:variable name="table" select="@table-name"/>
    <xsl:variable name="field" select="@column-name"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="$field = $valid-from">
          <xsl:value-of select="'valid-from'"/>
        </xsl:when>
        <xsl:when test="$field = $valid-to">
          <xsl:value-of select="'valid-to'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:get-field-type($schema,$table,$field)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="field">
      <xsl:attribute name="name">
        <xsl:value-of select="$field"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>


  <xsl:template match="foreign">
    <xsl:variable name="foreign" select="@constraint-name"/>
    <xsl:element name="reference">
      <xsl:attribute name="name">
        <xsl:value-of select="@constraint-name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="source">
        <xsl:attribute name="schema">
          <xsl:value-of select="@schema-name"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="@table-name"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="target">
        <xsl:attribute name="schema">
          <xsl:value-of select="@ref-schema-name"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="@ref-table-name"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="foreign">
        <xsl:apply-templates select="/database/foreign-columns/foreign-column[@constraint-name = $foreign]"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="foreign-column">
    <xsl:variable name="field" select="@column-name"/>
    <xsl:element name="key">
      <xsl:value-of select="$field"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="function">
    <xsl:variable name="function" select="@function-name"/>
    <xsl:variable name="schema"   select="@schema-name"/>
    <xsl:variable name="table"
                  select="/database/triggers/trigger[@function-schema = $schema and @function-name = $function]/@event-table"/>
    <xsl:element name="function">
      <xsl:attribute name="name">
        <xsl:value-of select="$function"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="$table"/>
      </xsl:attribute>
      <xsl:element name="text">
        <xsl:attribute name="language">
          <xsl:value-of select="@language"/>
        </xsl:attribute>
        <xsl:apply-templates select="/database/function-defs/function-def[@function-name = $function]/function-definition"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="function-definition">
    <xsl:value-of select="substring-before(substring-after(text(),'begin'),'  return')"/>
  </xsl:template>
  

  <xsl:template match="metadata">
    <xsl:apply-templates select="/database/tables/table[@table-name = 'metadata']"/>
    <xsl:element name="insert">
      <xsl:attribute name="schema">
        <xsl:value-of select="$base-schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="'metadata'"/>
      </xsl:attribute>
      <xsl:element name="project">
        <xsl:value-of select="@project"/>
      </xsl:element>
      <xsl:element name="version">
        <xsl:value-of select="@version"/>
      </xsl:element>
    </xsl:element>
    <xsl:element name="commit">
    </xsl:element>
  </xsl:template>
  

  
</xsl:stylesheet> 
