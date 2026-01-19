<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:str="http://exslt.org/strings"
                xmlns:math="http://exslt.org/math"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn str math exslt dyn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="xmldoc"/>
  
  <xsl:param name="tmpsrt"/>
  
  <xsl:variable name="space">
    <xsl:text>                    </xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:include href="functions.xslt"/>
  
  <xsl:variable name="space-size" select="string-length($space)" />

  <xsl:variable name="config" select="document($configfile)/config"/>

  <xsl:variable name="base-schema" select="exslt:node-set($config)/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="dim-schema"  select="exslt:node-set($config)/schemaconf[@name = 'dim']/@value"/>
  <xsl:variable name="fact-schema" select="exslt:node-set($config)/schemaconf[@name = 'fact']/@value"/>
  <xsl:variable name="hist-schema" select="exslt:node-set($config)/schemaconf[@name = 'hist']/@value"/>

  <xsl:variable name="valid-from"  select="exslt:node-set($config)/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="exslt:node-set($config)/columnconf[@name = 'valid-to']/@value"/>


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


  <fcn:function name="fcn:depth" >
    <xsl:param name="target" />
    <xsl:param name="level" />
    <xsl:variable name="next-level" select="$level + 1"/>
    <xsl:variable name="tgt-schema"
                  select="substring-before($target,'.')"/>
    <xsl:variable name="tgt-table"
                  select="substring-after($target,'.')"/>
    <xsl:variable name="name-list">
      <!--
          only works if document name supplied, no idea why this happens
      -->
      
      <xsl:for-each select="document($xmldoc)//reference/target[@schema = $tgt-schema and @table = $tgt-table]">
        <xsl:variable name="src-schema" select="../source/@schema"/>
        <xsl:variable name="src-table"  select="../source/@table"/>

        <xsl:value-of select="concat($src-schema,'.',$src-table)" />
        <xsl:if test="position() != last()">
          <xsl:value-of select="'#'" />
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="depth-list">
      <xsl:choose>
        <xsl:when test="contains($name-list,'#')">
          <xsl:for-each select="str:tokenize($name-list,'#')">
            <xsl:variable name="name" select="text()"/>
            <xsl:value-of select="fcn:depth($name,$next-level)"/>
            <xsl:if test="position() != last()">
              <xsl:value-of select="'#'" />
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$name-list != ''">
            <xsl:variable name="name" select="$name-list"/>
          <xsl:value-of select="fcn:depth($name,$next-level)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$level"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="result">
      <xsl:value-of select="math:max(str:tokenize($depth-list,'#'))" />
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$result"/>
    </fcn:result>
  </fcn:function>

  
  <xsl:template name="calc-depth">
    <xsl:variable name="target" select="concat(@schema,'.',@name)"/>
    <xsl:variable name="depth" select="fcn:depth($target,1)"/>
    <xsl:element name="data">
      <xsl:attribute name="schema">
        <xsl:value-of select="@schema"/>
      </xsl:attribute>
      <xsl:attribute name="table">
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:attribute name="depth">
        <xsl:value-of select="$depth"/>
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="model">
    <exslt:document href="{$tmpsrt}"
                    method="xml"
                    omit-xml-declaration="no"
                    indent="yes"
                    doctype-system="list.dtd">
      <xsl:element name="list">
        <xsl:for-each select="//table[@schema = $dim-schema]">
          <xsl:call-template name="calc-depth"/> 
        </xsl:for-each>
        <xsl:for-each select="//table[@schema = $fact-schema]">
          <xsl:call-template name="calc-depth"/> 
        </xsl:for-each>
      </xsl:element>
    </exslt:document>
    <xsl:apply-templates select="document($tmpsrt)/list"/>
  </xsl:template>


  <xsl:template name="write-list">
    <xsl:param name="kind"/>
    <xsl:variable name="schema" select="dyn:evaluate(concat('$',$kind,'-schema'))"/>
    <xsl:value-of select="concat('S#',$schema,'#',$kind,$nl)"/>
    <xsl:apply-templates select="data[@schema = $schema]">
      <xsl:sort select="@depth" order="descending"/>
      <xsl:with-param name="kind" select="$kind"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('end',$nl)"/>

  </xsl:template>
  

  <xsl:template match="list">
    <xsl:call-template name="write-list">
      <xsl:with-param name="kind"   select="'dim'"/>
    </xsl:call-template>
    <xsl:call-template name="write-list">
      <xsl:with-param name="kind"   select="'fact'"/>
    </xsl:call-template>
  </xsl:template>
  
  
  <xsl:template match="data">
    <xsl:param name="kind"/>
    <xsl:variable name="schema" select="@schema"/> 
    <xsl:variable name="table"  select="@table"/> 
    <xsl:apply-templates select="document($xmldoc)//table[@schema = $schema and @name = $table]">
      <xsl:with-param name="kind"   select="$kind"/>
    </xsl:apply-templates>
  </xsl:template>
  

  <xsl:template match="table">
    <xsl:param name="kind"/>
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema" />
    <xsl:variable name="reference">
      <xsl:apply-templates select="document($xmldoc)//reference/source[@schema = $schema and @table = $table]"/>
    </xsl:variable>
    <xsl:value-of select="concat('T#',$table,'#',$reference,$nl)"/>
    <xsl:apply-templates select="columns/column">
      <xsl:with-param name="kind" select="$kind"/>
      <xsl:with-param name="schema" select="@schema"/>
      <xsl:with-param name="table"  select="@name"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('end',$nl)"/>
  </xsl:template>


  <xsl:template match="source">
    <xsl:value-of select="../target/@table"/>
    <xsl:if test="position() != last()">
      <xsl:value-of select="':'"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="column">
    <xsl:param name="kind"/>
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="simple-type" select="@type"/>
    <xsl:variable name="dom-type" select="//domain[@name = $simple-type]/@type"/>
    <xsl:variable name="comment" select="@comment"/>
    <xsl:variable name="default" select="default/text()"/>
    <xsl:variable name="type" select="fcn:if-then-else(string-length($dom-type),'=',0,$simple-type,$dom-type)"/>

    <xsl:variable name="constraint">
      <xsl:choose>
        <xsl:when test="$dom-type != ''">
          <xsl:value-of select="//domain[@name = $simple-type]/constraint/value"/> 
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="constraint/value"/> 
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="reference">
      <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/../foreign/key">
        <xsl:if test="text() = $column">
          <xsl:value-of select="concat(../../target/@schema,':',../../target/@table,':',text())"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="primary">
      <xsl:for-each select="../../primary/key">
        <xsl:if test="text() = $column">
          <xsl:value-of select="'P'"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="unique">
      <xsl:for-each select="../../unique/key">
        <xsl:if test="text() = $column">
          <xsl:value-of select="'U'"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:value-of select="concat('C#',$column,'#',$type,'#',$default,'#',$constraint,'#',$primary,$unique,
                          '#',$reference,$nl)"/>
  </xsl:template>

  
</xsl:stylesheet> 
