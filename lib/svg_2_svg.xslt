<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                extension-element-prefixes="fcn"
                >

  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
              doctype-public="-//W3C//DTD SVG 1.1//EN"
              />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:param name="master"/>

  <fcn:function name="fcn:to-lower-case" >
    <xsl:param name="string" />

    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'" />

    <fcn:result>
      <xsl:value-of select="translate($string, $uppercase, $lowercase)" />
    </fcn:result>
  </fcn:function>


  
  <fcn:function name="fcn:find-comment">
    <xsl:param name="master"/>
    <xsl:param name="table"/>
    <xsl:param name="column"/>

    <xsl:variable name="lc-tab" select="fcn:to-lower-case($table)"/>
    <xsl:variable name="lc-col" select="fcn:to-lower-case($column)"/>
    
    <xsl:variable name="dom-comment"
                  select="document($master)/schema/domain[@name = $lc-col]/comment/text()"/>
    <xsl:variable name="tab-comment"
                  select="document($master)/schema/table[@name = $lc-tab]/comment/text()"/>
    <xsl:variable name="col-comment"
                  select="document($master)/schema/table[@name = $lc-tab]/column[@name = $lc-col]/comment/text()"/>
    
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$dom-comment != ''">
          <xsl:value-of select="$dom-comment" />
        </xsl:when>
        <xsl:when test="$col-comment != ''">
          <xsl:value-of select="$col-comment" />
        </xsl:when>
        <xsl:when test="$tab-comment != ''">
          <xsl:value-of select="$tab-comment" />
        </xsl:when>
      </xsl:choose>
    </fcn:result>
  </fcn:function>

  
  
  <xsl:template match="svg">
    <xsl:element name="svg">
      <xsl:attribute name="width">
        <xsl:value-of select="@width"/>
      </xsl:attribute>
      <xsl:attribute name="height">
        <xsl:value-of select="@height"/>
      </xsl:attribute>
      <xsl:attribute name="viewBox">
        <xsl:value-of select="@viewBox"/>
      </xsl:attribute>
      <xsl:attribute name="ns">
        <xsl:value-of select="'http://www.w3.org/2000/svg'"/>
      </xsl:attribute>
      <xsl:apply-templates select="g">
        <xsl:with-param name="parent" select="''"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>


  <xsl:template match="g">
    <xsl:param name="parent"/>
    <xsl:variable name="me" select="title/text()"/>
    <!--
        <xsl:variable name="comment" select="fcn:find-comment($master,$parent,'')"/>
    -->
    <xsl:element name="g">
      <xsl:attribute name="id">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:attribute name="class">
        <xsl:value-of select="@class"/>
      </xsl:attribute>
      <xsl:if test="@transform != ''">
        <xsl:attribute name="transform">
          <xsl:value-of select="@transform"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="title"/>
      <xsl:apply-templates select="path"/>
      <xsl:apply-templates select="polygon"/>
      <xsl:apply-templates select="text">
        <xsl:with-param name="parent" select="$me"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="g">
        <xsl:with-param name="parent" select="$me"/>
      </xsl:apply-templates>
    </xsl:element>
  </xsl:template>

  <xsl:template match="title">
    <xsl:element name="title">
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>


  <xsl:template match="path">
    <xsl:element name="path">
      <xsl:attribute name="fill">
        <xsl:value-of select="@fill"/>
      </xsl:attribute>
      <xsl:attribute name="stroke">
        <xsl:value-of select="@stroke"/>
      </xsl:attribute>
      <xsl:attribute name="d">
        <xsl:value-of select="@d"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>


  <xsl:template match="polygon">
    <xsl:element name="polygon">
      <xsl:attribute name="fill">
        <xsl:value-of select="@fill"/>
      </xsl:attribute>
      <xsl:attribute name="stroke">
        <xsl:value-of select="@stroke"/>
      </xsl:attribute>
      <xsl:attribute name="points">
        <xsl:value-of select="@points"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>


  <xsl:template match="text">
    <xsl:param name="parent"/>
    <xsl:variable name="text" select="text()"/>
    <xsl:variable name="comment" select="fcn:find-comment($master,$parent,$text)"/>
    <xsl:element name="text">
      <xsl:attribute name="text-anchor">
        <xsl:value-of select="@text-anchor"/>
      </xsl:attribute>
      <xsl:attribute name="x">
        <xsl:value-of select="@x"/>
      </xsl:attribute>
      <xsl:attribute name="y">
        <xsl:value-of select="@y"/>
      </xsl:attribute>
      <xsl:if test="@font-family != ''">
        <xsl:attribute name="font-family">
          <xsl:value-of select="@font-family"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@font-style != ''">
        <xsl:attribute name="font-style">
          <xsl:value-of select="@font-style"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@font-weight != ''">
        <xsl:attribute name="font-weight">
          <xsl:value-of select="@font-weight"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@font-size != ''">
        <xsl:attribute name="font-size">
          <xsl:value-of select="@font-size"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$comment = ''">
          <xsl:value-of select="$text"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:element name="title">
            <xsl:value-of select="$comment"/>
          </xsl:element>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>


</xsl:stylesheet> 
