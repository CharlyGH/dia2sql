<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                extension-element-prefixes="fcn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="tablename"/>
  
  <xsl:variable name="space">
    <xsl:text>                    </xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="space-size" select="string-length($space)" />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="q">
    <xsl:text>&apos;</xsl:text>
  </xsl:variable>

  <xsl:variable name="dim-schema" select="/model/schemas/schema[position() = 1]/@name"/>

  <fcn:function name="fcn:nvl" >
    <xsl:param name="first" />
    <xsl:param name="last" />

    <fcn:result>
      <xsl:choose>
        <xsl:when test="$first != ''">
          <xsl:value-of select="$first" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$last" />
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>


  <xsl:template match="model">
    <xsl:apply-templates select="schemas"/>
  </xsl:template>


  <xsl:template match="schemas">
    <xsl:apply-templates select="schema"/>
  </xsl:template>


  <xsl:template match="schema">
    <xsl:variable name="schema" select="@name" />

    <xsl:value-of select="concat('S#',$schema,$nl)" />
    <xsl:choose>
      <xsl:when test="$tablename != ''">
        <xsl:apply-templates select="table[@name = $tablename]">
          <xsl:with-param name="schema" select="$schema" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="tables">
          <xsl:with-param name="schema" select="$schema" />
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  
  <xsl:template match="tables">
    <xsl:param name="schema" />
    <xsl:apply-templates select="table">
      <xsl:with-param name="schema" select="$schema" />
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="table">
    <xsl:param name="schema" />
    <xsl:variable name="table" select="@name" />
    
    <xsl:value-of select="concat('T#',$table,$nl)" />
    <xsl:apply-templates select="columns">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table"  select="$table" />
    </xsl:apply-templates>

    <xsl:value-of select="concat('end',$nl)" />

  </xsl:template>


  <xsl:template match="columns">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:apply-templates select="column">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table"  select="$table" />
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="column">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="simple-type" select="@type"/>
    <xsl:variable name="dom-type" select="/model/schemas/schema[@name = $dim-schema]/domains/domain[@name = $simple-type]/@type"/>
    <xsl:variable name="comment" select="@comment"/>

    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="string-length($dom-type) = 0">
          <xsl:value-of select="$simple-type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$dom-type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="col-val">
      <xsl:value-of select="constraint/value[position() = 1]"/>
    </xsl:variable>

    <xsl:variable name="dom-val">
      <xsl:value-of select="/model/schemas/schema[@name = $dim-schema]/domains/domain[@name = $simple-type]/constraint/value[position() = 1]"/>
    </xsl:variable>

    <xsl:variable name="default" select="default/text()"/>

    <xsl:variable name="reference">
      <xsl:for-each select="/model/schemas/schema[@name = $schema]/tables/table[@name = $table]/references/reference/key">
        <xsl:if test="$column = text()">
          <xsl:value-of select="../@target"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    
    <xsl:value-of select="concat('C#',$column,'#',$type,'#',fcn:nvl($col-val,$dom-val),$nl)"/>
    <xsl:if test="$default != ''">
      <xsl:value-of select="concat('D#',$column,'#',$default,$nl)"/>
    </xsl:if>
    <xsl:if test="$reference != ''">
      <xsl:value-of select="concat('R#',$column,'#',$reference,$nl)"/>
    </xsl:if>
  </xsl:template>

  
</xsl:stylesheet> 
