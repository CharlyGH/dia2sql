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

  <xsl:variable name="space">
    <xsl:text>                    </xsl:text>
  </xsl:variable>

  <xsl:variable name="ht-4">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="ht-8">
    <xsl:text>        </xsl:text>
  </xsl:variable>

  <xsl:param name="document-name"/>  

  <xsl:param name="mode"/>

  <xsl:param name="count"/>

  <xsl:include href="functions.xslt"/>
  
  <xsl:variable name="project">
    <xsl:value-of select="fcn:to-lower-case(/model/@project)"/>
  </xsl:variable>

  <xsl:variable name="version">
    <xsl:value-of select="fcn:to-lower-case(/model/@version)"/>
  </xsl:variable>

  <xsl:include href="configuration.xslt"/>
  

  <xsl:variable name="space-size" select="string-length($space)" />

  <xsl:variable name="base-schema"  select="fcn:get-config-value('base')"/>
 <xsl:variable name="const-schema" select="fcn:get-config-value('const')"/>
  <xsl:variable name="dim-schema"   select="fcn:get-config-value('dim')"/>
  <xsl:variable name="fact-schema"  select="fcn:get-config-value('fact')"/>
  <xsl:variable name="hist-schema"  select="fcn:get-config-value('hist')"/>

  <xsl:variable name="valid-from"  select="fcn:get-config-value('valid-from')"/>
  <xsl:variable name="valid-to"    select="fcn:get-config-value('valid-to')"/>



  <fcn:function name="fcn:calc-depth">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="depth"/>
    <xsl:variable name="next-depth" select="$depth + 1"/>
    <xsl:variable name="result">
      <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/..">
        <xsl:value-of select="fcn:calc-depth(target/@schema,target/@table,$next-depth)"/>
      </xsl:for-each>
      <xsl:value-of select="concat($next-depth,' ')"/>
    </xsl:variable>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$depth = 0">
          <xsl:value-of select="math:max(str:tokenize($result,' '))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$result"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>

    

  <fcn:function name="fcn:get-test-value">
    <xsl:param name="type"/>
    <xsl:param name="text"/>
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="$type = 'amount_type'">
          <xsl:value-of select="concat('0.1234 + sd.rownum::integer','')"/>
        </xsl:when>
        <xsl:when test="$type = 'count_type'">
          <xsl:value-of select="concat('sd.rownum::integer')"/>
        </xsl:when>
        <xsl:when test="$type = 'date_type'">
          <xsl:value-of select="concat($q,'31.12.2020',$q,'::date + sd.rownum::integer')"/>
        </xsl:when>
        <xsl:when test="$type = 'id_type'">
          <xsl:value-of select="concat('sd.rownum::integer','')"/>
        </xsl:when>
        <xsl:when test="$type = 'text_type'">
          <xsl:value-of select="concat('concat(',$q,$text,'-',$q,',','sd.rownum::integer)')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">
            <xsl:value-of select="concat('unknown type [',$type,']',$nl)"/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$result"/>
    </fcn:result>
  </fcn:function>

    

  <fcn:function name="fcn:make-node-string">
    <xsl:param name="len"/>
    <xsl:param name="del" select="' '"/>
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="$len = 1">
          <xsl:value-of select="$len"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(fcn:make-node-string($len - 1,$del),$del,$len)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$result"/>
    </fcn:result>
  </fcn:function>

  
  
  <xsl:template match="model">
    <xsl:choose>
      <xsl:when test="$mode = 'count'">
        <xsl:value-of select="concat('select sum(cnt) total',$nl)"/>
        <xsl:value-of select="concat('  from (',$nl)"/>
        <xsl:apply-templates select="tables/table" mode="count"/>
        <xsl:value-of select="concat('    )',$nl)"/>
        <xsl:value-of select="concat(';',$nl)"/>
      </xsl:when>
      <xsl:when test="$mode = 'data'">
        <xsl:value-of select="concat('begin;',$nl,$nl)"/>
        <xsl:variable name="table-list">
          <xsl:for-each select="tables/table[@schema != $hist-schema]">
            <xsl:element name="table">
              <xsl:attribute name="name">
                 <xsl:value-of select="@name"/>
              </xsl:attribute>
              <xsl:attribute name="schema">
                 <xsl:value-of select="@schema"/>
              </xsl:attribute>
              <xsl:attribute name="depth">
                 <xsl:value-of select="fcn:calc-depth(@schema,@name,0)"/>
              </xsl:attribute>
            </xsl:element>
          </xsl:for-each>
        </xsl:variable>        
        <xsl:for-each select="exslt:node-set($table-list)/table">
          <xsl:sort select="concat(@depth,@schema,@table)"/>
          <xsl:variable name="schema" select="@schema"/>
          <xsl:variable name="table" select="@name"/>
          <xsl:variable name="depth" select="@depth"/>
          <xsl:apply-templates select="document($document-name)//table[@name = $table and @schema = $schema]"
                               mode="insert"/>
        </xsl:for-each>
        <xsl:value-of select="concat($nl,'commit;',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('unknown mode [',$mode,']',$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="table" mode="count">
     <xsl:value-of select="concat($ht-8,'select ',$q,@schema,'.',@name,$q,' name, count(*) cnt',$nl)"/>
     <xsl:value-of select="concat($ht-8,'  from ',@schema,'.',@name,$nl)"/>
     <xsl:if test="position() != last()">
       <xsl:value-of select="concat($ht-8,'union',$nl)"/>
     </xsl:if>
  </xsl:template>

  
  <xsl:template match="table" mode="insert">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:variable name="foreign">
      <xsl:for-each select="//reference/source[@schema = $schema and @table = $table]/..">
        <xsl:value-of select="@name"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="exslt:node-set(str:tokenize(fcn:make-node-string($count)))">
      <xsl:variable name="value" select="text()"/>
      <xsl:variable name="position" select="position()"/>
      <xsl:if test="string-length($foreign) = 0 or $position = 1">
        <xsl:value-of select="concat('insert into ',$schema,'.',$table,$nl,$ht-8,'(')"/>
        <xsl:apply-templates select="document($document-name)//table[@name = $table and @schema = $schema]/columns/column"
                             mode="names"/>
        <xsl:value-of select="concat(')',$nl)"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="string-length($foreign) = 0">
          <xsl:value-of select="concat($ht-8,'values',$nl)"/>
          <xsl:value-of select="concat($ht-8,'(')"/>
          <xsl:apply-templates select="document($document-name)//table[@name = $table and @schema = $schema]/columns/column"
                               mode="values">
            <xsl:with-param name="value" select="$value"/>
          </xsl:apply-templates>
          <xsl:value-of select="concat(');',$nl,$nl)"/>
        </xsl:when>
        <xsl:when test="$position = 1">
          <xsl:value-of select="concat('with source_data as',$nl)"/>
          <xsl:value-of select="concat($ht-4,'(select ')"/>
          <xsl:apply-templates select="document($document-name)//source[@schema = $schema and @table = $table]/.."
                               mode="fkey"/>
          <xsl:value-of select="concat('row_number() over() rownum',$nl)"/>
          <xsl:apply-templates select="document($document-name)//source[@schema = $schema and @table = $table]/.."
                               mode="tables"/>
          <xsl:value-of select="concat(')',$nl)"/>
          <xsl:apply-templates select="document($document-name)//table[@name = $table and @schema = $schema]/columns/column"
                               mode="select">
            <xsl:with-param name="schema" select="$schema"/>
            <xsl:with-param name="table" select="$table"/>
          </xsl:apply-templates>
          <xsl:value-of select="concat('  from source_data sd;',$nl,$nl)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  
  <xsl:template match="reference" mode="fkey">
    <xsl:value-of select="concat('rt',position(),'.',foreign/key/text(),', ')"/>
  </xsl:template>


  <xsl:template match="reference" mode="tables">
    <xsl:choose>
      <xsl:when test="position() = 1">
        <xsl:value-of select="concat($ht-8,'from ',target/@schema,'.',target/@table,' rt',position())"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($ht-8,'cross join ',target/@schema,'.',target/@table,' rt',position())"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="fcn:if-then-else(position(),'=',last(),'',$nl)"/>
  </xsl:template>

  
  <xsl:template match="column" mode="names">
    <xsl:variable name="column" select="@name"/>
    <xsl:value-of select="$column"/>
    <xsl:if test="position() != last()">
      <xsl:value-of select="', '"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="column" mode="values">
    <xsl:param name="value"/>
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="$type = 'amount_type'">
          <xsl:value-of select="concat($value,'.0')"/>
        </xsl:when>
        <xsl:when test="$type = 'count_type'">
          <xsl:value-of select="$value"/>
        </xsl:when>
        <xsl:when test="$type = 'date_type'">
          <xsl:value-of select="concat($q,'01.01.2026',$q,'::date + ',$value)"/>
        </xsl:when>
        <xsl:when test="$type = 'id_type'">
          <xsl:value-of select="$value"/>
        </xsl:when>
        <xsl:when test="$type = 'text_type'">
          <xsl:value-of select="concat($q,comment,'-',$value,$q)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$value"/>
    <xsl:if test="position() != last()">
      <xsl:value-of select="', '"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="column" mode="select">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:variable name="pos" select= "position()"/>
    <xsl:variable name="comment" select="comment"/>
    
    <xsl:variable name="primary">
      <xsl:for-each select="../../primary/key[text() = $column]">
        <xsl:value-of select="text()"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="foreign">
      <xsl:for-each select="//source[@schema = $schema and @table = $table]/../foreign/key[text() = $column]">
        <xsl:value-of select="text()"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="value">
      <xsl:choose>
        <xsl:when test="$column = $foreign">
          <xsl:value-of select="concat('sd.',$column)"/>
        </xsl:when>
        <xsl:when test="$column = $valid-from">
          <xsl:value-of select="concat($q,'31.12.2000',$q,'::date + sd.rownum::integer')"/>
        </xsl:when>
        <xsl:when test="$column = $valid-to">
          <xsl:value-of select="concat($q,'31.12.2030',$q,'::date + sd.rownum::integer')"/>
        </xsl:when>
        <xsl:when test="$column = $primary">
          <xsl:value-of select="concat(fcn:get-test-value($type,$comment),'')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(fcn:get-test-value($type,$comment),'')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat(fcn:if-then-else($pos,'=',1,'select ','       '),$value,
                          fcn:if-then-else($pos,'=',last(),'',','),$nl)"/>
  </xsl:template>


</xsl:stylesheet> 
