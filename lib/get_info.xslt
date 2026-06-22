<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>


  <xsl:template match="*">
    <xsl:variable name="node" select="name()"/>
    <xsl:choose>
      <xsl:when test="$node = 'model'">
        <xsl:value-of select="concat($node,':',@project,':',@version,$nl)"/>
      </xsl:when>
      <xsl:when test="$node = 'delta'">
        <xsl:value-of select="concat($node,':',@project,':',@old-version,':',@new-version,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('unknown top level element: ',$node,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
