<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                xmlns:str="http://exslt.org/strings"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn exslt str dyn">

  <xsl:output method="text"
              omit-xml-declaration="yes"
              indent="no"
              />
  
  <xsl:include href="functions.xslt"/> 

  <xsl:variable name="project">
    <xsl:value-of select="fcn:to-lower-case(diagram/metadata/metaitem[@name = 'projekt']/@type)"/>
  </xsl:variable>

  <xsl:variable name="version">
    <xsl:value-of select="fcn:to-lower-case(diagram/metadata/metaitem[@name = 'version']/@type)"/>
  </xsl:variable>

  <xsl:include href="configuration.xslt"/>
  


  <xsl:template match="diagram">
    <xsl:variable name="result-list">
      <!-- Rule 1: number of definitions must match number of references -->
      <xsl:call-template name="rule-1"/>
      
      <!-- Rule 2: each referenced table must have a definition -->
      <xsl:call-template name="rule-2"/>
      
      <!-- Rule 3: each defined table must be referenced -->
      <xsl:call-template name="rule-3"/>
      
      <!-- Rule 4: no duplictes in definition list allowed -->
      <xsl:call-template name="rule-4"/>
      
      <!-- Rule 5: no duplictes in reference list allowed -->
      <xsl:call-template name="rule-5"/>
      
      <!-- Rule 6: no column name should match valid_from or valid_to -->
      <xsl:call-template name="rule-6"/>
      
      <!-- Rule 7: primary key for const or dim table must be single column -->
      <xsl:call-template name="rule-7"/>
      
      <!-- Rule 8: primary key for const and dim table must be of type Id_Type -->
      <xsl:call-template name="rule-8"/>
      
      <!-- Rule 9: primary key columns for const and dim tables must be unique in model -->
      <xsl:call-template name="rule-9"/>
      
      <!-- Rule 10: all tables must have primary key -->
      <xsl:call-template name="rule-10"/>
      
      <!-- Rule 11: non primary key column names should be unique in all const and dim tables of model -->
          <xsl:call-template name="rule-11"/>
      
    </xsl:variable>
    
    <!-- end of rules -->
    <xsl:choose>
      <xsl:when test="not(contains($result-list,'ERROR:'))">
        <xsl:value-of select="concat('check succeded:  ',$nl,$result-list,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('check failed',$nl,$result-list,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template name="rule-1">
    <!-- Rule 1: number of definitions must match number of references -->
    <xsl:variable name="table-ref-count"
                  select="count(metadata/metaitem[@name = 'schema' and @type != 'Base']/metadetail)"/>
    <xsl:variable name="table-def-count"
                  select="count(tables/table)"/>
    
    <xsl:choose>
      <xsl:when test="$table-ref-count = $table-def-count">
        <xsl:value-of select="concat('Rule  1: OK: ',
                              $table-ref-count,' table references and ',$table-def-count,' table definitions',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('Rule  1: ERROR: ',
                              $table-ref-count,' table references but ',$table-def-count,' table definitions',$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-2">
    <!-- Rule 2: each referenced table must have a definition -->
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and @type != 'Base']/metadetail">
        <xsl:variable name="ref-table"
                      select="@name"/>
        <xsl:variable name="def-table"
                      select="/diagram/tables/table[@name = $ref-table]/@name"/>
        <xsl:if test="string-length($def-table) = 0">
          <xsl:value-of select="concat('Rule  2: ERROR: definition for table [',$ref-table,'] not found',$nl)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  2: OK: found definitions for all referenced tables',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-3">
    <!-- Rule 3: each defined table must be referenced -->
    <xsl:variable name="error-list">
      <xsl:for-each select="tables/table">
        <xsl:variable name="def-table"
                      select="@name"/>
        <xsl:variable name="ref-table"
                      select="/diagram/metadata/metaitem[@name = 'schema' and
                              @type != 'Base']/metadetail[@name = $def-table]/@name"/>
        <xsl:if test="string-length($ref-table) = 0">
          <xsl:value-of select="concat('Rule  3: ERROR: reference for table [',$def-table,'] not found',$nl)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  3: OK: found references for all definded tables',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-4">
    <!-- Rule 4: no duplictes in definition list allowed -->
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/tables/table">
        <xsl:variable name="outer-position" select="position()"/>
        <xsl:variable name="outer-table"    select="@name"/>
        <xsl:for-each select="/diagram/tables/table">
          <xsl:variable name="inner-position" select="position()"/>
          <xsl:variable name="inner-table" select="@name"/>
          <xsl:if test="$inner-table = $outer-table and $inner-position &gt; $outer-position ">
            <xsl:value-of select="concat('Rule  4: ERROR: found duplicate definitions for table ',$inner-table,$nl)"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  4: OK: no duplicate table definitions found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-5">
    <!-- Rule 5: no duplictes in reference list allowed -->
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and @type != 'Base']/metadetail">
        <xsl:variable name="outer-position" select="position()"/>
        <xsl:variable name="outer-table" select="@name"/>
        <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and @type != 'Base']/metadetail">
          <xsl:variable name="inner-position" select="position()"/>
          <xsl:variable name="inner-table" select="@name"/>
          <xsl:if test="$inner-table = $outer-table and $inner-position &gt; $outer-position ">
            <xsl:value-of select="concat('Rule  4: ERROR: found duplicate references for table ',$inner-table,$nl)"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  5: OK: no duplicate table references found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-6">
    <!-- Rule 6: no column name should match valid_from or valid_to -->
    <xsl:variable name="valid-from"     select="fcn:get-config-value('valid-from')"/>
    <xsl:variable name="valid-to"       select="fcn:get-config-value('valid-to')"/>
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/tables/table">
        <xsl:variable name="table" select="fcn:to-lower-case(@name)"/>
        <xsl:for-each select="columns/column">
          <xsl:variable name="column" select="fcn:to-lower-case(@name)"/>
          <xsl:if test="$column = $valid-from or $column = $valid-to">
            <xsl:value-of select="concat('Rule  6: ERROR: found illegal column name ',$column,' in table ',$table,$nl)"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  6: OK: no illegal column name found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  
  <xsl:template name="rule-7">
    <!-- Rule 7: primary key for const or dim table must be single column -->
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and (@type = 'Const' or @type = 'Dim')]/metadetail">
        <xsl:variable name="table" select="@name"/>
        <xsl:for-each select="/diagram/tables/table[@name = $table]">
          <xsl:variable name="pk-size" select="count(primary/key)"/>
          <xsl:if test="$pk-size != 1">
            <xsl:value-of select="concat('Rule  7: ERROR: found invalid primary key size ',$pk-size,' for table ',$table,$nl)"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  7: OK: no invalid primary key size found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-8">
    <!-- Rule 8: primary key for const and dim table must be of type Id_Type -->
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and (@type = 'Const' or @type = 'Dim')]/metadetail">
        <xsl:variable name="table" select="@name"/>
        <xsl:for-each select="/diagram/tables/table[@name = $table]">
          <xsl:variable name="pk-column" select="primary/key/@name"/> 
          <xsl:for-each select="columns/column[@name = $pk-column]">
            <xsl:variable name="type" select="@type"/>
            <xsl:if test="$type != 'Id_Type'">
              <xsl:value-of select="concat('Rule  8: ERROR: found invalid type ',$type,
                                    ' for primary column ',$pk-column,' for table ',$table,$nl)"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  8: OK: no invalid primary key types found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  
  <xsl:template name="rule-9">
    <!-- Rule 9: primary key columns for const and dim tables must be unique in model -->
    <xsl:variable name="table-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and (@type = 'Const' or @type = 'Dim')]/metadetail">
        <xsl:variable name="table" select="@name"/>
        <xsl:value-of select="concat($table,' ')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/tables/table[fcn:find($table-list,@name) != 0]/primary/key">
        <xsl:variable name="out-table" select="../../@name"/>
        <xsl:variable name="out-column" select="@name"/>
        <xsl:variable name="out-position" select="position()"/>
        <xsl:for-each select="/diagram/tables/table[fcn:find($table-list,@name) != 0]/primary/key">
          <xsl:variable name="in-table" select="../../@name"/>
          <xsl:variable name="in-column" select="@name"/>
          <xsl:variable name="in-position" select="position()"/>
          <xsl:if test="$out-column = $in-column and $out-position != $in-position">
            <xsl:value-of select="concat('Rule  9: ERROR: found column [',$in-column,'] in table [',
                                  $in-table,'] and in table [',$out-table,']',$nl)"/>
          </xsl:if>
          </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule  9: OK: no duplicate primary key columns found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template name="rule-10">
    <!-- Rule 10: all tables must have primary key -->
    <xsl:variable name="table-count" select="count(/diagram/tables/table)"/>
    <xsl:variable name="primary-count" select="count(/diagram/tables/table/primary)"/>
    <xsl:choose>
      <xsl:when test="$table-count = $primary-count">
        <xsl:value-of select="concat('Rule 10: OK: all tables have a primary key',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('Rule 10: ERROR: found ',$table-count,
                              ' tables but ',$primary-count,' primary keys',$nl)"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  
  <xsl:template name="rule-11">
    <!-- Rule 11: non primary key column names should be unique in all const and dim tables of model -->
    <xsl:variable name="table-list">
      <xsl:for-each select="/diagram/metadata/metaitem[@name = 'schema' and (@type = 'Const' or @type = 'Dim')]/metadetail">
        <xsl:variable name="table" select="@name"/>
        <xsl:value-of select="concat($table,' ')"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="error-list">
      <xsl:for-each select="/diagram/tables/table[fcn:find($table-list,@name) != 0]/columns/column">
        <xsl:variable name="out-table" select="../../@name"/>
        <xsl:variable name="out-primary" select="../../primary/key/@name"/>
        <xsl:variable name="out-column" select="@name"/>
        <xsl:variable name="out-position" select="position()"/>
        <xsl:for-each select="/diagram/tables/table[fcn:find($table-list,@name) != 0]/columns/column">
          <xsl:variable name="in-table" select="../../@name"/>
          <xsl:variable name="in-primary" select="../../primary/key/@name"/>
          <xsl:variable name="in-column" select="@name"/>
          <xsl:variable name="in-position" select="position()"/>
          <xsl:if test="$in-column = $out-column and $in-position &gt; $out-position and
                        $in-primary != $in-column and $out-primary != $out-column">
            <xsl:value-of select="concat('Rule 11: WARNING: found column [',$in-column,'] in table [',
                                  $in-table,'] and in table [',$out-table,']',$nl)"/>
          </xsl:if>
          </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string-length($error-list) = 0">
        <xsl:value-of select="concat('Rule 11: OK: no duplicate column names found',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$error-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
</xsl:stylesheet> 
