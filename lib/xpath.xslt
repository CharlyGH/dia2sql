<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="path"/>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="result" select="dyn:evaluate($path)"/>

  <xsl:template match="*">
    <xsl:value-of select="concat($result,$nl)"/>
  </xsl:template>

</xsl:stylesheet>