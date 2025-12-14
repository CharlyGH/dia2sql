<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn"
                >
  <xsl:output method="text"
              omit-xml-declaration="yes" 
              indent="no"
              version="1.0"
              doctype-system="report.dtd"
              />
<!--
  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="report.dtd"
              />
-->


  <xsl:param name="basename"/>

  <xsl:param name="projectfile"/>

  <xsl:param name="table"/>

  <xsl:param name="schema"/>

  <xsl:include href="functions.xslt"/>


  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>


  <xsl:variable name="dim-name" select="fcn:get-project-value($projectfile,'dimension',$basename)"/>


  
<!--
  <fcn:function name="fcn:get-ref-list-recu">
    <xsl:param name="src-schema"/>
    <xsl:param name="src-table"/>
    <xsl:param name="level"/>

    <xsl:variable name="next-level" select="$level + 1"/>
    <xsl:variable name="ref-list">
      <xsl:for-each select="/model/schemas/schema[@name = $src-schema]/tables/table[@name = $src-table]/references/reference">
        <xsl:element name="reference">
          <xsl:variable name="tgt-schema">
            <xsl:value-of select="@target-schema"/>
          </xsl:variable>
          <xsl:variable name="tgt-table">
            <xsl:value-of select="@target-table"/>
          </xsl:variable>
          <xsl:element name="table">
            <xsl:attribute name="schema-name">
              <xsl:value-of select="$tgt-schema"/>
            </xsl:attribute>
            <xsl:attribute name="table-name">
              <xsl:value-of select="$tgt-table"/>
            </xsl:attribute>
            <xsl:copy-of select="fcn:get-ref-list-recu($tgt-schema,$tgt-table,$next-level)"/>
          </xsl:element>
        </xsl:element>
      </xsl:for-each>
    </xsl:variable>
    <fcn:result>
      <xsl:copy-of select="$ref-list" />
    </fcn:result>
  </fcn:function>

    
  <fcn:function name="fcn:get-ref-list">
    <xsl:param name="src-schema"/>
    <xsl:param name="src-table"/>
    <xsl:param name="level"/>
    <fcn:result>
      <xsl:element name="table">
        <xsl:attribute name="schema-name">
          <xsl:value-of select="$src-schema"/>
        </xsl:attribute>
        <xsl:attribute name="table-name">
          <xsl:value-of select="$src-table"/>
        </xsl:attribute>
        <xsl:copy-of select="fcn:get-ref-list-recu($src-schema,$src-table,0)"/>
      </xsl:element>
    </fcn:result>
  </fcn:function>
-->


  <fcn:function name="fcn:get-ref-list-recu">
    <xsl:param name="src-schema"/>
    <xsl:param name="src-table"/>
    <xsl:param name="level"/>

    <xsl:variable name="next-level" select="$level + 1"/>
    <xsl:variable name="ref-list">
      <xsl:for-each select="/model/schemas/schema[@name = $src-schema]/tables/table[@name = $src-table]/references/reference">
        <xsl:variable name="tgt-schema">
          <xsl:value-of select="@target-schema"/>
        </xsl:variable>
        <xsl:variable name="tgt-table">
          <xsl:value-of select="@target-table"/>
        </xsl:variable>
        <xsl:variable name="recu-result">
          <xsl:value-of select="fcn:get-ref-list-recu($tgt-schema,$tgt-table,$next-level)"/>
        </xsl:variable>
        <xsl:variable name="opt-tab">
          <xsl:value-of select="fcn:if-then-else($level,'=',0,$tab,'')"/>
        </xsl:variable>
        <xsl:variable name="opt-delim">
          <xsl:value-of select="fcn:if-then-else($recu-result,'!=','',':','')"/>
        </xsl:variable>
        <xsl:value-of select="concat($opt-tab,$tgt-schema,'.',$tgt-table,$opt-delim,$recu-result)"/>
      </xsl:for-each>
      <xsl:variable name="opt-nl">
        <xsl:value-of select="fcn:if-then-else($level,'=',1,$nl,'')"/>
      </xsl:variable>
      <xsl:value-of select="$opt-nl"/>
    </xsl:variable>
    <fcn:result>
      <xsl:copy-of select="$ref-list" />
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:name-or-all">
    <xsl:param name="attr-name"/>
    <xsl:param name="var-name"/>
    <xsl:param name="all-name"/>
    <xsl:variable name="test-name">
      <xsl:choose>
        <xsl:when test="$var-name = $all-name">
          <xsl:value-of select="$attr-name" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$var-name" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$test-name" />
    </fcn:result>
  </fcn:function>

  

  <fcn:function name="fcn:get-ref-list">
    <xsl:param name="src-schema"/>
    <xsl:param name="src-table"/>
    <fcn:result>
      <xsl:if test="/model/schemas/schema[@name = $src-schema]/tables/table[@name = $src-table]/@name = $src-table">
        <xsl:value-of select="concat($src-schema,'.',$src-table,':',$nl,fcn:get-ref-list-recu($src-schema,$src-table,0),$nl)"/>
      </xsl:if>
    </fcn:result>
  </fcn:function>

  
  <xsl:template match="model">
    <xsl:for-each select="/model/schemas/schema[@name = $schema or 'all' = $schema]/tables/table[@name = $table or 'all' = $table]">
      <xsl:variable name="schema-name" select="(../../@name)"/>
      <xsl:variable name="table-name" select="(@name)"/>
      <xsl:value-of select="fcn:get-ref-list($schema-name,$table-name)"/>
    </xsl:for-each>
  </xsl:template>

  
  <xsl:template match="table">
    <xsl:variable name="src-table" select="@name"/>
    <xsl:for-each select="../table/references/reference[@target-table = $src-table]">
      <xsl:variable name="tgt-table" select="../../@name"/>
      <xsl:element name="ref">
        <xsl:attribute name="source">
          <xsl:value-of select="$src-table"/>
        </xsl:attribute>
        <xsl:attribute name="target">
          <xsl:value-of select="$tgt-table"/>
        </xsl:attribute>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>


  
</xsl:stylesheet>


