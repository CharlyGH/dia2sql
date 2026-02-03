<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="configfile" />
  

  <xsl:variable name="gtab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="empty">
    <xsl:text></xsl:text>
  </xsl:variable>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="comma">
    <xsl:text>,</xsl:text>
  </xsl:variable>

  


  <xsl:variable name="config" select="document($configfile)/config"/>

  <xsl:variable name="base-schema" select="exslt:node-set($config)/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="valid-from"  select="exslt:node-set($config)/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="exslt:node-set($config)/columnconf[@name = 'valid-to']/@value"/>
  
  
  <xsl:include href="functions.xslt"/>

  <fcn:function name="fcn:json-boolean" >
    <xsl:param name="value" />

    <fcn:result>
      <xsl:choose>
        <xsl:when test="$value = 'YES'">
          <xsl:value-of select="'true'"/>
        </xsl:when>
        <xsl:when test="$value = 'NO'">
          <xsl:value-of select="'false'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'error'"/>
        </xsl:otherwise>
      </xsl:choose>

    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:get-delimiter" >
    <xsl:param name="position" />
    <xsl:param name="last" />
    <xsl:param name="delim" />

    <fcn:result>
      <xsl:choose>
        <xsl:when test="$position != $last">
          <xsl:value-of select="$delim"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$empty"/>
        </xsl:otherwise>
      </xsl:choose>

    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:get-type" >
    <xsl:param name="type-name" />
    
    <xsl:variable name="dom-type" select="//domain[@name = $type-name]/@type"/>
    <xsl:variable name="res-type">
      <xsl:choose>
        <xsl:when test="string-length($dom-type) = 0">
          <xsl:value-of select="$type-name"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$dom-type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$res-type"/>
    </fcn:result>
  </fcn:function>

 
  <fcn:function name="fcn:is-key" >
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="column" />
    <xsl:param name="kind" />

    <xsl:variable name="key">
      <xsl:choose>
        <xsl:when test="$kind = 'primary'">
          <xsl:for-each select="//table[@name = $table and @schema = $schema]/primary/key">
            <xsl:if test="text() = $column">
              <xsl:value-of select="$column"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$kind = 'unique'">
          <xsl:for-each select="//table[@name = $table and @schema = $schema]/unique/key">
            <xsl:if test="text() = $column">
              <xsl:value-of select="$column"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$kind = 'foreign'">
          <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/../foreign/key">
            <xsl:if test="text() = $column">
              <xsl:value-of select="$column"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'undefined'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <fcn:result>
      <xsl:choose>
        <xsl:when test="$key = $column">
          <xsl:value-of select="'true'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'false'"/>
        </xsl:otherwise>
      </xsl:choose>

    </fcn:result>
  </fcn:function>

 
  <fcn:function name="fcn:get-ref-info" >
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="column" />
    <xsl:param name="kind" />

    <xsl:variable name="refschema">
      <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/../foreign/key">
        <xsl:if test="text() = $column">
          <xsl:value-of select="../../target/@schema"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="reftable">
      <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/../foreign/key">
        <xsl:if test="text() = $column">
          <xsl:value-of select="../../target/@table"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="refcomment">
      <xsl:value-of select="//table[@name = $table and @schema = $schema]/comment"/>
    </xsl:variable>

    <xsl:variable name="refpos">
      <xsl:for-each select="//table[@name = $table and @schema = $schema]/columns/column">
        <xsl:if test="@name = $column">
          <xsl:value-of select="position() - 1"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$kind = 'schema'">
          <xsl:value-of select="$refschema"/>
        </xsl:when>
        <xsl:when test="$kind = 'table'">
          <xsl:value-of select="$reftable"/>
        </xsl:when>
        <xsl:when test="$kind = 'comment'">
          <xsl:value-of select="$refcomment"/>
        </xsl:when>
        <xsl:when test="$kind = 'position'">
          <xsl:value-of select="$refpos"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'undefined'"/>
        </xsl:otherwise>
      </xsl:choose>

    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:if-not-0">
    <xsl:param name="number"/>
    <xsl:param name="value"/>
    <fcn:result>
      <xsl:if test="$number != 0">
        <xsl:value-of select="$value"/>
      </xsl:if>
    </fcn:result>
  </fcn:function>


  
  <xsl:template match="model">
    <xsl:variable name="nltab" select="concat($gtab,$gtab)" />
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat($gtab,$dq,'config',$dq,': {',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'valid-from',$dq,': ',$dq,$valid-from,$dq,',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'valid-to',  $dq,': ',$dq,$valid-to,$dq,$nl)"/>
    <xsl:value-of select="concat($gtab,'},',$nl)"/>
    <xsl:apply-templates select="schemas"/>
    <xsl:value-of select="concat('}',$nl,$nl)"/>
  </xsl:template>


  <xsl:template match="schemas">

    <xsl:variable name="nltab" select="concat($gtab,$gtab)" />
    <xsl:value-of select="concat($gtab,$dq,'schemas',$dq,': [',$nl)"/>
    <xsl:apply-templates select="schema" mode="list">
      <xsl:with-param name="ltab" select="$nltab"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat($gtab,'],',$nl)"/>

    <xsl:apply-templates select="schema" mode="detail">
      <xsl:with-param name="ltab" select="nltab"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="schema" mode="list">
    <xsl:param name="ltab"/>

    <xsl:variable name="schema"   select="@name" />
    <xsl:variable name="t-count"  select="count(//table[@schema = $schema])"/>
    <xsl:variable name="delim" select="fcn:get-delimiter(position(),last(),$comma)"/>

    <xsl:if test="$t-count != 0">
      <xsl:value-of select="concat($ltab,$dq,@name,$dq,$delim,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="schema" mode="detail">
    <xsl:param name="ltab"/>

    <xsl:variable name="delim"    select="fcn:get-delimiter(position(),last(),$comma)"/>
    <xsl:variable name="schema"   select="@name" />
    <xsl:variable name="auto"     select="fcn:json-boolean(@auto)"/>
    <xsl:variable name="desc"     select="comment" />

    <xsl:variable name="ltab"     select="$empty" />
    <xsl:variable name="nltab"    select="concat($ltab,$gtab)" />
    <xsl:variable name="nnltab"   select="concat($nltab,$gtab)" />

    <xsl:variable name="t-count"  select="count(/model/tables/table[@schema = $schema])"/>
    <xsl:variable name="opt-comma" select="fcn:if-then-else($t-count,'=','0','',',')"/>

    <xsl:if test="$t-count != 0">
      <xsl:value-of select="concat($nltab, $dq,@name,         $dq, ': {',                           $nl)"/>
      <xsl:value-of select="concat($nnltab,$dq,'name',        $dq, ': ',$dq, $schema, $dq, $comma,    $nl)"/>
      <xsl:value-of select="concat($nnltab,$dq,'auto',        $dq, ': ',     $auto,        $comma,    $nl)"/>
      <xsl:value-of select="concat($nnltab,$dq,'table-count', $dq, ': ',     $t-count,     $comma,    $nl)"/>
      <xsl:value-of select="concat($nnltab,$dq,'comment',     $dq, ': ',$dq, $desc,   $dq, $opt-comma,$nl)"/>
    
      <xsl:apply-templates select="//tables" mode="list">
        <xsl:with-param name="schema" select="$schema" />
        <xsl:with-param name="ltab"   select="$nnltab" />
      </xsl:apply-templates>

      <xsl:apply-templates select="//tables" mode="detail">
        <xsl:with-param name="schema" select="$schema" />
        <xsl:with-param name="ltab" select="$nnltab" />
      </xsl:apply-templates>
      <xsl:value-of select="concat($nltab,'}',$delim,$nl)"/>
    </xsl:if>

  </xsl:template>

  
  <xsl:template match="tables" mode="list">
    <xsl:param name="schema"/>
    <xsl:param name="ltab"/>
    <xsl:value-of select="concat($ltab,$dq,'tables',$dq,': [',$nl)"/>
    <xsl:apply-templates select="table[@schema = $schema]" mode="list">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="ltab" select="concat($ltab,$gtab)" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($ltab,'],',$nl)"/>
  </xsl:template>

  
  <xsl:template match="table" mode="list">
    <xsl:param name="schema"/>
    <xsl:param name="ltab"/>
    <xsl:variable name="name" select="@name" />
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:variable name="delim" select="fcn:get-delimiter(position(),last(),$comma)"/>
    <xsl:value-of select="concat($nltab,$dq,$name,$dq,$delim,$nl)"/>
  </xsl:template>

  
  <xsl:template match="tables" mode="detail">
    <xsl:param name="schema"/>
    <xsl:param name="ltab"/>

    <xsl:apply-templates select="table[@schema = $schema]" mode="detail">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="ltab" select="$ltab" />
    </xsl:apply-templates>

  </xsl:template>

  
  <xsl:template match="table" mode="detail">
    <xsl:param name="schema"/>
    <xsl:param name="ltab"/>
    <xsl:variable name="comment"        select="comment/text()"/>
    <xsl:variable name="table"          select="@name" />
    <xsl:variable name="auto"           select="fcn:json-boolean(@auto)" />
    <xsl:variable name="nltab"          select="concat($ltab,$gtab)" />
    <xsl:variable name="column-count"   select="count(columns/column)" />
    <xsl:variable name="primary-count"  select="count(primary/key)" />
    <xsl:variable name="unique-count"   select="count(unique/key)" />
    <xsl:variable name="foreign-count"  select="count(//reference/source[@schema = $schema and @table = $table])" />
    <xsl:variable name="ref-count"      select="count(//reference/target[@schema = $schema and @table = $table])" />
    <xsl:variable name="delim"          select="fcn:get-delimiter(position(),last(),$comma)"/>
    <xsl:variable name="table-kind">
      <xsl:choose>
        <xsl:when test="substring($schema,1,3) = 'dim'">
          <xsl:value-of select="'dimension'"/>
        </xsl:when>
        <xsl:when test="substring($schema,1,4) = 'fakt'">
          <xsl:value-of select="'fact'"/>
        </xsl:when>
        <xsl:when test="substring($schema,1,4) = 'hist'">
          <xsl:value-of select="'history'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">
            <xsl:value-of select="concat('Unknown schema prefix in ',$schema)"/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:value-of select="concat($ltab, $dq,$table,         $dq,': {',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'name',         $dq,': ',$dq,$table,        $dq,',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'auto',         $dq,': ',    $auto,             ',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'comment',      $dq,': ',$dq,$comment,      $dq,',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'type',         $dq,': ',$dq,$table-kind,   $dq,',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'ref-count',    $dq,': ',    $ref-count,        ',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'column-count', $dq,': ',    $column-count,     ',',$nl)"/>

    <xsl:apply-templates select="columns" mode="list">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table"  select="$table" />
      <xsl:with-param name="ltab"   select="concat($ltab,$gtab)" />
    </xsl:apply-templates>

    <xsl:apply-templates select="columns" mode="detail">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table"  select="$table" />
      <xsl:with-param name="ltab"   select="concat($ltab,$gtab)" />
    </xsl:apply-templates>

    <xsl:value-of select="concat($nltab,$dq,'foreign-count',$dq,': ',$foreign-count,',',$nl)"/>

    <xsl:if test="$foreign-count != 0">
      <xsl:apply-templates select="references/reference">
        <xsl:with-param name="schema"     select="$schema" />
        <xsl:with-param name="table"      select="$table" />
        <xsl:with-param name="ltab"       select="concat($ltab,$gtab)" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="$foreign-count != 0">
      <xsl:value-of select="concat($nltab,$dq,'reference',  $dq,': [',$nl)"/>
      <xsl:apply-templates select="//source[@schema = $schema and @table = $table]">
        <xsl:with-param name="ltab"   select="concat($ltab,$gtab)" />
      </xsl:apply-templates>
      <xsl:value-of select="concat($nltab,'],',$nl)"/>
    </xsl:if>
    
    <xsl:value-of select="concat($nltab,$dq,'unique-count',$dq,': ',$unique-count,',',$nl)"/>

    <xsl:if test="$unique-count != 0">
      <xsl:apply-templates select="unique">
        <xsl:with-param name="schema"     select="$schema" />
        <xsl:with-param name="table"      select="$table" />
        <xsl:with-param name="ltab"       select="concat($ltab,$gtab)" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:value-of select="concat($nltab,$dq,'primary-count',$dq,': ',$primary-count,',',$nl)"/>

    <xsl:apply-templates select="primary">
      <xsl:with-param name="schema"     select="$schema" />
      <xsl:with-param name="table"      select="$table" />
      <xsl:with-param name="ltab"       select="concat($ltab,$gtab)" />
    </xsl:apply-templates>
    
    <xsl:value-of select="concat($ltab,'}',$delim,$nl)"/>
   
  </xsl:template>

  
  <xsl:template match="source">
    <xsl:param name="ltab"/>
    <xsl:variable name="src-schema" select="@schema"/>
    <xsl:variable name="src-table"  select="@table"/>
    <xsl:variable name="tgt-schema" select="../target/@schema"/>
    <xsl:variable name="tgt-table"  select="../target/@table"/>
    <xsl:variable name="ref-name"   select="../@name"/>
    <xsl:variable name="delim" select="fcn:get-delimiter(position(),last(),$comma)"/>
    <xsl:apply-templates select="//table[@schema = $tgt-schema and @name = $tgt-table]" mode="reference">
      <xsl:with-param name="ltab"     select="concat($ltab,$gtab)"/>
      <xsl:with-param name="delim"    select="$delim"/>
      <xsl:with-param name="ref-name" select="$ref-name"/>
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="table" mode="reference">
    <xsl:param name="ltab"/>
    <xsl:param name="delim"/>
    <xsl:param name="ref-name"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table"  select="@name"/>
    <xsl:variable name="foreign-count"  select="count(//reference/source[@schema = $schema and @table = $table])" />
    <xsl:variable name="unique-count"  select="count(unique)" />
    
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:value-of select="concat($ltab,'{',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'name',  $dq,': ',$dq,$table  ,$dq,',',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'schema',$dq,': ',$dq,$schema,$dq,',',$nl)"/>

    <xsl:value-of select="concat($nltab,$dq,'key',  $dq,': [',$nl)"/>
    <xsl:apply-templates select="//reference[@name = $ref-name]/foreign/key" mode="reference">
      <xsl:with-param name="ltab"     select="concat($nltab,$gtab)"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat($nltab,']',fcn:if-then-else($unique-count + $foreign-count,'=','0','',','),$nl)"/>

    <xsl:if test="$unique-count != 0">
      <xsl:value-of select="concat($nltab,$dq,'unique',  $dq,': [',$nl)"/>
      <xsl:apply-templates select="unique/key" mode="reference">
        <xsl:with-param name="ltab"     select="concat($nltab,$gtab)"/>
      </xsl:apply-templates>
      <xsl:value-of select="concat($nltab,']',fcn:if-not-0($foreign-count,','),$nl)"/>
    </xsl:if>
    
    <xsl:if test="$foreign-count != 0">
      <xsl:value-of select="concat($nltab,$dq,'reference',  $dq,': [',$nl)"/>
      <xsl:apply-templates select="//source[@schema = $schema and @table = $table]">
        <xsl:with-param name="ltab"   select="concat($ltab,$gtab)" />
      </xsl:apply-templates>
      <xsl:value-of select="concat($nltab,']',$nl)"/>
    </xsl:if>
    <xsl:value-of select="concat($ltab,'}',$delim,$nl)"/>
  </xsl:template>

  
  <xsl:template match="key" mode="reference">
    <xsl:param name="ltab"/>
    <xsl:variable name="key" select="text()"/>
    <xsl:value-of select="concat($ltab,$dq,$key,$dq,fcn:get-delimiter(position(),last(),','),$nl)"/>
  </xsl:template>


  <xsl:template match="columns" mode="list">
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:variable name="name" select="@name" />
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:variable name="delim" select="$comma"/>

    <xsl:value-of select="concat($ltab,$dq,'columns',$dq,': [',$nl)"/>
    <xsl:apply-templates select="column" mode="list">
      <xsl:with-param name="table"       select="$table" />
      <xsl:with-param name="ltab"        select="$nltab" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($ltab,']',$delim,$nl)"/>

  </xsl:template>


  
  <xsl:template match="columns" mode="detail">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:apply-templates select="column" mode="detail">
      <xsl:with-param name="schema"      select="$schema" />
      <xsl:with-param name="table"       select="$table" />
      <xsl:with-param name="ltab"        select="$ltab" />
    </xsl:apply-templates>

  </xsl:template>


  
  <xsl:template match="column" mode="list">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>
    <xsl:variable name="column"     select="@name" />
    <xsl:variable name="nltab"      select="concat($ltab,$gtab)" />
    <xsl:variable name="delim"      select="fcn:get-delimiter(position(),last(),$comma)"/>
    <xsl:value-of select="concat($nltab,$dq,$column,    $dq,$delim,$nl)"/>
  </xsl:template>


  <xsl:template match="column" mode="detail">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>
    <xsl:variable name="column"      select="@name" />
    <xsl:variable name="auto"        select="fcn:json-boolean(@auto)" />
    <xsl:variable name="nltab"       select="concat($ltab,$gtab)" />
    <xsl:variable name="pos"         select="position() - 1"/>
    <xsl:variable name="nullable"    select="fcn:json-boolean(@nullable)" />
    <xsl:variable name="raw-type"    select="@type" />
    <xsl:variable name="type"        select="fcn:get-type(@type)" />
    <xsl:variable name="desc"        select="comment" />
    <xsl:variable name="ispk"        select="fcn:is-key($schema,$table,$column,'primary')" />
    <xsl:variable name="isuk"        select="fcn:is-key($schema,$table,$column,'unique')" />
    <xsl:variable name="isfk"        select="fcn:is-key($schema,$table,$column,'foreign')" />
    <xsl:variable name="refschema"   select="fcn:get-ref-info($schema,$table,$column,'schema')" />
    <xsl:variable name="reftable"    select="fcn:get-ref-info($schema,$table,$column,'table')" />
    <xsl:variable name="refcomment"  select="fcn:get-ref-info($refschema,$reftable,$column,'comment')" />
    <xsl:variable name="refpos"      select="fcn:get-ref-info($refschema,$reftable,$column,'position')" />

    <xsl:value-of select="concat($ltab,$dq,$column,$dq,': {',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'name',    $dq,': ',$dq,$column,    $dq,$comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'auto',    $dq,': ',    $auto,        $comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'pos',     $dq,': ',    $pos,         $comma,$nl)"/>

    <xsl:value-of select="concat($nltab,$dq,'nullable',$dq,': ',    $nullable,    $comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'type',    $dq,': ',$dq,$type,    $dq,$comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'ispk',    $dq,': ',    $ispk,        $comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'isuk',    $dq,': ',    $isuk,        $comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'isfk',    $dq,': ',    $isfk,        $comma,$nl)"/>
    
    <xsl:if test="$isfk = 'true'">
      <xsl:value-of select="concat($nltab,$dq,'refschema',  $dq,': ',$dq,$refschema,  $dq,$comma,$nl)"/>
      <xsl:value-of select="concat($nltab,$dq,'reftable',   $dq,': ',$dq,$reftable,   $dq,$comma,$nl)"/>
      <xsl:value-of select="concat($nltab,$dq,'refcomment', $dq,': ',$dq,$refcomment, $dq,$comma,$nl)"/>
      <xsl:value-of select="concat($nltab,$dq,'refpos',     $dq,': ',    $refpos,         $comma,$nl)"/>
    </xsl:if>
    <xsl:apply-templates select="//domain[@name = $raw-type and @schema = $base-schema]/constraint[@type = 'any']" mode="any">
      <xsl:with-param name="ltab" select="$nltab" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($nltab,$dq,'comment',    $dq,': ',$dq,$desc,    $dq,       $nl)"/>
    <xsl:value-of select="concat($ltab,'}',$comma,$nl)"/>
  </xsl:template>


  <xsl:template match="constraint" mode="any">
    <xsl:param name="ltab"/>
    <xsl:variable name="nltab"     select="concat($ltab,$gtab)" />
    <xsl:value-of select="concat($ltab,$dq,'check',$dq,': [',$nl)"/>
    <xsl:for-each select="value">
      <xsl:variable name="value"   select="fcn:replace(text(),$q,'')"/>      
      <xsl:variable name="delim"   select="fcn:get-delimiter(position(),last(),$comma)"/>      
      <xsl:value-of select="concat($nltab,$dq,$value,$dq,$delim,$nl)"/>
    </xsl:for-each>
    <xsl:value-of select="concat($ltab,'],',$nl)"/>
  </xsl:template>


  <xsl:template match="reference">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:variable name="name"   select="@name" />
    <xsl:variable name="target" select="@target" />
    <xsl:variable name="nltab"  select="concat($ltab,$gtab)" />
    <xsl:variable name="delim"  select="$comma"/>

    <xsl:value-of select="concat($ltab,$dq,'foreign',$dq,': [',$nl)"/>
    <xsl:apply-templates select="key">
      <xsl:with-param name="target"      select="$target" />
      <xsl:with-param name="schema"      select="$schema" />
      <xsl:with-param name="table"       select="$table" />
      <xsl:with-param name="ltab"        select="$nltab" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($ltab,']',$delim,$nl)"/>

  </xsl:template>


  <xsl:template match="unique">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:variable name="name" select="@name" />
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:variable name="delim" select="$comma"/>

    <xsl:value-of select="concat($ltab,$dq,'unique',$dq,': [',$nl)"/>
    <xsl:apply-templates select="key">
      <xsl:with-param name="schema"     select="$schema" />
      <xsl:with-param name="table"      select="$table" />
      <xsl:with-param name="ltab"       select="$nltab" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($ltab,']',$delim,$nl)"/>

  </xsl:template>


  <xsl:template match="primary">
    <xsl:param name="target"/>
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:variable name="name" select="@name" />
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:variable name="delim" select="fcn:get-delimiter(position(),last(),$comma)"/>

    <xsl:value-of select="concat($ltab,$dq,'primary',$dq,': [',$nl)"/>
    <xsl:apply-templates select="key">
      <xsl:with-param name="schema"     select="$schema" />
      <xsl:with-param name="table"      select="$table" />
      <xsl:with-param name="ltab"       select="$nltab" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($ltab,']',$delim,$nl)"/>

  </xsl:template>

  
  <xsl:template match="key">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="ltab"/>

    <xsl:variable name="key" select="text()" />
    <xsl:variable name="nltab" select="concat($ltab,$gtab)" />
    <xsl:variable name="delim" select="fcn:get-delimiter(position(),last(),$comma)"/>

    <xsl:variable name="pos">
      <xsl:for-each select="//table[@name = $table and @schema = $schema]/columns/column">
        <xsl:if test="@name = $key">
          <xsl:value-of select="position() - 1"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:value-of select="concat($ltab,'{',$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'key',$dq,': ',$dq,$key,$dq,$comma,$nl)"/>
    <xsl:value-of select="concat($nltab,$dq,'pos',$dq,': ',    $pos,    $nl)"/>
    <xsl:value-of select="concat($ltab,'}',$delim,$nl)"/>

  </xsl:template>

  
</xsl:stylesheet> 
