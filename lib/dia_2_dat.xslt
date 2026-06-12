<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="fcn exslt str">

  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="no"
              />

  <xsl:include href="functions.xslt"/>
  
  <xsl:template match="dia:diagram">
    <xsl:apply-templates select="dia:layer[@active='true']" />
  </xsl:template>

  
  <xsl:template match="dia:layer">
    <xsl:variable name="type" select="'Database - Table'"/>
    <xsl:variable name="text" select="'#MetaData#'"/>
    <xsl:apply-templates select="dia:object[@type = $type]/dia:attribute[@name = 'name']/dia:string[text() = $text]/../.."/>
  </xsl:template>


  <xsl:template match="dia:object">
    <xsl:variable name="result">
      <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite[@type = 'table_attribute']">
        <xsl:with-param name="key" select="'Projekt'"/>
      </xsl:apply-templates >
      <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite[@type = 'table_attribute']">
        <xsl:with-param name="key" select="'Version'"/>
      </xsl:apply-templates >
    </xsl:variable>
    <xsl:value-of select="concat(substring(fcn:to-lower-case($result),2),$nl)"/>
  </xsl:template>


  <xsl:template match="dia:composite">
    <xsl:param name="key"/>
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name = 'type']/dia:string/text())"/>
    <xsl:if test="$name = $key">
      <xsl:value-of select="concat(':',$type)"/>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>
