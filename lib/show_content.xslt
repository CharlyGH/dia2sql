<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                extension-element-prefixes="fcn"
                >

  <xsl:output method="text"
              omit-xml-declaration="yes" 
              indent="no"
              version="1.0"
              />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="gtab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  
  <xsl:param name="level"/>


  <xsl:template match="model">
    <xsl:if test="$level = 'all'">
      <xsl:apply-templates select="//tablespace">
        <xsl:with-param name="ltab"  select="$gtab"/>
      </xsl:apply-templates>
    </xsl:if> 
    <xsl:if test="$level = 'schema'">
      <xsl:apply-templates select="//schema" mode="list">
        <xsl:with-param name="ltab"  select="$gtab"/>
      </xsl:apply-templates>
    </xsl:if> 
    <xsl:if test="$level = 'all' or $level = 'table' or $level = 'column'">
      <xsl:apply-templates select="//schema" mode="detail">
        <xsl:with-param name="ltab"  select="$gtab"/>
      </xsl:apply-templates>
    </xsl:if> 
    <xsl:if test="$level = 'reference'">
      <xsl:apply-templates select="//schema" mode="reference">
        <xsl:with-param name="ltab"  select="$gtab"/>
      </xsl:apply-templates>
    </xsl:if> 
    <xsl:if test="$level = 'function'">
      <xsl:apply-templates select="//schema" mode="function">
        <xsl:with-param name="ltab"  select="$gtab"/>
      </xsl:apply-templates>
    </xsl:if> 
  </xsl:template>


  <xsl:template match="tablespace | domain | sequence | column">
    <xsl:param name="ltab"/>
    <xsl:value-of select="concat($ltab,@name,$nl)"/>
  </xsl:template>



  <xsl:template match="schema" mode="list">
    <xsl:param name="ltab"/>
    <xsl:value-of select="concat($ltab,@name,$nl)"/>
  </xsl:template>



  <xsl:template match="schema" mode="detail">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@name"/>
    <xsl:value-of select="concat($ltab,$schema,$nl)"/>

    <xsl:if test="$level = 'all'">
      <xsl:apply-templates select="//domain[@schema = $schema]">
        <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="//sequence[@schema = $schema]">
        <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:apply-templates select="//table[@schema = $schema]">
      <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
    </xsl:apply-templates>
  </xsl:template>



  <xsl:template match="table">
    <xsl:param name="ltab"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:value-of select="concat($ltab,@name,$nl)"/>
    <xsl:if test="$level = 'all' or $level = 'column'">
      <xsl:apply-templates select=".//column">
        <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="schema" mode="reference">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@name"/>
    <xsl:apply-templates select="//table[@schema = $schema]" mode="reference">
      <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="schema" mode="function">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@name"/>
    <xsl:value-of select="concat($ltab,$schema,$nl)"/>
    <xsl:apply-templates select="//table[@schema = $schema]" mode="function">
      <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="table" mode="reference">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table"  select="@name"/>
    <xsl:apply-templates select="//source[@schema = $schema and @table = $table]">
      <xsl:with-param name="ltab"  select="concat($ltab,$gtab)"/>
    </xsl:apply-templates>
  </xsl:template>

  

  <xsl:template match="table" mode="function">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table"  select="@name"/>
    <xsl:apply-templates select="//function[@schema = $schema and @table = $table]">
      <xsl:with-param name="ltab"  select="$ltab"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="function">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@table"/>
    <xsl:variable name="function" select="@name"/>
    <xsl:value-of select="concat($ltab,$function,' (',$table,')',$nl)"/>
  </xsl:template>
  

  <xsl:template match="source">
    <xsl:param name="ltab"/>
    <xsl:variable name="src-schema" select="@schema"/>
    <xsl:variable name="src-table"  select="@table"/>
    <xsl:variable name="src-pos"    select="position()"/>
    <xsl:if test="$src-pos = 1">
      <xsl:value-of select="concat($ltab,'s:',$src-schema,'.',$src-table,$nl)"/>
      <xsl:apply-templates select="//target">
        <xsl:with-param name="ltab"   select="concat($ltab,$gtab)"/>
        <xsl:with-param name="src-schema" select="$src-schema"/>
        <xsl:with-param name="src-table"  select="$src-table"/>
        <xsl:with-param name="src-pos"    select="$src-pos"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>


  <xsl:template match="target">
    <xsl:param name="ltab"/>
    <xsl:param name="src-schema"/>
    <xsl:param name="src-table"/>
    <xsl:param name="src-pos"/>
    <xsl:variable name="tgt-schema" select="@schema"/>
    <xsl:variable name="tgt-table"  select="@table"/>
    <xsl:variable name="tgt-pos"    select="position()"/>
    <xsl:if test="../source/@schema = $src-schema and ../source/@table = $src-table">
      <xsl:value-of select="concat($ltab,'t:',$tgt-schema,'.',$tgt-table,$nl)"/>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
