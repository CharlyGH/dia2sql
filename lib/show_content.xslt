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


</xsl:stylesheet>
