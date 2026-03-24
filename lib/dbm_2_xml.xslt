<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="fcn str"
                >

  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="model.dtd"
              />

  <xsl:param name="project"/>

  <xsl:param name="projectfile"/>

  <xsl:include href="functions.xslt"/>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>


  <fcn:function name="fcn:bool-id">
    <xsl:param name="arg"/>
    <xsl:param name="default"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="string-length($arg) = 0">
          <xsl:value-of select="$default"/>
        </xsl:when>
        <xsl:when test="$arg = 'true'">
          <xsl:value-of select="'YES'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'NO'"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:bool-not">
    <xsl:param name="arg"/>
    <xsl:param name="default"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="string-length($arg) = 0">
          <xsl:value-of select="$default"/>
        </xsl:when>
        <xsl:when test="$arg = 'false'">
          <xsl:value-of select="'YES'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'NO'"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  
  <fcn:function name="fcn:config-value">
    <xsl:param name="config"/>
    <xsl:param name="key"/>
    <xsl:variable name="raw-value"  select="exslt:node-set($config)/item[@name = $key]/@value"/>
    <fcn:result>
      <xsl:value-of select="fcn:replace-first($raw-value,'{}',$project)"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:trim-left">
    <xsl:param name="strg"/>
    <xsl:param name="chr" select="' '"/>
    <xsl:variable name="length" select="string-length($strg)"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$length = 0">
          <xsl:value-of select="$strg"/>
        </xsl:when>
        <xsl:when test="substring($strg,1,1) = $chr">
          <xsl:value-of select="fcn:trim-left(substring($strg,2),$chr)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$strg"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:trim-right">
    <xsl:param name="strg"/>
    <xsl:param name="chr" select="' '"/>
    <xsl:variable name="length" select="string-length($strg)"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="length = 0">
          <xsl:value-of select="$strg"/>
        </xsl:when>
        <xsl:when test="substring($strg,$length,1) = $chr">
          <xsl:value-of select="fcn:trim-left(substring($strg,1,$length - 1),$chr)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$strg"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:trim">
    <xsl:param name="strg"/>
    <xsl:param name="chr" select="' '"/>
    <xsl:variable name="length" select="string-length($strg)"/>
    <fcn:result>
      <xsl:value-of select="fcn:trim-left(fcn:trim-right($strg,$chr),$chr)"/>
    </fcn:result>
  </fcn:function>
  
  
  <fcn:function name="fcn:get-version">
    <xsl:param name="version-string"/>

    <xsl:variable name="raw-value" select="fcn:trim($version-string)"/>
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="fcn:to-lower-case(substring-before($raw-value,' ')) = 'version'">
          <xsl:value-of select="substring-after($raw-value,' ')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'1'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$value"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:iso-2-german">
    <xsl:param name="iso"/>
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="substring($iso,5,1) = '-' and substring($iso,8,1) = '-'">
          <xsl:value-of select="concat(substring($iso,9,2),'.',substring($iso,6,2),'.',substring($iso,1,4))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$iso"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$value"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:format-default">
    <xsl:param name="default"/>
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="$default = 'CURRENT_DATE'">
          <xsl:value-of select="'current_date'"/>
        </xsl:when>
        <xsl:when test="substring-after($default,'::') = 'date'">
          <xsl:variable name="iso" select="fcn:trim(substring-before($default,'::'),$q)"/>
          <xsl:value-of select="concat($q,fcn:iso-2-german($iso),$q,'::date')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$default"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$value"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-function-name">
    <xsl:param name="full-name"/>
    <fcn:result>
      <xsl:value-of select="substring-before(substring-after($full-name,'.'),'()')"/>
    </fcn:result>
  </fcn:function>

  
  <xsl:variable name="config" select="document($configfile)/config"/>

  <xsl:variable name="valid-from"  select="exslt:node-set($config)/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="exslt:node-set($config)/columnconf[@name = 'valid-to']/@value"/>

  <xsl:variable name="auto-column-list"
                select="concat('#',$valid-from,'#',$valid-to,'#')"/>
  
  <xsl:variable name="base-schema"  select="exslt:node-set($config)/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="const-schema" select="exslt:node-set($config)/schemaconf[@name = 'const']/@value"/>
  <xsl:variable name="dim-schema"   select="exslt:node-set($config)/schemaconf[@name = 'dim']/@value"/>
  <xsl:variable name="fact-schema"  select="exslt:node-set($config)/schemaconf[@name = 'fact']/@value"/>
  <xsl:variable name="hist-schema"  select="exslt:node-set($config)/schemaconf[@name = 'hist']/@value"/>

  <xsl:variable name="sequ-type"    select="exslt:node-set($config)/sequenceconf[@name = 'id-type']/@value"/>

  <xsl:variable name="schemas"
                select="concat('#',$base-schema,'#',$const-schema,'#',$dim-schema,'#',$fact-schema,'#',$hist-schema,'#')"/>
  
  <xsl:variable name="standard-types"
                select="'#double precision#integer#date#text#'"/>
  
  <xsl:template match="dbmodel">
    <xsl:variable name="project" select="database/@name"/>
    <xsl:variable name="version" select="fcn:get-version(database/comment/text())"/>
    <xsl:element name="model">
      <xsl:attribute name="project">
        <xsl:value-of select="$project"/>
      </xsl:attribute>
      <xsl:attribute name="version">
        <xsl:value-of select="$version"/>
      </xsl:attribute>
      <xsl:element name="tablespaces">
        <xsl:apply-templates select="tablespace"/>
      </xsl:element>
      <xsl:element name="schemas">
        <xsl:apply-templates select="schema[contains($schemas,@name)]"/>
      </xsl:element>
      <xsl:element name="domains">
        <xsl:apply-templates select="domain"/>
      </xsl:element>
      <xsl:element name="sequences">
        <xsl:apply-templates select="sequence"/>
      </xsl:element>
      <xsl:element name="tables">
        <xsl:apply-templates select="table[schema/@name = $const-schema]"/>
        <xsl:apply-templates select="table[schema/@name = $dim-schema]"/>
        <xsl:apply-templates select="table[schema/@name = $fact-schema]"/>
        <xsl:apply-templates select="table[schema/@name = $hist-schema]"/>
      </xsl:element>
      <xsl:element name="references">
        <xsl:apply-templates select="constraint[@type = 'fk-constr']" mode="foreign"/>
      </xsl:element>
      <xsl:element name="functions">
        <xsl:apply-templates select="function"/>
      </xsl:element>
      <xsl:apply-templates select="tables" mode="trg-fun"/>
      <xsl:call-template name="metadata">
        <xsl:with-param name="project" select="$project"/>
        <xsl:with-param name="version" select="$version"/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>


  <xsl:template match="tablespace">
    <xsl:element name="tablespace">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="location">
        <xsl:value-of select="fcn:trim(@directory,$q)"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>


  <xsl:template match="schema">
    <xsl:variable name="schema" select="@name"/>
    <xsl:element name="schema">
      <xsl:attribute name="name">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="exslt:node-set($config)/schemaconf[@value = $schema]/@auto"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="comment">
    <xsl:element name="comment">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="domain">
    <xsl:variable name="schema" select="schema/@name"/>
    <xsl:variable name="type" select="type/@name"/>
    <xsl:element name="domain">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="fcn:bool-not(@not-null)"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:apply-templates select="default"/>
      <xsl:if test="string-length(@default-value) != 0">
        <xsl:element name="default">
          <xsl:value-of select="@default-value"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="not(contains($standard-types,$type))">
        <xsl:element name="size">
          <xsl:value-of select="type/@length"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="sequence">
    <xsl:variable name="schema" select="schema/@name"/>
    <xsl:element name="sequence">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$sequ-type"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="config">
        <xsl:attribute name="start">
          <xsl:value-of select="@start"/>
        </xsl:attribute>
        <xsl:attribute name="min">
          <xsl:value-of select="@min-value"/>
        </xsl:attribute>
        <xsl:attribute name="max">
          <xsl:value-of select="@max-value"/>
        </xsl:attribute>
        <xsl:attribute name="increment">
          <xsl:value-of select="@increment"/>
        </xsl:attribute>
        <xsl:attribute name="cycle">
          <xsl:value-of select="substring(@cycle,1,1)"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="table">
    <xsl:variable name="schema" select="schema/@name"/>
    <xsl:variable name="name"   select="@name"/>
    <xsl:variable name="is-auto"  select="exslt:node-set($config)/schemaconf[@value = $schema]/@auto"/>
    <xsl:variable name="is-hist"  select="$schema = $hist-schema"/>
    <xsl:variable name="is-dim"   select="fcn:if-then-else($schema,'=',$dim-schema,'true','false')"/>
    <xsl:element name="table">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="tablespace">
        <xsl:value-of select="tablespace/@name"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="fcn:bool-id(($is-auto = 'YES') or $is-hist)"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="columns">
        <xsl:apply-templates select="column">
          <xsl:with-param name="schema" select="$schema"/>
        </xsl:apply-templates>
      </xsl:element>
      <xsl:apply-templates select="constraint[@type = 'uq-constr']" mode="unique"/>
      <xsl:apply-templates select="constraint[@type = 'pk-constr']" mode="primary"/>
      <xsl:if test="$is-dim = 'true'">
        <xsl:apply-templates select="."    mode="trigger">
          <xsl:with-param name="schema" select="$schema"/>
        </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="column">
    <xsl:param name="schema"/>
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="default" select="@default-value"/>
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$column"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="substring-after(type/@name,'.')"/>
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="fcn:bool-not(@not-null,'YES')"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
       <xsl:value-of select="fcn:bool-id(contains($auto-column-list,$column) or ($schema = $hist-schema))"/>
     </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:if test="string-length($default) != 0">
        <xsl:element name="default">
          <xsl:value-of select="fcn:format-default($default)"/>
        </xsl:element>
      </xsl:if> 
      <xsl:apply-templates select="comment"/>
    </xsl:element>
  </xsl:template>



  <xsl:template match="references">
    <xsl:element name="references">
      <xsl:apply-templates select="reference"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="key">
    <xsl:element name="key">
      <xsl:value-of select="text()"/>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="columns" mode="constraint">
    <xsl:variable name="key-list" select="@names"/>
    <xsl:for-each select="str:tokenize($key-list,',')">
      <xsl:element name="key">
        <xsl:value-of select="text()"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>

  
  <xsl:template match="constraint" mode="unique">
    <xsl:element name="unique">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:apply-templates select="columns" mode="constraint"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="constraint" mode="primary">
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="primary">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="columns" mode="constraint"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="constraint" mode="foreign">
    <xsl:variable name="name" select="@name"/>
    <xsl:element name="reference">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="action">
        <xsl:value-of select="'create'"/>
      </xsl:attribute>
      <xsl:element name="source">
        <xsl:attribute name="schema">
          <xsl:value-of select="substring-before(@table,'.')"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="substring-after(@table,'.')"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="target">
        <xsl:attribute name="schema">
          <xsl:value-of select="substring-before(@ref-table,'.')"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="substring-after(@ref-table,'.')"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="foreign">
        <xsl:element name="key">
          <xsl:value-of select="columns[@ref-type = 'dst-columns']/@names"/>
        </xsl:element>
      </xsl:element>
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
        <xsl:variable name="pk-column"
                      select="constraint[@type = 'pk-constr']/columns/@names"/>
        <xsl:element name="fields">
          <xsl:apply-templates select="column" mode="trigger-xml">
            <xsl:with-param name="pk-column" select="$pk-column"/>
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
    <xsl:param name="pk-column"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@name = $pk-column">
          <xsl:value-of select="'primary'"/>
        </xsl:when>
        <xsl:when test="@name = $valid-from">
          <xsl:value-of select="'valid-from'"/>
        </xsl:when>
        <xsl:when test="@name = $valid-to">
          <xsl:value-of select="'valid-to'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'other'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="field">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="function">
    <xsl:variable name="name"       select="@name"/>
    <xsl:variable name="schema"     select="schema/@name"/>
    <xsl:variable name="table"
                  select="substring-after(//trigger[fcn:get-function-name(function/@signature) = $name]/@table,'.')"/>

    <xsl:variable name="language"   select="language/@name"/>
    <xsl:variable name="definition" select="substring-before(substring-after(definition,'  begin'),'  return new;')"/>
    <xsl:element name="function">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:attribute name="schema">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="$table"/>
      </xsl:attribute>
      <xsl:element name="text">
        <xsl:attribute name="language">
          <xsl:value-of select="$language"/>
        </xsl:attribute>
        <xsl:value-of select="$definition"/>
      </xsl:element>
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
