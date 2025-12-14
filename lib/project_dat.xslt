<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="project"/>

  <xsl:param name="basename"/>

   <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>
 
  <xsl:include href="functions.xslt"/>


  <xsl:template match="project">
    <xsl:apply-templates select="item[substring(@name,1,5) = 'valid']"   mode="column"/>
    <xsl:apply-templates select="item[contains(@value,'{}')]"            mode="schema"/>
    <xsl:apply-templates select="item[@info = 'sequence']"               mode="sequence"/>
    <xsl:apply-templates select="item[@name = 'tablespace-root']"        mode="tablespace"/>
  </xsl:template>


  <xsl:template match="item" mode="schema">
    <xsl:variable name="schema" select="fcn:replace-first(@value,'{}',$basename)"/>
    <xsl:variable name="auto" select="fcn:if-then-else(@info,'=','writable','NO','YES')"/>
    <xsl:value-of select="concat('schemaconf#',@name,'#',$schema,'#',$auto,$nl)"/>
  </xsl:template>


  <xsl:template match="item" mode="column">
    <xsl:value-of select="concat('columnconf#',@value,'#','YES',$nl)"/>
  </xsl:template>

  
  <xsl:template match="item" mode="sequence">
    <xsl:value-of select="concat('sequenceconf#',@name,'#',@value,$nl)"/>
  </xsl:template>

  <xsl:template match="item" mode="tablespace">
    <xsl:value-of select="concat('tablespaceconf#',@value,$nl)"/>
  </xsl:template>

  
</xsl:stylesheet>
