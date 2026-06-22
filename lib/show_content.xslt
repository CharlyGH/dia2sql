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


  <xsl:variable name="gtab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  
  <xsl:param name="objectlist"/>

  <xsl:param name="schema"/>

  <xsl:param name="table"/>

  <xsl:include href="functions.xslt"/>

  <xsl:template match="model">
    <xsl:variable name="ntab" select="fcn:if-contains-else($objectlist,'model',$gtab,'')"/>

    <xsl:if test="contains($objectlist,'model')">
      <xsl:value-of select="concat(@project,$nl)"/>
    </xsl:if>

    <xsl:apply-templates select="model/tablespaces/tablespace">
        <xsl:with-param name="ltab"  select="$ntab"/>
      </xsl:apply-templates>

    <xsl:choose>
      <xsl:when test="string-length($schema) != 0">
        <xsl:apply-templates select="//schema[@name = $schema]">
          <xsl:with-param name="ltab"  select="$ntab"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="//schema">
          <xsl:with-param name="ltab"  select="$ntab"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="tablespace">
    <xsl:param name="ltab"/>
    <xsl:if test="contains($objectlist,'tablespace')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if> 
  </xsl:template>


  <xsl:template match="schema">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@name"/>
    <xsl:variable name="ntab" select="fcn:if-contains-else($objectlist,'schema',concat($ltab,$gtab),$ltab)"/>

    <xsl:if test="contains($objectlist,'schema')">
      <xsl:value-of select="concat($ltab,$schema,$nl)"/>
    </xsl:if>
    <xsl:apply-templates select="/model/domains/domain[@schema = $schema]">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="/model/sequences/sequence[@schema = $schema]">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="/model/tables/table[@schema = $schema]">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="table">
    <xsl:param name="ltab"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:variable name="ntab" select="fcn:if-contains-else($objectlist,'table',concat($ltab,$gtab),ltab)"/>

    <xsl:if test="contains($objectlist,'table')">
      <xsl:value-of select="concat($ltab,$table,$nl)"/>
    </xsl:if>

    <xsl:apply-templates select="columns/column">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>

    <xsl:apply-templates select="/model/references/reference/source[@schema = $schema and @table = $table]/..">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>
    
    <xsl:apply-templates select="/model/functions/function[@schema = $schema and @table = $table]">
      <xsl:with-param name="ltab"  select="$ntab"/>
    </xsl:apply-templates>
    
  </xsl:template>

  
  <xsl:template match="column">
    <xsl:param name="ltab"/>
    <xsl:if test="contains($objectlist,'column')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="domain">
    <xsl:param name="ltab"/>

    <xsl:if test="contains($objectlist,'domain')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="sequence">
    <xsl:param name="ltab"/>

    <xsl:if test="contains($objectlist,'sequence')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="reference">
    <xsl:param name="ltab"/>
    <xsl:if test="contains($objectlist,'reference')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="function">
    <xsl:param name="ltab"/>
    <xsl:if test="contains($objectlist,'function')">
      <xsl:value-of select="concat($ltab,@name,$nl)"/>
    </xsl:if>
  </xsl:template>





</xsl:stylesheet>
