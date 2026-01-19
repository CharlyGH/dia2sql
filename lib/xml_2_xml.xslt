<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn"
                >

  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="model.dtd"
              />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:include href="functions.xslt"/>
  
  <xsl:param name="configfile"/>


  <fcn:function name="fcn:set-list">
    <xsl:param name="column-list"/>
    <xsl:param name="old-delim"/>
    <xsl:param name="new-delim"/>
    <xsl:variable name="target">
      <xsl:choose>
        <xsl:when test="contains($column-list,$old-delim)">
          <xsl:variable name="left" select="substring-before($column-list,$old-delim)"/>
          <xsl:variable name="right" select="substring-after($column-list,$old-delim)"/>
          <xsl:value-of select="concat($left,$new-delim,$left,$old-delim,' ',
                                fcn:set-list($right,$old-delim,$new-delim))"/>
        </xsl:when>
        <xsl:when test="string-length($column-list) = 0">
          <xsl:value-of select="''" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($column-list,$new-delim,$column-list)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$target" />
    </fcn:result>
  </fcn:function>

    
  <fcn:function name="fcn:function-text">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="constraint" />
    <xsl:param name="pk-column" />
    <xsl:param name="valid-from" />
    <xsl:param name="valid-to" />
    <xsl:param name="column-list" />
    <xsl:variable name="source-list" select="fcn:replace($column-list,',',', new.')"/>
    <fcn:result>
      <xsl:value-of select="concat(
                            '        insert into ',$schema,'.',$table,$nl,
                            '          (',$pk-column,',',$valid-from,',',$valid-to,',',$column-list,')',$nl,
                            '        select new.',$pk-column,', new.',$valid-from,', new.',$valid-to,', new.',$source-list,$nl,
                            '        on conflict on constraint ',$constraint,$nl,
                            '        do update set',$nl,
                            '           ',$valid-from,' = current_date, ',$valid-to,' = excluded.',$valid-to,',',$nl,
                            '           ',fcn:set-list($column-list,',',' = excluded.'),';',$nl,'      '
                            )"/>
    </fcn:result>
  </fcn:function>

  
  <xsl:variable name="config" select="document($configfile)/config"/>

  <xsl:variable name="base-schema" select="exslt:node-set($config)/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="dim-schema"  select="exslt:node-set($config)/schemaconf[@name = 'dim']/@value"/>
  <xsl:variable name="fact-schema" select="exslt:node-set($config)/schemaconf[@name = 'fact']/@value"/>
  <xsl:variable name="hist-schema" select="exslt:node-set($config)/schemaconf[@name = 'hist']/@value"/>

  <xsl:variable name="valid-from"  select="exslt:node-set($config)/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="exslt:node-set($config)/columnconf[@name = 'valid-to']/@value"/>

  

  <xsl:template match="model">
    <xsl:variable name="project" select="@project"/>
    <xsl:variable name="version" select="@version"/>
    <xsl:element name="model">
      <xsl:attribute name="project">
        <xsl:value-of select="$project"/>
      </xsl:attribute>
      <xsl:attribute name="version">
        <xsl:value-of select="$version"/>
      </xsl:attribute>
      <xsl:apply-templates select="tablespaces"/>
      <xsl:apply-templates select="schemas"/>
      <xsl:apply-templates select="domains"/>
      <xsl:apply-templates select="sequences"/>
      <xsl:apply-templates select="tables" mode="define"/>
      <xsl:apply-templates select="references"/>
      <xsl:apply-templates select="tables" mode="trg-fun"/>
      <xsl:call-template name="metadata">
        <xsl:with-param name="project" select="$project"/>
        <xsl:with-param name="version" select="$version"/>
      </xsl:call-template>
      
    </xsl:element>
  </xsl:template>


  <xsl:template match="tablespaces">
    <xsl:element name="tablespaces">
      <xsl:apply-templates select="tablespace"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="tablespace">
    <xsl:element name="tablespace">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="@action"/>
      </xsl:attribute>
      <xsl:apply-templates select="location"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="schemas">
    <xsl:element name="schemas">
      <xsl:apply-templates select="schema"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="schema">
    <xsl:element name="schema">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="@auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="@action"/>
      </xsl:attribute>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="comment">
    <xsl:element name="comment">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="location">
    <xsl:element name="location">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="domains">
    <xsl:element name="domains">
      <xsl:apply-templates select="domain"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="domain">
    <xsl:element name="domain">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="@nullable"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="default"/>
      <xsl:apply-templates select="size"/>
      <xsl:apply-templates select="constraint"/>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="default">
    <xsl:element name="default">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="size">
    <xsl:element name="size">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="constraint">
    <xsl:element name="constraint">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type"/>
      </xsl:attribute>
      <xsl:apply-templates select="value"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="value">
    <xsl:element name="value">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="sequences">
    <xsl:element name="sequences">
      <xsl:apply-templates select="sequence"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="sequence">
    <xsl:element name="sequence">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="config"/>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="config">
    <xsl:element name="config">
      <xsl:attribute name="start">
        <xsl:value-of select="@start"/>
      </xsl:attribute>
      <xsl:attribute name="min">
        <xsl:value-of select="@min"/>
      </xsl:attribute>
      <xsl:attribute name="max">
        <xsl:value-of select="@max"/>
      </xsl:attribute>
      <xsl:attribute name="increment">
        <xsl:value-of select="@increment"/>
      </xsl:attribute>
      <xsl:attribute name="cycle">
        <xsl:value-of select="@cycle"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>


  <xsl:template match="tables"  mode="define">
    <xsl:element name="tables">
      <xsl:apply-templates select="table[@schema = $dim-schema]"  mode="copy"/>
      <xsl:apply-templates select="table[@schema = $fact-schema]" mode="copy"/>
      <xsl:apply-templates select="table[@schema = $dim-schema]"  mode="hist"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="tables"  mode="trg-fun">
    <xsl:element name="functions">
      <xsl:apply-templates select="table[@schema = $dim-schema]"  mode="trg-fun"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="table" mode="trg-fun">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:variable name="pk-column" select="//table[@name = $table and @schema = $schema]/primary/key"/>

    <xsl:element name="function">
      <xsl:attribute name="name">
        <xsl:value-of select="concat(@name,'_trg_fun')"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="$table"/>
      </xsl:attribute>
      <xsl:variable name="column-list">
        <xsl:apply-templates select="columns/column[@name != $pk-column]" mode="list"/>
      </xsl:variable>
      <xsl:variable name="constraint" select="concat('pk_',$table)"/>
      <xsl:element name="text">
      <xsl:attribute name="language">
        <xsl:value-of select="'plpgsql'"/>
      </xsl:attribute>
      <xsl:value-of select="$nl"/>
      <xsl:value-of select="fcn:function-text($hist-schema,$table,$constraint,
                            $pk-column,$valid-from,$valid-to,$column-list)"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column" mode="trg-fun">
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="field">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="'other'"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>
    
  
  <xsl:template match="column" mode="list">
    <xsl:param name="prefix"/>
    <xsl:variable name="column-name" select="@name"/>
    <xsl:variable name="delim" select="fcn:if-then-else(position(),'=',last(),'',',')"/>
    <xsl:value-of select="concat($prefix,$column-name,$delim)"/>
  </xsl:template>
  

  <xsl:template match="table" mode="copy">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="is-dim">
      <xsl:choose>
        <xsl:when test="substring(@schema,1,3) = 'dim'">
          <xsl:value-of select="'true'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'false'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="table">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="tablespace">
        <xsl:value-of select="@tablespace"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="@auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="columns" mode="copy">
        <xsl:with-param name="is-dim" select="$is-dim"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="unique"/>
      <xsl:apply-templates select="primary" mode="copy"/>
      <xsl:if test="$is-dim = 'true'">
        <xsl:apply-templates select="."    mode="trigger">
          <xsl:with-param name="schema" select="$schema"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="table" mode="hist">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="is-dim">
      <xsl:choose>
        <xsl:when test="substring($schema,1,3) = 'dim'">
          <xsl:value-of select="'true'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'false'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$is-dim = 'true'">
      <xsl:element name="table">
        <xsl:attribute name="name">
          <xsl:value-of select="@name"/>
        </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$hist-schema"/>
      </xsl:attribute>
        <xsl:attribute name="tablespace">
          <xsl:value-of select="$hist-schema"/>
        </xsl:attribute>
        <xsl:attribute name="auto">
          <xsl:value-of select="'YES'"/>
        </xsl:attribute>
        <xsl:attribute name="action">
          <xsl:value-of select="'create'"/>
        </xsl:attribute>
        <xsl:apply-templates select="columns" mode="hist">
          <xsl:with-param name="is-dim" select="$is-dim"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="primary" mode="hist"/>
        <xsl:apply-templates select="comment"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  
  <xsl:template name="hist-date-field">
    <xsl:param name="field-name"/>
    <xsl:param name="field-default"/>
    <xsl:param name="field-comment"/>
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$field-name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="'date_type'"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="'NO'"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="'YES'"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="default">
        <xsl:value-of select="$field-default"/>
      </xsl:element>
      <xsl:element name="comment">
        <xsl:value-of select="$field-comment"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match="columns" mode="copy">
    <xsl:param name="is-dim"/>
    <xsl:element name="columns">
      <xsl:choose>
        <xsl:when test="$is-dim = 'true'">
          <xsl:apply-templates select="column[position() = 1]" mode="copy"/>
          <xsl:call-template name="hist-date-field">
            <xsl:with-param name="field-name" select="$valid-from"/>
            <xsl:with-param name="field-default" select="'current_date'"/>
            <xsl:with-param name="field-comment" select="concat('automatisch erzeugtes ',$valid-from,'-Datum')"/>
          </xsl:call-template>
          <xsl:call-template name="hist-date-field">
            <xsl:with-param name="field-name" select="$valid-to"/>
            <xsl:with-param name="field-default" select="concat($q,'31.12.9999',$q,'::date')"/>
            <xsl:with-param name="field-comment" select="concat('automatisch erzeugtes ',$valid-to,'-Datum')"/>
          </xsl:call-template>
          <xsl:apply-templates select="column[position() != 1]" mode="copy"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="column" mode="copy"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


  <xsl:template match="columns" mode="hist">
    <xsl:param name="is-dim"/>
    <xsl:element name="columns">
      <xsl:choose>
        <xsl:when test="$is-dim = 'true'">
          <xsl:apply-templates select="column[position() = 1]" mode="hist"/>
          <xsl:call-template name="hist-date-field">
            <xsl:with-param name="field-name" select="$valid-from"/>
            <xsl:with-param name="field-default" select="'current_date'"/>
            <xsl:with-param name="field-comment" select="concat('automatisch erzeugtes ',$valid-from,'-Datum')"/>
          </xsl:call-template>
          <xsl:call-template name="hist-date-field">
            <xsl:with-param name="field-name" select="$valid-to"/>
            <xsl:with-param name="field-default" select="concat($q,'31.12.9999',$q,'::date')"/>
            <xsl:with-param name="field-comment" select="concat('automatisch erzeugtes ',$valid-to,'-Datum')"/>
          </xsl:call-template>
          <xsl:apply-templates select="column[position() != 1]" mode="hist"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="column" mode="hist"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column" mode="copy">
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="@nullable"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
       <xsl:value-of select="@auto"/>
     </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
     <xsl:apply-templates select="default"/>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column" mode="hist">
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="@type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="@nullable"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="'YES'"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="references">
    <xsl:element name="references">
      <xsl:apply-templates select="reference"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="key" mode="copy">
    <xsl:element name="key">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="key" mode="hist">
    <xsl:param name="key"/>
    <xsl:element name="key">
      <xsl:choose>
        <xsl:when test="$key != ''">
          <xsl:value-of select="$key"/>
        </xsl:when>
        <xsl:otherwise>        
          <xsl:value-of select="text()"/>
        </xsl:otherwise>        
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="unique">
    <xsl:element name="unique">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:apply-templates select="key" mode="copy"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="primary" mode="copy">
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="key" mode="copy"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="primary" mode="hist">
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="key" mode="hist"/>
      <xsl:apply-templates select="key" mode="hist">
        <xsl:with-param name="key" select="$valid-from"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>


  <xsl:template name="trigger">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="trigger"/>
    <xsl:param name="function"/>
    <xsl:param name="action"/>
    <xsl:param name="pk-column"/>
    <xsl:element name="trigger">
      <xsl:attribute name="name">
        <xsl:value-of select="$trigger"/>
      </xsl:attribute>
      <xsl:element name="definition">
        <xsl:attribute name="action">
          <xsl:value-of select="$action"/>
        </xsl:attribute>
        <xsl:attribute name="level">
          <xsl:value-of select="'row'"/>
        </xsl:attribute>
        <xsl:attribute name="timing">
          <xsl:value-of select="'after'"/>
        </xsl:attribute>
        <xsl:attribute name="language">
          <xsl:value-of select="'plpgsql'"/>
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
          <xsl:apply-templates select="columns/column[@name = $pk-column]" mode="trigger-xml">
            <xsl:with-param name="type" select="'primary'"/>
          </xsl:apply-templates>
          <xsl:element name="field">
            <xsl:attribute name="name">
              <xsl:value-of select="$valid-from"/>
            </xsl:attribute>
            <xsl:attribute name="type">
              <xsl:value-of select="'valid-from'"/>
            </xsl:attribute>
          </xsl:element>
          <xsl:element name="field">
            <xsl:attribute name="name">
              <xsl:value-of select="$valid-to"/>
            </xsl:attribute>
            <xsl:attribute name="type">
              <xsl:value-of select="'valid-to'"/>
            </xsl:attribute>
          </xsl:element>
          <xsl:apply-templates select="columns/column[@name != $pk-column]" mode="trigger-xml">
            <xsl:with-param name="type" select="'other'"/>
          </xsl:apply-templates>
        </xsl:element>

      </xsl:element>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="table" mode="trigger">
    <xsl:param name="schema"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:variable name="insert-trigger" select="concat($table,'_ins_trg')"/>
    <xsl:variable name="update-trigger" select="concat($table,'_upd_trg')"/>
    <xsl:variable name="function-name" select="concat($table,'_trg_fun')"/>
    <xsl:variable name="pk-column" select="//table[@name = $table and @schema = $schema]/primary/key"/>
    <xsl:variable name="column-list">
      <xsl:apply-templates select="columns/column[@name != $pk-column]" mode="list"/>
    </xsl:variable>
    <xsl:element name="triggers">
      <xsl:call-template name="trigger">
        <xsl:with-param name="schema"     select="$schema"/>
        <xsl:with-param name="table"      select="$table"/>
        <xsl:with-param name="trigger"    select="$insert-trigger"/>
        <xsl:with-param name="function"   select="$function-name"/>
        <xsl:with-param name="action"     select="'insert'"/>
        <xsl:with-param name="pk-column"  select="$pk-column"/>
      </xsl:call-template>
      <xsl:call-template name="trigger">
        <xsl:with-param name="schema"     select="$schema"/>
        <xsl:with-param name="table"      select="$table"/>
        <xsl:with-param name="trigger"    select="$update-trigger"/>
        <xsl:with-param name="function"   select="$function-name"/>
        <xsl:with-param name="action"     select="'update'"/>
        <xsl:with-param name="pk-column"  select="$pk-column"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column" mode="trigger-xml">
    <xsl:param name="type"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="field">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="references">
    <xsl:element name="references">
      <xsl:apply-templates select="reference"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="reference">
    <xsl:element name="reference">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="@action"/>
      </xsl:attribute>
      <xsl:apply-templates select="source"/>
      <xsl:apply-templates select="target"/>
      <xsl:apply-templates select="foreign"/>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="source | target">
    <xsl:element name="{name()}">
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="@table"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="foreign">
    <xsl:element name="{name()}">
      <xsl:apply-templates select="key" mode='copy'/>
    </xsl:element>
  </xsl:template>


  <xsl:template name="metacolumn">
    <xsl:param name="name"/>
    <xsl:param name="type"/>
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="'NO'"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="'NO'"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template name="metapk">
    <xsl:param name="name"/>
    <xsl:param name="key"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:element name="key">
        <xsl:value-of select="$key"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  
  <xsl:template name="metainsert">
    <xsl:param name="project"/>
    <xsl:param name="version"/>
    <xsl:element name="insert">
      <xsl:attribute name="schema">
        <xsl:value-of select="$base-schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="'metadata'"/>
      </xsl:attribute>
      <xsl:element name="project">
        <xsl:value-of select="$project"/>
      </xsl:element>
      <xsl:element name="version">
        <xsl:value-of select="$version"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>
  

  <xsl:template name="metadata">
    <xsl:param name="project"/>
    <xsl:param name="version"/>
    <xsl:element name="metadata">
      <xsl:element name="table">
        <xsl:attribute name="name">
          <xsl:value-of select="'metadata'"/>
        </xsl:attribute>
        <xsl:attribute name="schema">
          <xsl:value-of select="$base-schema"/>
        </xsl:attribute>
        <xsl:attribute name="tablespace">
          <xsl:value-of select="$base-schema"/>
        </xsl:attribute>
        <xsl:attribute name="auto">
          <xsl:value-of select="'NO'"/>
        </xsl:attribute>
        <xsl:attribute name="action">
          <xsl:value-of select="'create'"/>
        </xsl:attribute>
        <xsl:element name="columns">
          <xsl:call-template name="metacolumn">
            <xsl:with-param name="name" select="'project'"/>
            <xsl:with-param name="type" select="'text_type'"/>
          </xsl:call-template>
          <xsl:call-template name="metacolumn">
            <xsl:with-param name="name" select="'version'"/>
            <xsl:with-param name="type" select="'count_type'"/>
          </xsl:call-template>
        </xsl:element>
        <xsl:call-template name="metapk">
          <xsl:with-param name="name" select="'pk_metadata'"/>
          <xsl:with-param name="key" select="'version'"/>
        </xsl:call-template>
      </xsl:element>    
      <xsl:call-template name="metainsert">
        <xsl:with-param name="project" select="$project"/>
        <xsl:with-param name="version" select="$version"/>
      </xsl:call-template>
      <xsl:element name="commit">
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  
</xsl:stylesheet>
