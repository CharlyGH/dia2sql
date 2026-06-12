<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="fcn exslt str">

  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="no"
              />

  <xsl:include href="functions.xslt"/>
  
  <xsl:template match="dbmodel">
    <xsl:apply-templates select="database" />
  </xsl:template>

  
  <xsl:template match="database">
    <xsl:variable name="project" select="@name"/>
    <xsl:variable name="version" select="substring-before(substring-after(substring(comment/text(),2),' '),' ')"/>
    <xsl:value-of select="concat($project,':',$version,$nl)"/>
  </xsl:template>


</xsl:stylesheet>
