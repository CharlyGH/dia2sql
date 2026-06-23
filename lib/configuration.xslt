<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn str">

  
  <xsl:param name="config-file"/>

  <xsl:template match="project">
    <xsl:element name="project">
      <xsl:apply-templates select="item"/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="item">
    <xsl:element name="item">
      <xsl:attribute name="name">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="value">
        <xsl:value-of select="fcn:replace-first(@value,'{}',$project)"/>
      </xsl:attribute>
      <xsl:attribute name="info">
        <xsl:value-of select="@info"/>
      </xsl:attribute>
      <xsl:attribute name="color">
        <xsl:value-of select="@color"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:variable name="global-config">
    <xsl:apply-templates select="document($config-file)/project"/>
  </xsl:variable>



  
  <fcn:function name="fcn:get-config-value">
    <xsl:param name="name"/>
    <xsl:param name="config" select="$global-config"/>
    <xsl:variable name="value" select="exslt:node-set($config)/project/item[@name = $name]/@value"/>
    <fcn:result>
      <xsl:value-of select="$value"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-config-info">
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <xsl:param name="config" select="$global-config"/>
    <xsl:variable name="info">
      <xsl:choose>
        <xsl:when test="string-length($name) != 0">
          <xsl:value-of select="exslt:node-set($config)/project/item[@name = $name]/@info"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="exslt:node-set($config)/project/item[@value = $value]/@info"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <fcn:result>
      <xsl:value-of select="$info"/>
    </fcn:result>
  </fcn:function>



  <fcn:function name="fcn:get-schema-color">
    <xsl:param name="schema"/>
    <xsl:param name="config" select="$global-config"/>
    <xsl:variable name="color">
      <xsl:value-of select="exslt:node-set($config)/project/item[@value = $schema]/@color"/>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$color"/>
    </fcn:result>
  </fcn:function>



  <xsl:template name="check-config">
    <xsl:param name="name"/>
    <xsl:for-each select="str:tokenize($name,',')">
      <xsl:variable name="value" select="dyn:evaluate(concat('$',text()))"/>
      <xsl:if test="string-length($value) = 0">
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('missing configuration value for ',$name,$nl)"/>
        </xsl:message>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  
</xsl:stylesheet> 
