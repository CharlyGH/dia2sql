<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn">

  <xsl:output method="xml"
              omit-xml-declaration="no"
              indent="yes"
              version="1.0"
              doctype-system="config.dtd"
              />


  <xsl:param name="basename"/>

   <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>
 
  <xsl:include href="functions.xslt"/>


  <xsl:template match="project">
    <xsl:element name="config">
      <xsl:apply-templates select="item[substring(@name,1,5) = 'valid']"   mode="column"/>
      <xsl:apply-templates select="item[contains(@value,'{}')]"            mode="schema"/>
      <xsl:apply-templates select="item[@info = 'sequence']"               mode="sequence"/>
      <xsl:apply-templates select="item[@name = 'tablespace-root']"        mode="tablespace"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="item" mode="column">
    <xsl:element name="columnconf">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="'YES'"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>


  <xsl:template match="item" mode="schema">
    <xsl:variable name="schema" select="fcn:replace-first(@value,'{}',$basename)"/>
    <xsl:variable name="auto" select="fcn:if-then-else(@info,'=','writable','NO','YES')"/>
    <xsl:element name="schemaconf">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="$schema"/>
      </xsl:attribute>
      <xsl:attribute name="auto">
        <xsl:value-of select="$auto"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="item" mode="sequence">
    <xsl:element name="sequenceconf">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="item" mode="tablespace">
    <xsl:element name="tablespaceconf">
      <xsl:attribute name="path">
        <xsl:value-of select="@value"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
</xsl:stylesheet>
